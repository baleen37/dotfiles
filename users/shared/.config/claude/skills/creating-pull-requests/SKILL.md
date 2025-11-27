---
name: creating-pull-requests
description: Use when creating or updating a PR - enforces parallel context gathering, explicit --base flag, PR state check before action
---

# Creating Pull Requests

## Overview

Prevent common PR mistakes. **Core: gather all context in parallel, always use --base.**

## Red Flags - STOP If You Think This

- "GitHub will use the default branch anyway" → **WRONG.** `--base` is mandatory
- "Let me check status first..." → **WRONG.** Gather all context in parallel
- "There's no existing PR" → **WRONG.** Always check PR state first

## Implementation (Exactly 3 Steps)

### 1. Gather Context (parallel Bash calls)

Run these commands in **parallel** (multiple Bash tool calls in one message):

```bash
# Call 1: Git state
git status --porcelain && git branch --show-current

# Call 2: Base branch and diff
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && \
echo "BASE=$BASE" && \
git log --oneline $BASE..HEAD && \
git diff $BASE..HEAD --stat

# Call 3: PR state
gh pr view --json state,number,url -q '{state: .state, number: .number, url: .url}' 2>/dev/null || echo "NO_PR"

# Call 4: PR template (if exists)
find .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1 | xargs cat 2>/dev/null
```

**Run all 4 calls in parallel. Sequential calls = failure.**

### 2. Commit Uncommitted Changes (if needed)

```bash
git add <specific-files>   # NEVER git add -A
git commit -m "..."
```

### 3. Push & Create/Update PR

```bash
git push -u origin HEAD
```

Then based on PR state:

| PR State | Command |
|----------|---------|
| `OPEN` | `gh pr edit --title "..." --body "..."` |
| `NO_PR` or `MERGED`/`CLOSED` | See below |

**Creating new PR:**
```bash
gh pr create --base $BASE --title "..." --body "..."
```

## Rationalization Table

| Rationalization | Reality |
|-----------------|---------|
| "No time for --base" | Wrong base = more time wasted fixing it |
| "Can't gather context in parallel" | Yes you can - multiple Bash calls |
| "I'm sure there's no PR" | Not checking = duplicate PRs |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` |
| `git add -A` | Check status, add specific files only |
| Sequential context gathering | Use parallel Bash calls |

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
