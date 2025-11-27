---
name: creating-pull-requests
description: Use when creating or updating a PR - enforces base branch detection, draft for WIP branches, selective git add
---

# Creating Pull Requests

## Overview

Streamlined PR workflow minimizing roundtrips. Enforces explicit `--base`, `--draft` for WIP branches, and selective file staging.

## Quick Reference

| Condition | Action |
|-----------|--------|
| PR exists | `gh pr edit --title "..." --body "..."` |
| Branch `wip/\|draft/\|WIP-` | `gh pr create --draft --base $BASE` |
| Otherwise | `gh pr create --base $BASE` |

## Implementation

### 1. Gather Context (single parallel call)
```bash
git status --porcelain
git branch --show-current
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && \
  git log --oneline $BASE..HEAD && \
  git diff $BASE..HEAD --stat
find . .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1 | xargs cat 2>/dev/null
```

### 2. Commit Uncommitted Changes
- `git add <specific-files>` - stage only relevant files
- NEVER `git add -A` blindly

### 3. Push & Create/Update PR
```bash
git push -u origin HEAD
gh pr view --json url -q .url 2>/dev/null && gh pr edit ... || gh pr create --base $BASE ...
```

Fill PR template sections from commits and diff.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | Always use `--base $BASE` from step 1 |
| Forget `--draft` for WIP | Check branch name pattern before creating |
| `git add -A` | Review status, add specific files only |

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
