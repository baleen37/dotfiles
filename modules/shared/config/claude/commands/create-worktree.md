# Create Worktree

Git worktrees enable parallel development by creating multiple working directories from a single repository.

## Claude Command Usage

When jito requests:
```
/user:create-worktree 사용자 인증 기능을 만들고 싶어
```

**Your Response Protocol:**

1. **Check for team conventions** (look for .github/, CONTRIBUTING.md, or recent branch patterns)
2. **Generate branch name** using default format if no team rules:
   - **Default**: `{type}/{scope}-{description}`
   - **With team username**: `{type}/{username}/{scope}-{description}`
   - Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
   - Convert Korean to English, use kebab-case

3. **Execute worktree creation and navigate**:
   ```bash
   # Default format: feat/auth-system
   git worktree add -b feat/auth-system ./.local/tree/feat/auth-system
   cd ./.local/tree/feat/auth-system
   ```

4. **Provide confirmation** with current directory and next steps

**Examples:**

| Request | Branch Name | Command |
|---------|-------------|---------|
| "사용자 인증 기능" | `feat/auth-system` | `git worktree add -b feat/auth-system ./.local/tree/feat/auth-system && cd ./.local/tree/feat/auth-system` |
| "결제 시스템 버그 수정" | `fix/payment-bug` | `git worktree add -b fix/payment-bug ./.local/tree/fix/payment-bug && cd ./.local/tree/fix/payment-bug` |
| "API 성능 개선" | `feat/api-performance` | `git worktree add -b feat/api-performance ./.local/tree/feat/api-performance && cd ./.local/tree/feat/api-performance` |
| "문서 업데이트" | `docs/readme-update` | `git worktree add -b docs/readme-update ./.local/tree/docs/readme-update && cd ./.local/tree/docs/readme-update` |

**Branch Naming Rules:**
- **Priority 1**: Follow existing repository conventions
- **Default**: `{type}/{scope}-{description}`
- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- **English only** for branch names
- **Kebab-case** for all parts
- **Avoid**: temporal descriptors (new, old, temp)

## Why Use Worktrees

- **PR Reviews**: Isolated environments for reviewing pull requests without disrupting current work
- **Hotfixes**: Create urgent fixes while preserving feature branch state
- **Parallel Development**: Work on multiple features simultaneously without stashing
- **Testing**: Compare behavior across branches side-by-side
- **Experimentation**: Try risky changes without affecting main working directory

## Quick Start

```bash
# Create worktree with new branch from main
git worktree add -b feature/new-feature ./.local/tree/feature/new-feature

# Create worktree from existing branch
git worktree add ./.local/tree/feature/existing feature/existing

# Create worktree from specific base branch
git worktree add -b hotfix/urgent ./.local/tree/hotfix/urgent production

# From GitHub issue URL
issue_url="https://github.com/wooto/ssulmeta/issues/101"
issue_num=$(echo "$issue_url" | grep -oE '[0-9]+$')
git worktree add -b feature/issue-$issue_num ./.local/tree/feature/issue-$issue_num

# List all worktrees
git worktree list

# Remove worktree when done
git worktree remove ./.local/tree/feature/new-feature
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

# Create detached worktree (for temporary work)
git worktree add --detach ./.local/tree/temp-work
```

## Management Commands

```bash
# List all worktrees with details
git worktree list

# Show porcelain output (for scripting)
git worktree list --porcelain

# Move worktree to new location
git worktree move ./.local/tree/old-path ./.local/tree/new-path

# Remove worktree (safe - preserves uncommitted changes)
git worktree remove ./.local/tree/BRANCH_NAME

# Force remove worktree (discards changes)
git worktree remove --force ./.local/tree/BRANCH_NAME

# Clean up stale worktree entries
git worktree prune

# Repair worktree administrative files
git worktree repair
```

## Common Workflows

### GitHub Issue Development

```bash
# Extract issue number from URL and create worktree
issue_url="https://github.com/owner/repo/issues/101"
issue_num=$(echo "$issue_url" | grep -oE '[0-9]+$')
branch_name="feature/issue-$issue_num"
git worktree add -b "$branch_name" "./.local/tree/$branch_name"
cd "./.local/tree/$branch_name"

# With descriptive suffix
issue_num=101
desc="login-bug"
branch_name="feature/issue-$issue_num-$desc"
git worktree add -b "$branch_name" "./.local/tree/$branch_name"
```

### PR Review Workflow

