---
name: restore
description: "Load previous session summaries"
mcp-servers: []
agents: []
tools: [Read, Glob]
---

# /restore - Load Session Summaries

**Purpose**: See what you worked on before

## Usage

```bash
/restore                     # Show recent 3 sessions (date-based)
/restore <partial>           # Auto-complete memo search
```

## Execution

1. Find session files in `~/.claude/sessions/{project}/`
2. Default: Show recent 3 sessions by date
3. Search: Auto-complete memo names for quick access

## Display Format

```
📅 2024-08-08 14:30 [config-fix]
Completed: Fixed Claude settings, Updated commands
Next: Test MCP servers

📅 2024-08-07 10:15 [debug]  
Completed: Fixed build errors
Next: Add tests
```
