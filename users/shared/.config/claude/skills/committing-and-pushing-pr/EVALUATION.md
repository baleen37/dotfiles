# Evaluation Scenarios

This document defines test cases to verify the `committing-and-pushing-pr` skill works correctly. Run these scenarios before and after changes to measure effectiveness.

## Scenario 1: Simple Single-Commit PR

### User Request
"Commit this and create a PR"

### Expected Behavior
1. Runs `pr-check.sh` and outputs:
   - BASE branch (e.g., `main`)
   - Current branch (e.g., `feature/add-auth`)
   - Git status showing changed files
   - PR state (NO_PR)
   - Changed lines count

2. If on main/master:
   - Creates WIP branch: `wip/add-auth` or similar
   - Checks for uncommitted changes
   - Stages specific files (not `git add -A`)

3. Commit with Conventional Commits format:
   - Type inferred from changes (feat/fix/chore/etc.)
   - Subject line clear and concise
   - Body includes summary if multiple files

4. Pushes to remote:
   - Uses `git push -u origin HEAD`
   - Confirms push success

5. Creates PR with:
   - `--base $BASE` flag (MANDATORY)
   - Title from commit message
   - Body with Summary, Test plan, References
   - Claude attribution footer

### Success Criteria
- [ ] `pr-check.sh` executed successfully
- [ ] All context gathered in parallel (status, BASE, PR state)
- [ ] WIP branch created if on main
- [ ] Commit follows Conventional Commits
- [ ] Push succeeds
- [ ] PR created with `--base` flag
- [ ] PR body includes Summary + Test plan
- [ ] No `git add -A` used without verification

### Failure Modes
- Missing `--base` flag → **FAIL**
- Sequential context gathering → **FAIL** (must be parallel)
- `git add -A` without status check → **FAIL**
- Skipping conflict check → **FAIL**

---

## Scenario 2: Merge Conflict Detected

### User Request
"Commit and push these changes" (with conflicts)

### Setup
- Base branch has diverged
- Files: `src/auth.ts`, `tests/auth.test.ts`
- Conflicting changes in both files

### Expected Behavior
1. Runs `pr-check.sh` → shows BASE branch

2. **BEFORE pushing, checks for conflicts:**
   ```bash
   git fetch origin $BASE
   git merge-tree $(git merge-base HEAD origin/$BASE) HEAD origin/$BASE
   ```

3. **If conflicts detected:**
   - Identifies conflict files from output
   - Informs user: "Conflicts detected in: src/auth.ts, tests/auth.test.ts"
   - Guides through resolution:
     1. `git merge origin/$BASE`
     2. Resolve conflicts (remove markers, keep correct content)
     3. `git add <resolved-files>`
     4. `git commit -m "fix: resolve merge conflicts from $BASE"`
   - **Only then proceeds** to push

4. **If no conflicts:**
   - Proceeds directly to push

### Success Criteria
- [ ] Conflict check runs BEFORE push
- [ ] Conflicts detected and reported
- [ ] User guided through resolution step-by-step
- [ ] Merge commit created with proper message
- [ ] Push happens only after resolution
- [ ] Final PR creation succeeds

### Failure Modes
- Pushing without conflict check → **FAIL**
- Not detecting conflicts → **FAIL**
- Leaving conflict markers in files → **FAIL**

---

## Scenario 3: Existing PR Update

### User Request
"Push these changes to the existing PR"

### Setup
- Current branch: `feature/user-profile`
- Existing PR: #123 in OPEN state
- Base branch: `main`

### Expected Behavior
1. Runs `pr-check.sh` → shows:
   - PR state: `OPEN`
   - PR number: `123`
   - PR URL: `https://github.com/user/repo/pull/123`

2. Stages and commits new changes:
   - Uses `git status` first
   - Adds specific files explicitly
   - Commit message references existing work

3. Pushes to branch:
   - `git push` (branch already tracked)

4. **Updates existing PR** (does NOT create new):
   ```bash
   gh pr edit --title "$TITLE" --body "$BODY"
   ```
   - NOT: `gh pr create`

5. Uses `--base main` explicitly (even though PR exists)

