# Create Pull Request

Intelligent PR creation with automated branch management, conflict resolution, and quality checks.

## Usage
```
/project:create-pr [--draft] [--auto-merge] [--title "Custom Title"]
```

## Pre-flight Process

### 1. Repository Analysis
```bash
# Fetch latest remote state
git fetch origin

# Auto-detect default branch
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
echo "Default branch: $DEFAULT_BRANCH"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"
```

### 2. Branch Health Assessment
```bash
# Check if branch exists on remote
git ls-remote --exit-code --heads origin $CURRENT_BRANCH

# Analyze branch status relative to default branch
AHEAD=$(git rev-list --count origin/$DEFAULT_BRANCH..$CURRENT_BRANCH)
BEHIND=$(git rev-list --count $CURRENT_BRANCH..origin/$DEFAULT_BRANCH)

echo "Branch status: $AHEAD ahead, $BEHIND behind"
```

### 3. Automatic Branch Updating
```bash
# If behind, rebase on latest default branch
if [[ $BEHIND -gt 0 ]]; then
  echo "🔄 Updating branch with latest changes..."
  git rebase origin/$DEFAULT_BRANCH
  
  # Check for conflicts
  if [[ $? -ne 0 ]]; then
    echo "❌ Conflicts detected. Please resolve manually:"
    echo "1. Fix conflicts in the listed files"
    echo "2. git add <resolved-files>"
    echo "3. git rebase --continue"
    echo "4. Re-run /project:create-pr"
    exit 1
  fi
fi
```

### 4. Commit Quality Validation
```bash
# Check for commits ahead of default branch
if [[ $AHEAD -eq 0 ]]; then
  echo "❌ No new commits to create PR with"
  echo "💡 Make some changes and commit them first"
  exit 1
fi

# Validate commit messages
git log --oneline origin/$DEFAULT_BRANCH..$CURRENT_BRANCH --format="%s" | while read commit_msg; do
  if [[ ${#commit_msg} -lt 10 ]]; then
    echo "⚠️  Short commit message detected: '$commit_msg'"
  fi
done
```

## Branch Health Requirements

### ✅ Must Pass Checks
- [x] **Ahead of default branch**: Has new commits to merge
- [x] **No merge conflicts**: Clean rebase possible
- [x] **Pushed to remote**: Branch exists on origin
- [x] **Valid commit messages**: Descriptive and properly formatted
- [x] **Lint passes**: Code formatting and style checks
- [x] **No duplicate commits**: Clean commit history

### 🔧 Auto-Resolution Strategy

#### Behind Default Branch
```bash
# Automatic rebase
git fetch origin
git rebase origin/$DEFAULT_BRANCH

# If successful, continue
# If conflicts, pause for manual resolution
```

#### Missing Remote Branch
```bash
# Push branch to origin
git push -u origin $CURRENT_BRANCH
```

#### Lint Failures
```bash
# Auto-fix formatting issues
make lint
git add .
git commit --amend --no-edit
```

#### Poor Commit Messages
```bash
# Interactive rebase to improve messages
git rebase -i origin/$DEFAULT_BRANCH
# Guide user through message improvements
```

## PR Creation Flow

### 1. Pre-commit Validation
```bash
# Run project-specific checks
export USER=ci
make lint                    # Format and lint code
make smoke                   # Quick validation

# Stage any auto-fixes
if [[ -n $(git status --porcelain) ]]; then
  echo "🔧 Auto-fixed formatting issues"
  git add .
  git commit --amend --no-edit
fi
```

### 2. Branch Preparation
```bash
# Ensure branch is pushed
git push origin $CURRENT_BRANCH

# Force push if rebased (safely)
if [[ $REBASED == "true" ]]; then
  git push --force-with-lease origin $CURRENT_BRANCH
fi
```

### 3. PR Generation
```bash
# Check if PR already exists
EXISTING_PR=$(gh pr list --head $CURRENT_BRANCH --json number --jq '.[0].number')

if [[ -n "$EXISTING_PR" ]]; then
  echo "✅ PR #$EXISTING_PR already exists"
  gh pr view $EXISTING_PR
else
  echo "🚀 Creating new pull request..."
  
  # Generate PR with template
  gh pr create \
    --title "$PR_TITLE" \
    --body "$(cat <<'EOF'
## Summary
[Automatic summary based on commits]

## Changes
$(git log --oneline origin/$DEFAULT_BRANCH..$CURRENT_BRANCH)

## Test Plan
- [ ] Local testing completed
- [ ] CI checks pass
- [ ] Manual verification performed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated if needed
- [ ] Tests added/updated for new functionality

🤖 Generated with Claude Code
EOF
)" \
    --assignee @me \
    $DRAFT_FLAG
fi
```

