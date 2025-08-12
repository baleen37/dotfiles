---
name: create-pr
description: "Automated pull request creation with intelligent descriptions and metadata"
agents: [general-purpose]
---

# /create-pr - Automated Pull Request Creation

**Purpose**: Create pull requests with intelligent descriptions, metadata, and branch analysis

## Usage

```bash
/create-pr                   # Create PR with auto-generated description
/create-pr [title]           # Create PR with custom title
/create-pr --draft           # Create draft PR
```

## Execution Strategy

- **Branch Analysis**: Analyze commits between feature branch and base branch
- **Description Generation**: Create comprehensive PR description from commit history
- **Metadata Extraction**: Detect related issues, breaking changes, and test coverage
- **Template Application**: Apply repository PR templates if available
- **Validation**: Ensure PR meets repository requirements

## PR Generation Logic

1. **Branch Validation**: `git branch --show-current` - ensure not on main
2. **Commit Analysis**: `git log --oneline main..HEAD` - extract commit messages
3. **File Analysis**: `git diff --name-status main..HEAD` - identify changed files
4. **Smart Title**: Generate title from branch name or first commit if not provided
5. **Description Build**: Create comprehensive description from file changes
6. **Template Check**: Look for `.github/pull_request_template.md` and apply
7. **PR Creation**: `gh pr create --title "..." --body "..." [--draft]`

## Implementation Steps

- **Prerequisites Check**: Verify branch differs from main and has commits
- **Content Analysis**: Parse commits for feature descriptions and issue references
- **Template Integration**: Merge repository PR templates with generated content
- **Metadata Detection**: Extract issue numbers, breaking changes, test coverage
- **Quality Validation**: Ensure description meets minimum standards
- **Interactive Options**: Prompt for draft status or additional details

## Content Structure

- **Summary**: Brief overview of changes based on commit analysis
- **Changes**: Detailed list of modifications organized by file type
- **Test Plan**: Generated test approach based on changed files
- **Breaking Changes**: Detected from commit messages and file analysis
- **Related Issues**: Auto-linked from commit messages (fixes #123, closes #456)

## Examples

```bash
/create-pr                   # Auto-generate PR with smart description
/create-pr "Add auth system" # Custom title with auto description
/create-pr --draft           # Create draft PR for work-in-progress
```
