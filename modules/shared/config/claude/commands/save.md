---
name: save
description: "Save session work summary"
mcp-servers: []
agents: []
tools: [Write]
---

# /save - Save Session Summary

**Purpose**: Save what you accomplished this session

## Usage

```bash
/save                       # Save current session (auto-generates memo from work)
/save <memo>                # Save with specific memo (rare use)
```

## Execution

1. Review TodoWrite completed tasks
2. Auto-generate memo from main task (e.g. "claude-config", "build-fix")
3. Write 2-3 line summary to `~/.claude/sessions/{project}/session-{date}.md`

## Summary Format

```
Date: 2024-08-08 14:30
Memo: config-fix

Completed:
- Fixed Claude settings
- Updated commands

What's next:
- Test MCP servers
```
