#!/bin/bash
set -e
echo "Checking GitHub authentication status..."
if ! gh auth status >/dev/null 2>&1; then
    echo "You are not logged into GitHub. Running 'gh auth login'..."
    gh auth login
else
    echo "You are already logged into GitHub."
fi
echo "Checking for gh-dash extension..."
if ! gh extension list | grep -q "gh-dash"; then
    echo "Installing gh-dash extension..."
    gh extension install dlvhdr/gh-dash
else
    echo "gh-dash extension is already installed."
fi
echo "Setup complete! You can now run 'gh dash'."