### 4. Auto-merge Setup (Optional)
```bash
# Enable auto-merge if requested
if [[ "$AUTO_MERGE" == "true" ]]; then
  gh pr merge --auto --squash $PR_NUMBER
  echo "✅ Auto-merge enabled - will merge when CI passes"
fi
```

## Advanced Features

### Smart Commit Organization
```bash
# Detect file types for logical grouping
git diff --name-only origin/$DEFAULT_BRANCH..$CURRENT_BRANCH | while read file; do
  case "$file" in
    *.nix)     echo "nix: $file" ;;
    *.md)      echo "docs: $file" ;;
    *.yml)     echo "ci: $file" ;;
    tests/*)   echo "test: $file" ;;
    *)         echo "misc: $file" ;;
  esac
done
```

### Duplicate Commit Detection
```bash
# Find duplicate commits by message
git log --format="%H %s" origin/$DEFAULT_BRANCH..$CURRENT_BRANCH | \
  sort -k2 | uniq -f1 -d | while read hash message; do
  echo "⚠️  Duplicate commit detected: $message"
  echo "   Hash: $hash"
done
```

### Interactive History Cleanup
```bash
# Offer to clean up commit history
echo "📝 Current commits:"
git log --oneline origin/$DEFAULT_BRANCH..$CURRENT_BRANCH

echo "🔧 Options:"
echo "1. Keep as-is"
echo "2. Squash all commits"
echo "3. Interactive rebase"
echo "4. Split large commits"

# Handle user choice
case $CHOICE in
  2) git rebase -i origin/$DEFAULT_BRANCH ;;
  3) git rebase -i origin/$DEFAULT_BRANCH ;;
  4) echo "💡 Use 'git add -p' to stage partial changes" ;;
esac
```

## Error Handling & Recovery

### Conflict Resolution Guide
```bash
# When conflicts occur during rebase
echo "🔧 Conflict Resolution Steps:"
echo "1. Edit conflicted files (marked with <<<<<<< ======= >>>>>>>)"
echo "2. Remove conflict markers and choose correct content"
echo "3. Stage resolved files: git add <file>"
echo "4. Continue rebase: git rebase --continue"
echo "5. Re-run: /project:create-pr"

# Show conflicted files
git status --porcelain | grep "^UU" | cut -c4-
```

### Failed Push Recovery
```bash
# If push fails due to remote changes
echo "🔄 Remote branch updated during process"
echo "Running automatic recovery..."

git fetch origin
git rebase origin/$CURRENT_BRANCH  # Rebase on updated remote
git push origin $CURRENT_BRANCH    # Retry push
```

### Rollback Options
```bash
# If user wants to abort PR creation
echo "🔙 Rollback options:"
echo "1. Keep changes, abort PR: git reset --soft origin/$DEFAULT_BRANCH"
echo "2. Restore original state: git reset --hard origin/$CURRENT_BRANCH"
echo "3. Stash changes: git stash"
```

## Examples

### Basic Usage
```bash
# Simple PR creation for current branch
/project:create-pr
```
**Output:**
```
🔄 Analyzing branch: feature/add-check-ci-command
📊 Repository state:
  - Default branch: main
  - Current branch: feature/add-check-ci-command
  - Status: 3 ahead, 0 behind ✅

🔧 Running pre-commit validation...
  ✅ Lint checks passed
  ✅ Smoke tests passed

🚀 Creating pull request...
  📝 PR #127 created successfully
  🔗 https://github.com/user/dotfiles/pull/127
  ✅ Auto-merge enabled (squash and merge)
```

### With Options
```bash
# Create draft PR with custom title
/project:create-pr --draft --title "WIP: Add new CI monitoring system"
```

### Auto-resolution Examples

#### Scenario: Branch Behind Main
```bash
/project:create-pr

# Output:
🔄 Branch is 2 commits behind main
🔧 Auto-updating with rebase...
✅ Successfully rebased on main
🚀 Continuing with PR creation...
```

#### Scenario: Lint Failures
```bash
/project:create-pr

# Output:
❌ Lint check failed
🔧 Auto-fixing formatting issues...
  - Fixed 3 .nix files
  - Amended commit with fixes
✅ Lint now passes
🚀 Creating PR...
```

