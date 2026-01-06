---
name: commit-push-pr
description: Commit changes, push to remote, and create/update pull request with proper context gathering and --base flag enforcement
---

# Commit, Push & Create PR

## Overview

Complete git workflow: commit → push → create/update PR. **Core: gather all context in parallel, always use --base.**

## Red Flags - STOP If You Think This

- "GitHub will use the default branch anyway" → **WRONG.** `--base` is mandatory
- "Let me check status first..." → **WRONG.** Gather all context in parallel
- "There's no existing PR" → **WRONG.** Always check PR state first
- "No conflicts, I can push directly" → **WRONG.** Always check for merge conflicts first

## Implementation (Exactly 5 Steps)

### 1. Gather Context

Run the context gathering script:

```bash
bash users/shared/.config/claude/skills/commit-push-pr/scripts/pr-check.sh
```

This script collects (in parallel):
- Git status and current branch
- Base branch, commit history, and diff stats
- Existing PR state (if any)
- PR template (if exists)

**All checks run in parallel for speed. Review all output before proceeding.**

### 1.5. Check for Merge Conflicts (IMPORTANT)

**Before pushing, ALWAYS check if your branch can merge cleanly:**

```bash
# Fetch latest base branch
git fetch origin $BASE

# Check for conflicts without merging
git merge-tree $(git merge-base HEAD origin/$BASE) HEAD origin/$BASE
```

**If conflicts are detected:**

1. **Identify conflict files** from the output
2. **Merge base branch** to resolve conflicts:
   ```bash
   git merge origin/$BASE
   ```
3. **Resolve conflicts** in each file:
   - Remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Keep correct content from both branches
   - Test that files are valid
4. **Commit merge resolution**:
   ```bash
   git add <resolved-files>
   git commit -m "fix: resolve merge conflicts from $BASE"
   ```
5. **Only then proceed** to Step 4 (push)

**If no conflicts**: Proceed directly to Step 4.

### 2. Auto-Create Branch (if on main/master)

**CRITICAL:** Never commit directly to main/master.

If current branch is `main` or `master`:
1. Check if there are uncommitted changes with `git status`
2. Create WIP branch with descriptive name:
   ```bash
   git checkout -b wip/<short-description>
   ```

**Naming convention:**
- Use 2-4 words describing the change
- Examples: `wip/fix-auth-bug`, `wip/add-user-api`, `wip/refactor-config`
- Default: `wip/changes` if uncertain (but avoid when possible)

**If WIP branch already exists:**
- Append timestamp: `wip/<description>-$(date +%s)`
- OR append number: `wip/<description>-2`

**Never ask user for branch name.** This prevents accidental commits to main/master.

### 3. Commit Uncommitted Changes (if needed)

**Primary approach (safest):**
```bash
# Review what changed first
git status

# Add specific files explicitly
git add path/to/file1 path/to/file2

# Or add by pattern (more selective than -A)
git add *.nix
git add tests/

# Then commit
git commit -m "..."
```

**Allowed use of `git add -A`:**
- ONLY if you just ran `git status` and verified all changes are intended
- ONLY if no test artifacts, build outputs, or temporary files are present
- When in doubt, use explicit file paths instead

**Commit message format:**
Use Conventional Commits:
- `feat: add new feature`
- `fix: resolve bug description`
- `docs: update documentation`
- `test: add tests for feature`
- `refactor: restructure code`

If uncertain about commit type, default to `chore:` or ask for clarification.

### 5. Push & Create/Update PR

```bash
git push -u origin HEAD
```

**Then determine PR state from Step 1 output:**

| PR State | Action | Command |
|----------|--------|---------|
| `OPEN` | Update existing PR | `gh pr edit --title "$TITLE" --body "$BODY"` |
| `NO_PR` | Create new PR | `gh pr create --base $BASE --title "$TITLE" --body "$BODY"` |
| `MERGED` | Create new PR | Same as NO_PR (branch is ahead of merged PR) |
| `CLOSED` | Ask user | "PR was closed. Create new PR or reopen closed one?" |

**PR Title Generation:**
1. Use commit message if single commit: `git log -1 --pretty=%s`
2. Use summary if multiple commits: Combine top 2-3 commit messages
3. Apply Conventional Commits format if not already present

**PR Body Generation:**
Include:
1. **Summary**: 2-3 bullet points of what changed
2. **Test plan**: How to verify (e.g., "Ran `make test`, all passed")
3. **References**: Related issues if any (e.g., "Fixes #123")

**Use PR template if found in Step 1:**
- Fill in template sections
- Append summary and test plan below template

**Example body:**
```markdown
## Summary
- Add authentication middleware to API endpoints
- Fix session timeout bug
- Update tests for new auth flow

## Test plan
- [x] All unit tests pass (`make test`)
- [x] Integration tests pass
- [x] Manual testing with test credentials verified

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Rationalization Table

| Rationalization | Reality |
|-----------------|---------|
| "No time for --base" | Wrong base = more time wasted fixing it |
| "Can't gather context in parallel" | Yes you can - multiple Bash calls |
| "I'm sure there's no PR" | Not checking = duplicate PRs |
| "Conflicts are rare" | Conflicts block PR merging = wasted CI time |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` |
| `git add -A` | Check status, add specific files only |
| Sequential context gathering | Use parallel Bash calls |
| Skipping conflict check | Always check `git merge-tree` before pushing |

## Auto Merge

**Default behavior:** Do NOT auto-merge. Always let CI run and user review first.

**Only auto-merge when:**
1. User explicitly requests: "Please merge after CI passes"
2. User has already reviewed the changes in this session
3. You're confident the changes are trivial (e.g., typo fix)

**Even then, follow this sequence:**
```bash
# 1. Wait for CI to pass
gh run watch

# 2. Confirm with user
"CI passed. Merge with squash? (y/n)"

# 3. Only if user confirms
gh pr merge --squash --delete-branch
```

**Never auto-merge if:**
- Tests are flaky or skipped
- Changes affect critical paths (auth, payments, etc.)
- User hasn't reviewed in this session
- PR is larger than 50 lines

## Error Handling

**Before starting, verify prerequisites:**
```bash
# Check GitHub CLI is installed and authenticated
gh auth status

# Check remote is configured
git remote -v

# Check current branch
git branch --show-current
```

**If `gh` command fails:**
1. Check authentication: `gh auth login`
2. Check repository exists: `gh repo view`
3. Check network connection

**If push fails:**
1. Check remote: `git remote -v`
2. Check authentication: `git config --get remote.origin.url`
3. Ask user to set up remote: `git remote add origin <url>`

**If PR create fails:**
1. Check if PR already exists (state should show this)
2. Check branch is pushed: `git branch -vv`
3. Check base branch exists: `git branch -r | grep $BASE`
