---
name: committing-and-pushing-pr
description: Handle complete git workflow (commit → push → PR) with parallel context gathering, --base enforcement, and merge conflict detection. Use when user asks to commit, push, create PR, mentions git workflow, or says "auto merge".
---

# Committing and Pushing PR

## Overview

Automates the full git workflow: gather context → check conflicts → commit → push → create/update PR. **Core principles: parallel context gathering, --base flag mandatory, conflict check before push.**

**Announce at start:** "I'm using the committing-and-pushing-pr skill to handle the git workflow."

**Auto-merge shortcut:** If user says "auto merge", skip the prompt and automatically run `gh pr merge --auto` after creating PR.

---

## Red Flags - STOP If You Think This

| Rationalization | Reality |
|-----------------|---------|
| "GitHub will use the default branch anyway" | **WRONG.** `--base` is mandatory |
| "Let me check status first..." | **WRONG.** Gather all context in parallel |
| "There's no existing PR" | **WRONG.** Always check PR state first |
| "No conflicts, I can push directly" | **WRONG.** Always check for merge conflicts first |

---

## Implementation (6 Steps)

### 1. Gather Context (Parallel)

```bash
bash {baseDir}/scripts/pr-check.sh
```

*({baseDir} is the skill directory; Claude Code resolves this automatically)*

**Output includes:**
- `BASE` - Default branch (e.g., `main`)
- Current branch and git status
- PR state: `OPEN`, `NO_PR`, `MERGED`, or `CLOSED`
- Changed lines count
- PR template (if exists)

**Review all output before proceeding.**

---

### 2. Check for Merge Conflicts (**CRITICAL**)

**Before pushing, ALWAYS check:**

```bash
bash {baseDir}/scripts/conflict-check.sh
```

*({baseDir} is the skill directory; Claude Code resolves this automatically)*

**Exit code 0** = No conflicts, proceed to Step 4.
**Exit code 1** = Conflicts detected, follow resolution steps below.

**If conflicts detected, see [CONFLICT_RESOLUTION.md](CONFLICT_RESOLUTION.md):**
1. Identify conflict files from output
2. Merge base branch: `git merge origin/$BASE`
3. Resolve conflicts in each file (remove markers)
4. Stage resolved files: `git add <files>`
5. Commit resolution: `git commit -m "fix: resolve merge conflicts from $BASE"`
6. Only then proceed to Step 4

---

### 3. Auto-Create Branch (if on main/master)

**CRITICAL:** Never commit directly to main/master.

If current branch is `main` or `master`:
1. Check for uncommitted changes
2. Create WIP branch: `git checkout -b wip/<short-description>`

**Naming:** 2-4 words (e.g., `wip/fix-auth-bug`, `wip/add-user-api`)
**If branch exists:** Append `-$(date +%s)` or `-2`

---

### 4. Commit Changes

**Primary approach (safest):**
```bash
git status                    # Review first
git add path/to/file1 file2   # Add specific files
git commit -m "feat: description"
```

**`git add -A` ONLY if:**
- Just ran `git status` AND verified all changes are intended
- No test artifacts or temporary files present

**Commit format:** Conventional Commits (`feat:`, `fix:`, `chore:`, etc.)

---

### 5. Push & Create/Update PR

```bash
git push -u origin HEAD
```

**Determine action from PR state (Step 1):**

| PR State | Action | Command |
|----------|--------|---------|
| `OPEN` | Update existing | `gh pr edit --title "$TITLE" --body "$BODY"` |
| `NO_PR` | Create new | `gh pr create --base $BASE --title "$TITLE" --body "$BODY"` |
| `MERGED` | Create new | Same as NO_PR (branch is ahead of merged PR) |
| `CLOSED` | Ask user first | See below |

**After creating PR (NO_PR/MERGED states):**

If user said "auto merge" initially:
```bash
gh pr merge --auto --squash
```

This enables auto-merge with squash (merges automatically when CI passes).

**CLOSED state handling:**
1. Ask user: "PR was closed. Create new PR or reopen closed one?"
2. If "new" → Run `gh pr create --base $BASE ...`
3. If "reopen" → Run `gh pr reopen` then `gh pr edit ...`

**PR Title Generation:**
- **Single commit:** Use commit message: `git log -1 --pretty=%s`
- **Multiple commits:** Combine top 2-3 commits into summary
  - Example: `feat(auth): add OAuth2 login and session management`
  - Merge related scopes: `feat: OAuth2 authentication + session fixes`

**PR Body Generation:**
1. **Summary:** Review all commits from `git log $BASE..HEAD`
   - Create 2-3 bullet points covering ALL commits
   - Group related changes together
   - Don't just use latest commit

2. **Test plan:** What was verified
   - Example: `[x] Unit tests pass (\`make test\`)`
   - Include relevant tests from commit messages

3. **References:** Related issues (if any)
   - Example: `Fixes #123`

**PR Body Template:**
```markdown
## Summary
- Change 1 (from commit X)
- Change 2 (from commit Y)
- Change 3 (from commit Z)

## Test plan
- [x] Test 1
- [x] Test 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

### 6. Auto Merge (Optional)

**Default:** Do NOT auto-merge. Let CI run and review first.

**After PR creation, ask user:**
"Wait for CI to pass and merge automatically? (yes/no/skip)"

**User responses:**
- **yes** → Run full auto-merge sequence below
- **no** → PR created, user will handle manually
- **skip** → Don't ask, just create PR

**Auto-merge sequence (if user says yes):**

```bash
# 1. Wait for CI to complete
gh run watch

# 2. Confirm CI passed
gh run view --json conclusion,state

# 3. If CI passed, ask user
"CI passed. Merge with squash? (y/n)"

# 4. Only if user confirms
gh pr merge --squash --delete-branch
```

**Only auto-merge when ALL conditions met:**
1. User explicitly requests "yes"
2. CI checks pass successfully
3. User confirms merge after seeing CI results
4. Changes are trivial (< 50 lines) OR user reviewed this session

**Never auto-merge if:**
- Tests are flaky or skipped
- Changes affect critical paths (auth, payments, security)
- User hasn't reviewed in this session
- PR is larger than 50 lines
- CI checks failed

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Omit `--base` | **Always** use `--base $BASE` when creating PR |
| `git add -A` | Check status, add specific files |
| Sequential gathering | Use parallel script calls |
| Skip conflict check | Always run conflict-check.sh before push |
| Only use latest commit for PR body | Review ALL commits from git log |

---

## Auto Merge

**Default:** Do NOT auto-merge. Let CI run first.

**Only auto-merge when:**
1. User explicitly requests
2. User reviewed changes this session
3. Trivial change (typo fix < 20 lines)

**Sequence:**
```bash
gh run watch                    # Wait for CI
"CI passed. Merge with squash?"  # Confirm
gh pr merge --squash --delete-branch  # Only if confirmed
```

---

## Error Handling

| Error | Check | Fix |
|-------|-------|-----|
| `gh` fails | `gh auth status` | `gh auth login` |
| Push fails | `git remote -v` | `git remote add origin <url>` |
| PR create fails | `git branch -vv` | Check branch is pushed |

---

## Quick Reference

See [QUICK_START.md](QUICK_START.md) for a condensed checklist.

For detailed conflict resolution, see [CONFLICT_RESOLUTION.md](CONFLICT_RESOLUTION.md).

For evaluation scenarios, see [EVALUATION.md](EVALUATION.md).
