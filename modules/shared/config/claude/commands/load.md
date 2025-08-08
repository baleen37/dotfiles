---
name: load
description: "Session lifecycle management with Serena MCP integration for project context loading"
allowed-tools: [Read, Grep, Glob, Write, activate_project, list_memories, read_memory, write_memory, check_onboarding_performed, onboarding]

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
  memory-operations: <200ms
---

# /sc:load - Project Context Loading with Serena

## Purpose
Load and analyze project context using Serena MCP for project activation, memory retrieval, and session lifecycle integration.

## Usage
```
/sc:load [target] [--type TYPE] [--refresh] [--analyze] [--checkpoint ID] [--resume] [--validate] [--performance] [--metadata] [--cleanup] [--uc]
```

## Arguments
- `target` - Project directory or name (defaults to current directory)
- `--type` - Specific loading type (project, config, deps, env, checkpoint)
- `--refresh` - Force reload of project memories and context
- `--analyze` - Run deep analysis after loading
- `--onboard` - Run onboarding if not performed
- `--checkpoint` - Restore from specific checkpoint ID
- `--resume` - Resume from latest checkpoint automatically
- `--validate` - Validate session integrity and data consistency
- `--performance` - Enable performance monitoring
- `--metadata` - Include comprehensive session metadata
- `--cleanup` - Perform session cleanup and optimization
- `--uc` - Enable Token Efficiency mode (30-50% compression for session data)

## Core Operations

### 1. Project Activation
- Use `activate_project` tool with `{"project": target}`
- Handle project registration if needed
- Validate project path and language detection

### 2. Memory Management
- Call `list_memories` to discover existing memories
- Use `read_memory` with `{"memory_file_name": name}` to load specific memories
- Load memories based on --type parameter:
  - **project**: project_purpose, tech_stack
  - **config**: code_style_conventions, completion_tasks
  - **deps**: package.json/pyproject.toml analysis
  - **env**: environment-specific memories

### 3. Session State Management
- Call `check_onboarding_performed` tool
- If not onboarded and --onboard flag, call `onboarding` tool
- Create initial memories if project is new
- Handle checkpoint restoration if specified

### 4. Context Building
- Build comprehensive project context from memories
- Supplement with file analysis if memories incomplete
- Create/update memories with new discoveries
- Initialize session metadata with start time

### 5. Performance Validation
- Monitor operation performance against targets
- Validate memory efficiency and response times
- Generate performance reports if --performance flag

## Memory Categories
- `project_purpose` - Overall project goals and architecture
- `tech_stack` - Technologies, frameworks, dependencies
- `code_style_conventions` - Coding standards and patterns
- `completion_tasks` - Build/test/deploy commands
- `suggested_commands` - Common development workflows
- `session/*` - Session records and continuity data
- `checkpoints/*` - Checkpoint data for restoration

## Token Efficiency Mode
When `--uc` flag is used:
- Applies 30-50% compression to session data only
- Framework content excluded from compression
- User project content preserved at full fidelity
- Improves memory operation performance

## Performance Targets
- Session Initialization: <500ms
- Core Operations: <200ms per operation
- Memory Operations: <200ms per operation
- Project Activation: <100ms

## Error Handling
- **Serena Unavailable**: Fallback to traditional file analysis
- **Memory Access Failures**: Retry with exponential backoff
- **Onboarding Failures**: Graceful degradation with manual options
- **Context Corruption**: Rebuild from available information

## Examples

### Basic Project Load
```
/sc:load
# Activates current directory and loads all memories
```

### Specific Project with Analysis
```
/sc:load ~/projects/webapp --analyze
# Activates webapp project and runs analysis
```

### Configuration Refresh
```
/sc:load --type config --refresh
# Reloads configuration memories
```

### New Project Setup
```
/sc:load ./new-project --onboard
# Activates and onboards new project
```

### Session Recovery
```
/sc:load --resume --validate
# Resume from latest checkpoint with validation

/sc:load --checkpoint checkpoint-2025-01-31-16:00:00
# Restore from specific checkpoint
```

### Performance Monitoring
```
/sc:load --performance --uc
# Enable performance monitoring with compression
```

### Session Workflow
```
# Initialize session
/sc:load MyProject

# Work on project...

# Create checkpoint
/sc:save --checkpoint

# Next session
/sc:load MyProject --resume
```

## Integration with /sc:save
- Context loaded by /sc:load is enhanced during session
- Use /sc:save to persist session changes back to Serena
- Maintains session lifecycle: load → work → save
- Enables cross-session continuity through checkpoints

## Boundaries

**This command will:**
- Provide session lifecycle management with performance targets
- Integrate with Serena MCP for comprehensive session capabilities
- Maintain context continuity across sessions
- Support checkpoint restoration and session recovery

**This command will not:**
- Operate without Serena MCP integration
- Compromise performance targets
- Skip session state validation
- Function without proper error handling
