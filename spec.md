# Dotfiles Auto-Update System Specification

## Overview
Automatic update system for Nix-based dotfiles that checks for new commits on the main branch and prompts users to update their local configuration.

## Core Requirements

### Update Detection
- **Check Frequency**: Every hour via cron job
- **Check Trigger**: Also checks when starting a new shell session
- **Target Branch**: main branch on origin remote
- **Method**: Use GitHub API to avoid touching local git state

### User Interaction
- **Notification**: Terminal message when starting shell
- **Approval**: User must explicitly approve updates (y/N prompt)
- **Frequency Capping**: 1-3 hours between notifications for same update
- **Information Displayed**:
  - Number of new commits available
  - Latest commit message
  - Simple prompt: "Updates available. Apply now? [y/N]"

### Update Process
- **Execution**: Run `nix run .#build-switch` directly in current terminal
- **Prerequisites**: Only allow updates with clean working tree
- **Conflict Prevention**: Refuse to update if local changes exist
- **Security**: No additional confirmations (trust origin)
- **Error Handling**: Display simple error message and continue

### System Behavior
- **State Management**: Stateless operation (no history tracking)
- **Multi-Machine**: Same behavior across all machines
- **Disable Option**: Always enabled (no disable feature)
- **Local Changes**: Skip updates if working tree is dirty

## Implementation Architecture

### Components

1. **Main Script**: `scripts/auto-update-dotfiles`
   - Check for updates using GitHub API
   - Verify clean working tree
   - Handle user prompts
   - Execute update command
   - Manage frequency capping

2. **Nix Module**: `modules/shared/auto-update.nix`
   - Install auto-update script
   - Configure shell integration (.zshrc)
   - Set up hourly cron job
   - Define systemd timers (Linux) / launchd (macOS)

3. **State Management**: `lib/auto-update-state.nix`
   - Helper functions for state file management
   - Frequency capping logic

4. **BL Commands Integration**:
   - `bl auto-update check` - Manual update check
   - `bl auto-update status` - Show last check time
   - `bl auto-update apply` - Force immediate update

### Technical Details

#### Update Check Logic
```bash
1. Read state file for last notification time
2. Check if frequency cap expired (1-3 hours)
3. Fetch latest commit from GitHub API
4. Compare with current HEAD
5. If updates available and cap expired:
   - Show update prompt
   - Update last notification time
```

#### Shell Integration
```bash
# Added to .zshrc via Nix
if [ -x "$HOME/.local/bin/auto-update-dotfiles" ]; then
    $HOME/.local/bin/auto-update-dotfiles --check-on-start
fi
```

#### Cron Configuration
```
0 * * * * /Users/username/.local/bin/auto-update-dotfiles --scheduled
```

#### State File Location
- `~/.cache/dotfiles-auto-update/last-check`
- Contains: timestamp, last commit hash, notification time

#### Error Scenarios
- Network failure: Silent skip
- GitHub API error: Simple message, continue
- Dirty working tree: Skip with message
- Build failure: Show error, no retry

## User Experience Flow

1. **Automatic Check**:
   ```
   $ zsh
   Dotfiles update available (3 new commits)
   Latest: "feat: add new shell aliases"
   Apply update now? [y/N]:
   ```

2. **Manual Check**:
   ```
   $ bl auto-update check
   Checking for updates...
   Your dotfiles are up to date.
   ```

3. **Approval Flow**:
   ```
   Apply update now? [y/N]: y
   Building configuration...
   Applying system changes...
   Update complete!
   ```

## Security Considerations
- Only fetch from configured origin remote
- Require clean working tree to prevent conflicts
- Use GitHub API with read-only access
- No automatic execution without user consent
- Trust origin repository (no additional verification)

## Platform Support
- macOS (x86_64, aarch64): Full support with launchd
- Linux (x86_64, aarch64): Full support with systemd
- All platforms use same core script and logic

## Future Enhancements (Out of Scope)
- Update rollback functionality
- Selective file updates
- Multiple remote support
- Update scheduling preferences
- Detailed changelog viewing
- Automatic conflict resolution
