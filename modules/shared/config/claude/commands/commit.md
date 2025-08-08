---
name: commit
description: "Intelligent commit message generation with change analysis and conventional commits"
mcp-servers: []
agents: []
tools: [Read, Bash, Grep, Glob, Write]
---

# /commit - Smart Git Commit

**Purpose**: Generate intelligent commit messages through automated change analysis and conventional commit standards

## Usage

```bash
/commit                      # Smart commit with auto-generated message
/commit -m "message"         # Commit with custom message
/commit --amend              # Amend previous commit with updated message
```

## Execution Strategy

- **Change Analysis**: Analyze staged files and generate contextual commit messages
- **Conventional Commits**: Follow conventional commit format (feat:, fix:, docs:, etc.)
- **Scope Detection**: Automatically detect affected modules/components for commit scope
- **Breaking Changes**: Detect and mark breaking changes in commit messages
- **Validation**: Ensure commit message follows project conventions

## MCP Integration

- None required for commit message generation

## Examples

```bash
/commit                      # Auto: "feat(auth): add JWT token validation"
/commit -m "fix: resolve login bug"  # Custom message with validation
/commit --amend              # Update previous commit message
```

## Message Generation Logic

1. **Analyze Changes**: Read diff of staged files
2. **Categorize Type**: Determine commit type (feat, fix, docs, style, refactor, test, chore)
3. **Extract Scope**: Identify affected modules/components
4. **Generate Description**: Create clear, concise description of changes
5. **Format Message**: Apply conventional commit format

## Agent Routing

- No specialized agents required for commit operations
