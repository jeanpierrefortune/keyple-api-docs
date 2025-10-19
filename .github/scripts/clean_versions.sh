#!/usr/bin/env bash
set -euo pipefail

cd "$CLEAN_REPO"

for module in *; do
  [[ -d "$module" && ! "$module" =~ ^(\.git|_layouts|\.github|\.idea)$ ]] || continue
  echo "Processing module: $module"

  declare -A version_groups
  for version_dir in "$module"/*/; do
    [[ -d "$version_dir" ]] || continue
    version_name=$(basename "$version_dir")
    if [[ "$version_name" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
      major="${BASH_REMATCH[1]}"
      minor="${BASH_REMATCH[2]}"
      patch="${BASH_REMATCH[3]}"
      key="${major}.${minor}"
      current_patch="${version_groups[$key]:-0}"
      if (( patch > current_patch )); then
        version_groups[$key]=$patch
      fi
    fi
  done

  for version_dir in "$module"/*/; do
    [[ -d "$version_dir" ]] || continue
    version_name=$(basename "$version_dir")
    if [[ "$version_name" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
      major="${BASH_REMATCH[1]}"
      minor="${BASH_REMATCH[2]}"
      key="${major}.${minor}"
      max_patch=${version_groups[$key]}
      if (( BASH_REMATCH[3] < max_patch )); then
        echo "Deleting $module/$version_name"
        rm -rf "$version_dir"
      fi
    fi
  done
done

git add -A
git commit --amend --no-edit
