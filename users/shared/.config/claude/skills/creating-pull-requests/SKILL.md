---
name: creating-pull-requests
description: Use when creating a PR - enforces pre-flight checks (template, diff, base branch)
---
### 1. Gather All Context (single parallel call)
```bash
git status --porcelain
git branch --show-current
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && \
  git log --oneline $BASE..HEAD && \
  git diff $BASE..HEAD --stat
find . .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1 | xargs cat 2>/dev/null
```

### 2. Handle Uncommitted Changes (if any)
- Stage only relevant files: `git add <specific-files>`
- NEVER `git add -A` blindly

### 3. Push & Create/Update PR
```bash
git push -u origin HEAD
gh pr view --json url -q .url 2>/dev/null && gh pr edit --title "..." --body "..." || gh pr create --base $BASE --title "..." --body "..."
```
- PR exists: update with `gh pr edit`
- No PR: create with `gh pr create --draft` if branch matches `wip/|draft/|WIP-`
- Extract ticket from branch name if present
- Fill PR template sections from commits and diff

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
