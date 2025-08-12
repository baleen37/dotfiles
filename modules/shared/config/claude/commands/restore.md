---
name: restore
description: "Restore saved todos and plans from file"
agents: []
---

# /restore - Restore Todos & Plans

**Purpose**: Load previously saved todo states and work plans

## Usage

```bash
/restore                     # List available saved plans
/restore <name>              # Restore specific plan by name/search
```

## Execution Flow

1. **List mode**: Show available `plan_*.md` files with previews
2. **Restore mode**: Load selected plan and restore TodoWrite state
3. **Confirmation**: Show what will be restored before applying

## List Display

```
📋 Found 3 saved plans:

📅 plan_config-improvements_2024-08-12-1530.md
   Context: Improving Claude commands for session management
   Todos: 2 pending, 1 in-progress, 2 completed

📅 plan_debug-build_2024-08-11-0915.md
   Context: Fix build errors in lib/platform-system.nix  
   Todos: 3 pending, 0 in-progress, 1 completed

📅 plan_nix-update_2024-08-10-1400.md
   Context: Update flake inputs and test cross-platform
   Todos: 1 pending, 1 in-progress, 4 completed
```

## Restore Process

```
🔄 Restoring plan: config-improvements

Current todos will be replaced with:
✅ Completed (2):
  - Analyze current command structure  
  - Gather user requirements

🔄 In Progress (1):
  - Redesign save/restore commands

📋 Pending (2):
  - Fix build errors in lib/platform-system.nix
  - Add tests for new functionality

Continue? [Y/n]
```

## Implementation
1. Find and parse `plan_*.json` files
2. Show previews with todo counts and context  
3. For restore: use TodoWrite to recreate exact state
4. Simple name matching (fuzzy search on partial names)
