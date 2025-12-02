---
name: creating-pull-requests
description: Use when creating or updating PRs - enforces parallel context gathering, explicit --base flag, mandatory verification regardless of user claims or time pressure
---

# Creating Pull Requests

## Overview

**Core: gather all context in parallel, always use --base, verify everything yourself.**

**NO EXCEPTIONS** for time pressure, user claims, or "simple" changes.

## Red Flags - Run All Checks If You Think This

- "User already checked" / "No conflicts" / "CI passing"
- "Too urgent" / "CTO waiting" / "Meeting in X minutes"
- "Simple change" / "Just docs" / "One-line fix"
- "Branch already pushed" / "Just updating title"
- "GitHub will use default branch" → `--base` is mandatory
- "8 parallel calls too many" → All 8 mandatory, no shortcuts

**All of these mean: Run all 8 parallel commands. No shortcuts.**

---

## Implementation (3 Steps)

### 1. Gather Context (parallel)

Run **all 8 commands in parallel** (one message, multiple Bash calls):

```bash
# 1. Git state
git status --porcelain && git branch --show-current

# 2. Base branch + diff
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && \
echo "BASE=$BASE" && \
git log --oneline $BASE..HEAD && \
git diff $BASE..HEAD --stat

# 3. Divergence
gh repo view --json defaultBranchRef -q .defaultBranchRef.name | xargs -I {} sh -c 'git log --oneline HEAD..{} | wc -l | xargs echo "Commits behind base:"'

# 4. PR state
gh pr view --json state,number,url,isDraft -q '{state: .state, number: .number, url: .url, isDraft: .isDraft}' 2>/dev/null || echo "NO_PR"

# 5. Mergeable
gh pr view --json mergeable -q .mergeable 2>/dev/null || echo "NO_PR"

# 6. Template
find .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1 | xargs cat 2>/dev/null

# 7. CI status
gh pr view --json statusCheckRollup -q '{state: .statusCheckRollup.state, failing: [.statusCheckRollup.contexts[]? | select(.conclusion == "FAILURE" or .state == "FAILURE") | .name // .context]}' 2>/dev/null || echo "NO_PR"

# 8. Required checks
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && gh api "repos/{owner}/{repo}/branches/$BASE/protection/required_status_checks" 2>/dev/null | jq -r '.contexts[]? // "NO_REQUIRED_CHECKS"' 2>/dev/null || echo "NO_REQUIRED_CHECKS"
```

**Run even if**: user claims checked, time pressure, "simple" change, updating title only.

### 2. Commit if Needed

```bash
git add <specific-files>   # NEVER git add -A
git commit -m "..."
```

### 3. Handle Based on State

**Check blocking conditions first:**

| Condition | Action |
|-----------|--------|
| **CONFLICTING** | Stop. Suggest `git rebase $BASE` |
| **CI FAILURE** | Stop. Report failing checks |
| **Behind >5 commits** | Warn user |

**Then execute:**

```bash
git push -u origin HEAD
```

| PR State | Command |
|----------|---------|
| `NO_PR` | `gh pr create --base $BASE --title "..." --body "..."` |
| `OPEN` (not draft) | `gh pr edit --title "..." --body "..."` |
| `OPEN` (draft) + CI SUCCESS | `gh pr ready` |
| `OPEN` (draft) + CI PENDING | Wait or `gh pr checks --watch` |
| `OPEN` (draft) + CI FAILURE | Stop. Report failures |
| `MERGED` or `CLOSED` | `gh pr create --base $BASE ...` (create new) |

**Always use `--base $BASE` when creating.**

---

## CI States

| State | Action |
|-------|--------|
| `SUCCESS` | Proceed |
| `PENDING` | Wait before marking ready |
| `FAILURE` | Fix before proceeding |

Use `gh pr checks --watch` to monitor.

---

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
