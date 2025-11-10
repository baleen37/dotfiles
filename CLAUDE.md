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

- **Architecture**: Follows [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) philosophy:
  - **Simplicity over complexity**: One purpose per target, minimal abstractions
  - **Explicit over implicit**: Clear configuration names, no magic auto-detection
  - **Working code over comprehensive**: Focus on what actually works
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

- Use Makefile commands (`make build`, `make switch`) - USER must be set manually
- Use `make build` during development (builds current platform automatically)
- Run `make format` before committing
- Follow TDD: write failing test → minimal code → refactor

## Essential Commands

### Daily Development

```bash
# Simple development cycle
export USER=$(whoami)          # Required first step
make format                    # Format files
make build                     # Build configuration
make switch                    # Apply configuration
make test                      # Test configuration
make cache                     # Push to cache

# USER required for all nix operations
# hostname automatically detected
```

### Testing

```bash
# Core test commands
make test               # Run full test suite (includes build test)

# VM Testing (NixOS)
make test-vm                # VM test suite (build + boot + E2E validation)
                           # - Same tests that run in CI
                           # - Multi-platform: ARM64 Mac → aarch64-linux, Intel Mac → x86_64-linux

# Add new test: just create file, it's auto-discovered!
touch tests/unit/my-feature-test.nix
# No registration needed - automatically discovered via builtins.readDir
```

**Current Test Structure:**
- `tests/unit/` - Unit tests for individual components
- `tests/integration/` - Integration tests for module interactions
- `tests/e2e/` - End-to-end tests including VM testing
- `tests/lib/` - Test helpers and utilities
- `tests/performance/` - Performance benchmarking tests

**VM Testing Platform Support:**

- **Native Linux**: Full VM testing with no emulation required
- **macOS (ARM64)**: Cross-compiles to `aarch64-linux` VM
- **macOS (Intel)**: Cross-compiles to `x86_64-linux` VM

**VM Testing Requirements:**

VM testing requires Linux execution environment. On macOS without `linux-builder`, the test will:

1. Attempt cross-compilation (may fail due to QEMU requirements)
2. Provide clear guidance for enabling full VM testing:
   - Enable `linux-builder` in `machines/macbook-pro.nix` (requires `nix.enable = true`)
   - Run tests on native Linux system
   - Use GitHub Actions CI for automated VM testing

**Note**: VM test infrastructure validates cross-platform compatibility even when QEMU emulation is unavailable.

**Test organization:**
- All `*-test.nix` files in `tests/unit/` are automatically discovered
- All `*-test.nix` files in `tests/integration/` are automatically discovered
- All tests are pure Nix derivations (no shell scripts)
- Uses nixpkgs-approved pattern from `lib.filesystem`
- Tests run automatically on every commit via pre-commit hooks

### Linux Builder (macOS only)

Build Linux packages locally on macOS:

