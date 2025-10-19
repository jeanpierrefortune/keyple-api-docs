#!/bin/bash
set -e

echo "=== Preparing clean GH Pages repository ==="

# SOURCE_DIR: source repo (gh-pages-source)
# CLEAN_GH_PAGES: destination clean repo (temporary for gh-pages)

if [[ -z "$SOURCE_DIR" ]] || [[ -z "$CLEAN_GH_PAGES" ]]; then
  echo "ERROR: SOURCE_DIR or CLEAN_GH_PAGES not set"
  exit 1
fi

echo "Source directory: $SOURCE_DIR"
echo "Clean GH Pages directory: $CLEAN_GH_PAGES"

# Remove old temporary repo if exists
rm -rf "$CLEAN_GH_PAGES"

# Create new clean repo
mkdir -p "$CLEAN_GH_PAGES"
cd "$CLEAN_GH_PAGES"
git init
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

echo "Copying source content to clean repo..."
rsync -av --exclude='.git' --exclude='.gitmodules' "$SOURCE_DIR/" .

git add -A
git commit -m "Initial clean commit for GH Pages"
echo "Clean GH Pages repository prepared successfully"
