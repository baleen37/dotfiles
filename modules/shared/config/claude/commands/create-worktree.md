# Create Worktree

Efficient git worktree management for parallel development workflows.

## When to Use Worktrees

- **PR Reviews**: Create isolated environments for reviewing pull requests
- **Hotfixes**: Work on urgent fixes while keeping feature branches intact  
- **Parallel Development**: Switch between multiple features without stashing
- **Testing**: Compare behavior across different branches simultaneously
- **Release Preparation**: Maintain separate environments for release candidates

## Quick Start

```bash
# Most common: Create feature branch worktree
git worktree add -b feature/new-feature ./.local/tree/feature/new-feature

# Review PR: Create worktree for existing remote branch
git worktree add ./.local/tree/pr-123 origin/feature/some-feature

# Hotfix: Create worktree from main
git worktree add -b hotfix/critical-bug ./.local/tree/hotfix/critical-bug main
```

## Core Commands

```bash
# Create new branch and worktree (from current HEAD)
git worktree add -b BRANCH_NAME ./.local/tree/BRANCH_NAME

# Create new branch and worktree from specific base
git worktree add -b BRANCH_NAME ./.local/tree/BRANCH_NAME BASE_BRANCH

# Create worktree for existing branch
git worktree add ./.local/tree/BRANCH_NAME BRANCH_NAME

# Create worktree for remote branch
git worktree add ./.local/tree/BRANCH_NAME origin/BRANCH_NAME
```

## Management Commands

```bash
# List all worktrees with branch info
git worktree list

# Move worktree to new location
git worktree move ./.local/tree/old-path ./.local/tree/new-path

# Remove worktree (safe - checks for uncommitted changes)
git worktree remove ./.local/tree/BRANCH_NAME

# Remove worktree (force - ignores uncommitted changes)
git worktree remove --force ./.local/tree/BRANCH_NAME

# Prune deleted worktree references
git worktree prune
```

## Workflow Examples

### PR Review Workflow
```bash
# Create worktree for PR review
pr_number=123
gh pr checkout $pr_number --detach
git worktree add ./.local/tree/review-pr-$pr_number HEAD

# Switch to review environment
cd ./.local/tree/review-pr-$pr_number
# Run tests, review code, etc.

# Clean up after review
cd ../..
git worktree remove ./.local/tree/review-pr-$pr_number
```

### Multi-feature Development
```bash
# Create worktrees for parallel features
git worktree add -b feature/auth ./.local/tree/feature/auth
git worktree add -b feature/api ./.local/tree/feature/api
git worktree add -b feature/ui ./.local/tree/feature/ui

# Work on different features in parallel
# Each worktree maintains its own working directory state
```

## Bulk Operations

### Create worktrees for all open PRs
```bash
# Ensure GitHub CLI is authenticated
gh auth status || gh auth login

# Create ./tree directory if it doesn't exist
mkdir -p ./tree

# Create worktrees for all open PRs
gh pr list --json number,headRefName --jq '.[] | "\(.number):\(.headRefName)"' | while IFS=':' read pr_num branch; do
  branch_path="./.local/tree/pr-${pr_num}-${branch//\//-}"
  
  if [ ! -d "$branch_path" ]; then
    echo "Creating worktree for PR #$pr_num ($branch)"
    # Fetch the branch first
    git fetch origin "$branch"
    git worktree add "$branch_path" "origin/$branch"
  else
    echo "Worktree for PR #$pr_num already exists"
  fi
done
```

### Clean up stale worktrees
```bash
# Show worktrees that may need cleanup
git worktree list | while read path commit branch; do
  if [[ "$path" == *"/tree/"* ]]; then
    branch_name=$(echo "$branch" | sed 's/\[//;s/\]//')
    if [[ "$branch_name" != "detached" ]] && ! git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
      echo "Stale worktree detected: $path (branch: $branch_name)"
    fi
  fi
done

# Remove all stale worktrees (be careful!)
git worktree list | while read path commit branch; do
  if [[ "$path" == *"/tree/"* ]]; then
    branch_name=$(echo "$branch" | sed 's/\[//;s/\]//')
    if [[ "$branch_name" != "detached" ]] && ! git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
      echo "Removing stale worktree: $path"
      git worktree remove --force "$path"
    fi
  fi
done
```

## Best Practices

### Directory Structure
```
./.local/tree/
├── feature/auth/           # Feature branches
├── feature/api/
├── hotfix/bug-123/         # Hotfixes
├── pr-456-some-feature/    # PR reviews
└── release/v2.0/           # Release branches
```

### Safety Tips
- **Always commit or stash** changes before switching worktrees
- **Use descriptive names** for worktree directories
- **Clean up regularly** to avoid disk space issues
- **Don't delete branches** that have active worktrees
- **Check git status** before removing worktrees

### Performance Considerations
- Worktrees share the same `.git` directory (efficient)
- Large repositories benefit more from worktrees than small ones
- Each worktree maintains separate working directory state
- Shared hooks, config, and refs across all worktrees

## Troubleshooting

```bash
# Fix "worktree already exists" error
git worktree remove --force ./.local/tree/problematic-worktree
git worktree prune

# Fix "branch is already checked out" error
git worktree list  # Find where branch is checked out
# Remove the conflicting worktree first

# Fix corrupted worktree
git worktree prune
git worktree repair

# Check worktree status
git worktree list --porcelain
```