```bash
# Option 1: Using GitHub CLI
pr_number=123
gh pr checkout $pr_number --detach
git worktree add --detach ./.local/tree/review-pr-$pr_number HEAD
cd ./.local/tree/review-pr-$pr_number

# Option 2: Direct from remote
pr_branch="feature/awesome-feature"
git fetch origin pull/$pr_number/head:pr-$pr_number
git worktree add ./.local/tree/review-pr-$pr_number pr-$pr_number

# Clean up after review
cd ../..
git worktree remove ./.local/tree/review-pr-$pr_number
git branch -D pr-$pr_number  # If using Option 2
```

### Multi-Feature Development

```bash
# Create worktrees for parallel features
git worktree add -b feature/auth ./.local/tree/feature/auth
git worktree add -b feature/api ./.local/tree/feature/api main
git worktree add -b feature/ui ./.local/tree/feature/ui develop

# Quick navigation between worktrees
cd ./.local/tree/feature/auth   # Work on authentication
cd ./.local/tree/feature/api    # Switch to API work
cd ./.local/tree/feature/ui     # Switch to UI work
```

## Advanced Operations

### Bulk PR Worktrees

```bash
# Create worktrees for all open PRs
gh pr list --json number,headRefName --jq '.[] | "\(.number):\(.headRefName)"' | \
while IFS=':' read -r pr_num branch; do
  worktree_path="./.local/tree/pr-${pr_num}"
  if [ ! -d "$worktree_path" ]; then
    echo "Creating worktree for PR #$pr_num"
    git fetch origin "$branch"
    git worktree add "$worktree_path" "origin/$branch"
  fi
done
```

### Cleanup Stale Worktrees

```bash
# List stale worktrees (branches that no longer exist)
git worktree list --porcelain | \
awk '/^worktree/ {wt=$2} /^branch/ {print wt, $2}' | \
while read -r path ref; do
  if ! git show-ref --verify --quiet "$ref" 2>/dev/null; then
    echo "Stale: $path"
  fi
done

# Remove all stale worktrees
git worktree list --porcelain | \
awk '/^worktree/ {wt=$2} /^branch/ {branch=$2; print wt, branch}' | \
while read -r path ref; do
  if ! git show-ref --verify --quiet "$ref" 2>/dev/null; then
    echo "Removing stale worktree: $path"
    git worktree remove --force "$path"
  fi
done

# Alternative: Simple prune
git worktree prune
```

### Quick Worktree Status

```bash
# Show all worktrees with current branch and last commit
git worktree list --porcelain | \
awk '/^worktree/ {wt=$2} 
     /^HEAD/ {head=$2} 
     /^branch/ {branch=$2; gsub("refs/heads/", "", branch); 
              print wt, branch ? branch : "detached", head}'
```

## Directory Structure

```
./.local/tree/
├── feature/
│   ├── issue-101-login/
│   ├── issue-102-api/
│   └── new-dashboard/
├── hotfix/
│   └── critical-security/
├── review-pr-123/
└── release/
    └── v2.0-prep/
```

## Best Practices

1. **Consistent Naming**: Use clear, descriptive branch names that indicate purpose
2. **Regular Cleanup**: Remove worktrees after merging to prevent clutter
3. **Commit Before Switching**: Always commit or stash changes before changing directories
4. **Use .gitignore**: Add `.local/tree/` to `.gitignore` if not already present
5. **Avoid Nested Worktrees**: Don't create worktrees inside other worktrees

## Troubleshooting

```bash
# "worktree already exists" error
git worktree remove --force ./.local/tree/BRANCH_NAME
git worktree prune

# "branch already checked out" error
git worktree list  # Find where branch is checked out
# Remove the conflicting worktree first

# Corrupted worktree
git worktree repair ./.local/tree/BRANCH_NAME
# Or remove and recreate
git worktree remove --force ./.local/tree/BRANCH_NAME
git worktree prune

# List detailed worktree info
git worktree list --porcelain

# Clean up all worktrees (nuclear option)
git worktree list | grep ".local/tree" | awk '{print $1}' | \
xargs -I {} git worktree remove --force {}
```

## Tips for Efficiency

- **Tab Completion**: Most shells autocomplete worktree paths after typing `.local/tree/`
- **Shell Aliases**: Add to your shell config for quick access:
  ```bash
  alias wtl='git worktree list'
  alias wtp='git worktree prune'
  ```
- **Editor Integration**: Configure your editor to recognize worktree directories
- **CI/CD**: Worktrees work well with CI systems that need isolated environments