### Success Criteria
- [ ] Detects OPEN PR state correctly
- [ ] Updates existing PR (does not create new one)
- [ ] Preserves PR number and URL
- [ ] Uses `gh pr edit`, NOT `gh pr create`
- [ ] Base branch already set correctly (from original PR creation)

### Failure Modes
- Creating duplicate PR → **FAIL**
- Not detecting existing PR → **FAIL**
- Using `gh pr create` for OPEN PR → **FAIL**

---

## Scenario 4: Multiple Commits, PR Body Generation

### User Request
"Create a PR for these changes"

### Setup
- 3 commits on branch:
  - `feat(auth): add OAuth2 login`
  - `fix(auth): resolve session timeout`
  - `test(auth): add integration tests`

### Expected Behavior
1. Runs `pr-check.sh` → shows all commits

2. **PR Title Generation:**
   - Uses latest commit: `feat(auth): add OAuth2 login`
   - OR combines: `feat: OAuth2 authentication and session management`

3. **PR Body includes:**
   - **Summary** (2-3 bullets):
     - Add OAuth2 authentication flow
     - Fix session timeout bug
     - Add integration tests for auth flow
   - **Test plan:**
     - [x] Unit tests pass
     - [x] Integration tests pass
     - [x] Manual testing completed
   - **References:** (if applicable)
     - Fixes #45
   - **Footer:**
     - Generated with Claude Code attribution

### Success Criteria
- [ ] PR title is meaningful
- [ ] Summary covers all commits (not just first)
- [ ] Test plan shows what was verified
- [ ] References included if issues exist
- [ ] Attribution footer present

### Failure Modes
- PR title from first commit only → **FAIL**
- Missing test plan → **FAIL**
- Generic PR body (no summary) → **FAIL**

---

## Scenario 5: Closed PR State

### User Request
"Push and create PR"

### Setup
- Branch has existing PR in `CLOSED` state
- New commits added

### Expected Behavior
1. Runs `pr-check.sh` → shows `CLOSED` state

2. **Asks user:**
   - "PR was previously closed. Create new PR or reopen closed one?"

3. **If user chooses "new":**
   - Creates new PR with `gh pr create`
   - New PR number

4. **If user chooses "reopen":**
   - Reopens with `gh pr reopen`
   - Updates with new changes

### Success Criteria
- [ ] Detects CLOSED state
- [ ] Asks user for preference
- [ ] Executes chosen action correctly
- [ ] Does NOT auto-create without asking

### Failure Modes
- Auto-creating without asking → **FAIL**
- Not detecting CLOSED state → **FAIL**

---

## Baseline Performance (Without Skill)

Measure Claude's performance WITHOUT this skill on each scenario:

| Metric | Scenario 1 | Scenario 2 | Scenario 3 | Scenario 4 | Scenario 5 |
|--------|-----------|-----------|-----------|-----------|-----------|
| Activation | N/A | N/A | N/A | N/A | N/A |
| --base used | ? | ? | ? | ? | ? |
| Parallel context | ? | ? | ? | ? | ? |
| Conflict check | ? | ? | ? | ? | ? |
| Success rate | ? | ? | ? | ? | ? |

## Post-Skill Performance

Same metrics after implementing the skill. Target:

- **Activation rate:** >90% (with description triggers)
- **--base compliance:** 100%
- **Parallel context:** 100%
- **Conflict check:** 100% before push
- **Overall success:** >85%

## Testing Instructions

1. **Manual Testing:**
   - Create test branch for each scenario
   - Run scenario in fresh Claude Code session
   - Record actual behavior vs expected

2. **Two-Claude Testing:**
   - **Claude A:** Refine skill based on failures
   - **Claude B:** Test scenarios (fresh session)
   - Iterate until all pass

3. **Regression Testing:**
   - After ANY skill change, re-run all scenarios
   - Document any new failures

## Scoring Rubric

| Score | Criteria |
|-------|----------|
| **2 (Pass)** | All success criteria met, no failures |
| **1 (Partial)** | Most criteria met, minor issues or manual intervention needed |
| **0 (Fail)** | Critical failure, wrong action, or missing key step |

Target: **Average score ≥ 1.8/2.0** across all scenarios
