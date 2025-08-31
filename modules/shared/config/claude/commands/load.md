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
   Status: pending(2), in-progress(1), completed(0)
   Context: Fixing lib/platform-system.nix build errors

2. config-improvements (202408110915)
   Status: pending(1), in-progress(0), completed(3)
   Context: Claude command session management improvements

3. nix-update (202408101400)
   Status: pending(0), in-progress(1), completed(4)
   Context: flake inputs update and cross-platform testing
```

## Load Process

Pre-load confirmation message:

```
🔄 Loading session: fix-build-errors

Current todo list will be replaced with:

🔄 In Progress (1):
  - Fix platform-system.nix syntax errors

📋 Pending (2):
  - Run tests and validation
  - Update documentation

Continue? [Y/n]
```

## Core Features

- **File Discovery**: Searches `./session_*.md` pattern in current directory
- **Markdown Parsing**: Extracts state from ## Current Todos section
- **Fuzzy Matching**: Partial slug matching (e.g., "build" → "fix-build-errors")
- **State Loading**: Accurate state regeneration via TodoWrite
- **Safety Confirmation**: Shows current state before load and requests confirmation
- **Chronological Sorting**: Automatic time-based ordering with yyyymmddHHMM format

## Safety Features

- **Session Validation**: Automatic detection of corrupted session files
- **Backup State Verification**: Pre-validation of restorable state
- **Current Work Protection**: Warns against loss of in-progress work
- **Error Recovery**: Rollback to previous state on load failure

## Integration

- Works with `/save` command for session management
- Uses current working directory (`./`) for easy access
- Same Markdown format as `/save` command with chronological naming
- Compatible with TodoWrite/TodoRead tool ecosystem