#### Scenario: Missing Remote Branch
```bash
/project:create-pr

# Output:
⚠️  Branch not found on remote
🚀 Pushing branch to origin...
✅ Branch pushed successfully
🚀 Creating PR...
```

## Configuration Options

### Command Flags
```bash
--draft              # Create as draft PR
--auto-merge         # Enable auto-merge when CI passes
--title "Title"      # Custom PR title (default: branch name)
--no-rebase         # Skip automatic rebase
--force             # Skip safety checks
--squash            # Offer to squash commits before creating PR
```

### Environment Variables
```bash
# Customize PR behavior
export CREATE_PR_DEFAULT_DRAFT="false"
export CREATE_PR_AUTO_MERGE="true"
export CREATE_PR_TEMPLATE_PATH=".github/pull_request_template.md"

# Git configuration
export CREATE_PR_DEFAULT_BRANCH="main"  # Override default branch detection
export CREATE_PR_COMMIT_MESSAGE_MIN_LENGTH="15"
```

### Project Integration
```bash
# Check for project-specific PR template
if [[ -f ".github/pull_request_template.md" ]]; then
  PR_TEMPLATE=$(cat .github/pull_request_template.md)
else
  PR_TEMPLATE="[Generated template]"
fi

# Use project-specific validation commands
make lint     # Project lint command
make smoke    # Project validation command
make test     # Project test command (optional)
```

## Workflow Integration

### With Other Commands
```bash
# Complete workflow example
/project:create-pr           # Create PR
/project:check-ci            # Monitor CI until complete
/project:verify-pr           # Final verification before merge

# Development workflow
git checkout -b feature/new-feature
# ... make changes ...
git add . && git commit -m "feat: implement new feature"
/project:create-pr --auto-merge
/project:check-ci           # Auto-monitor until CI passes
```

### Integration with Repository Settings
```bash
# Respects repository branch protection rules
# - Required status checks
# - Required reviews
# - Dismiss stale reviews
# - Restrict pushes

# Automatically enables appropriate settings
gh pr merge --auto --squash    # If repository allows auto-merge
gh pr create --draft          # If work in progress
```

### Team Collaboration Features
```bash
# Auto-assign reviewers based on CODEOWNERS
if [[ -f ".github/CODEOWNERS" ]]; then
  # Parse CODEOWNERS and auto-assign
  gh pr create --reviewer @team/reviewers
fi

# Label assignment based on file changes
case "$CHANGED_FILES" in
  *"*.nix"*)      LABELS="$LABELS,nix" ;;
  *"tests/"*)     LABELS="$LABELS,tests" ;;
  *"docs/"*)      LABELS="$LABELS,documentation" ;;
  *".github/"*)   LABELS="$LABELS,ci" ;;
esac

gh pr create --label "$LABELS"
```

## Troubleshooting Guide

### Common Issues

#### "No commits to create PR with"
```bash
# Cause: Branch is not ahead of default branch
# Solution: Make sure you have new commits
git log --oneline origin/main..HEAD  # Should show commits
git status                           # Check for uncommitted changes
```

#### "Conflicts during rebase"
```bash
# Manual resolution required
git status                          # Show conflicted files
# Edit files to resolve conflicts
git add <resolved-files>
git rebase --continue
/project:create-pr                  # Retry PR creation
```

#### "Permission denied" errors
```bash
# Check GitHub CLI authentication
gh auth status
gh auth login                       # Re-authenticate if needed

# Check repository permissions
gh repo view --json permissions
```

#### "Branch protection rules prevent push"
```bash
# Some branches may be protected
# Create PR from a feature branch instead
git checkout -b feature/my-changes
git cherry-pick <commit-hash>       # Copy commits to new branch
/project:create-pr
```

### Debug Mode
```bash
# Enable verbose logging for troubleshooting
export CREATE_PR_DEBUG="true"
/project:create-pr

# Output will include:
# - Detailed git commands and output
# - API request/response details
# - Step-by-step execution trace
```

### Recovery Commands
```bash
# If PR creation fails halfway
git log --oneline                   # Check current state
git status                          # Check working directory
git push origin HEAD               # Push current state
gh pr list --head $(git branch --show-current)  # Check if PR exists

# Clean up partial state
git reset --hard origin/$(git branch --show-current)  # Reset to remote
git clean -fd                      # Clean working directory
```