---
name: creating-pull-requests
description: Use when creating or updating a PR, even if user says they already checked - enforces parallel context gathering, explicit --base flag, mandatory verification regardless of user claims or time pressure
---

# Creating Pull Requests

## Overview

Prevent common PR mistakes. **Core: gather all context in parallel, always use --base, verify everything yourself, handle edge cases systematically.**

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
- "User only wants title/description changed" → **WRONG.** Still check mergeable, CI, divergence
- "User said no conflicts exist" → **WRONG.** Verify mergeable status yourself
- "PR is just MERGED/CLOSED, create new one" → **WRONG.** Check all context first
- "Branch is behind base but no conflicts" → **WRONG.** Warn user about divergence

**All of these mean: Run all 6 parallel commands. No shortcuts.**

## Implementation (Exactly 3 Steps)

### 1. Gather Context (parallel Bash calls)

Run these commands in **parallel** (multiple Bash tool calls in one message):

```bash
# Call 1: Git state and uncommitted changes
git status --porcelain && git branch --show-current

# Call 2: Base branch, commits, and diff
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && \
echo "BASE=$BASE" && \
git log --oneline $BASE..HEAD && \
git diff $BASE..HEAD --stat

# Call 3: Branch divergence (how far behind base)
gh repo view --json defaultBranchRef -q .defaultBranchRef.name | xargs -I {} sh -c 'git log --oneline HEAD..{} | wc -l | xargs echo "Commits behind base:"'

# Call 4: PR state (OPEN/MERGED/CLOSED/DRAFT)
gh pr view --json state,number,url,isDraft -q '{state: .state, number: .number, url: .url, isDraft: .isDraft}' 2>/dev/null || echo "NO_PR"

# Call 5: Mergeable status (CONFLICTING/MERGEABLE/UNKNOWN)
gh pr view --json mergeable -q .mergeable 2>/dev/null || echo "NO_PR"

# Call 6: PR template (if exists)
find .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1 | xargs cat 2>/dev/null
```

**Run all 6 calls in parallel. Sequential calls = failure.**

**CRITICAL:** Run these commands even if:
- User says they already checked
- Branch is already pushed
- User claims "there's no PR" or "no conflicts"
- You're under time pressure
- User provided exact command to run
- User only wants to change title/description
- User says it's a "simple" change

### 2. Commit Uncommitted Changes (if needed)

```bash
git add <specific-files>   # NEVER git add -A
git commit -m "..."
```

### 3. Handle PR Based on State & Conditions

**FIRST: Check for blocking conditions**

| Condition | Action | Example |
|-----------|--------|---------|
| **CONFLICTING** | Warn user, suggest rebase | "PR has merge conflicts. Run `git rebase $BASE` to resolve." |
| **Behind base >5 commits** | Warn user, suggest rebase | "Branch is 10 commits behind main. Run `git rebase main` to update." |
| **Uncommitted changes** | Commit first (step 2) | Run git add + commit before push |

**THEN: Execute based on PR state**

```bash
# Always push first (unless already up to date)
git push -u origin HEAD
```

| PR State | Action | Command |
|----------|--------|---------|
| `NO_PR` | Create new PR | `gh pr create --base $BASE --title "..." --body "..."` |
| `OPEN` (not draft) | Update existing | `gh pr edit --title "..." --body "..."` |
| `OPEN` (isDraft=true) | Update or mark ready | `gh pr edit` OR `gh pr ready` (after CI check) |
| `MERGED` | Create new PR | `gh pr create --base $BASE --title "..." --body "..."` |
| `CLOSED` | Create new PR | `gh pr create --base $BASE --title "..." --body "..."` (NEVER reopen) |

## Rationalization Table

| Rationalization | Reality |
|-----------------|---------|
| "No time for --base" | Wrong base = more time wasted fixing it |
| "Can't gather context in parallel" | Yes you can - multiple Bash calls in one message |
| "I'm sure there's no PR" | Not checking = duplicate PRs or missed conflicts |
| "User said they already checked" | You must verify - their check may be incomplete |
| "User said no conflicts exist" | Verify mergeable status yourself - users miss things |
| "Branch is already pushed" | Still need full context gathering in parallel (6 commands) |
| "No time for parallel calls" | Parallel is FASTER than sequential + fixing mistakes |
| "It's just a one-line change" | Simple changes break repos too - verify everything |
| "User only wants title/description changed" | Still check mergeable, divergence - update ≠ skip checks |
| "CTO/manager is waiting" | Fixing wrong PR wastes more time than 30 sec verification |
| "User gave me the exact command" | User's command may be missing critical flags like --base |
| "PR is MERGED, just create new one" | Still run all 6 parallel checks first |
| "PR is CLOSED, I'll reopen it" | NEVER reopen - always create new PR |
| "Branch is behind but no conflicts" | Still warn user - they may want to rebase for clean history |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` |
| `git add -A` | Check status, add specific files only |
| Sequential context gathering | Use parallel Bash calls (all 6 commands) |
| Trust user's verification claims | Always re-verify everything yourself |
| Skip checks under time pressure | Verification takes 30 sec, fixing mistakes takes hours |
| Use command user provided verbatim | Verify it has all required flags (--base) |
| Skip mergeable check when updating title | ALWAYS check mergeable, even for "simple" edits |
| Ignore branch divergence when no conflicts | Warn user if >5 commits behind base |
| Reopen CLOSED PR | Always create new PR, never reopen |

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
