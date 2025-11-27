---
description: Manage .git/info/exclude file for personal file exclusions
allowed-tools:
  - Bash
  - Read
---

# Git Exclude Manager

Manage `.git/info/exclude` file to exclude personal files from Git repository.

## Usage

```bash
/git-exclude <pattern>      # Add pattern
/git-exclude --list         # Show current patterns
/git-exclude --clear        # Clear all patterns
```

## Examples

```bash
# Exclude personal config files
/git-exclude "*.local"
/git-exclude ".vscode/"

# Show current exclude patterns
/git-exclude --list

# Clear all exclude patterns
/git-exclude --clear
```

## Internal Bash Commands

### Add Pattern
```bash
# Create .git/info directory if needed and add pattern
mkdir -p .git/info
echo "*.local" >> .git/info/exclude
```

### List Patterns
```bash
# Show contents of exclude file
cat .git/info/exclude 2>/dev/null || echo "No exclude patterns found"
```

### Clear All
```bash
# Remove exclude file
rm -f .git/info/exclude
```

### Prevent Duplicates
```bash
# Check if pattern exists before adding
if ! grep -q "^\\.vscode/$" .git/info/exclude 2>/dev/null; then
    echo ".vscode/" >> .git/info/exclude
fi
```

## Description

`.git/info/exclude` is a repository-specific personal ignore file:
- Not shared with other collaborators
- Lower priority than .gitignore
- Perfect for personal file exclusions

For global ignore, use `git config --global core.excludesFile ~/.gitignore`
