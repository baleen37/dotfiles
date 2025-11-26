---
name: creating-pull-requests
description: Use when creating a PR, especially under time pressure or fatigue - enforces pre-flight checks that get skipped when rushed (template, diff, uncommitted changes, base branch)
---

# Creating Pull Requests

## Overview

**A PR created without proper checks is worse than no PR at all.** Time pressure is when you most need this discipline.

## Pre-Flight Checklist (MANDATORY)

Before running `gh pr create`, you MUST complete ALL of these. No exceptions.

| Check | Command | Why |
|-------|---------|-----|
| Clean working directory | `git status` | Uncommitted changes? → `git add -A && git commit` |
| Commit convention | `git log --oneline -10` | Match existing commit message style |
| PR template exists? | `find . -maxdepth 3 -iname '*pull_request_template*' 2>/dev/null` | Template = project standards |
| Actual diff reviewed | `git diff <base>...HEAD` | Commit messages lie, diff doesn't |
| Base branch confirmed | `git remote show origin \| grep "HEAD branch"` | Don't guess main vs master vs develop |
| Branch pushed | `git push -u origin HEAD` | Can't PR unpushed branch |

**Skip any check = start over.** Not negotiable.

**Interrupted?** If more than 5 minutes passed since checks, re-run ALL of them. State changes.

## Quick Reference

```bash
# 1. Verify clean state
git status

# 2. Get base branch
BASE=$(git remote show origin | grep "HEAD branch" | cut -d: -f2 | tr -d ' ')

# 3. Check for PR template
find . -maxdepth 3 -iname '*pull_request_template*' 2>/dev/null

# 4. Review actual changes (not just commit messages)
git log ${BASE}..HEAD --oneline
git diff ${BASE}...HEAD --stat

# 5. Push and create PR
git push -u origin HEAD
gh pr create --base ${BASE} --title "..." --body "..."
```

## PR Body Structure

Use project template if exists. Fallback:

```markdown
## Summary
[2-3 bullets: WHAT changed and WHY]

## Test plan
- [ ] [Specific verification steps]
```

## Red Flags - STOP

If you catch yourself thinking any of these, STOP:

- "I don't have time to check the template"
- "The commit messages explain everything"
- "I'll fix the uncommitted changes after"
- "It's definitely main, I don't need to check"
- "This is urgent, I can skip the diff review"
- "Senior dev said to skip the process"
- "I already did the checks 30 minutes ago"

**All of these mean: You're about to create a bad PR. Slow down.**

**Authority override is not an excuse.** If someone tells you to skip checks, the answer is "2 more minutes" not "okay".

## Draft PRs

Use `--draft` for incomplete features or uncertain approaches.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "No time for template check" | 5 seconds to cat a file vs hours fixing rejected PR |
| "Commits are clear enough" | Reviewers need context commits don't provide |
| "Uncommitted changes are unrelated" | If unrelated, stash them. If related, commit them. |
| "I know the base branch" | You're often wrong. 10 seconds to verify. |
| "Urgent means skip checks" | Urgent means get it RIGHT the first time |
| "Senior dev said skip it" | You own the quality. They own the review. Different jobs. |
| "I checked 30 min ago" | State changes. Re-run. 90 seconds vs broken PR. |