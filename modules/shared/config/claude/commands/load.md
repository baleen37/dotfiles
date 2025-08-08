---
name: load
description: "Project context loading and session lifecycle management"
mcp-servers: [sequential-thinking, serena]
---

# /load - Project Context Loading

**Purpose**: Load and analyze project context for session initialization and project activation

## Usage

```bash
/load [project]              # Load project context
/load refresh                # Refresh project memories
/load checkpoint <id>        # Restore from checkpoint
/load resume                 # Resume latest session
```

## Execution Strategy

- **Basic**: Project activation and context loading from existing data
- **Refresh**: Force reload of project context and patterns
- **Checkpoint**: Restore from specific checkpoint with session state
- **Resume**: Automatic restoration from latest session checkpoint
- **Onboarding**: Initialize new project with discovery analysis

## MCP Integration

- None required for basic project loading

## Examples

```bash
/load                        # Load current project
/load ~/projects/webapp      # Load specific project
/load refresh                # Refresh project context
/load resume                 # Resume latest session
```

## Agent Routing

- No specialized agents required for project loading
