# Create Pull Request Command

Create a clean, conflict-free pull request with proper branch management.

## Pre-flight Process
1. **Fetch latest**: `git fetch origin`
2. **Detect default branch**: Auto-detect main/master/develop from remote
3. **Check branch status**: ahead/behind/diverged analysis
4. **Update if needed**: Rebase on latest default branch
5. **Resolve conflicts**: Guide manual resolution if needed
6. **Clean duplicates**: Remove duplicate commits
7. **Verify readiness**: Ensure branch has commits to merge

## Branch Health Requirements
- Must be ahead of default branch
- No merge conflicts
- No duplicate commits
- Clean commit history

## Auto-Resolution Strategy
- **Behind**: `git rebase origin/[default-branch]`
- **Diverged**: Interactive rebase to clean history
- **Conflicts**: Pause and provide resolution guidance
- **No ahead commits**: Exit with "nothing to PR"

## PR Creation Flow
- Format code with available tools
- Split changes into logical commits
- Create descriptive commit messages
- Push clean branch to remote
- Generate PR with summary and test plan

## Commit Organization
- One logical change per commit
- Related files grouped together
- Refactoring separate from features
- Self-contained, reviewable commits