---
name: creating-pull-requests
description: Use when creating a PR - fully automated, no review steps
---

# Creating Pull Requests

Fully automated. No confirmation prompts.

## Steps

### 1. Pre-flight & Commit (parallel)
```bash
git status --porcelain                                           # check uncommitted
gh repo view --json defaultBranchRef -q .defaultBranchRef.name   # base branch
git branch --show-current                                        # current branch
git log --oneline @{u}.. 2>/dev/null || git log --oneline -5     # commits
find .github -maxdepth 1 -iname 'pull_request_template*' -exec cat {} \; 2>/dev/null  # PR template
```

If uncommitted changes exist:
```bash
git add -A && git commit  # follow repo's commit convention
```

### 2. Push & Create PR
```bash
git push -u origin HEAD
gh pr create --fill [--draft]
```
Add `--draft` if branch matches `wip/|draft/|WIP-`.

### 3. Done

Output PR URL.

## Auto Merge

Only on explicit request:
```bash
gh pr merge --auto --squash
```
