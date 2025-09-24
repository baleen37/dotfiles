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
/create-pr --merge           # Create PR and attempt immediate merge
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
2. **Auto-Commit**: Automatically commit any uncommitted changes before proceeding
3. **Branch Management**: Auto-create feature branch if currently on main/master, sync with upstream
4. **Commit Validation**: Ensure commits exist and are ready for PR before proceeding
5. **Content Generation**: Extract commit messages, file changes, and metadata for PR description
6. **Template Integration**: Discover and populate repository PR templates automatically
7. **PR Creation**: Execute `gh pr create` with optimized title and description
8. **Auto-Merge** (when --merge flag used): Enable `gh pr create --enable-auto-merge --merge-method squash`

## Branch Management

### Auto-Creation Logic
When on main/master branch:
- Analyze recent commits for conventional commit patterns
- Generate branch name: `feat/[scope]-[description]` or `fix/[issue-number]`
- Pull latest changes from origin/main before creating branch
- Set upstream tracking for new branch automatically
- Handle branch conflicts: generate descriptive alternative names (e.g., feat/validation-fix → feat/validation-self-reference-fix)

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
- **Auto-Commit**: Automatically commit staged and unstaged changes with generated commit message
- **Commit Existence**: Ensure commits exist before attempting PR creation
- **Working Directory**: Achieve clean state through auto-commit before branch operations
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
- **Branch Conflicts**: Generate contextual branch names based on recent commits instead of generic suffixes
- **Uncommitted Changes**: Auto-commit with intelligent commit message generation
- **Missing Remote**: "Error: No upstream remote configured"
- **Duplicate PR**: "Error: PR already exists for this branch"

### Smart Fallback Behaviors
- Auto-commit uncommitted changes with generated commit messages
- Interactive branch naming if conventional patterns fail
- Template fallback to basic format if custom templates fail
- Draft PR creation if validation concerns exist

## Implementation

Use Task tool with subagent_type="git-specialist" to execute PR creation workflow:

Prompt: "Analyze Git repository state and create pull request with arguments: $ARGUMENTS. Execute these operations in parallel:

1. Run `git status` to check working directory state
2. Run `git log --oneline -10` to see recent commits
3. Run `git diff --name-only HEAD~5..HEAD` to see changed files
4. Run `git branch -v` to check current branch status

Before creating PR:
- If uncommitted changes exist, automatically commit them with intelligent commit message
- Generate commit message based on file changes and conventional commit patterns
- Use `git add -A && git commit -m "[generated message]"` for auto-commit

After ensuring clean state, create a pull request with:
- Intelligent title based on commit messages
- Comprehensive description from file changes and commits
- Proper Korean language formatting if templates exist
- Auto-generated summary of changes

Use proper Git workflow expertise for branch management and PR creation. If on main branch, create appropriate feature branch first.

Branch conflict handling:
- If branch exists: analyze recent commit messages to generate descriptive alternative name
- If --merge flag: add `--enable-auto-merge --merge-method squash` to gh pr create command
- Fallback to timestamp suffix only if context analysis fails"

## Examples

```bash
/create-pr                           # Full automation with safety checks
/create-pr "Implement user auth"     # Custom title with branch validation
/create-pr --draft                   # Create draft PR from feature branch
/create-pr --merge                   # Create PR and merge when checks pass
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
