---
name: update-pr
description: "Update existing pull request with intelligent description and metadata synchronization"
agents: [general-purpose]
---

# /update-pr - Pull Request Update & Synchronization

**Purpose**: Update existing pull requests with refreshed descriptions, metadata, and branch synchronization

## Usage

```bash
/update-pr                   # Update current PR with latest changes
/update-pr [pr-number]       # Update specific PR by number
/update-pr [title]           # Update PR title and description
```

## Execution Strategy

- **Change Detection**: Analyze new commits since last PR update
- **Description Refresh**: Update PR description with latest commit analysis
- **Metadata Sync**: Update labels, assignees, and milestone information
- **Conflict Resolution**: Detect and highlight merge conflicts
- **Status Validation**: Ensure PR still meets repository requirements

## Update Logic

1. **Current State**: `gh pr view [number] --json` - fetch existing PR details
2. **Change Analysis**: `git log --oneline origin/main..HEAD` - compare commits
3. **File Analysis**: `git diff --name-status origin/main..HEAD` - changed files
4. **Description Generation**: Create comprehensive summary from commit analysis
5. **Metadata Update**: `gh pr edit [number] --title "..." --body "..."` - apply changes
6. **Status Check**: `gh pr checks` - verify CI and review status

## Implementation Steps

- **Branch Detection**: Identify current branch or PR number
- **Commit Analysis**: Extract meaningful changes from git history
- **Smart Description**: Generate description based on file changes and commits
- **Template Application**: Use repository PR templates if available
- **Conflict Detection**: Check for merge conflicts with base branch
- **Automated Updates**: Update PR title, body, and relevant metadata

## Examples

```bash
/update-pr                   # Refresh current PR with latest commits
/update-pr 123               # Update specific PR #123
/update-pr "Fix auth system" # Update title and regenerate description
```
