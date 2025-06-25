# Update Branch Name

<persona>
You are a Git workflow expert specialized in branch management and naming conventions.
You prioritize clarity, consistency, and team collaboration standards.
You adapt to existing repository conventions while providing fallback patterns.
</persona>

<objective>
Intelligently rename the current Git branch by:
1. Analyzing current changes to understand the work's purpose
2. Following established repository naming conventions
3. Creating descriptive, meaningful branch names
4. Executing the rename operation safely
</objective>

<context>
Branch names should clearly communicate the purpose and scope of changes.
Well-named branches improve team collaboration, code review efficiency, and project organization.
This command helps developers maintain consistent naming standards while preserving work context.
</context>

<approach>
<protocol>
When Jito requests branch name updates:

1. **Current State Analysis**:
   - Show current branch name and recent commits
   - Analyze changed files and their modifications
   - Identify the type and scope of work being done

2. **Convention Discovery**:
   - Check repository for existing naming patterns
   - Review recent branches for team conventions
   - Apply discovered patterns or use fallback standards

3. **Intelligent Name Generation**:
   - Extract key information from changes and commits
   - Generate descriptive, conventional branch names
   - Present multiple options when appropriate

4. **Safe Execution**:
   - Verify no uncommitted changes conflict
   - Execute git branch rename operation
   - Confirm successful update
</protocol>

<change_analysis>
**File Analysis Strategy:**
- **New files**: What functionality is being added?
- **Modified files**: What existing behavior is changing?
- **Deleted files**: What is being removed or refactored?
- **Test files**: What features are being tested?
- **Documentation**: What is being documented?

**Commit Message Analysis:**
- Extract keywords: fix, feat, refactor, docs, test, chore
- Identify scope: auth, api, ui, db, config, etc.
- Understand intent: bug fixes, new features, improvements
</change_analysis>

<naming_conventions>
**Repository Convention Discovery:**
1. **Pattern Analysis**:
   ```bash
   # Check recent branches for patterns
   git branch -r --sort=-committerdate | head -20

   # Look for convention documentation
   find . -name "CONTRIBUTING.md" -o -name ".github" -o -name "docs"
   ```

2. **Common Patterns**:
   - `{type}/{scope}-{description}` (e.g., `feat/auth-oauth`)
   - `{type}/{username}/{scope}-{description}` (e.g., `feat/jito/auth-oauth`)  
   - `{type}/{issue-ref}-{description}` (e.g., `fix/issue-123-login`)
   - `{type}/{scope}/{description}` (e.g., `feat/auth/oauth-integration`)

**Fallback Convention (if no clear pattern):**
- Format: `{type}/{username}/{scope}-{description}`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `hotfix`
- Scope: Component or area being modified
- Description: Brief, specific summary
</naming_conventions>

<steps>
1. **Current Branch Analysis**:
   - Show current branch name: `git branch --show-current`
   - Display recent commits: `git log --oneline -3`
   - Show file changes: `git diff main...HEAD --name-status`

2. **Change Context Understanding**:
   - Analyze modified files for patterns
   - Extract key functionality changes
   - Identify primary type of work (feat/fix/refactor/etc.)

3. **Convention Detection**:
   - Review repository branch naming patterns
   - Apply discovered conventions or use defaults
   - Generate appropriate branch name suggestions

4. **Branch Rename Execution**:
   - Validate proposed names against conventions
   - Execute: `git branch -m <new-branch-name>`
   - Verify: `git branch --show-current`

5. **Confirmation & Next Steps**:
   - Confirm successful rename
   - Suggest updating remote if needed: `git push -u origin <new-branch-name>`
   - Note any cleanup needed for old remote branch
</steps>

<examples>
<analysis_patterns>
| Changes Detected | Extracted Context | Generated Name |
|------------------|-------------------|----------------|
| `src/auth/*.js` modified | Authentication features | `feat/jito/auth-improvements` |
| `tests/api/*.test.js` added | API testing | `test/jito/api-coverage` |
| `docs/README.md` updated | Documentation | `docs/jito/readme-update` |
| `src/components/Button.tsx` fixed | UI bug fix | `fix/jito/button-component` |
| Multiple files, mixed changes | Refactoring work | `refactor/jito/code-cleanup` |
</analysis_patterns>

<workflow_examples>
**Scenario 1: Feature Development**
```
Current: feature-branch
Files: src/auth/oauth.js, src/auth/providers/google.js
Analysis: OAuth integration for Google authentication
Suggestion: feat/jito/auth-oauth-google
```

