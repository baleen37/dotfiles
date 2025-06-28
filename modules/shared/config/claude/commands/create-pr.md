# Create Pull Request

Smart PR creation with automatic conflict resolution and branch management.

## Usage
```bash
/project:create-pr [--draft] [--auto-merge] [--title "Custom Title"]
```

## Core Features

### 🎯 Default Branch Detection (No more "default" errors)
```bash
# Auto-detects via: GitHub API → git refs → common names → fallback
# Override if needed: export CREATE_PR_DEFAULT_BRANCH="main"
```

### 🛡️ Smart Conflict Prevention
```bash
# If branch is behind:
# 1. Pre-checks for conflicts
# 2. Tries merge first (easier to resolve)
# 3. Falls back to rebase if merge fails
# 4. Provides clear resolution steps
```

### ✅ Robust PR Creation
```bash
# Always specifies --base and --head explicitly
# Auto-generates title from branch or commit
# Handles existing PRs gracefully
```

## Quick Reference

| Problem | Solution |
|---------|----------|
| "default" branch error | Auto-detected with 4 fallback methods |
| Merge conflicts | Tries merge → rebase → manual guide |
| No origin remote | `git remote add origin <url>` |
| Not authenticated | `gh auth login` |
| Auto-merge fails | Check repo settings allows auto-merge |

## Examples

```bash
# Basic PR
/project:create-pr

# Draft with auto-merge
/project:create-pr --draft --auto-merge

# Custom title
/project:create-pr --title "feat: add new feature"
```

## Conflict Resolution

When conflicts occur:
```bash
# 1. Fix conflicts in listed files (look for <<<<<<< markers)
# 2. Stage resolved files
git add <resolved-files>

# 3. Continue operation
git rebase --continue  # or: git merge --continue

# 4. Re-run command
/project:create-pr
```

## Key Improvements

✅ **Never fails on default branch** - Multiple detection methods  
✅ **Prevents conflicts** - Pre-checks and dual strategy (merge→rebase)  
✅ **Clear recovery** - Step-by-step guidance when issues occur  
✅ **Explicit branches** - Always sets base/head to prevent ambiguity
