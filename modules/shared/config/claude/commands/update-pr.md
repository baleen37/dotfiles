---
name: update-pr
description: "Update existing pull request with intelligent description and metadata synchronization"
---

# /update-pr - Pull Request Update & Synchronization

**Purpose**: Update existing pull requests with refreshed descriptions, metadata, and branch synchronization

## Usage

```bash
/update-pr                   # Update current PR with latest changes
/update-pr [pr-number]       # Update specific PR by number
/update-pr [title]           # Update PR title and description
/update-pr --add-label bug,enhancement  # Add labels to PR
/update-pr --add-reviewer @username     # Request review from user
/update-pr --ready-for-review           # Mark draft PR as ready
/update-pr --add-assignee @username     # Add assignee to PR
```

## Execution Strategy

- **Parallel Git Operations**: ALWAYS run git status, git diff, and git log commands in parallel for optimal performance
- **Change Detection**: Analyze new commits since last PR update
- **Description Refresh**: Update PR description with latest commit analysis
- **Metadata Sync**: Update labels, assignees, and milestone information
- **Conflict Resolution**: Detect and highlight merge conflicts
- **Status Validation**: Ensure PR still meets repository requirements

**Performance Note**: Use Claude's capability to call multiple tools in a single response. Batch git operations together for 20-30% speed improvement.

## Update Logic

1. **Current State**: `gh pr view [number] --json` - fetch existing PR details
2. **Parallel Analysis** (run in parallel):
   - `git log --oneline origin/main..HEAD` - compare commits
   - `git diff --name-status origin/main..HEAD` - changed files
   - `gh pr status --json` - current PR metadata
3. **Template Discovery**: Find GitHub PR templates using intelligent detection
4. **Description Generation**: Create comprehensive summary with template structure
5. **Template Apply**: Parse and populate template with refreshed content
6. **Metadata Update**: Apply changes based on options:
   - Basic: `gh pr edit [number] --title "..." --body "..."`
   - Labels: `gh pr edit [number] --add-label "bug,enhancement"`
   - Reviewers: `gh pr edit [number] --add-reviewer "@username"`
   - Ready: `gh pr ready [number]`
   - Assignees: `gh pr edit [number] --add-assignee "@username"`
7. **Status Check**: `gh pr checks` - verify CI and review status

## Implementation Steps

- **Branch Detection**: Identify current branch or PR number
- **Commit Analysis**: Extract meaningful changes from git history
- **Template Discovery**: Use intelligent detection to find repository PR templates
- **Smart Description**: Generate description based on file changes and commits
- **Template Integration**: Parse template structure and populate with refreshed content
- **Conflict Detection**: Check for merge conflicts with base branch
- **Automated Updates**: Update PR title, body, and relevant metadata

## Template Discovery Logic

```bash
find_pr_template() {
  local template_paths=(
    ".github/pull_request_template.md"
    ".github/PULL_REQUEST_TEMPLATE.md"
    ".github/PULL_REQUEST_TEMPLATE/default.md"
  )

  for template in "${template_paths[@]}"; do
    [[ -f "$template" ]] && echo "$template" && return 0
  done

  # Check for multiple template directory
  if [[ -d ".github/PULL_REQUEST_TEMPLATE" ]]; then
    find .github/PULL_REQUEST_TEMPLATE -name "*.md" | head -1
  fi
}
```

## Template Update Strategy

### Existing PR with Template
- **Preserve Structure**: Maintain original template sections and formatting
- **Update Content**: Refresh only the content within template sections
- **Korean Template Support**: Special handling for Korean language templates
  - Update "요약" section with latest commit analysis
  - Refresh "변경사항" checkboxes based on new file changes
  - Preserve "테스트 계획" and "체크리스트" sections as-is

### Existing PR without Template
- **Template Detection**: Check if repository now has PR templates
- **Migration Option**: Offer to migrate existing PR to template format
- **Content Preservation**: Maintain existing content while adding template structure

## Examples

```bash
/update-pr                   # Refresh current PR with latest commits
/update-pr 123               # Update specific PR #123
/update-pr "Fix auth system" # Update title and regenerate description

# Advanced usage
/update-pr --add-label bug,security         # Add multiple labels
/update-pr --add-reviewer @lead-dev         # Request review
/update-pr --ready-for-review               # Convert draft to ready
/update-pr 123 --add-assignee @developer    # Assign PR to developer

# Combined operations
/update-pr "Update auth" --add-label enhancement --add-reviewer @team-lead
```
