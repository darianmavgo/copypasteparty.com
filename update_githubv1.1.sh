#!/bin/bash

# Script to update https://github.com/darianmavgo/copypasteparty.com with new HTML content
# Assumes git and gh (GitHub CLI) are installed, and index.html is in the current directory

# Configuration
REPO_URL="https://github.com/darianmavgo/copypasteparty.com.git"
BRANCH="main"
HTML_FILE="index.html"
COMMIT_MESSAGE="Update index.html with new website content"

# Check if index.html exists in the current directory
if [ ! -f "$HTML_FILE" ]; then
    echo "Error: $HTML_FILE not found in the current directory"
    exit 1
fi

# Step 1: Ensure we're in a git repository
if [ ! -d ".git" ]; then
    echo "Error: Current directory is not a git repository"
    exit 1
fi

# Step 2: Ensure we're on the main branch
git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to checkout or create branch $BRANCH"
    exit 1
fi

# Pull latest changes to avoid conflicts
git pull origin "$BRANCH"
if [ $? -ne 0 ]; then
    echo "Warning: Failed to pull latest changes. Continuing, but you may need to resolve conflicts manually."
fi

# Step 3: Stage and commit changes to index.html
git add "$HTML_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to stage $HTML_FILE"
    exit 1
fi

git commit -m "$COMMIT_MESSAGE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to commit changes"
    exit 1
fi

# Step 4: Push changes to GitHub
git push origin "$BRANCH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to push changes to $BRANCH"
    exit 1
fi
echo "Changes pushed to $BRANCH"

# Step 5: Configure GitHub Pages using gh CLI
echo "Configuring GitHub Pages..."
gh repo set-default darianmavgo/copypasteparty.com
if [ $? -ne 0 ]; then
    echo "Error: Failed to set default repository for gh CLI"
    exit 1
fi

# Enable GitHub Pages for the main branch, root directory
gh api -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/darianmavgo/copypasteparty.com/pages \
  -f "source[branch]=$BRANCH" \
  -f "source[path]=/"
if [ $? -ne 0 ]; then
    echo "Error: Failed to configure GitHub Pages. Please check repository settings manually."
    exit 1
fi
echo "GitHub Pages configured to serve from $BRANCH branch, root directory"

# Step 6: Prompt for custom domain setup (cannot fully automate DNS)
echo "Do you want to set up a custom domain (copypasteparty.com)? (y/n)"
read -r setup_domain
if [ "$setup_domain" = "y" ] || [ "$setup_domain" = "Y" ]; then
    # Add CNAME file
    echo "copypasteparty.com" > CNAME
    git add CNAME
    git commit -m "Add CNAME for custom domain"
    git push origin "$BRANCH"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to push CNAME file"
        exit 1
    fi
    echo "Added CNAME file for copypasteparty.com"

    # Configure custom domain via GitHub API
    gh api -X PUT \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      /repos/darianmavgo/copypasteparty.com/pages \
      -f "source[branch]=$BRANCH" \
      -f "source[path]=/" \
      -f "cname=copypasteparty.com"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set custom domain. Please set it manually in GitHub Pages settings."
        exit 1
    fi
    echo "Custom domain copypasteparty.com set in GitHub Pages"

    echo "Please configure DNS at your domain registrar:"
    echo "1. Add A records pointing to:"
    echo "   185.199.108.153"
    echo "   185.199.109.153"
    echo "   185.199.110.153"
    echo "   185.199.111.153"
    echo "2. Add a CNAME record for www.copypasteparty.com pointing to darianmavgo.github.io"
    echo "DNS changes may take up to 24 hours to propagate."
fi

# Step 7: Output final instructions
echo "Deployment complete!"
echo "Your website should be live at https://darianmavgo.github.io/copypasteparty.com"
if [ "$setup_domain" = "y" ] || [ "$setup_domain" = "Y" ]; then
    echo "After DNS propagation, it will also be available at https://copypasteparty.com"
fi
echo "If the site doesn't update, wait 5-10 minutes, clear your browser cache, or try incognito mode."
echo "Check for errors in GitHub repository settings or Actions tab if issues persist."

