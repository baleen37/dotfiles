---
description: Create feature branches systematically without forgetting critical steps
---

# Create Feature Branch

Systematically create feature branches with proper git hygiene and workflow management.

**Process:**

1. **Pre-Flight Checks**
   - Run `git status` to check for uncommitted changes or untracked files
   - If there are uncommitted changes:
     - Ask user: "You have uncommitted changes. Would you like to:
       1. Commit them first (recommended)
       2. Stash them temporarily
       3. Discard them (dangerous)
       4. Cancel branch creation"
   - Handle untracked files based on user choice

2. **Branch Name Collection & Validation**
   - Ask user for feature name (simple, descriptive)
   - Suggest standardized naming patterns:
     - `feature/description` (for new features)
     - `fix/description` (for bug fixes)
     - `refactor/description` (for refactoring)
     - `docs/description` (for documentation)
     - `test/description` (for test improvements)
   - Validate branch name:
     - No spaces (use hyphens instead)
     - Lowercase only
     - Avoid special characters except hyphens
     - Keep under 50 characters
   - Check if branch already exists locally or remotely

3. **Base Branch Selection**
   - Check current branch with `git branch --show-current`
   - Ask user: "Create branch from current branch ($(current_branch)) or switch to main/develop first?"
   - If switching needed:
     - Ask which base branch (main, develop, or custom)
     - Run `git fetch` to ensure latest
     - Run `git switch <base-branch>` or `git checkout <base-branch>`
     - Run `git pull` if remote branch exists

4. **Branch Creation**
   - Create new branch: `git switch -c <validated-branch-name>`
   - Confirm success and show current branch
   - Run `git branch -v` to show all local branches with tracking info

5. **Initial Setup**
   - Ask user: "Would you like to:"
     - Create initial commit with empty message
     - Create WIP commit with feature description
     - Skip initial commit"
   - If creating commit:
     - Stage any appropriate files (ask user which)
     - Create meaningful initial commit message
   - Set up remote tracking if needed: `git push -u origin <branch-name>`

6. **Verification & Summary**
   - Display current status: `git status`
   - Show branch info: `git branch --show-current`
   - Show tracking info: `git branch -vv`
   - Provide helpful next steps:
     - Ready to start development
     - Remember to commit frequently
     - Use conventional commit messages
     - Consider creating a draft PR early

**Error Handling:**

- If git operations fail, provide clear error message and recovery suggestions
- If network issues occur (for remote operations), offer to continue locally
- If conflicts arise during branch switching, guide user through resolution

**Examples of Good Branch Names:**
- `feature/user-authentication`
- `fix/memory-leak-data-processing`
- `refactor/api-client-structure`
- `docs-api-endpoint-documentation`
- `test-user-registration-coverage`

**Examples of Bad Branch Names (to avoid):**
- `new feature` (spaces)
- `FEATURE/AUTH` (uppercase, slashes)
- `fix_#123_bug` (special characters)
- `very-long-branch-name-that-exceeds-reasonable-length-and-is-hard-to-read`

**Important:** Always ask for confirmation before making destructive changes. Provide clear feedback at each step so the user understands what's happening and why.
