---
name: creating-pull-requests
description: Use when creating a PR - fully automated, no review steps
---

# Creating Pull Requests

Fully automated. No confirmation prompts.

Branch, PR, commit follow project convention. Fallback to conventional style.

## Steps

### 1. Prepare (parallel)
```bash
git status --porcelain                                           # uncommitted
gh repo view --json defaultBranchRef -q .defaultBranchRef.name   # base branch
git branch --show-current                                        # current branch
git log --oneline @{u}.. 2>/dev/null || git log --oneline -5     # commits
find . .github -maxdepth 1 -iname 'pull_request_template*' 2>/dev/null | head -1 | xargs cat 2>/dev/null  # PR template
```

If uncommitted: `git add -A && git commit`

### 2. Push & Create PR
```bash
git push -u origin HEAD
gh pr view --json url -q .url 2>/dev/null || gh pr create --fill [--draft]
```
- Add `--draft` if branch matches `wip/|draft/|WIP-`
- Extract ticket/issue from branch name if present

### 3. Done

Output PR URL.

## Auto Merge

Only on explicit request:
```bash
gh pr merge --auto
```
