---
name: create-feature-branch
description: Use when starting new development work - quickly creates git feature branches with standard naming conventions
---

# Create Feature Branch

Quickly create a feature branch for development work. This command handles the essential steps without over-engineering.

## Overview
Creates a new git branch following conventional naming patterns. Focuses on speed and simplicity over excessive safety checks.

## Quick Reference
```bash
# Basic usage
/feature-branch user-authentication     # → git switch -c user-authentication

# With prefixes
/feature-branch fix/login-bug          # → git switch -c fix/login-bug
/feature-branch refactor/api-client    # → git switch -c refactor/api-client
```

## Implementation
1. **Get branch name** - Prompt for simple, descriptive branch name
2. **Create branch** - Use `git switch -c` for new branch creation
3. **Confirm** - Show success and current branch status

## Common Patterns
- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation changes
- `test/description` - Test improvements

## Common Mistakes
**Don't overcomplicate** - This command should be fast, not a comprehensive workflow tool
**Don't add excessive checks** - Let developers handle git status/conflicts themselves
**Don't force remote setup** - Local branching is sufficient for most workflows
