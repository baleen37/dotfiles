---
name: load
description: "Load previously saved TodoWrite state and work context"
agents: []
---

# /load - Load Work State

Load previously saved TodoWrite state and work context

## Usage

```bash
/load                        # List available saved sessions
/load <slug>                 # Load specific session (slug/partial search)
/load <number>               # Select from list by number
```

## List Mode

Scans current directory (`./`) for `session_*.md` files:

```
📋 Found 3 saved sessions:

1. fix-build-errors (202408121530)
   Status: pending(2), in-progress(1), completed(0) | Step 3/5
   Context: Fixing lib/platform-system.nix build errors

2. config-improvements (202408110915)
   Status: pending(1), in-progress(0), completed(3) | Step 4/4
   Context: Claude command session management improvements

3. nix-update (202408101400)
   Status: pending(0), in-progress(1), completed(4) | Step 5/6
   Context: flake inputs update and cross-platform testing
```

## Load Process

Pre-load confirmation message:

```
🔄 Loading session: fix-build-errors (Step 3/5)

🔄 In Progress (1):
  - Fix platform-system.nix syntax errors

📋 Pending (2):
  - Run tests and validation
  - Update documentation

💡 Key context: Root cause in import paths, testing phase next

Continue? [Y/n]
```

## Core Features

- **File Discovery**: Searches `./session_*.md` pattern in current directory
- **Context-Rich Display**: Shows planning progress, current phase, and key insights
- **Intelligent Parsing**: Extracts TodoWrite state, planning context, and next steps
- **Progress Tracking**: Displays plan completion percentage and current phase
- **Fuzzy Matching**: Partial slug matching (e.g., "build" → "fix-build-errors")  
- **Smart Context Filtering**: Shows relevant insights while hiding unnecessary details
- **State Loading**: Accurate state regeneration via TodoWrite with full context
- **Safety Confirmation**: Shows current state and context before load with confirmation
- **Chronological Sorting**: Automatic time-based ordering with yyyymmddHHMM format

## Context Intelligence

**Smart Information Filtering**:
- **Essential Context**: Plan progress, current phase, key insights, next steps
- **Filtered Out**: Verbose logs, intermediate debugging details, redundant information
- **Context Relevance**: Shows tools used, decisions made, and blockers encountered
- **Progressive Disclosure**: Summary first, details on demand

**Planning Context Integration**:
- **Phase Tracking**: Current step in overall plan with progress percentage
- **Decision History**: Key technical decisions and alternative approaches considered  
- **Insight Preservation**: Critical discoveries and problem-solving breakthroughs
- **Next Step Preparation**: Context needed to continue work seamlessly

## Safety Features

- **Session Validation**: Automatic detection of corrupted session files
- **Context Completeness**: Verification that essential planning context is preserved
- **Backup State Verification**: Pre-validation of restorable state
- **Current Work Protection**: Warns against loss of in-progress work
- **Error Recovery**: Rollback to previous state on load failure

## Integration

- Works with `/save` command for session management
- Uses current working directory (`./`) for easy access
- Same Markdown format as `/save` command with chronological naming
- Compatible with TodoWrite/TodoRead tool ecosystem
