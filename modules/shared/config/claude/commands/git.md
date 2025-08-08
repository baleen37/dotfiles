---
name: git
description: "Git operations with intelligent commit messages and workflow optimization"
mcp-servers: []
agents: []
tools: [Read, Bash, Grep, Glob, Write]
---

# /git - Git Operations

**Purpose**: Execute Git operations with intelligent commit message generation and workflow optimization

## Usage

```bash
/git <operation>             # Standard git operations
/git commit                  # Smart commit with intelligent messages
/git status                  # Enhanced status with recommendations
/git branch <name>           # Branch management with conventions
```

## Execution Strategy

- **Basic**: Standard Git operations with validation and error checking
- **Smart Commit**: Intelligent commit message generation from change analysis
- **Status**: Enhanced status with workflow recommendations
- **Branch Management**: Consistent naming conventions and workflow patterns
- **Conflict Resolution**: Automated merge conflict detection and guidance

## MCP Integration

- None required for basic Git operations

## Examples

```bash
/git status                  # Enhanced repository status
/git commit                  # Smart commit with generated message
/git branch feature/auth     # Create branch with naming convention
/git merge develop           # Merge with conflict detection
```

## Agent Routing

- No specialized agents required for Git operations
