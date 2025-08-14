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
5. **Template Discovery**: Find GitHub PR templates using intelligent detection
6. **Template Apply**: Parse and populate template structure with generated content
7. **PR Creation**: `gh pr create --title "..." --body "..." [--draft]`

## Implementation Steps

- **Prerequisites Check**: Verify branch differs from main and has commits
- **Content Analysis**: Parse commits for feature descriptions and issue references
- **Template Discovery**: Use intelligent detection to find repository PR templates
- **Template Integration**: Parse template structure and populate with generated content
- **Metadata Detection**: Extract issue numbers, breaking changes, test coverage
- **Quality Validation**: Ensure description meets minimum standards
- **Interactive Options**: Prompt for draft status or additional details

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

## Content Structure

### Default Format (No Template)
- **Summary**: Brief overview of changes based on commit analysis
- **Changes**: Detailed list of modifications organized by file type
- **Test Plan**: Generated test approach based on changed files
- **Breaking Changes**: Detected from commit messages and file analysis
- **Related Issues**: Auto-linked from commit messages (fixes #123, closes #456)

### Template-Based Format
- **Template Discovery**: Automatically detect and parse repository PR templates
- **Content Mapping**: Map generated content to template sections intelligently
- **Structure Preservation**: Maintain template checkboxes and formatting
- **Korean Template Support**: Special handling for Korean language templates
  - "요약" section populated from commit analysis
  - "변경사항" checkboxes auto-selected based on file changes
  - "테스트 계획" structure preserved from template
  - "체크리스트" maintained as-is from template

## Examples

```bash
/create-pr                   # Auto-generate PR with smart description
/create-pr "Add auth system" # Custom title with auto description
/create-pr --draft           # Create draft PR for work-in-progress
```
