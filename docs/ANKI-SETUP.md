# Anki Setup Guide

This document describes how Anki is configured in the dotfiles.

## Installation

Anki is automatically installed via Homebrew cask in `modules/darwin/casks.nix`:

```nix
# Study Tools
"anki"
```

## Configuration Files

Currently, Anki configuration is managed manually. For future automation, consider:

### Basic Configuration Structure

Anki stores its configuration in:

- `~/Library/Application Support/Anki2/` - Main data directory
- `~/Library/Application Support/Anki2/User 1/` - User profile
- `~/Library/Application Support/Anki2/addons21/` - Add-ons

### Recommended Add-ons

Popular Anki add-ons that can be manually installed:

1. **Review Heatmap** (1771074083) - Visual review calendar
2. **AnkiConnect** (2055492159) - API for external applications
3. **Load Balancer** (1046608507) - Distribute cards evenly
4. **Progress Bar** (609537157) - Show progress during reviews
5. **Image Occlusion Enhanced** (1374772155) - Create image-based cards
6. **Speed Focus Mode** (1531997860) - Time-based reviewing
7. **Advanced Browser** (1715991943) - Enhanced card browser
8. **Frozen Fields** (1933645497) - Preserve field content
9. **Popup Dictionary** (1344485230) - Quick definitions
10. **Night Mode** (1136455830) - Dark theme for late studying

### Recommended Settings

Basic study settings for optimal learning:

- **New cards per day**: 20-30
- **Maximum reviews per day**: 200-300
- **Learning steps**: 1m 10m
- **Graduating interval**: 1 day
- **Easy interval**: 4 days
- **Maximum answer time**: 60 seconds

### Sync Configuration

To enable AnkiWeb sync:

1. Create account at https://ankiweb.net
2. In Anki: Tools → Preferences → Sync
3. Sign in with AnkiWeb credentials
4. Enable auto-sync for seamless syncing

## Future Automation

To automate Anki configuration in dotfiles:

1. **Configuration Files**: Add JSON/preference files to `modules/darwin/config/anki/`
2. **File Management**: Reference them in `modules/darwin/files.nix`
3. **Add-on Management**: Script add-on installation via AnkiConnect API
4. **Profile Templates**: Create default deck templates and study presets

## Usage

After installation via dotfiles:

1. Launch Anki from Applications or Spotlight
2. Complete initial setup wizard
3. Import any existing decks or create new ones
4. Install recommended add-ons manually
5. Configure sync if desired

## Troubleshooting

- **Permissions**: Anki may require accessibility permissions for some add-ons
- **Storage**: Anki data can grow large; monitor `~/Library/Application Support/Anki2/`
- **Sync Issues**: Check network connectivity and AnkiWeb status
- **Add-on Conflicts**: Disable add-ons one by one to identify conflicts
