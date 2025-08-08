---
name: save
description: "Session context persistence with Serena MCP integration"
allowed-tools: [Read, Grep, Glob, Write, write_memory, list_memories, read_memory, summarize_changes, think_about_collected_information]

# Command Classification
category: session
complexity: standard
scope: cross-session

# Integration Configuration
mcp-integration:
  servers: [serena]
  personas: []
  wave-enabled: false
  complexity-threshold: 0.3
  auto-flags: []

# Performance Profile
performance-profile: session-critical
performance-targets:
  initialization: <500ms
  core-operations: <200ms
  checkpoint-creation: <1s
  memory-operations: <200ms
---

# /sc:save - Session Context Persistence

## Purpose
Save session context, progress, and discoveries to Serena MCP memories for continuous project understanding across sessions.

## Usage
```
/sc:save [--type session|learnings|context|all] [--summarize] [--checkpoint] [--uc]
```

## Arguments
- `--type` - What to save (session, learnings, context, all)
- `--summarize` - Generate session summary using Serena's summarize_changes
- `--checkpoint` - Create a session checkpoint for recovery
- `--uc` - Enable token efficiency mode for session data compression

## Core Operations

### 1. Session Analysis
- Call `think_about_collected_information` to analyze session work
- Identify new discoveries, patterns, and insights
- Determine what should be persisted for future sessions

### 2. Serena MCP Integration
- Execute `list_memories` to check existing memories
- Organize information by category:
  - **session_context**: Current work and progress
  - **code_patterns**: Discovered patterns and conventions  
  - **project_insights**: New understanding about the project
  - **technical_decisions**: Architecture and design choices
- Use `write_memory` to persist data with appropriate keys

### 3. Save Types
Based on `--type` parameter:
- **session**: Save current session work using key "session/{timestamp}"
- **learnings**: Save discoveries and update knowledge memories
- **context**: Save enhanced project understanding
- **all**: Comprehensive save of all categories

### 4. Checkpoint Creation
When `--checkpoint` flag provided or triggered automatically:
- Time elapsed ≥30 minutes since last checkpoint
- High priority task completed
- High risk operation pending or completed
- Include restoration data with current task states and open questions

## Memory Keys

### Session Memories
- `session/{timestamp}` - Individual session records
- `session/current` - Latest session state pointer

### Knowledge Memories
- `code_patterns` - Discovered coding patterns
- `project_insights` - Accumulated project understanding
- `technical_decisions` - Architecture decisions
- `performance_metrics` - Operation timing data

### Checkpoint Memories
- `checkpoints/{timestamp}` - Session checkpoints
- `checkpoints/latest` - Most recent checkpoint pointer
- `checkpoints/task-{task-id}-{timestamp}` - Task-specific checkpoints

## Session Metadata Structure

```yaml
# Memory key: session/{timestamp}
session:
  id: "session-{YYYY-MM-DD-HHMMSS}"
  project: "{project_name}"
  start_time: "{ISO8601_timestamp}"
  end_time: "{ISO8601_timestamp}"
  duration_minutes: {number}

work:
  tasks_completed:
    - id: "{task_id}"
      description: "{task_description}"
      duration_minutes: {number}

  files_modified:
    - path: "{absolute_path}"
      operations: [edit|create|delete]

  decisions_made:
    - decision: "{decision_description}"
      rationale: "{reasoning}"
      impact: "architectural|functional|performance|security"

discoveries:
  patterns_found: [list_of_patterns]
  insights_gained: [list_of_insights]

checkpoints:
  - timestamp: "{ISO8601_timestamp}"
    type: "task_complete|time_based|risk_based"
    trigger: "{trigger_description}"
```

## Automatic Checkpoint Triggers

### Task-Based Triggers
- Major task marked complete via TodoWrite
- Memory Key: `checkpoints/task-{task-id}-{timestamp}`

### Time-Based Triggers
- Every 30 minutes of active work
- Memory Key: `checkpoints/auto-{timestamp}`

### Risk-Based Triggers
- Before major refactoring (>50 files)
- Before deletion operations
- Before architecture changes
- Memory Key: `checkpoints/risk-{operation}-{timestamp}`

## Performance Requirements

- **Session Save**: <2s for typical session
- **Core Operations**: <200ms for memory operations
- **Checkpoint Creation**: <1s for comprehensive checkpoint
- **Memory Operations**: <200ms per individual operation

## Error Handling

- **Serena Unavailable**: Queue saves locally for later sync
- **Memory Conflicts**: Merge intelligently or prompt user
- **Data Integrity Errors**: Validate and recover with fallback mechanisms
- **Performance Degradation**: Monitor timing and optimize automatically

## Integration with /sc:load

### Session Lifecycle
1. `/sc:load` - Activate project and load context
2. Work on project (make changes, discover patterns)
3. `/sc:save` - Persist discoveries and progress
4. Next session: `/sc:load` retrieves enhanced context

### Continuous Learning
- Each session builds on previous knowledge
- Patterns and insights accumulate over time
- Project understanding deepens with each cycle

## Examples

```bash
# Basic session save
/sc:save

# Create checkpoint with metadata
/sc:save --checkpoint

# Save with summary generation
/sc:save --summarize

# Save only new learnings
/sc:save --type learnings

# Comprehensive save with token efficiency
/sc:save --type all --uc
```

## Boundaries

**This command will:**
- Save session context and discoveries to Serena MCP
- Create checkpoints for session recovery
- Maintain context continuity across sessions
- Meet performance targets for session operations

**This command will not:**
- Operate without Serena MCP integration
- Compromise performance targets
- Skip session validation
- Function without proper error handling
