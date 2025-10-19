#!/usr/bin/env bash
set -euo pipefail

cd "$CLEAN_REPO"

echo "Delete old -uml directories"
for dir in *-uml*/; do
  [[ -d "$dir" ]] || continue
  rm -rf "$dir"
done

echo "Generate UML modules"
for module in *; do
  [[ -d "$module" ]] || continue
  if [[ "$module" == *"-java-"* || "$module" == *"kmp"* ]]; then
    uml_module="${module//-java-/-uml-}"
    uml_module="${uml_module//kmp/uml}"
    mkdir -p "$uml_module"

    for version_dir in "$module"/*/; do
      [[ -d "$version_dir" ]] || continue
      version_name=$(basename "$version_dir")
      [[ "$version_name" =~ ^(_layouts|\.git)$ ]] && continue

      if [[ -f "$version_dir/api_class_diagram.svg" ]]; then
        mkdir -p "$uml_module/$version_name"
        cp "$version_dir/api_class_diagram.svg" "$uml_module/$version_name/"
      fi
    done

    if [[ -f "$module/list_versions.md" ]]; then
      sed 's/\[API documentation\]([^)]*)<br>//g' "$module/list_versions.md" > "$uml_module/index.md"
    fi
  fi
done

git add -A
if [[ -n $(git status --porcelain) ]]; then
  git commit -m "Generate UML documentation from updated modules"
fi
