# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Enterprise-grade dotfiles management system providing reproducible development environments across macOS and NixOS using Nix flakes, Home Manager, and nix-darwin.

**Platforms**: macOS (Intel/ARM), NixOS (x86_64/ARM64)
**Architecture**: dustinlyons-inspired direct import patterns (simplified from complex abstractions)
**Tools**: 50+ development packages, 34+ macOS GUI apps via Homebrew
**macOS Optimization**: Performance tuning + automatic cleanup of unused default apps (6-8GB saved)

## ⚠️ Critical Rules

**NEVER:**

- Hardcode Nix store paths (they change with every rebuild)
- Skip pre-commit hooks with `--no-verify`
- Manually fix formatting - always use `make format`
- Use bats for testing - use Nix's built-in test framework

**ALWAYS:**

- Use Makefile commands (`make build`, `make switch`) - USER is auto-detected
- Use `make build-current` during development (not `make build`)
- Run `make format` before committing
- Follow TDD: write failing test → minimal code → refactor

## Essential Commands

### Daily Development

```bash
# Development cycle (USER auto-detected by Makefile)
make format                    # Auto-format all files (nix run .#format)
make build-current            # Build current platform only (fastest)
make test-core                # Run essential tests
make smoke                    # Quick validation (~30 seconds)

# System Management (Option 3 - Clear separation)
make switch                   # Full system update (darwin-rebuild: system + Homebrew + user)
make build-switch             # Same as 'switch' (full system update)
make switch-user              # User config only (home-manager: git, vim, zsh - faster)

# Note: Makefile automatically detects USER=$(whoami)
# Only set manually when using nix commands directly:
# export USER=$(whoami) && nix build --impure .#darwinConfigurations.macbook-pro.system
```

### Testing

```bash
make test-nix                # Nix-based unit tests
make test-enhanced           # Integration tests
make test-monitor           # Performance monitoring
```

### Platform-Specific

```bash
make build-darwin           # macOS only
make build-linux            # NixOS only
make platform-info          # Show platform details
make build-switch-dry       # CI-safe dry-run
```

## Architecture

### Module Structure

```text
users/shared/      # Shared user configuration (supports multiple users: baleen, jito, etc.)
├── home-manager.nix    # Main user configuration
├── darwin.nix         # macOS-specific settings (includes performance tuning + app cleanup)
├── git.nix           # Git configuration
├── vim.nix           # Vim/Neovim setup
├── zsh.nix           # Zsh shell configuration
├── tmux.nix          # Terminal multiplexer
└── .config/claude/   # Claude Code configuration

machines/          # Machine-specific configs (hostname, hardware)
lib/               # Pure Nix utilities (mksystem.nix factory, formatters, testing)
tests/             # TDD test suite (unit, integration, smoke)
```

### Module Philosophy

**User-Centric Structure**: `users/shared/` contains shared configuration used by all users (baleen, jito, etc.) in flat, tool-specific files following evantravers pattern.

**System Factory**: `lib/mksystem.nix` provides a unified interface for building systems across platforms using the factory pattern.

**Machine Definitions**: `machines/` define hardware-specific configurations without complex inheritance hierarchies.

**Test-Driven Development**: `tests/` provides comprehensive TDD framework with helpers for validating configurations.

### Design Principles

**evantravers Patterns**: Factory pattern for system building, user-centric flat files, minimal abstractions. Result: clean separation of concerns with maintainable structure.

**Nix-Based Tooling**:

- System Building: `lib/mksystem.nix` factory → `nix build .#darwinConfigurations.macbook-pro.system`
- Formatting: `lib/formatters.nix` → `nix run .#format`
- Testing: Native `nix flake check` with TDD framework
- Development: `nix flake show` for structure validation

## Code Quality

### Auto-Formatting

```bash
make format              # Format all files (Nix, YAML, JSON, Markdown, shell)
make lint-format         # Pre-commit workflow
```

**Supported formats**: nixfmt (Nix), yamlfmt (YAML), jq (JSON), prettier (Markdown), shfmt (shell)

### Pre-commit Hooks

**Never bypass** with `--no-verify`. If pre-commit fails, run `make format` instead of manual fixes.

### Testing

**Multi-tier strategy**:

- Unit tests: Component-level validation
- Integration tests: Module interaction verification
- E2E tests: Complete workflow validation
- Performance tests: Build time and resource monitoring

**NO bats** - use Nix's built-in test framework (`pkgs.runCommand`, etc.)

## Important Notes

### USER Variable & Multi-User Support

**Automatic Detection (Recommended)**:
- Makefile automatically detects USER via `whoami`
- Works for any user: baleen, jito, or any other username
- Just run `make build` or `make switch` - no manual export needed

**Manual Export (Only for Direct Nix Commands)**:
- Required when running nix commands directly (bypassing Makefile)
- Example: `export USER=$(whoami) && nix build --impure .#darwinConfigurations.macbook-pro.system`
- The `--impure` flag is required to read environment variables

