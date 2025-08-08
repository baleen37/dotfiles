---
name: save
description: "Session context persistence and memory management"
mcp-servers: []
agents: []
tools: [Read, Grep, Glob, Write, TodoWrite]
---

# /save - Session Persistence

**Purpose**: Save session context, progress, and discoveries for continuous project understanding across sessions

## Usage

```bash
/save                        # Save current session state
/save checkpoint             # Create recovery checkpoint
/save learnings              # Save discoveries and insights
/save context                # Save project context
```

## Execution Strategy

- **Basic**: Save current session work and progress
- **Checkpoint**: Create recovery point with current state
- **Learnings**: Persist discovered patterns and insights
- **Context**: Save enhanced project understanding
- **Automatic**: Triggered by time or major task completion

## MCP Integration

- None required for basic session persistence

## Examples

```bash
/save                        # Save current session
/save checkpoint             # Create recovery checkpoint
/save learnings              # Save discoveries only
/save context                # Save project understanding
```

## Agent Routing

- No specialized agents required for session persistence
