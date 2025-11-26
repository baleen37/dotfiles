---
name: creating-pull-requests
description: Use when creating a PR, especially under time pressure or fatigue - enforces pre-flight checks that get skipped when rushed (template, diff, uncommitted changes, base branch)
---

# Creating Pull Requests

## Pre-flight (before `gh pr create`)

1. `git status` - uncommitted changes? commit first (`git log --oneline -5` for convention)
2. `git diff <base>...HEAD` - **read the actual diff**, not just stats
3. `git remote show origin | grep "HEAD branch"` - verify base branch
4. Read `.github/PULL_REQUEST_TEMPLATE.md` - follow exactly (fallback: Summary + Test plan)
5. `git push -u origin HEAD && gh pr create`

Use `--draft` for incomplete work.

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
