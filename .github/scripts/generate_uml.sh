#!/bin/bash
set -e

echo "=== Generating UML documentation ==="

if [[ -z "$CLEAN_GH_PAGES" ]]; then
  echo "ERROR: CLEAN_GH_PAGES not set"
  exit 1
fi

cd "$CLEAN_GH_PAGES"

# Delete old UML directories
echo "Deleting existing -uml directories..."
for dir in *-uml*/; do
  [[ -d "$dir" ]] && { echo "Deleting $dir"; rm -rf "$dir"; }
done

# Process modules to generate UML
for module in *; do
  [[ -d "$module" ]] || continue
  [[ "$module" == *"-java-"* || "$module" == *"kmp"* ]] || continue

  echo "Processing module: $module"

  if [[ "$module" == *"-java-"* ]]; then
    uml_module="${module//-java-/-uml-}"
  else
    uml_module="${module//kmp/uml}"
  fi

  mkdir -p "$uml_module"

  # Copy UML diagrams
  for version_dir in "$module"/*/; do
    [[ -d "$version_dir" ]] || continue
    version_name=$(basename "$version_dir")
    [[ "$version_name" == "_layouts" || "$version_name" == ".git" ]] && continue
    [[ -f "$version_dir/api_class_diagram.svg" ]] && {
      mkdir -p "$uml_module/$version_name"
      cp "$version_dir/api_class_diagram.svg" "$uml_module/$version_name/"
      echo "Copied UML diagram for $version_name"
    }
  done

  # Create index.md from list_versions.md
  [[ -f "$module/list_versions.md" ]] && sed 's/\[API documentation\]([^)]*)<br>//g' "$module/list_versions.md" > "$uml_module/index.md"

  echo "Finished $module -> $uml_module"
done

git add -A

if [[ -n $(git status --porcelain) ]]; then
  git commit -m "Generate UML documentation from updated modules"
  echo "UML documentation committed"
else
  echo "No UML documentation changes to commit"
fi
