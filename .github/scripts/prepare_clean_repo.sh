#!/usr/bin/env bash
set -euo pipefail

echo "Starting build and publish process..."

SOURCE_DIR=$(pwd)
echo "SOURCE_DIR=$SOURCE_DIR" >> $GITHUB_ENV

CLEAN_REPO=$(mktemp -d)
echo "CLEAN_REPO=$CLEAN_REPO" >> $GITHUB_ENV

echo "Initializing clean repo..."
cd "$CLEAN_REPO"
git init
git config user.name "${GIT_USER_NAME}"
git config user.email "${GIT_USER_EMAIL}"

echo "Copy all files except .git/.gitmodules"
rsync -av --exclude='.git' --exclude='.gitmodules' "$SOURCE_DIR/" .

git add -A
git commit -m "Update submodules and clean old patch versions"
echo "Clean repository ready."
