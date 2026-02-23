#!/bin/bash
set -e

BUILD_DIR="build/web"
DEPLOY_BRANCH="gh-pages"
TEMP_DIR="$(mktemp -d)"

echo "Building Flutter web project..."
flutter build web --base-href "/Dyson-Descent/"

# Get the remote URL from the main repo
REMOTE_URL=$(git config --get remote.origin.url)
if [ -z "$REMOTE_URL" ]; then
    echo "Error: Could not find remote.origin.url"
    exit 1
fi

echo "Preparing temporary deployment directory..."
cp -r $BUILD_DIR/* $TEMP_DIR

cd $TEMP_DIR

echo "Initializing temporary git repo..."
git init
git remote add origin "$REMOTE_URL"
git checkout -b $DEPLOY_BRANCH
git add .
git commit -m "Deploy Flutter web build: $(date '+%Y-%m-%d %H:%M:%S')"

echo "Pushing to $DEPLOY_BRANCH branch..."
git push --force origin $DEPLOY_BRANCH

echo "Deployment complete!"