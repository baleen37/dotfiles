---
name: create-pr
description: "Smart PR creation with auto branch/commit/description"
agents: [general-purpose]
---

# /create-pr - Smart PR Creation

Automated workflow for branch creation, commits, and PR description generation

## Usage
```bash
/create-pr                   # Auto-generated description
/create-pr [title]           # Custom title
/create-pr --draft           # Draft PR
```

## Auto Flow

### 1. Scenario Handling
- **main branch + changes**: stage → commit → create branch → PR
- **main branch + no changes**: exit ("No changes found")
- **feature branch + commits**: create PR immediately
- **feature branch + uncommitted**: stage → commit → PR

### 2. Git Commands (Parallel Execution)
```bash
git status --porcelain          # Working directory status
git log --oneline main..HEAD    # Commit history
git diff main..HEAD --stat      # Changed files
```

### 3. Branch Name Generation
- Commit message analysis → `feat/auth-improvements`
- File path analysis → `feat/[component]-updates`
- Fallback → `feat/update-YYYYMMDD-HHMMSS`

## Template Support

### Auto Detection
```bash
.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE/default.md
```

### Korean Template Support
- "요약" section: auto-generated from commit analysis
- "변경사항" checkboxes: auto-selected based on file changes
- "테스트 계획": preserve template structure

## Default PR Structure (No Template)
- **Summary**: Overview based on commit analysis
- **Changes**: Modifications organized by file type
- **Test Plan**: Testing approach based on changed files
- **Related Issues**: Auto-extracted from commits (fixes #123)

## Error Handling
- Git command syntax validation
- Fallback commands on failure
- Continue PR creation despite non-critical failures