```bash
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
├── claude-code.nix   # Claude Code configuration
├── hammerspoon.nix   # Hammerspoon automation
├── karabiner.nix     # Karabiner key remapping
├── ghostty.nix       # Ghostty terminal configuration
└── .config/claude/   # Claude Code settings and skills

machines/          # Machine-specific configs (hostname, hardware)
├── macbook-pro.nix          # macOS configuration
└── nixos/                  # NixOS configurations
    ├── vm-aarch64-utm.nix   # ARM64 VM for UTM
    ├── vm-shared.nix        # Shared VM settings
    └── hardware/            # Hardware-specific configs

lib/               # Pure Nix utilities (mksystem.nix factory, performance, testing)
├── mksystem.nix             # System factory function
├── user-info.nix            # User information utilities
├── performance*.nix         # Performance monitoring and reporting
└── nix-app-linker.sh        # Nix app linking script

tests/             # TDD test suite (unit, integration, e2e, performance)
├── unit/                   # Unit tests
├── integration/            # Integration tests
├── e2e/                    # End-to-end tests (including VM testing)
├── lib/                    # Test helpers and utilities
├── performance/            # Performance benchmarks
└── default.nix             # Test entry point
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
- **Formatting**: `make format` (uses `nixfmt-rfc-style`) → direct formatting available
- **Testing**: Native `nix flake check` with comprehensive TDD framework
- **Development**: `nix flake show` for structure validation
- **Performance**: Built-in performance monitoring and benchmarking via `lib/performance*.nix`

## Code Quality

### Auto-Formatting

```bash
make format              # Format all files (uses nixfmt-rfc-style)
make check               # Run flake check (validation)
make lint                # Alias for format (for CI compatibility)
```

**Supported formats**: nixfmt-rfc-style (Nix) - specified in flake.nix formatter

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

**Manual Export Required for All Operations**:
- Must set USER environment variable before any build operation
- Example: `export USER=$(whoami) && make build`
- The `--impure` flag is required for nix commands to read environment variables

**Multi-User Support**:
- Configuration is stored in `users/shared/` directory
- Actual username is dynamically resolved from `USER` environment variable in flake.nix
- Supports multiple users without code duplication: baleen, jito, etc.

**Important**: The `USER` variable is mandatory for all build operations. The Makefile does NOT automatically detect USER - you must export it manually.

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

- **Full System**: `make switch`
  - macOS: darwin-rebuild (system + Homebrew + user config)
  - NixOS: nixos-rebuild (system + user config)

**When to use each**

- **Development**: `make build` - builds current platform without activation
- **Production**: `make switch` - full system update with activation

**Build Target Auto-Detection**

The Makefile automatically selects the correct build target based on the current system:

```bash
# Auto-detected targets (no manual selection needed):
aarch64-darwin  → darwinConfigurations.macbook-pro.system
x86_64-linux    → checks.x86_64-linux.smoke
aarch64-linux   → checks.aarch64-linux.smoke
```

This ensures you're always building the appropriate configuration for your platform.


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
7. Commit (pre-commit hooks automatically run quality checks)

### Git Workflow

- **Branch**: Currently on `feature/makefile-refactor-2025-01-10`
- **Main Branch**: `main` (target for PRs)
- **Status**: Clean working directory
- **Recent commits**: Makefile refactoring and documentation updates

### CI/CD Pipeline

The project uses GitHub Actions for continuous integration with:
- **Multi-platform testing**: macOS (Darwin), Linux x64, Linux ARM
- **Consistent commands**: Same `make format/check/build/test` commands across all platforms
- **Automatic caching**: Pushes to cachix.io on main branch
- **120-minute timeout**: Sufficient for full build and test suite

### VM Testing Workflow

```bash
# Development iteration during VM config changes
1. Edit VM configuration (machines/nixos/vm-shared.nix)
2. make test-vm             # VM test suite
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
make format  # Format files
make check   # Run flake check
make build   # Platform-specific build (auto-detected)
make test    # Full test suite
make test-vm # VM test suite
```

**Workflow**:
```
ci (parallel across 3 platforms)
├─ Darwin: format → check → build → test → test-vm
├─ Linux x64: format → check → build → test → test-vm
└─ Linux ARM: format → check → build → test → test-vm
```

**Total duration**: ~90 minutes (parallel execution, includes VM testing)

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

- **Auto-Formatting**: Nix formatting via `make format`
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

## VM Management

The project includes comprehensive VM testing and management capabilities:

```bash
# VM Bootstrap & Management
make vm/bootstrap0           # Bootstrap new NixOS VM (initial install)
make vm/bootstrap            # Complete VM setup with dotfiles
make vm/copy                 # Copy configurations to VM
make vm/switch               # Apply configuration changes on VM

# VM Testing (uses QEMU + nixos-generators)
make test-vm                 # Full VM test suite (build + boot + E2E validation)

# VM Configuration Requirements:
# NIXADDR - VM IP address
# NIXPORT - SSH port (default: 22)
# NIXUSER - SSH user (default: root)
```

**VM Testing Architecture:**
- **Cross-platform**: QEMU virtualization on macOS, Linux, Windows (WSL2)
- **Automated**: Build, generate, boot, and validate in single command
- **Service Validation**: SSH, Docker, and user configuration testing
- **Resource Optimized**: 2 cores, 2GB RAM, 10GB disk for testing

**Usage Example:**
```bash
# Set VM connection details
export NIXADDR=192.168.64.2
export NIXPORT=2222
export NIXUSER=root

# Bootstrap and test
make vm/bootstrap0   # Initial NixOS install
make vm/bootstrap    # Complete setup with dotfiles
make vm/switch       # Apply configuration changes
make test-vm         # Run validation tests
```
