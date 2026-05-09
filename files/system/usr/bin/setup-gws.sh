#!/bin/bash
set -e
echo "Setting up gws (Google Workspace CLI)..."

if ! command -v gws &> /dev/null; then
    echo "gws is not installed. Please ensure you have rebuilt your image with the latest changes."
    exit 1
fi

echo "Checking gws login status..."
# Try to list calendars to see if we are logged in
if ! gws calendar list &> /dev/null; then
    echo "You are not logged into gws. Running 'gws login'..."
    gws login
else
    echo "You are already logged into gws."
fi