**Multi-User Support**:
- Configuration is stored in `users/shared/` directory
- Actual username is dynamically resolved from `USER` environment variable
- Supports multiple users without code duplication: baleen, jito, etc.

### Nix Store Paths

**NEVER** hardcode paths like `/nix/store/abc123xyz-package/bin/command`:

- Change with every rebuild
- Differ across platforms
- Break after `nix-collect-garbage`

**Use command names instead** (PATH lookup) or install via Home Manager.

### Configuration File Management with home.file

**Approach**: Use `home.file` to symlink configuration files to `/nix/store` (managed by Home Manager)

```nix
# ✅ Recommended: Use home.file with recursive symlinks
home.file.".claude" = {
  source = ./.config/claude;
  recursive = true;
  force = true;
};
```

**How it works:**
- `~/.claude/` becomes a directory (not a symlink itself)
- Individual files inside symlink to `/nix/store`: `~/.claude/settings.json` → `/nix/store/.../settings.json`
- Runtime files (debug/, projects/, todos/) are created by Claude Code and git-ignored
- Managed files are read-only but can be updated by editing dotfiles and rebuilding

**Pattern used by:**
- `users/shared/claude-code.nix`: Claude Code configuration
- `users/shared/hammerspoon.nix`: Hammerspoon configuration
- `users/shared/karabiner.nix`: Karabiner-Elements configuration

**Alternative (home.activation):** If you need writable symlinks to actual dotfiles (not /nix/store), use `home.activation` with dynamic path detection. This is more complex but allows in-place editing.

### Build & Switch Commands (Option 3)

**Clear Separation Philosophy:**

- `switch` / `build-switch`: Full system (darwin-rebuild) - includes Homebrew, system settings, user config
- `switch-user`: User-only (home-manager) - faster for git, vim, zsh changes

**Development**: `make build-current` (builds only current platform)
**Production**: `make switch` or `make build-switch` (full system update)
**Quick User Updates**: `make switch-user` (skips system/Homebrew)

### Platform Detection

System automatically detects platform via `lib/platform-system.nix`. Cross-platform validation runs on 4 platforms: Darwin ARM64/x64, Linux ARM64/x64.

## Code Documentation

**File headers**: Every file must explain its role
**Inline comments**: Sparingly, for complex logic only
**Avoid**: Implementation details, temporal context (new/old/legacy), refactoring history

```nix
# ❌ BAD: Refactored Zod validation wrapper
# ✅ GOOD: Validates user input against schema
```

## Development Workflow

1. Write failing tests first (TDD)
2. Implement minimal code to pass tests
3. Run `make format` for auto-formatting
4. Run `make smoke` for quick validation
5. Run `make build-current` to test current platform
6. Refactor while keeping tests green
7. Commit (pre-commit hooks run automatically)

## Key Features

- **Dynamic User Resolution**: No hardcoded usernames
- **Auto-Formatting**: Parallel formatting via `make format`
- **Homebrew Integration**: Declarative GUI app management
- **macOS Performance Optimization**: Level 1+2 tuning (animations, auto-correct, iCloud, Dock)
- **Automatic App Cleanup**: Removes unused default apps (GarageBand, iMovie, TV, Podcasts, News, Stocks, Freeform)
- **Advanced Testing**: 87% optimized suite with parallel execution
- **Claude Code Integration**: 20+ specialized commands
- **Performance Monitoring**: Real-time build metrics

## macOS Optimization

### Performance Tuning (users/baleen/darwin.nix)

**Level 1 - Safe Optimizations:**

- Disable window/popover animations (30-50% UI speed boost)
- Disable auto-capitalization, spelling correction, quote substitution
- Fast Dock with minimal delays (autohide-delay: 0.0s)
- Mission Control speed boost (expose-animation: 0.2s)

**Level 2 - Performance Priority:**

- Window resize speed: 0.1s (default: 0.2s)
- Disable smooth scrolling for performance
- Enable automatic app termination (memory management)
- Disable iCloud auto-save (battery/network savings)
- Optimized trackpad settings (tap-to-click, three-finger drag)

**Expected Impact:**

- UI responsiveness: 30-50% faster
- CPU usage: Reduced (auto-correction disabled)
- Battery life: Extended (iCloud sync minimized)
- Memory: Better management (automatic termination)

### App Cleanup (users/baleen/darwin.nix)

**Automatically removed apps (~6-8GB saved):**

- GarageBand (2-3GB) - Music production
- iMovie (3-4GB) - Video editing
- TV (200MB) - Apple TV+
- Podcasts (100MB)
- News (50MB)
- Stocks (30MB)
- Freeform (50MB) - Whiteboard

**Execution:** Runs automatically during `darwin-rebuild switch` via activation script

**Safety:** Only removes explicitly listed apps; system essentials protected
