# WezTerm to Ghostty Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate from WezTerm to Ghostty terminal emulator with minimal Nix-managed configuration

**Architecture:** Create new ghostty.nix module following claude-code.nix pattern, symlink config files to ~/.config/ghostty/, remove WezTerm from home-manager.nix

**Tech Stack:** Nix, Home Manager, Ghostty terminal emulator

---

## Task 1: Create Ghostty Configuration File

**Files:**
- Create: `users/shared/.config/ghostty/config`

**Step 1: Create directory structure**

```bash
mkdir -p users/shared/.config/ghostty
```

Expected: Directory created successfully

**Step 2: Write minimal Ghostty configuration**

Create `users/shared/.config/ghostty/config` with:

```
# Ghostty Terminal Configuration
# Managed via Nix Home Manager

# Font Configuration
font-family = JetBrains Mono
font-size = 14

# Theme
theme = dark

# Window Settings
window-padding-x = 10
window-padding-y = 10

# Shell Integration
shell-integration = true
shell-integration-features = cursor,sudo,title
```

**Step 3: Verify file format**

Run: `cat users/shared/.config/ghostty/config`
Expected: File contents display correctly

**Step 4: Commit configuration file**

```bash
git add users/shared/.config/ghostty/config
git commit -m "feat: add Ghostty configuration file"
```

---

## Task 2: Create Ghostty Nix Module

**Files:**
- Create: `users/shared/ghostty.nix`

**Step 1: Create ghostty.nix module**

Create `users/shared/ghostty.nix` with:

```nix
# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{ pkgs, ... }:

{
  # Install Ghostty package
  home.packages = with pkgs; [ ghostty ];

  # Symlink Ghostty configuration
  # Pattern: XDG-compliant location (destination: ~/.config/ghostty/)
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".config/ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
    force = true;
  };
}
```

**Step 2: Verify Nix syntax**

Run: `nix-instantiate --parse users/shared/ghostty.nix`
Expected: Nix expression parses without errors

**Step 3: Commit Ghostty module**

```bash
git add users/shared/ghostty.nix
git commit -m "feat: add Ghostty Nix module"
```

---

## Task 3: Update Home Manager Configuration

**Files:**
- Modify: `users/shared/home-manager.nix:38-46` (imports section)
- Modify: `users/shared/home-manager.nix:111` (wezterm package line)
- Modify: `users/shared/home-manager.nix:20` (comment line)

**Step 1: Add ghostty.nix to imports**

In `users/shared/home-manager.nix`, update the imports section:

```nix
  # Import all extracted tool configurations
  imports = [
    ./git.nix
    ./vim.nix
    ./zsh.nix
    ./tmux.nix
    ./claude-code.nix
    ./hammerspoon.nix
    ./karabiner.nix
    ./ghostty.nix
  ];
```

**Step 2: Remove wezterm package**

In `users/shared/home-manager.nix` line 111, remove the wezterm line:

```nix
      # Terminal apps
      # wezterm  # Removed: Migrated to Ghostty
```

**Step 3: Update package comment**

In `users/shared/home-manager.nix` line 20, update the comment:

```nix
#   - Terminal: ghostty, htop, zsh-powerlevel10k
```

**Step 4: Verify changes**

Run: `git diff users/shared/home-manager.nix`
Expected: Shows three changes (import added, wezterm removed, comment updated)

**Step 5: Commit Home Manager updates**

```bash
git add users/shared/home-manager.nix
git commit -m "feat: integrate Ghostty and remove WezTerm from Home Manager"
```

---

## Task 4: Format and Validate

**Files:**
- All modified Nix files

**Step 1: Format all files**

Run: `make format`
Expected: All files formatted successfully

**Step 2: Commit formatting changes (if any)**

```bash
git add -u
git commit -m "style: format Nix files"
```

(Skip if no changes from formatting)

**Step 3: Build current platform**

Run: `make build-current`
Expected: Build completes without errors

**Step 4: Check build output for Ghostty**

Run: `ls result/sw/bin/ | grep ghostty`
Expected: `ghostty` binary present in build output

---

## Task 5: Apply and Test

**Files:**
- System configuration

**Step 1: Apply configuration**

Run: `make switch`
Expected: System switches successfully with Ghostty installed

**Step 2: Verify Ghostty installation**

Run: `which ghostty`
Expected: `/Users/jito/.nix-profile/bin/ghostty` or similar path

**Step 3: Verify configuration symlink**

Run: `ls -la ~/.config/ghostty/`
Expected: Directory with symlinked config file pointing to /nix/store

**Step 4: Launch Ghostty and verify settings**

Run: `ghostty`
Expected:
- Ghostty launches successfully
- JetBrains Mono font is used
- Dark theme is applied
- Window has 10px padding

**Step 5: Verify WezTerm removed**

Run: `which wezterm`
Expected: Command not found (WezTerm no longer in PATH)

**Step 6: Final commit**

```bash
git add -A
git commit -m "chore: complete WezTerm to Ghostty migration

- Added Ghostty configuration with JetBrains Mono font
- Created ghostty.nix module following claude-code.nix pattern
- Removed WezTerm from Home Manager
- Tested on macOS (aarch64-darwin)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Verification Checklist

- [ ] Ghostty package installed via Nix
- [ ] Configuration file symlinked to ~/.config/ghostty/config
- [ ] JetBrains Mono font applied
- [ ] Dark theme active
- [ ] Window padding configured
- [ ] WezTerm completely removed from system
- [ ] All files formatted correctly
- [ ] Build completes without errors
- [ ] Changes committed to git

---

## Rollback Instructions

If issues occur, rollback with:

```bash
git revert HEAD~5..HEAD
make switch
```

This will restore WezTerm and remove Ghostty.

---

## Notes for Engineer

**About Ghostty:**
- Ghostty is a fast, native terminal emulator written in Zig
- Configuration uses simple `key = value` format (not Lua like WezTerm)
- Supports shell integration for better command tracking

**About the Pattern:**
- We follow the claude-code.nix pattern for config file management
- Files are symlinked from dotfiles to ~/.config/ghostty/
- Symlinks point to /nix/store (read-only, managed by Home Manager)
- This ensures reproducible, version-controlled configuration

**Cross-Platform:**
- This configuration works on both macOS and NixOS
- Same config file format across platforms
- Nix handles platform-specific package installation
