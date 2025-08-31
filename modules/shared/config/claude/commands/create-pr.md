---
name: create-pr
description: "Automated pull request creation with intelligent descriptions and metadata"
agents: [git-specialist]
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
2. **Branch Management**: Auto-create feature branch if currently on main/master
3. **Content Generation**: Extract commit messages, file changes, and metadata for PR description
4. **Template Integration**: Discover and populate repository PR templates automatically
5. **PR Creation**: Execute `gh pr create` with optimized title and description

## Branch Auto-Creation

When on main/master branch:
- Analyze first commit message for conventional commit patterns
- Generate branch name: `feat/[scope]-[description]` or `fix/[issue-number]`
- Create and switch to new branch automatically

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

## Performance Optimization

- **Parallel Git Commands**: All repository analysis operations run simultaneously
- **Command Validation**: Git syntax validation prevents execution errors
- **Efficient Batching**: Multiple operations combined in single tool calls
- **Error Recovery**: Fallback strategies for Git command failures

## Examples

```bash
/create-pr                           # Full automation with smart defaults
/create-pr "Implement user auth"     # Custom title with auto description
/create-pr --draft                   # Create draft for work-in-progress
```
