---
name: save
description: "Save current TodoWrite state and work context to restore later"
---

<command>
/save - Save Work State

<purpose>
Save current TodoWrite state and work context for later restoration
</purpose>

<usage>
```bash
/save <name>    # Save with specific identifier
/save           # Auto-generate name from main todo
```
</usage>

<storage-location-contents>

**Storage Path**: `./session_{slug}_{yyyymmddHHMM}.md`

**Saved Data**:
- Complete TodoWrite state (including metadata)
- Problem analysis and technical details
- Execution commands and estimated timeframes
- Decision points and learning insights
- Blockers and risk assessments

</storage-location-contents>

<core-features>
- **Context Preservation**: Maintains current work state and decisions
- **Progress Tracking**: Tracks completed vs pending tasks
- **Technical Details**: Commands, timeframes, and reasoning process
- **Auto-naming**: Intelligent naming from current TodoWrite tasks
- **Safety Checks**: Warns before overwriting existing plans
</core-features>

<safety-features>
- **Overwrite Protection**: Confirmation prompt when plan name exists
- **File Validation**: Pre-save plan file integrity checks
</safety-features>

<integration>
- Works with `/restore` command for session recovery
- Stores in current working directory (`./`)
- Human-readable Markdown format with chronological naming
- Compatible with TodoWrite/TodoRead tool ecosystem
</integration>
</command>
