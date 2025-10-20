# Keyple API Documentation

[![License](https://img.shields.io/badge/License-EPL_2.0-red.svg)](https://opensource.org/licenses/EPL-2.0)

Central repository for API documentation of all **Eclipse Keyple** libraries, including both **Java** (Javadoc) and
**C++** (Doxygen) references.

Published at: [https://docs.keyple.org/](https://docs.keyple.org/)

---

## Table of Contents

- [Architecture](#architecture)
- [Branch Structure](#branch-structure)
- [Automated Publication Workflow](#automated-publication-workflow)
- [Managing Documentation](#managing-documentation)
- [Maintenance & Troubleshooting](#maintenance--troubleshooting)

---

## Architecture

This repository aggregates documentation from multiple Keyple libraries using **Git submodules**. Each library maintains its own documentation in its repository's `doc` branch, and this repository automatically publishes a consolidated view.

### Key Components

1. **Submodules**: Each Keyple library is included as a Git submodule (30+ libraries)
2. **Workflow**: GitHub Actions automatically updates and publishes documentation
3. **Version Management**: Old patch versions are automatically cleaned (keeps only latest per minor version)
4. **UML Generation**: Automatically generates UML documentation from Java/KMP libraries

---

## Branch Structure

### `main`
- **Purpose**: Repository configuration and automation scripts
- **Contains**:
  - Workflow definitions (`.github/workflows/`)
  - Publication script (`.github/scripts/update_and_publish.sh`)
  - This README
- **Who modifies**: DevOps/maintainers

### `gh-pages-source`
- **Purpose**: Source configuration for documentation
- **Contains**:
  - Git submodule definitions (`.gitmodules`)
  - Jekyll configuration (`_config.yml`, `_layouts/`)
  - Index pages
- **Who modifies**: When adding/removing libraries

### `gh-pages`
- **Purpose**: Published documentation (auto-generated, **do not edit manually**)
- **Contains**:
  - All extracted documentation from submodules
  - Generated UML documentation
  - Jekyll site ready for GitHub Pages
- **Who modifies**: Automated workflow only

---

## Automated Publication Workflow

### Trigger Events

The workflow runs automatically on:
- **Manual trigger**: Via GitHub Actions UI
- **Schedule**: (configure if needed)
- **Repository dispatch**: When a library publishes new docs

### Workflow Steps

```mermaid
graph LR
    A[Checkout gh-pages-source] --> B[Update Submodules]
    B --> C[Clean Old Versions]
    C --> D[Copy to Clean Repo]
    D --> E[Generate UML Docs]
    E --> F[Push to gh-pages]
```

#### 1. **Update Submodules** (~30s)
Fetches latest documentation from all library `doc` branches.

#### 2. **Clean Old Patch Versions** (~1s)
Removes outdated patch versions to save space:
- Keeps: `2.1.0`, `2.2.5`, `3.0.1` (latest per minor)
- Removes: `2.2.0`, `2.2.1`, `2.2.2`, `2.2.3`, `2.2.4`

#### 3. **Prepare Clean Repository** (~10s)
Copies documentation files excluding Git metadata:
```bash
rsync -a --exclude='.git' --exclude='.gitmodules'
```

#### 4. **Generate UML Documentation** (~1s)
Creates `-uml-` variants for Java/KMP libraries:
- `keyple-card-calypso-java-lib` → `keyple-card-calypso-uml-lib`
- Extracts class diagrams (`api_class_diagram.svg`)

#### 5. **Force Push to gh-pages** (~20s)
Publishes consolidated documentation to GitHub Pages.

**Total Duration**: ~1 minute 12 seconds for 30+ libraries

### Monitoring

View workflow runs: [Actions > Update Submodules and Publish](../../actions/workflows/update-submodules.yml)

Logs are organized in collapsible groups:
- Updating submodules
- Cleaning old patch versions
- Preparing clean GH Pages repository
- Generating UML documentation
- Pushing to gh-pages

---

## Managing Documentation

### Adding a New Library

1. **Switch to gh-pages-source branch**:
```bash
git checkout gh-pages-source
```

2. **Add submodule**:
```bash
git submodule add -b doc \
  https://github.com/eclipse-keyple/[library-name].git \
  [library-name]
```

3. **Commit and push**:
```bash
git add .gitmodules [library-name]
git commit -m "feat: add documentation for [library-name]"
git push origin gh-pages-source
```

4. **Trigger workflow**: The documentation will be published automatically on next run.

### Removing a Library

1. **Switch to gh-pages-source branch**:
```bash
git checkout gh-pages-source
```

2. **Remove submodule**:
```bash
git submodule deinit -f [library-name]
rm -rf .git/modules/[library-name]
git rm -f [library-name]
```

3. **Commit and push**:
```bash
git commit -m "feat: remove documentation for [library-name]"
git push origin gh-pages-source
```

### Manually Triggering Publication

1. Go to [Actions](../../actions/workflows/update-submodules.yml)
2. Click "Run workflow"
3. Select branch `main`
4. Click "Run workflow"

---

## Maintenance & Troubleshooting

### Common Issues

#### Workflow fails with "unbound variable"
**Cause**: Script uses `set -u` (strict mode) and encounters uninitialized variable.
**Fix**: Check script `.github/scripts/update_and_publish.sh` - all variables must be initialized.

#### Workflow fails with "Unable to find refs/remotes/origin/doc"
**Cause**: Submodule doesn't have a `doc` branch.
**Fix**: Ensure library has a `doc` branch, or update `.gitmodules` with correct branch.

#### Documentation not appearing on site
**Cause**: Submodule not properly initialized or workflow didn't run.
**Fix**:
1. Check workflow ran successfully
2. Verify submodule exists in `gh-pages-source` branch
3. Check library's `doc` branch has content

### Workflow Script Location

The publication logic is in: `.github/scripts/update_and_publish.sh`

**Important**: The script is fetched from `main` branch during workflow execution:
```yaml
- name: Fetch scripts from main branch
  run: |
    git fetch origin main
    git checkout origin/main -- .github/scripts/update_and_publish.sh
```

To modify the script:
1. Edit on `main` branch
2. Push changes
3. Next workflow run will use updated script

### Debugging Workflow

Enable detailed logging by adding to script:
```bash
set -x  # Print each command before execution
```

View logs with GitHub CLI:
```bash
gh run list --workflow=update-submodules.yml --limit 5
gh run view [RUN_ID] --log
gh run watch [RUN_ID]  # Real-time monitoring
```

### Disk Space Optimization

Current workflow processes:
- **30,515 files**
- **3.6 million lines of code**
- **Execution time**: ~1m12s
- **Disk usage**: ~200-300 MB

This is already optimized (2-3x faster than typical multi-submodule workflows).

### Version Cleanup Logic

```bash
# Example: For keyple-card-calypso-java-lib
# Before: 2.1.0, 2.2.0, 2.2.1, 2.2.2, 2.2.3, 2.2.4, 2.2.5, 3.0.0, 3.0.1
# After:  2.1.0, 2.2.5, 3.0.1
# Kept: Latest patch version per major.minor group
```

To modify cleanup behavior, edit the script's "Clean old patch versions" section.

### Emergency: Revert Published Docs

If bad documentation is published:

```bash
# Find previous good commit on gh-pages
git log origin/gh-pages

# Force push previous commit
git push origin [GOOD_COMMIT_SHA]:gh-pages --force
```

Or re-run workflow after fixing `gh-pages-source`.

## Contributing

Please read our [contribution guidelines](https://keyple.org/community/contributing/) before submitting any changes.

## License

This project is licensed under the Eclipse Public License v. 2.0. See [LICENSE](LICENSE) for details.