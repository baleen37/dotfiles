---
name: creating-pull-requests
description: Use when creating or updating a PR, even if user says they already checked - enforces parallel context gathering, explicit --base flag, mandatory verification regardless of user claims or time pressure
---

# Creating Pull Requests

## Overview

Prevent common PR mistakes. **Core: gather all context in parallel, always use --base, verify everything yourself.**

**NO EXCEPTIONS for time pressure, user claims, or partial work done.**

## Red Flags - STOP If You Think This

- "GitHub will use the default branch anyway" → **WRONG.** `--base` is mandatory
- "Let me check status first..." → **WRONG.** Gather all context in parallel
- "Let me gather the necessary context" → **WRONG.** Just do it in parallel, don't announce
- "There's no existing PR" → **WRONG.** Always check PR state first
- "User already checked [X]" → **WRONG.** You must verify everything yourself
- "Branch is already pushed, skip context" → **WRONG.** Still need full parallel gathering
- "Too urgent for parallel calls" → **WRONG.** Parallel is faster than sequential + fixing
- "It's a simple one-line change" → **WRONG.** Simple changes still need full process
- "User is waiting, skip verification" → **WRONG.** Verification: 5 sec, fixing mistakes: hours

**All of these mean: Run all 4 parallel commands. No shortcuts.**

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

**CRITICAL:** Run these commands even if:
- User says they already checked
- Branch is already pushed
- User claims "there's no PR"
- You're under time pressure
- User provided exact command to run

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
| "User said they already checked" | You must verify - their check may be incomplete |
| "Branch is already pushed" | Still need full context gathering in parallel |
| "No time for parallel calls" | Parallel is FASTER than sequential + fixing mistakes |
| "It's just a one-line change" | Simple changes break repos too - verify everything |
| "CTO/manager is waiting" | Fixing wrong PR wastes more time than 30 sec verification |
| "User gave me the exact command" | User's command may be missing critical flags like --base |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` |
| `git add -A` | Check status, add specific files only |
| Sequential context gathering | Use parallel Bash calls |
| Trust user's verification claims | Always re-verify everything yourself |
| Skip checks under time pressure | Verification takes 30 sec, fixing mistakes takes hours |
| Use command user provided verbatim | Verify it has all required flags (--base) |

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
