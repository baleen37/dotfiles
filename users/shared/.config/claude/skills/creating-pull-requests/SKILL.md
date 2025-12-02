---
name: creating-pull-requests
description: Use when creating or updating PRs, or encountering 'wrong base branch', 'PR already exists', 'cannot merge', 'has conflicts', 'diverged from base', or duplicate PR issues - enforces parallel context gathering (git status, base branch, divergence, PR state, mergeable status, CI status, template), explicit --base flag, mandatory verification regardless of user claims or time pressure
---

# Creating Pull Requests

## Overview

Prevent common PR mistakes. **Core: gather all context in parallel, always use --base, verify everything yourself, handle edge cases systematically.**

**NO EXCEPTIONS for time pressure, user claims, or partial work done.**

## Red Flags - STOP If You Think This

**NO EXCEPTIONS for:**
- Time pressure ("urgent", "waiting", "meeting in X minutes")
- User claims ("already checked", "no conflicts", "already pushed", "it's simple")
- Partial work ("branch pushed", "just title change", "one-line fix")
- Authority ("CTO waiting", "manager requested", "user gave exact command")
- Simplicity ("simple change", "just docs", "trivial fix")
- PR state assumptions ("no existing PR", "MERGED/CLOSED so just create")
- CI assumptions ("mergeable is enough", "CI will run after", "no required checks")

**Specific rationalizations to reject:**
- "GitHub will use default branch" → `--base` is mandatory
- "Let me check first..." / "Let me gather..." → Just do it in parallel, don't announce
- "User already checked [X]" → Verify everything yourself
- "Too urgent for parallel calls" → Parallel is faster than sequential + fixing
- "It's just a one-line change" → Simple changes need full process
- "Mergeable status is enough" → Check both mergeable AND CI status
- "CI will run after PR creation" → Check CI status before creating
- "Mark ready now, CI will finish soon" → Never mark ready while CI failing/pending
- "8 parallel calls too many" → All 8 calls mandatory, takes same time as 6

**All of these mean: Run all 8 parallel commands. No shortcuts.**

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

# Call 7: CI status (state + failing checks)
gh pr view --json statusCheckRollup -q '{state: .statusCheckRollup.state, failing: [.statusCheckRollup.contexts[]? | select(.conclusion == "FAILURE" or .state == "FAILURE") | .name // .context]}' 2>/dev/null || echo "NO_PR"

# Call 8: Required checks (if configured)
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name) && gh api "repos/{owner}/{repo}/branches/$BASE/protection/required_status_checks" 2>/dev/null | jq -r '.contexts[]? // "NO_REQUIRED_CHECKS"' 2>/dev/null || echo "NO_REQUIRED_CHECKS"
```

**Run all 8 calls in parallel. Sequential calls = failure.**

**CRITICAL:** Run these commands even if:
- User says they already checked
- Branch is already pushed
- User claims "there's no PR" or "no conflicts"
- You're under time pressure
- User provided exact command to run
- User only wants to change title/description
- User says it's a "simple" change
- CI status seems obvious or "will run after"

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
| **CI FAILURE** | Stop and report | "PR has failing checks: [test-unit, lint]. Fix before proceeding." |
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
| `OPEN` (isDraft=true) + CI SUCCESS | Mark ready | `gh pr ready` |
| `OPEN` (isDraft=true) + CI PENDING | Warn, don't mark ready | Wait with `gh pr checks --watch` or user override |
| `OPEN` (isDraft=true) + CI FAILURE | Block, report failures | "Cannot mark ready with failing CI: [list]" |
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
| "Branch is already pushed" | Still need full context gathering in parallel (8 commands) |
| "No time for parallel calls" | Parallel is FASTER than sequential + fixing mistakes |
| "It's just a one-line change" | Simple changes break repos too - verify everything |
| "User only wants title/description changed" | Still check mergeable, CI, divergence - update ≠ skip checks |
| "CTO/manager is waiting" | Fixing wrong PR wastes more time than 30 sec verification |
| "User gave me the exact command" | User's command may be missing critical flags like --base |
| "PR is MERGED, just create new one" | Still run all 8 parallel checks first |
| "PR is CLOSED, I'll reopen it" | NEVER reopen - always create new PR |
| "Branch is behind but no conflicts" | Still warn user - they may want to rebase for clean history |
| "Mergeable means CI passed" | mergeable = no conflicts, CI status is separate |
| "Creating PR will trigger CI" | Check existing CI status first |
| "Draft doesn't need CI check" | Check CI before marking ready |
| "No time to wait for CI" | Verification: 30 sec, broken main: hours of team time |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` |
| `git add -A` | Check status, add specific files only |
| Sequential context gathering | Use parallel Bash calls (all 8 commands) |
| Trust user's verification claims | Always re-verify everything yourself |
| Skip checks under time pressure | Verification takes 30 sec, fixing mistakes takes hours |
| Use command user provided verbatim | Verify it has all required flags (--base) |
| Skip mergeable check when updating title | ALWAYS check mergeable AND CI, even for "simple" edits |
| Ignore branch divergence when no conflicts | Warn user if >5 commits behind base |
| Reopen CLOSED PR | Always create new PR, never reopen |
| Mark ready while CI failing | Check CI status, wait for SUCCESS before `gh pr ready` |
| Ignore CI status when updating | Always verify CI in parallel gathering |
| Assume mergeable = CI passing | Check both mergeable AND statusCheckRollup |
| Skip CI check for "simple" changes | All 8 parallel commands, no exceptions |

## CI Status Handling

**Always check CI status before creating/updating PR.**

### Interpreting CI Status

| State | Meaning | Action |
|-------|---------|--------|
| `SUCCESS` | All checks passed | Safe to proceed |
| `PENDING` | Checks running | Wait before marking ready |
| `FAILURE` | One or more failed | Fix before proceeding |
| `ERROR` | System error | Investigate CI system |
| `null` or `NO_PR` | No CI configured | Proceed but warn if no required checks |

### Required Checks Warning

If `NO_REQUIRED_CHECKS` returned, warn user:
```
Warning: Base branch has no required status checks configured.
Consider adding branch protection rules for quality gates.
```

### Watching CI

When CI is PENDING and user wants to proceed:
```bash
# Watch until completion (blocking)
gh pr checks --watch

# Check current status
gh pr checks

# Watch with fail-fast (exit on first failure)
gh pr checks --watch --fail-fast
```

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
