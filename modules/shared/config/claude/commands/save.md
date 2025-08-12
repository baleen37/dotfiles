---
name: save
description: "Save current todos and plans to file"
agents: []
---

# /save - Save Todos & Plans

**Purpose**: Capture current todos and work plans for later restoration

## Usage

```bash
/save <name>                # Save todos with specific name
/save                       # Auto-name from main task/context
```

## What Gets Saved

Create `plan_{name}_{timestamp}.md` containing:

- **Current TodoWrite state**: All pending/in-progress/completed todos
- **Work context**: What we're working on and why
- **Next steps**: Planned actions and priorities
- **Key insights**: Important discoveries or decisions
- **Blockers**: Any issues or dependencies

## File Format

```markdown
# Plan: {name}
**Saved**: 2024-08-12 15:30
**Context**: Improving Claude commands for session management

## Current Todos
### Pending
- [ ] Fix build errors in lib/platform-system.nix
- [ ] Add tests for new functionality
- [ ] Update documentation

### In Progress  
- [x] Redesign save/restore commands

### Completed
- [x] Analyze current command structure
- [x] Gather user requirements

## Work Context
Working on simplifying session management workflow. User wants to save/restore todo states rather than session summaries. Focus on practical utility over complex features.

## Next Steps
1. Implement todo restoration logic
2. Test with real workflow scenarios  
3. Add fuzzy search for saved plans

## Key Insights
- User prefers simple, direct approaches
- Todo state preservation is more valuable than session logging
- Korean communication + English docs works well

## Blockers
- Need to understand TodoWrite internal state format
- File naming convention should be consistent
```

## Implementation
1. Use TodoRead to get current todo state
2. Generate meaningful name from main todo or ask user
3. Store as simple JSON format for easy parsing

## File Structure
```json
{
  "name": "config-improvements",
  "saved": "2024-08-12T15:30:00Z",
  "context": "Improving Claude commands",
  "todos": [
    {"id": "1", "content": "Fix build errors", "status": "pending"},
    {"id": "2", "content": "Add tests", "status": "completed"}
  ]
}
```
