#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

echo "=== Starting Update and Publish process ==="

# Update all submodules to their latest versions
echo "::group::Updating submodules"
git submodule update --init --recursive --remote
echo "::endgroup::"

# Step 1: Clean old patch versions before preparing clean GH repository
echo "::group::Cleaning old patch versions"
cleaned_count=0

# Function to compare versions (supports x.y.z and x.y.z.t)
# Returns 0 if v1 >= v2, 1 otherwise
version_gte() {
  local v1=$1 v2=$2
  IFS='.' read -ra v1_parts <<< "$v1"
  IFS='.' read -ra v2_parts <<< "$v2"

  # Pad arrays to same length with zeros
  local max_len=${#v1_parts[@]}
  [[ ${#v2_parts[@]} -gt $max_len ]] && max_len=${#v2_parts[@]}

  for ((i=0; i<max_len; i++)); do
    local n1=${v1_parts[i]:-0}
    local n2=${v2_parts[i]:-0}
    if (( n1 > n2 )); then
      return 0
    elif (( n1 < n2 )); then
      return 1
    fi
  done
  return 0  # Equal
}

for module in *; do
  if [[ -d "$module" ]] && [[ ! "$module" =~ ^(\.git|\.github|\.idea|_layouts)$ ]]; then
    declare -A version_groups=()

    # Detect versions (3 or 4 parts)
    for version_dir in "$module"/*/; do
      if [[ -d "$version_dir" ]]; then
        version_name=$(basename "$version_dir")
        # Match x.y.z or x.y.z.t
        if [[ "$version_name" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(\.([0-9]+))?$ ]]; then
          major="${BASH_REMATCH[1]}"
          minor="${BASH_REMATCH[2]}"
          group_key="${major}.${minor}"

          # Keep highest version in this major.minor group
          if [[ -z "${version_groups[$group_key]:-}" ]]; then
            version_groups[$group_key]="$version_name"
          else
            current_version="${version_groups[$group_key]}"
            if version_gte "$version_name" "$current_version"; then
              version_groups[$group_key]="$version_name"
            fi
          fi
        fi
      fi
    done

    declare -A keep_versions=()
    if [[ ${#version_groups[@]} -gt 0 ]]; then
      for group in "${!version_groups[@]}"; do
        keep_versions[${version_groups[$group]}]=1
      done
    fi

    # Delete versions not kept
    declare -a deleted_versions=()
    for version_dir in "$module"/*/; do
      if [[ -d "$version_dir" ]]; then
        version_name=$(basename "$version_dir")
        # Match x.y.z or x.y.z.t
        if [[ "$version_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] && [[ -z "${keep_versions[$version_name]:-}" ]]; then
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
      cleaned_count=$((cleaned_count + 1))
    fi

    unset version_groups
    unset keep_versions
    unset deleted_versions
  fi
done
echo "Cleaned $cleaned_count module(s)"
echo "::endgroup::"

# Step 2: Prepare clean GH Pages repository
echo "::group::Preparing clean GH Pages repository"
SOURCE_DIR=$(pwd)
CLEAN_GH_REPO=$(mktemp -d)
cd "$CLEAN_GH_REPO"

# Initialize fresh repo for gh-pages
git init
git config user.name "${GIT_USER_NAME}"
git config user.email "${GIT_USER_EMAIL}"

# Copy files excluding git metadata
rsync -a --exclude='.git' --exclude='.gitmodules' "$SOURCE_DIR/" .

git add -A
git commit -m "Update submodules and prepare clean GH Pages repo"
echo "::endgroup::"

# Step 3: Extract and organize UML documentation into dedicated modules
echo "::group::Extracting UML documentation"
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
  git commit -m "Extract UML documentation from updated modules"
fi
echo "::endgroup::"

echo "::group::Pushing to gh-pages"
git remote add origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git push origin HEAD:gh-pages --force
echo "::endgroup::"

# Cleanup
cd "$SOURCE_DIR"
rm -rf "$CLEAN_GH_REPO"

echo "=== Update and Publish process completed successfully ==="
