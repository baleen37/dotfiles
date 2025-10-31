# WezTerm to Ghostty Migration Design

**Date**: 2025-10-31
**Status**: Approved
**Platforms**: macOS (aarch64-darwin), NixOS (x86_64-linux, aarch64-linux)

## Overview

Complete migration from WezTerm to Ghostty terminal emulator with minimal configuration management through Nix modules.

## Requirements

- **Platform Support**: Cross-platform (macOS + NixOS)
- **WezTerm Removal**: Complete removal of WezTerm package
- **Configuration Management**: Minimal settings (font, theme, keybindings)
- **Configuration Approach**: Nix module following claude-code.nix pattern

## Architecture

### File Structure

```
users/shared/
├── home-manager.nix          # Import ghostty.nix, remove wezterm
├── ghostty.nix (NEW)         # Ghostty module with package + config symlink
└── .config/
    └── ghostty/
        └── config (NEW)      # Ghostty configuration file
```

### Module Design

**ghostty.nix**:
- Installs ghostty package via `home.packages`
- Symlinks `.config/ghostty/` to Nix store using `home.file`
- Follows existing pattern from `claude-code.nix`

**Configuration File**:
- Simple `key = value` format
- Minimal settings: font, theme, basic keybindings
- Cross-platform compatible (same config for macOS and NixOS)

## Implementation Steps

### 1. Create Ghostty Module

**File**: `users/shared/ghostty.nix`

```nix
{
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [ ghostty ];

  home.file.".config/ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
    force = true;
  };
}
```

### 2. Create Configuration File

**File**: `users/shared/.config/ghostty/config`

Minimal configuration including:
- Font: JetBrains Mono (already in dotfiles)
- Theme: Dark theme or custom colors
- Keybindings: Default + custom if needed
- Window settings: Padding, size, etc.

Format:
```
font-family = JetBrains Mono
font-size = 14
theme = dark
window-padding-x = 10
window-padding-y = 10
```

### 3. Update Home Manager

**File**: `users/shared/home-manager.nix`

Changes:
- Remove `wezterm` from `home.packages`
- Add `./ghostty.nix` to `imports`
- Update comments (line 20, 111: wezterm → ghostty)

### 4. Validation

**Build & Test**:
```bash
make format              # Format all files
make build-current       # Build current platform
make switch              # Apply changes
```

**Verification**:
- Ghostty launches successfully
- Font/theme applied correctly
- Configuration loads from ~/.config/ghostty/config
- Works on both macOS and NixOS

## Rollback Plan

- All changes tracked in git
- Can revert with `git revert` if issues occur
- WezTerm can be quickly restored by uncommenting package line

## Success Criteria

- [x] Ghostty installs and runs on macOS
- [x] Ghostty installs and runs on NixOS
- [x] Font (JetBrains Mono) applies correctly
- [x] Theme/colors display as configured
- [x] Configuration synced via Nix (in /nix/store)
- [x] No build errors on either platform
- [x] WezTerm completely removed

## Notes

- Ghostty config format is simpler than WezTerm (no Lua)
- Settings file is plaintext, easy to modify
- Future enhancements can be added incrementally
- Configuration is version-controlled and reproducible
