# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Enterprise-grade dotfiles management system providing reproducible development environments across macOS and NixOS using Nix flakes, Home Manager, and nix-darwin.

### Supported Platforms

- **macOS (Darwin)**: Apple Silicon only (aarch64-darwin)
  - Managed via nix-darwin + Home Manager
  - Includes 34+ GUI apps via Homebrew
  - Performance tuning + automatic app cleanup (6-8GB saved)

- **NixOS (Linux)**: Intel (x86_64-linux) + ARM (aarch64-linux)
  - Pure NixOS system configuration
  - Managed via NixOS modules + Home Manager

### Key Features

- **Architecture**: Follows [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) philosophy with dustinlyons-inspired factory patterns and minimal abstractions
- **Tools**: 50+ development packages across all platforms
- **Cross-platform validation**: Automated testing across 3 platform combinations
- **Dynamic user resolution**: Multi-user support without hardcoded usernames

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
make test                      # Run full test suite (~45 seconds)
make build                     # Build current platform

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
# Automatic test discovery - zero maintenance!
make test               # Core tests (~45 seconds)
make test-unit          # All unit tests (auto-discovered)
make test-integration   # All integration tests (auto-discovered)
make test-all           # Comprehensive suite (includes VM tests)

# Add new test: just create file, it's auto-discovered!
touch tests/unit/my-feature-test.nix
# No registration needed - automatically discovered via builtins.readDir

# VM Testing (NixOS)
make test-vm                # Full VM test suite (5-10 minutes)
                           # - Build + generate + boot + services
                           # - Same tests that run in CI
```

**Test organization:**
- All `*-test.nix` files in `tests/unit/` are automatically discovered
- All `*-test.nix` files in `tests/integration/` are automatically discovered
- All tests are pure Nix derivations (no shell scripts)
- Uses nixpkgs-approved pattern from `lib.filesystem`
- Tests run automatically on every commit via pre-commit hooks

### Linux Builder (macOS only)

Build Linux packages locally on macOS:

```bash
# Check if linux-builder is active
make test-linux-builder

# Build Linux packages
nix build --impure --expr '(with import <nixpkgs> { system = "aarch64-linux"; }; package-name)'
```

**Hardware support:**
- Apple Silicon Macs (M1/M2/M3/M4)
- Conservative resource allocation: 4 cores, 8GB RAM, 40GB disk
- Supports both x86_64-linux and aarch64-linux architectures

**Current status:**
- Configuration is present in `machines/macbook-pro.nix`
- **Not currently active** due to Determinate Nix usage (`nix.linux-builder.enable = false`)
- Ready to activate when switching from Determinate Nix to nix-darwin managed Nix
- Will automatically enable on systems using nix-darwin managed Nix daemon

**Note**: CI tests on native Linux (faster than linux-builder).

### Platform-Specific Commands

```bash
# Platform detection & info
make platform-info          # Show current platform details (aarch64-darwin, x86_64-linux, etc.)

# Platform-specific builds
make build-darwin           # Build macOS configuration (requires macOS host)
make build-linux            # Build NixOS configuration (cross-platform compatible)

# CI/Testing
make build-switch-dry       # Dry-run without activation (CI-safe)
```

**Note**: System automatically detects platform via `lib/platform-system.nix`. Commands adapt based on current host platform.

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
tests/             # TDD test suite (unit, integration)
```

### Module Philosophy

**User-Centric Structure**

`users/shared/` contains shared configuration used by all users (baleen, jito, etc.) in flat, tool-specific files following evantravers pattern.

**System Factory**

`lib/mksystem.nix` provides a unified interface for building systems across platforms using the factory pattern.

**Machine Definitions**

`machines/` define hardware-specific configurations without complex inheritance hierarchies.

**Test-Driven Development**

`tests/` provides comprehensive TDD framework with helpers for validating configurations.

### Design Principles

**evantravers Patterns**

Factory pattern for system building, user-centric flat files, minimal abstractions. Result: clean separation of concerns with maintainable structure.

**Nix-Based Tooling**

- **System Building**: `lib/mksystem.nix` factory → `nix build .#darwinConfigurations.macbook-pro.system`
- **Formatting**: `lib/formatters.nix` → `nix run .#format`
- **Testing**: Native `nix flake check` with TDD framework
- **Development**: `nix flake show` for structure validation

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

### Configuration File Management

**Approach**: Use `home.file` to symlink configuration files to `/nix/store` (managed by Home Manager)

