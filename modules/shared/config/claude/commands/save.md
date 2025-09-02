# /save - Session Context Persistence

**Purpose**: Save session state, project context, and progress to persistent memory with intelligent checkpoint management

## Usage

```bash
/save [description]              # Save current session with description
/save --type all                 # Complete session preservation  
/save --type learnings           # Save only new discoveries
/save --type checkpoint          # Create recovery checkpoint
/save --consolidate              # Merge related memories
```

## Core Features

### **Session Persistence**
- **Project Context**: Current file states, TodoWrite progress, Serena memories
- **Development State**: Active branches, uncommitted changes, environment settings
- **Conversation Context**: Key decisions, patterns discovered, implementation progress
- **Cross-Session Continuity**: Enable seamless resume across Claude Code sessions

### **Automatic Checkpoint System**
- **Time-based**: Auto-checkpoint after 30+ minutes of active work
- **Milestone-based**: Checkpoint on significant progress (phase completion, major features)
- **Error Recovery**: Create restoration points before risky operations
- **Memory Optimization**: Consolidate related memories to prevent fragmentation

## Integration Points

### **Serena MCP Integration** (Required)
- `write_memory()`: Store session context and discoveries
- `list_memories()`: Validate existing project state  
- `read_memory()`: Cross-reference with stored context
- `delete_memory()`: Cleanup obsolete checkpoint data

### **TodoWrite State Management**
- Serialize current todo states (pending/in_progress/completed)
- Preserve todo content and activeForm descriptions
- Track task completion progress and milestones
- Enable resume with exact todo context restoration

### **Project Context Packaging**
- **Git State**: Current branch, uncommitted files, stash state
- **Environment**: Working directory, additional directories, model settings
- **Permissions**: Temporary permission grants, custom settings
- **MCP States**: Context7 history, Sequential thinking progress

## Command Behavior

### **Basic Session Save**
```bash
/save "user authentication phase complete"
```
- Analyzes current session discoveries and progress
- Saves to Serena memory with structured metadata
- Creates recovery checkpoint if session > 30 minutes
- Updates cross-session learning patterns

### **Comprehensive Preservation**
```bash
/save --type all --checkpoint
```
- Complete session state preservation
- Full TodoWrite serialization
- Git repository snapshot
- Environment configuration backup
- Recovery checkpoint creation

### **Discovery-Only Persistence**
```bash
/save --type learnings
```
- Extracts new patterns and insights only
- Updates project understanding without full session data
- Lightweight memory footprint
- Focus on accumulated knowledge

### **Memory Consolidation**
```bash
/save --consolidate
```
- Merge related checkpoint memories
- Remove obsolete session data
- Optimize memory structure
- Prevent memory fragmentation

## Advanced Features

### **Smart Context Analysis**
- Identifies significant progress markers automatically
- Distinguishes between session noise and valuable discoveries
- Prioritizes architectural decisions and implementation patterns
- Filters out temporary debugging context

### **Cross-Session Learning**
- Accumulates project insights across multiple sessions
- Identifies recurring patterns and anti-patterns
- Builds institutional knowledge about project specifics
- Enables context-aware recommendations in future sessions

### **Recovery & Validation**
- Validates save integrity before completion
- Creates recovery metadata for restoration
- Enables rollback to previous stable states
- Handles corrupted or incomplete save scenarios

## Examples

```bash
# Phase completion save
/save "Phase 1: Core authentication system implemented with JWT tokens"

# Weekly checkpoint pattern  
/save --type all "Week 3 progress: payment integration, user profiles, basic admin"

# Discovery session save
/save --type learnings "Found optimal Nix module pattern for cross-platform config"

# Pre-risky-operation checkpoint
/save --checkpoint "Before major refactoring of home-manager structure"

# Memory cleanup
/save --consolidate
```

## Safety & Recovery

### **Data Integrity**
- Validates all save operations before commit
- Creates backup of previous state before overwrite
- Enables atomic save operations (all-or-nothing)
- Maintains save operation audit trail

### **Error Scenarios**
- **Incomplete Save**: Automatically retry with reduced scope
- **Memory Corruption**: Fallback to previous checkpoint
- **Storage Limits**: Auto-cleanup oldest non-critical memories  
- **Network Issues**: Queue saves for retry on reconnection

The save command creates a comprehensive preservation system that enables true cross-session development continuity, transforming Claude Code from a session-based tool into a persistent development environment.
