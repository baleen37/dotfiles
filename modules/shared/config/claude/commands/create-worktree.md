# Create Worktree

Efficient git worktree management for parallel development workflows.

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
   git worktree add -b feat/auth-system .local/tree/feat-auth-system
   cd .local/tree/feat-auth-system
   ```

4. **Provide confirmation** with current directory and next steps

**Examples:**

| Request | Branch Name | Command |
|---------|-------------|---------|
| "사용자 인증 기능" | `feat/auth-system` | `git worktree add -b feat/auth-system .local/tree/feat-auth-system && cd .local/tree/feat-auth-system` |
| "결제 시스템 버그 수정" | `fix/payment-bug` | `git worktree add -b fix/payment-bug .local/tree/fix-payment-bug && cd .local/tree/fix-payment-bug` |
| "API 성능 개선" | `feat/api-performance` | `git worktree add -b feat/api-performance .local/tree/feat-api-performance && cd .local/tree/feat-api-performance` |
| "문서 업데이트" | `docs/readme-update` | `git worktree add -b docs/readme-update .local/tree/docs-readme-update && cd .local/tree/docs-readme-update` |

**Branch Naming Rules:**
- **Priority 1**: Follow existing repository conventions
- **Default**: `{type}/{scope}-{description}`
- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- **English only** for branch names
- **Kebab-case** for all parts
- **Avoid**: temporal descriptors (new, old, temp)

## When to Use Worktrees

- **PR Reviews**: Create isolated environments for reviewing pull requests
- **Hotfixes**: Work on urgent fixes while keeping feature branches intact  
- **Parallel Development**: Switch between multiple features without stashing
- **Testing**: Compare behavior across different branches simultaneously
- **Release Preparation**: Maintain separate environments for release candidates

## Quick Start

```bash
# Create feature branch worktree
git worktree add -b feat/auth-system .local/tree/feat-auth-system

# Review PR: Create worktree for existing branch
git worktree add .local/tree/pr-123 origin/feat/some-feature

# Fix: Create worktree from main
git worktree add -b fix/critical-bug .local/tree/fix-critical-bug main
```

## Core Commands

```bash
# Create new branch and worktree (from current HEAD)
git worktree add -b BRANCH_NAME .local/tree/BRANCH_NAME

# Create new branch and worktree from specific base
git worktree add -b BRANCH_NAME .local/tree/BRANCH_NAME BASE_BRANCH

# Create worktree for existing branch
git worktree add .local/tree/BRANCH_NAME BRANCH_NAME

# Create worktree for remote branch
git worktree add .local/tree/BRANCH_NAME origin/BRANCH_NAME
```

## Management Commands

```bash
# List all worktrees with branch info
git worktree list

# Move worktree to new location
git worktree move .local/tree/old-path .local/tree/new-path

# Remove worktree (safe - checks for uncommitted changes)
git worktree remove .local/tree/BRANCH_NAME

# Remove worktree (force - ignores uncommitted changes)
git worktree remove --force .local/tree/BRANCH_NAME

# Prune deleted worktree references
git worktree prune
```

## Workflow Examples

### PR Review Workflow
```bash
# Create worktree for PR review
pr_number=123
git worktree add .local/tree/pr-$pr_number origin/pr-$pr_number

# Switch to review environment
cd .local/tree/pr-$pr_number
# Run tests, review code, etc.

# Clean up after review
cd ../..
git worktree remove .local/tree/pr-$pr_number
```

### Multi-feature Development
```bash
# Create worktrees for parallel features
git worktree add -b feat/auth-system .local/tree/feat-auth-system
git worktree add -b feat/api-redesign .local/tree/feat-api-redesign
git worktree add -b feat/ui-update .local/tree/feat-ui-update

# Work on different features in parallel
# Each worktree maintains its own working directory state
```

## Bulk Operations

### Create worktrees for all open PRs
```bash
# Create .local/tree directory if it doesn't exist
mkdir -p .local/tree

# Create worktrees for all open PRs
gh pr list --json number,headRefName --jq '.[] | "\(.number):\(.headRefName)"' | while IFS=':' read pr_num branch; do
  branch_path=".local/tree/pr-${pr_num}"
  if [ ! -d "$branch_path" ]; then
    echo "Creating worktree for PR #$pr_num"
    git fetch origin "$branch" && git worktree add "$branch_path" "origin/$branch"
  fi
done
```

### Clean up stale worktrees
```bash
# Remove all stale worktrees
git worktree prune

# List and remove specific stale worktrees
git worktree list | grep ".local/tree" | while read path _; do
  if [ ! -d "$path" ]; then
    echo "Removing stale worktree: $path"
    git worktree remove --force "$path" 2>/dev/null || true
  fi
done
```

## Best Practices

### Directory Structure
```
project/.local/tree/
├── feat-auth-system/          # Feature branches
├── feat-api-redesign/
├── fix-payment-bug/           # Bug fixes
├── docs-readme-update/        # Documentation
├── chore-cleanup/             # Maintenance
├── pr-456/                    # PR reviews
└── release-v2.0/              # Release branches
```

### Safety Tips
- **Always commit or stash** changes before switching worktrees
- **Use descriptive names** for worktree directories
- **Branch names MUST be in English** following repository conventions
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
git worktree remove --force .local/tree/problematic-worktree
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