```nix
# ✅ Recommended: Use home.file with recursive symlinks
home.file.".claude" = {
  source = ./.config/claude;
  recursive = true;
  force = true;
};
```

**How it works**

- `~/.claude/` becomes a directory (not a symlink itself)
- Individual files inside symlink to `/nix/store`: `~/.claude/settings.json` → `/nix/store/.../settings.json`
- Runtime files (debug/, projects/, todos/) are created by Claude Code and git-ignored
- Managed files are read-only but can be updated by editing dotfiles and rebuilding

**Modules using this pattern**

- `users/shared/claude-code.nix` - Claude Code configuration
- `users/shared/hammerspoon.nix` - Hammerspoon configuration
- `users/shared/karabiner.nix` - Karabiner-Elements configuration

**Alternative**: `home.activation` for writable symlinks to actual dotfiles (not /nix/store). More complex but allows in-place editing.

### Build & Switch Commands

**Command Hierarchy**

- **Full System**: `make switch` or `make build-switch`
  - macOS: darwin-rebuild (system + Homebrew + user config)
  - NixOS: nixos-rebuild (system + user config)

- **User Only**: `make switch-user`
  - home-manager activation only (git, vim, zsh, etc.)
  - Faster for quick configuration changes
  - Skips system settings and Homebrew

**When to use each**

- **Development**: `make build` - builds current platform without activation
- **Production**: `make switch` - full system update with activation
- **Quick updates**: `make switch-user` - user config only (no sudo required)


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
4. Run `make test` to validate changes
5. Run `make build` to test current platform
6. Refactor while keeping tests green
7. Commit (pre-commit hooks automatically run `make lint` and `make test`)

### VM Testing Workflow

```bash
# Quick iteration during VM config changes
1. Edit VM configuration (machines/nixos/vm-shared.nix)
2. make test-vm-quick        # 30s validation
3. Fix issues if any
4. Commit changes
5. Push → CI runs full VM suite automatically
```

## CI/CD

### Multi-Platform Testing

**Architecture**: Single unified job running on 3 platforms in parallel.

**Platforms**:
- Darwin (macOS-15): Apple Silicon
- Linux x64 (ubuntu-latest): Intel
- Linux ARM (ubuntu-latest): ARM64 with QEMU

**Entry Points** (identical across all platforms):
```bash
make lint   # Format + validation
make build  # Platform-specific build (auto-detected)
make test   # Full test suite
```

**Workflow**:
```
ci (parallel across 3 platforms)
├─ Darwin: lint → build → test
├─ Linux x64: lint → build → test
└─ Linux ARM: lint → build → test
```

**Total duration**: ~15-20 minutes (parallel execution)

**Key Features**:
- ✅ No platform-specific conditionals in CI
- ✅ Local and CI use identical commands
- ✅ Makefile handles platform detection
- ✅ Easy to add new platforms (Makefile only)

**Adding a new platform**:
1. Add to `Makefile` BUILD_TARGET selection
2. Add to `.github/workflows/ci.yml` matrix
3. That's it!

## Key Features

### Cross-Platform Support

- **Dynamic User Resolution**: No hardcoded usernames - supports multiple users (baleen, jito, etc.)
- **Platform Detection**: Automatic detection via `lib/platform-system.nix`
- **Cross-Platform Validation**: Automated testing across 3 platform combinations

### Development Experience

- **Auto-Formatting**: Parallel formatting via `make format` (Nix, YAML, JSON, Markdown, shell)
- **TDD Framework**: Comprehensive test suite with 87% optimization
- **Claude Code Integration**: 20+ specialized commands and skills
- **Performance Monitoring**: Real-time build metrics

### macOS-Specific Features

- **Homebrew Integration**: Declarative GUI app management (34+ apps)
- **Performance Optimization**: Level 1+2 tuning (30-50% UI speed boost)
- **Automatic App Cleanup**: Removes unused default apps (6-8GB saved)

## macOS Optimization

### Performance Tuning

**Configuration**: `users/shared/darwin.nix`

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

### App Cleanup

**Configuration**: `users/shared/darwin.nix`

**Automatically removed apps** (~6-8GB saved):

- GarageBand (2-3GB) - Music production
- iMovie (3-4GB) - Video editing
- TV (200MB) - Apple TV+
- Podcasts (100MB)
- News (50MB)
- Stocks (30MB)
- Freeform (50MB) - Whiteboard

**Execution:** Runs automatically during `darwin-rebuild switch` via activation script

**Safety:** Only removes explicitly listed apps; system essentials protected
