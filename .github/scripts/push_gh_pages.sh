#!/bin/bash
set -e

echo "=== Pushing clean GH Pages repository ==="

if [[ -z "$CLEAN_GH_PAGES" || -z "$GITHUB_TOKEN" ]]; then
  echo "ERROR: CLEAN_GH_PAGES or GITHUB_TOKEN not set"
  exit 1
fi

cd "$CLEAN_GH_PAGES"

git remote add origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git push origin HEAD:gh-pages --force

echo "Successfully pushed to gh-pages"
