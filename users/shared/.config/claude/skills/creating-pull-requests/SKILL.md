---
name: creating-pull-requests
description: Use when creating a PR, especially under time pressure or fatigue - enforces pre-flight checks that get skipped when rushed (template, diff, uncommitted changes, base branch)
---

# Creating Pull Requests

## Pre-flight (before `gh pr create`)

### 1. Gather context (parallel)
Run these simultaneously - all are independent reads:
- `git status`
- `git diff <base>...HEAD`
- `git remote show origin | grep "HEAD branch"`
- `find . -maxdepth 3 -iname '*pull_request_template*'`
- `git log --oneline -5`

### 2. Act on findings (sequential)
- Uncommitted changes? → **commit immediately** following convention
- PR template found? → **follow it exactly** (fallback: Summary + Test plan)
- `git push -u origin HEAD && gh pr create`

Use `--draft` for incomplete work.

## Auto Merge (Optional)

```bash
# Enable auto-merge after requirements are met
gh pr merge --auto

# Disable auto-merge for this PR
gh pr merge --disable-auto

# Check PR status including conflicts
gh pr status --conflict-status
```

## Red Flags - STOP

- "It's just a typo" → **All PRs follow this process. No exceptions.**
- "I know what I changed" → **Read the diff anyway. Memory lies.**
- "CI will catch it" → **Verify locally first.**
- "I can fix it later" → **Fix it now or don't merge.**
- "I'll do it in a follow-up PR" → **Same thing. Fix it now.**
- "Friday 6pm, need to ship" → **Especially then. Fatigue = mistakes.**
- "This section doesn't apply" → **Write "N/A - [reason]", don't delete.**

## Common Mistakes

| Mistake | Reality |
|---------|---------|
| Skip template | Template exists for reviewers. Follow it. |
| `--stat` only | Stats hide actual changes. Read full diff. |
| Assume base branch | Could be `develop`, `staging`. Verify. |
| Mark checklist without doing | Lying to reviewers. Run the tests. |
