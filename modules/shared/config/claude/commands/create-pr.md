---
name: create-pr
description: "Automated pull request creation with intelligent descriptions and metadata"
---

# /create-pr - Automated Pull Request Creation

**Purpose**: Create pull requests with intelligent descriptions and metadata using Git workflow expertise

## Usage

```bash
/create-pr                   # Create PR with auto-generated description
/create-pr [title]           # Create PR with custom title  
/create-pr --draft           # Create draft PR
```

## Agent Integration

This command leverages the **git-specialist** agent for:
- Parallel Git operations for optimal performance
- Intelligent PR description generation from commit analysis
- Branch validation and auto-creation when needed
- Template discovery and integration
- Git command optimization and error recovery

## Core Workflow

1. **Repository Analysis**: Parallel execution of `git status`, `git log`, and `git diff` for complete branch state
2. **Branch Management**: Auto-create feature branch if currently on main/master, sync with upstream
3. **Commit Validation**: Ensure commits exist and are ready for PR before proceeding
4. **Content Generation**: Extract commit messages, file changes, and metadata for PR description
5. **Template Integration**: Discover and populate repository PR templates automatically
6. **PR Creation**: Execute `gh pr create` with optimized title and description

## Branch Management

### Auto-Creation Logic
When on main/master branch:
- Analyze recent commits for conventional commit patterns
- Generate branch name: `feat/[scope]-[description]` or `fix/[issue-number]`
- Pull latest changes from origin/main before creating branch
- Set upstream tracking for new branch automatically
- Validate branch doesn't already exist locally or remotely

### Branch Validation
- Ensure commits exist before PR creation
- Require clean working directory before branch operations
- Validate upstream remote exists and is accessible
- Check for existing PRs to prevent duplicates

## Template Support

### Automatic Discovery
- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE/default.md`

### Korean Template Integration
- "요약" sections populated from commit analysis
- "변경사항" checkboxes auto-selected based on file changes
- "테스트 계획" structure preserved from template
- All template formatting and checklists maintained

## Safety & Validation

### Pre-Flight Checks
- **Commit Existence**: Ensure commits exist before attempting PR creation
- **Working Directory**: Require clean state before branch operations
- **Remote Sync**: Verify remote access and sync status
- **Duplicate Prevention**: Check existing PRs for current branch

### Performance Optimization
- **Parallel Git Commands**: All repository analysis operations run simultaneously
- **Command Validation**: Git syntax validation prevents execution errors
- **Efficient Batching**: Multiple operations combined in single tool calls
- **Error Recovery**: Fallback strategies for Git command failures

## Error Scenarios & Solutions

### Common Issues Prevented
- **No Commits**: "Error: No commits found for PR creation"
- **Branch Conflicts**: "Error: Branch already exists remotely"
- **Dirty Working Directory**: "Error: Uncommitted changes detected"
- **Missing Remote**: "Error: No upstream remote configured"
- **Duplicate PR**: "Error: PR already exists for this branch"

### Smart Fallback Behaviors
- Auto-stash uncommitted changes when safe
- Interactive branch naming if conventional patterns fail
- Template fallback to basic format if custom templates fail
- Draft PR creation if validation concerns exist

## Examples

```bash
/create-pr                           # Full automation with safety checks
/create-pr "Implement user auth"     # Custom title with branch validation
/create-pr --draft                   # Create draft PR from feature branch
```

### Workflow Examples
```bash
# Feature branch workflow
git checkout -b feat/user-authentication
# ... make changes and commits ...
/create-pr                           # Creates PR from feature branch

# Auto-branch creation from main
git checkout main
# ... make commits on main ...
/create-pr                           # Auto-creates feature branch, then PR
```
