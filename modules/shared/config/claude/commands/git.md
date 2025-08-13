---
name: git
description: "Basic Git operations with status, branch management, and workflow guidance"
agents: []
---

# /git - Basic Git Operations

**Purpose**: Execute basic Git operations with enhanced status reporting and branch management

## Usage

```bash
/git status                  # Enhanced repository status with recommendations
/git branch <name>           # Branch management with naming conventions
/git merge <branch>          # Merge with conflict detection
/git <operation>             # Standard git operations with validation
```

## Execution Strategy

- **Status**: Enhanced status with workflow recommendations and change summary
- **Branch Management**: Consistent naming conventions and branch operations
- **Merge Operations**: Automated merge conflict detection and guidance
- **Basic Operations**: Standard Git operations with validation and error checking

## MCP Integration

- None required for basic Git operations

## Examples

```bash
/git status                  # Enhanced repository status
/git branch feature/auth     # Create branch with naming convention
/git merge develop           # Merge with conflict detection
/git stash                   # Stash operations with context
```

## Agent Routing

- No specialized agents required for Git operations
