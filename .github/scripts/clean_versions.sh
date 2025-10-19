#!/bin/bash
set -e

echo "=== Cleaning old patch versions ==="

if [[ -z "$CLEAN_GH_PAGES" ]]; then
  echo "ERROR: CLEAN_GH_PAGES not set"
  exit 1
fi

cd "$CLEAN_GH_PAGES"

for module in *; do
  if [[ -d "$module" ]]; then
    [[ "$module" == ".git" || "$module" == "_layouts" || "$module" == ".github" || "$module" == ".idea" ]] && continue

    echo "Processing module: $module"

    declare -A version_groups

    # Identify highest patch version for each minor
    for version_dir in "$module"/*/; do
      [[ -d "$version_dir" ]] || continue
      version_name=$(basename "$version_dir")
      if [[ "$version_name" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        group_key="${major}.${minor}"

        if [[ -z "${version_groups[$group_key]}" ]] || (( patch > ${version_groups[$group_key]%:*} )); then
          version_groups[$group_key]="$patch:$version_name"
        fi
      fi
    done

    # Keep only the highest patch versions
    declare -A keep_versions
    for group in "${!version_groups[@]}"; do
      version_to_keep="${version_groups[$group]##*:}"
      keep_versions[$version_to_keep]=1
      echo "Keeping $module/$version_to_keep"
    done

    # Delete older versions
    declare -a deleted_versions
    for version_dir in "$module"/*/; do
      [[ -d "$version_dir" ]] || continue
      version_name=$(basename "$version_dir")
      if [[ "$version_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if [[ -z "${keep_versions[$version_name]}" ]]; then
          echo "Deleting $module/$version_name"
          rm -rf "$version_dir"
          deleted_versions+=("$version_name")
        fi
      fi
    done

    # Update list_versions.md if needed
    if [[ -f "$module/list_versions.md" && ${#deleted_versions[@]} -gt 0 ]]; then
      echo "Updating $module/list_versions.md..."
      temp_file=$(mktemp)
      while IFS= read -r line; do
        keep_line=true
        for deleted_version in "${deleted_versions[@]}"; do
          if [[ "$line" =~ \|[[:space:]]*${deleted_version}[[:space:]]*\| ]] || \
             [[ "$line" =~ \(${deleted_version}\) ]] || \
             [[ "$line" =~ \(${deleted_version}/ ]]; then
            keep_line=false
            break
          fi
        done
        $keep_line && echo "$line" >> "$temp_file"
      done < "$module/list_versions.md"
      mv "$temp_file" "$module/list_versions.md"
      echo "Updated list_versions.md, removed ${#deleted_versions[@]} versions"
    fi

    unset version_groups keep_versions deleted_versions
  fi
done

git add -A
git commit --amend --no-edit
echo "Old patch versions cleaned successfully"
