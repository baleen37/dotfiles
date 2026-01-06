---
name: creating-pull-requests
description: Use when creating or updating a PR - enforces parallel context gathering, explicit --base flag, Conventional Commits format
---

# Creating Pull Requests

## Core Principles

1. **Always** use `--base $BASE` (never omit)
2. **Always** gather context in parallel (use the script)
3. **Always** use Conventional Commits format
4. Keep PRs small (<250 lines), focused, self-contained

## Implementation

### 1. Gather Context (Parallel)

```bash
bash {baseDir}/scripts/pr-check.sh
```

Review all output before proceeding.

### 2. Branch & Commit

```bash
# Auto-create WIP branch if on main/master
git checkout -b wip/descriptive-name

# Commit (NEVER git add -A)
git add <specific-files>
git commit -m "..."
```

### 3. Push & Create PR

```bash
git push -u origin HEAD
```

**Draft (WIP):**
```bash
gh pr create --base $BASE --draft --title "WIP: type(scope): description"
gh pr ready  # When ready
```

**Ready:**
```bash
gh pr create --base $BASE --title "..." --body "..."
# Update existing: gh pr edit --title "..." --body "..."
```

## PR Title (Conventional Commits)

**Format:** `type(scope): description`

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `refactor` | Code refactoring |
| `test` | Test changes |
| `chore` | Build/tools |

**Breaking:** Add `!` → `feat!: ...` or `fix(scope)!: ...`

## PR Body

```markdown
## What
Brief description.

## Why
Context/motivation.

## How
- Change X
- Change Y

## Checklist
- [ ] Tests pass

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Handling Conflicts

### Push Conflicts

```bash
# Pull latest changes first
git pull --rebase origin $BASE

# Fix conflicts if any
# Edit conflicted files
git add <resolved-files>
git rebase --continue

# Push again
git push -u origin HEAD
```

### Merge Conflicts in PR

When PR has conflicts with base branch:

```bash
# Update branch
git fetch origin
git rebase origin/$BASE

# Resolve conflicts
# (edit files)
git add <resolved-files>
git rebase --continue

# Force push (safe for your branch)
git push --force-with-lease
```

**Never use `git push --force`** - always `--force-with-lease`.

### Avoiding Conflicts

- Keep PRs small and short-lived
- Rebase frequently: `git pull --rebase`
- Communicate with team on overlapping work

## Common Mistakes

| Wrong | Right |
|-------|-------|
| No `--base` | `--base $BASE` |
| `git add -A` | Add specific files |
| Sequential checks | Parallel script |
| Free-form title | Conventional Commits |
| Missing structure | Use template |
| PR > 250 lines | Break into smaller PRs |
| `git push --force` | `--force-with-lease` |
