#!/usr/bin/env bash
set -euo pipefail

cd "$CLEAN_REPO"
git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${{ github.repository }}.git
git push origin HEAD:gh-pages --force
echo "Successfully pushed to gh-pages"
