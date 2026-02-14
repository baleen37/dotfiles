# D2 Coding Font Installation Design

**Date**: 2025-02-15
**Status**: Approved
**Author**: Claude Code

## Overview

Add D2 Coding font as Korean fallback for Ghostty terminal, maintaining JetBrains Mono for English/symbols.

## Context

- Current setup: JetBrains Mono (primary font) via Homebrew
- Existing Nix-managed fonts: `noto-fonts-cjk-sans`, `cascadia-code`
- Recent work: Added JetBrains Mono support (commit 6bf739c)
- Ghostty 1.2.0+ supports automatic fallback font size adjustment

## Architecture

### Components

1. **Package Management** (`users/shared/home-manager.nix`)
   - Add `d2coding` to Nix packages alongside existing fonts
   - Managed via Home Manager for reproducibility

2. **Ghostty Configuration** (`users/shared/.config/ghostty/config`)
   - Configure font-family fallback chain
   - JetBrains Mono → D2Coding

### Data Flow

```
home-manager.nix (d2coding package)
    ↓
Nix build/install
    ↓
Font available system-wide
    ↓
Ghostty config (fallback chain)
    ↓
Runtime: JetBrains Mono (English) + D2Coding (Korean)
```

## Implementation

### File Changes

**1. users/shared/home-manager.nix** (line 122-124)

```nix
# Fonts
noto-fonts-cjk-sans
cascadia-code
d2coding        # D2 Coding for Korean characters
```

**2. users/shared/.config/ghostty/config** (line 5-6)

```
# Font Configuration
font-family = JetBrains Mono
font-family = D2Coding
font-size = 14
```

### Behavior

- **English/Symbols**: Rendered with JetBrains Mono
- **Korean (한글)**: Rendered with D2Coding
- **Font Size**: Auto-adjusted by Ghostty 1.2.0+ for consistent line height
- **Powerline Symbols**: D2Coding v1.3+ includes Powerline support

## Testing & Verification

### Build Verification

```bash
make build  # Verify Nix configuration builds successfully
```

### Font Installation Check

```bash
fc-list | grep -i d2coding  # Confirm font installed system-wide
```

### Runtime Verification

1. Open Ghostty terminal
2. Type: `Hello 안녕하세요`
3. Verify:
   - "Hello" renders in JetBrains Mono
   - "안녕하세요" renders in D2Coding
   - Line height consistent between fonts

### Configuration Validation

```bash
cat ~/.config/ghostty/config | grep font-family
# Expected output:
# font-family = JetBrains Mono
# font-family = D2Coding
```

## Rationale

### Why Nix Package over Homebrew?

- **Consistency**: Matches existing Nix-managed fonts (cascadia-code, noto-fonts-cjk-sans)
- **Reproducibility**: Fully declarative, version-controlled configuration
- **Simplicity**: Single-line addition to existing packages list

### Why D2Coding over Alternatives?

- **Native Korean Support**: Designed by Naver for Korean developers
- **Monospace**: Proper alignment with JetBrains Mono
- **Powerline Symbols**: v1.3+ includes development symbols
- **Available in nixpkgs**: No custom packaging needed

## References

- [d2codingfont on MyNixOS](https://mynixos.com/nixpkgs/package/d2coding)
- [Ghostty Font Configuration](https://ghostty.org/docs/config/reference)
- [Ghostty 1.2.0 Fallback Font Sizing](https://ghostty.org/docs/install/release-notes/1-2-0)