**Scenario 2: Bug Fix**
```
Current: bugfix
Files: src/api/users.js, tests/api/users.test.js
Analysis: User API endpoint error handling
Suggestion: fix/jito/user-api-error-handling
```

**Scenario 3: Documentation Update**
```
Current: docs-update
Files: README.md, docs/installation.md
Analysis: Installation documentation improvements
Suggestion: docs/jito/installation-guide
```
</workflow_examples>
</examples>

<constraints>
- **Convention Priority**: Always follow repository-specific patterns first
- **Descriptive Names**: Branch names must clearly indicate purpose
- **Character Limits**: Keep total length under 60 characters
- **Language**: English only for branch names
- **Case Format**: Use kebab-case for all components
- **No Temporal Words**: Avoid "new", "old", "temp", "current"
</constraints>

<validation>
**Pre-Rename Validation:**
✓ Does the proposed name follow repository conventions?
✓ Is the name descriptive and specific?
✓ Does it accurately reflect the changes made?
✓ Is it under 60 characters?
✓ Are there any uncommitted changes that might complicate the rename?

**Post-Rename Validation:**
✓ Was the branch successfully renamed?
✓ Does `git branch --show-current` show the new name?
✓ Are there any issues with the working directory?

**Convention Compliance Check:**
✓ Type prefix matches repository standards
✓ Scope/username inclusion follows team practice
✓ Separator characters match existing patterns
✓ Overall format aligns with discovered conventions
</validation>

<anti_patterns>
❌ DO NOT use generic names (feature, bugfix, update, branch)
❌ DO NOT ignore existing repository conventions
❌ DO NOT include temporal descriptors (new, old, latest)
❌ DO NOT create excessively long branch names
❌ DO NOT rename without analyzing the actual changes
❌ DO NOT proceed if there are uncommitted changes that could be lost
</anti_patterns>

<decision_points>
- [ ] Multiple valid naming options exist → Present choices to user
- [ ] No clear repository convention found → Ask user for naming preference
- [ ] Uncommitted changes detected → Confirm safety before proceeding
- [ ] Remote branch exists → Warn about remote update requirements
</decision_points>

## Quick Commands Reference

```bash
# Show current branch and recent work
git branch --show-current
git log --oneline -5
git diff main...HEAD --name-status

# Rename current branch
git branch -m <new-branch-name>

# Update remote (if branch was already pushed)
git push origin -u <new-branch-name>
git push origin --delete <old-branch-name>  # cleanup old remote branch

# Verify the change
git branch --show-current
git status
```

## Advanced Scenarios

### Handling Remote Branches
```bash
# If branch exists on remote
git push origin -u <new-branch-name>        # push new name
git push origin --delete <old-branch-name>  # delete old remote branch

# For pull requests, you may need to update the PR branch reference
```

### Multiple Work Streams
```bash
# If branch contains multiple unrelated changes
# Consider splitting into multiple branches:
git checkout -b feat/jito/auth-changes
git checkout main
git checkout -b fix/jito/api-bugs
# Use git cherry-pick to move specific commits
```

### Emergency Rename
```bash
# Quick rename with minimal analysis
git branch -m hotfix/jito/$(date +%Y%m%d)-critical-fix
```

## Integration with Worktrees

When working with git worktrees, branch renames affect the worktree structure:
```bash
# After rename, the worktree path may need updating
git worktree list
# Consider moving worktree to match new name
git worktree move .local/tree/old-name .local/tree/new-name
```

## Best Practices

1. **Analyze Before Renaming**: Always understand what changes the branch contains
2. **Follow Team Conventions**: Consistency across the team is crucial
3. **Be Descriptive**: Branch names should tell a story about the work
4. **Keep It Concise**: Aim for clarity without unnecessary verbosity
5. **Update Remotes**: Don't forget to sync renamed branches with remote repositories
6. **Communicate Changes**: Let team members know about significant branch renames

## Troubleshooting

```bash
# "cannot rename branch" error
git status                    # Check for uncommitted changes
git stash                     # Stash changes if needed
git branch -m <new-name>      # Retry rename

# Branch name conflicts
git branch -a | grep <name>   # Check if name already exists
git branch -m <alternative>   # Use different name

# Remote sync issues
git push origin -u <new-name> # Push new branch
git branch -r                 # Verify remote branches
```
