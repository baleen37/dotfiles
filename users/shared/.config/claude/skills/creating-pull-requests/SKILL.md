---
name: creating-pull-requests
description: Use when creating a PR - automatically analyzes changes, generates description from template, and creates PR with proper conventions
---

# Creating Pull Requests

**Run automatically before `gh pr create`:**

1. `git status` - uncommitted changes? `git log --oneline -5` for commit convention, then commit (fallback: conventional commits)
2. `git branch --show-current` - check branch convention (fallback: feat/, fix/, docs/, refactor/, test/, chore/)
3. `git remote show origin | grep "HEAD branch"` - confirm base branch
4. `git diff <base>...HEAD` - analyze changes for PR description
5. Read `.github/PULL_REQUEST_TEMPLATE.md` - follow template format exactly (fallback: Summary + Test plan)
6. Generate PR title from branch name + changes
7. `git push -u origin HEAD && gh pr create`
8. Return PR URL

Use `--draft` for incomplete work.
