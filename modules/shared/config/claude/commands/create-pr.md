---
name: create-pr
description: "Automated pull request creation with intelligent descriptions and metadata"
mcp-servers: []
agents: []
tools: [Read, Bash, Grep, Glob, Write]
---

# /create-pr - Automated Pull Request Creation

**Purpose**: Create pull requests with intelligent descriptions, metadata, and branch analysis

## Usage

```bash
/create-pr                   # Create PR with auto-generated description
/create-pr [title]           # Create PR with custom title
```

## Execution Strategy

- **Branch Analysis**: Analyze commits between feature branch and base branch
- **Description Generation**: Create comprehensive PR description from commit history
- **Metadata Extraction**: Detect related issues, breaking changes, and test coverage
- **Template Application**: Apply repository PR templates if available
- **Validation**: Ensure PR meets repository requirements

## MCP Integration

- None required for PR creation

## Examples

```bash
/create-pr                   # Auto-generate PR with smart description
/create-pr "Add auth system" # Custom title with auto description
```

## PR Generation Logic

1. **Commit Analysis**: Extract commit messages and changed files
2. **Summary Generation**: Create high-level summary of changes
3. **Detail Extraction**: List specific changes, additions, and modifications
4. **Test Plan**: Generate test plan based on changed files
5. **Issue Linking**: Detect and link related issues from commit messages

## Content Structure

- **Summary**: Brief overview of changes
- **Changes**: Detailed list of modifications
- **Test Plan**: How to verify the changes
- **Breaking Changes**: Any breaking changes introduced
- **Related Issues**: Links to related issues/tickets

## Agent Routing

- No specialized agents required for PR creation
