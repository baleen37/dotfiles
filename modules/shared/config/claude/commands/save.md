---
name: save
description: "Save current TodoWrite state and work context to restore later"
---

# /save - Save Work State

Save current TodoWrite state and work context for later restoration

## Usage

```bash
/save <name>    # Save with specific identifier
/save           # Auto-generate name from main todo
```

## Storage Location & Contents

**Storage Path**: `./session_{slug}_{yyyymmddHHMM}.md`

**Saved Data**:
- Complete TodoWrite state (including metadata)
- Problem analysis and technical details
- Execution commands and estimated timeframes
- Decision points and learning insights
- Blockers and risk assessments

## Core Features

- **Context Preservation**: Maintains current work state and decisions
- **Progress Tracking**: Tracks completed vs pending tasks
- **Technical Details**: Commands, timeframes, and reasoning process
- **Auto-naming**: Intelligent naming from current TodoWrite tasks
- **Safety Checks**: Warns before overwriting existing plans
- **Auto-cleanup**: Removes backup files older than 30 days

## Safety Features

- **Overwrite Protection**: Confirmation prompt when plan name exists
- **Backup Validation**: Pre-save plan file integrity checks
- **Automatic Cleanup**: Manages old backup files automatically

## Integration

- Works with `/restore` command for session recovery
- Stores in current working directory (`./`)
- Human-readable Markdown format with chronological naming
- Compatible with TodoWrite/TodoRead tool ecosystem
