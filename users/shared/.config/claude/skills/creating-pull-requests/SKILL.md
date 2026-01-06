---
name: creating-pull-requests
description: Use when creating or updating a PR - enforces parallel context gathering, explicit --base flag, PR state check, Conventional Commits format, standardized PR body
---

# Creating Pull Requests

## Overview

Prevent common PR mistakes. **Core: gather all context in parallel, always use --base, enforce Conventional Commits, use standardized PR template, keep PRs small and focused.**

## What Makes a Good Pull Request?

A good PR is:
- **Small**: Under 250 lines of code change (reviewable in under 15 minutes)
- **Focused**: Does ONE thing well (single bug fix, ONE feature, ONE refactor)
- **Self-contained**: Can be reviewed and understood independently
- **Well-documented**: Clear summary, context, and test plan
- **Ready to merge**: All tests pass, no pending requests
- **Atomic commits**: Each commit is one logical change with descriptive message

## Red Flags - STOP If You Think This

- "GitHub will use the default branch anyway" → **WRONG.** `--base` is mandatory
- "Let me check status first..." → **WRONG.** Gather all context in parallel
- "There's no existing PR" → **WRONG.** Always check PR state first
- "Any title format is fine" → **WRONG.** Conventional Commits format is mandatory
- "Free-form PR description is OK" → **WRONG.** Use standardized template

## Implementation (Exactly 4 Steps)

### 1. Gather Context

Run the context gathering script:

```bash
bash {baseDir}/scripts/pr-check.sh
```

This script collects (in parallel):
- Git status and current branch
- Base branch, commit history, and diff stats
- Existing PR state (if any)
- PR template (if exists)

**All checks run in parallel for speed. Review all output before proceeding.**

### 2. Auto-Create Branch (if on main/master)

If current branch is main or master, automatically create a WIP branch:

```bash
git checkout -b wip/descriptive-name
```

Use a descriptive name based on the changes being made. Never ask user for permission.

### 3. Commit Uncommitted Changes (if needed)

```bash
git add <specific-files>   # NEVER git add -A
git commit -m "..."
```

### 4. Push & Create/Update PR

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

**Creating draft PR (for early development):**
```bash
gh pr create --base $BASE --draft --title "..." --body "..."
```

## PR Title Format (Conventional Commits)

**MANDATORY FORMAT:** `type(scope): description`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (semicolon, indentation, etc)
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build system, tool updates

**Examples:**
```
feat(auth): add OAuth2 login support
fix(api): resolve race condition in user creation
docs(readme): update installation instructions
refactor(config): simplify module imports
test(user): add integration tests for signup flow
```

**Breaking Changes (use `!` after type/scope):**
```
feat!: send an email to customer when product is shipped
fix(auth)!: remove deprecated OAuth1 provider
chore!: drop support for Node 6
```

## PR Body Template (Standardized)

**ALWAYS use this structure:**

```markdown
## Summary

<!-- 2-3 bullet points summarizing key changes -->

- First major change
- Second major change
- Third major change

## Changes

<!-- Detailed list of specific changes -->

- File X: what changed and why
- File Y: what changed and why

## Test plan

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Breaking changes

<!-- None or describe breaking changes -->

None (or describe breaking changes with migration notes)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**If PR template exists:** Include it after "## Changes" section or replace the template structure if project-specific.

## Commit History Best Practices

Before creating a PR, clean up your commit history:

```bash
# Interactive rebase to squash, reword, or reorder commits
git rebase -i HEAD~n  # n = number of commits to review
```

**Guidelines for clean history:**
- Each commit should be one logical change (atomic)
- Use active voice: "Add user authentication" not "Added user authentication"
- Treat commit message as completing: "If applied, this commit will..."
- Remove "wip", "fix typo", "fixing review comments" type commits
- Squash related small commits into one meaningful commit

**Example commit message:**
```
feat(profile): allow users to upload custom avatar

Implements server-side logic for handling image uploads to user profiles.
Includes validation for file type (JPEG, PNG) and size (max 2MB).

New endpoint: POST /api/users/avatar
```

## PR Labeling (Auto-apply based on title)

Labels are automatically applied based on Conventional Commits type:

| Type | Label | Color |
|------|-------|-------|
| `feat` | `enhancement` | green |
| `fix` | `bug` | red |
| `docs` | `documentation` | blue |
| `style` | `style` | gray |
| `refactor` | `refactor` | orange |
| `test` | `tests` | purple |
| `chore` | `maintenance` | yellow |
| `feat!`, `fix!`, etc. | `breaking-change` | red (bold) |

**Scope labels** (if configured): `scope:auth`, `scope:api`, etc.

## Rationalization Table

| Rationalization | Reality |
|-----------------|---------|
| "No time for --base" | Wrong base = more time wasted fixing it |
| "Can't gather context in parallel" | Yes you can - multiple Bash calls |
| "I'm sure there's no PR" | Not checking = duplicate PRs |
| "Conventional Commits is too strict" | Consistency = better git history + automation |
| "Template is too verbose" | Structure = clearer reviews |
| "Commit history doesn't matter" | Clean history = easier debugging & reverts |
| "My PR is too big to break down" | Large PRs = more bugs, slower reviews, harder to review |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` |
| `git add -A` | Check status, add specific files only |
| Sequential context gathering | Use parallel Bash calls |
| Free-form PR title | **MUST** use Conventional Commits format |
| Missing PR structure | **MUST** use standardized template |
| Forgetting Co-Authored-By | **ALWAYS** include attribution |
| Messy commit history | Use `git rebase -i` to clean up before PR |
| PRs over 250 lines | Break into smaller, focused PRs |
| Missing breaking change notice | Use `!` in title for breaking changes |

## Auto Merge

Only on explicit request: `gh pr merge --auto --squash`
