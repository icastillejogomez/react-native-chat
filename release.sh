#!/bin/bash

# Check for pending changes to commit in git
if [ -n "$(git status --porcelain)" ]; then
  echo "There are pending changes to commit in git. Please commit or discard these changes before running this script."
  exit 1
fi

if [ -z "$1" ]; then
  echo "You must specify the new version."
  exit 1
fi

# Check if j1 command is available under node_modules/.bin/jq
if ! [ -x "$(command -v ./node_modules/.bin/jq)" ]; then
  echo "jq is not installed. Please install running 'npm install' and try again."
  exit 1
fi

if ! npm run lint; then
  echo "Linting failed. The release will be stopped."
  exit 1
fi

if ! npm run check-types; then
  echo "Type checking failed. The release will be stopped."
  exit 1
fi

if ! npm run test; then
  echo "Testing failed. The release will be stopped."
  exit 1
fi

# Update package.json with the new version
./node_modules/.bin/jq --arg ver "$1" '.version = $ver' package.json > package.json.tmp && mv package.json.tmp package.json
./node_modules/.bin/jq --arg ver "$1" '.version = $ver' package-lock.json > package-lock.json.tmp && mv package-lock.json.tmp package-lock.json

# Create the commit
git add .
git commit -m "Upgrade to v$1" -n

# Create the tag
git tag "v$1"

# Push tag
git push origin "$(git branch --show-current)" --tags
