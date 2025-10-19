#!/usr/bin/env bash
set -euo pipefail

echo "=== Starting Update and Publish process ==="

# Update all submodules to their latest versions
echo "::group::Updating submodules"
git submodule update --init --recursive --remote
echo "::endgroup::"

# Step 1: Clean old patch versions before preparing clean GH repository
echo "::group::Cleaning old patch versions"
cleaned_count=0
for module in *; do
  if [[ -d "$module" ]] && [[ ! "$module" =~ ^(\.git|\.github|\.idea|_layouts)$ ]]; then
    declare -A version_groups

    # Detect versions
    for version_dir in "$module"/*/; do
      if [[ -d "$version_dir" ]]; then
        version_name=$(basename "$version_dir")
        if [[ "$version_name" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
          major="${BASH_REMATCH[1]}"
          minor="${BASH_REMATCH[2]}"
          patch="${BASH_REMATCH[3]}"
          group_key="${major}.${minor}"
          if [[ -z "${version_groups[$group_key]:-}" ]] || (( patch > ${version_groups[$group_key]%%:*} )); then
            version_groups[$group_key]="$patch:$version_name"
          fi
        fi
      fi
    done

    declare -A keep_versions
    for group in "${!version_groups[@]}"; do
      keep_versions[${version_groups[$group]#*:}]=1
    done

    # Delete versions not kept
    declare -a deleted_versions=()
    for version_dir in "$module"/*/; do
      if [[ -d "$version_dir" ]]; then
        version_name=$(basename "$version_dir")
        if [[ "$version_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ -z "${keep_versions[$version_name]:-}" ]]; then
          rm -rf "$version_dir"
          deleted_versions+=("$version_name")
        fi
      fi
    done

    # Update list_versions.md
    if [[ -f "$module/list_versions.md" ]] && [[ ${#deleted_versions[@]} -gt 0 ]]; then
      temp_file=$(mktemp)
      while IFS= read -r line; do
        keep_line=true
        for deleted_version in "${deleted_versions[@]}"; do
          if [[ "$line" =~ \|[[:space:]]*$deleted_version[[:space:]]*\| ]] || \
             [[ "$line" =~ \($deleted_version\) ]] || \
             [[ "$line" =~ \($deleted_version/ ]]; then
            keep_line=false
            break
          fi
        done
        $keep_line && echo "$line" >> "$temp_file"
      done < "$module/list_versions.md"
      mv "$temp_file" "$module/list_versions.md"
      ((cleaned_count++))
    fi

    unset version_groups
    unset keep_versions
    unset deleted_versions
  fi
done
echo "Cleaned $cleaned_count module(s)"
echo "::endgroup::"

# Step 2: Prepare clean GH Pages repository using git worktree (saves ~50% disk space)
echo "::group::Preparing clean GH Pages repository"
SOURCE_DIR=$(pwd)
CLEAN_GH_REPO=$(mktemp -d)

# Use git worktree for efficient file handling
git worktree add --detach "$CLEAN_GH_REPO"
cd "$CLEAN_GH_REPO"

# Remove git metadata to create a clean orphan repo
rm -rf .git .gitmodules

# Initialize fresh repo for gh-pages
git init
git config user.name "${GIT_USER_NAME}"
git config user.email "${GIT_USER_EMAIL}"
git add -A
git commit -m "Update submodules and prepare clean GH Pages repo"
echo "::endgroup::"

# Step 3: Generate UML modules
echo "::group::Generating UML documentation"
for module in *; do
  if [[ -d "$module" ]]; then
    if [[ "$module" == *"-java-"* ]] || [[ "$module" == *"kmp"* ]]; then
      if [[ "$module" == *"-java-"* ]]; then
        uml_module="${module//-java-/-uml-}"
      else
        uml_module="${module//kmp/uml}"
      fi
      mkdir -p "$uml_module"

      for version_dir in "$module"/*/; do
        version_name=$(basename "$version_dir")
        [[ "$version_name" == "_layouts" || "$version_name" == ".git" ]] && continue
        if [[ -f "$version_dir/api_class_diagram.svg" ]]; then
          mkdir -p "$uml_module/$version_name"
          cp "$version_dir/api_class_diagram.svg" "$uml_module/$version_name/"
        fi
      done

      if [[ -f "$module/list_versions.md" ]]; then
        sed 's/\[API documentation\]([^)]*)<br>//g' "$module/list_versions.md" > "$uml_module/index.md"
      fi
    fi
  fi
done

# Commit and push
git add -A
if [[ -n $(git status --porcelain) ]]; then
  git commit -m "Generate UML documentation from updated modules"
fi
echo "::endgroup::"

echo "::group::Pushing to gh-pages"
git remote add origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git push origin HEAD:gh-pages --force
echo "::endgroup::"

# Cleanup: return to source and remove worktree
cd "$SOURCE_DIR"
git worktree remove --force "$CLEAN_GH_REPO" 2>/dev/null || rm -rf "$CLEAN_GH_REPO"

echo "=== Update and Publish process completed successfully ==="
