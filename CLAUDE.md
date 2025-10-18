# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Enterprise-grade dotfiles management system providing reproducible development environments across macOS and NixOS using Nix flakes, Home Manager, and nix-darwin.

**Platforms**: macOS (Intel/ARM), NixOS (x86_64/ARM64)
**Architecture**: dustinlyons-inspired direct import patterns (simplified from complex abstractions)
**Tools**: 50+ development packages, 34+ macOS GUI apps via Homebrew

## ⚠️ Critical Rules

**NEVER:**

- Hardcode Nix store paths (they change with every rebuild)
- Skip pre-commit hooks with `--no-verify`
- Manually fix formatting - always use `make format`
- Use bats for testing - use Nix's built-in test framework

**ALWAYS:**

- Set `export USER=$(whoami)` before any build operations
- Use `make build-current` during development (not `make build`)
- Run `make format` before committing
- Follow TDD: write failing test → minimal code → refactor

## Essential Commands

### Daily Development

```bash
# Setup (once per session)
export USER=$(whoami)          # REQUIRED: Set before builds

# Development cycle
make format                    # Auto-format all files (nix run .#format)
make build-current            # Build current platform only (fastest)
make test-core                # Run essential tests
make smoke                    # Quick validation (~30 seconds)

# System Management (Option 3 - Clear separation)
make switch                   # Full system update (darwin-rebuild: system + Homebrew + user)
make build-switch             # Same as 'switch' (full system update)
make switch-user              # User config only (home-manager: git, vim, zsh - faster)
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
modules/
├── shared/        # Cross-platform configs (most dev tools go here)
├── darwin/        # macOS-specific (system settings, Homebrew casks)
└── nixos/         # NixOS-specific (systemd services, Linux packages)

hosts/             # Machine-specific configs (hostname, hardware, user)
lib/               # Pure Nix utilities (formatters, testing, automation)
tests/             # Multi-tier testing (unit, integration, e2e, performance)
```

### Module Philosophy

**Platform Separation**: `modules/{darwin,nixos}/` contain OS-specific code to prevent cross-contamination. Darwin handles macOS system settings and Homebrew; NixOS handles systemd and Linux packages.

**Shared Abstractions**: `modules/shared/` provides cross-platform functionality (DRY principle). Write once, use everywhere.

**Host Specialization**: `hosts/` define machine-specific overrides while inheriting from platform modules.

**Library Functions**: `lib/` contains platform-agnostic utilities testable in isolation.

### Design Principles

**dustinlyons Patterns**: Direct imports, explicit configurations, minimal abstractions. Result: 300+ lines removed while preserving all functionality.

**Nix-Based Tooling**:

- Formatting: `lib/formatters.nix` → `nix run .#format`
- Testing: Native `nix flake check` (no bats)
- Building: Flake apps for reproducibility

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

### USER Variable

All builds require `export USER=$(whoami)` due to dynamic user resolution. Builds fail without this.

### Nix Store Paths

**NEVER** hardcode paths like `/nix/store/abc123xyz-package/bin/command`:

- Change with every rebuild
- Differ across platforms
- Break after `nix-collect-garbage`

**Use command names instead** (PATH lookup) or install via Home Manager.

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
- **Advanced Testing**: 87% optimized suite with parallel execution
- **Claude Code Integration**: 20+ specialized commands
- **Performance Monitoring**: Real-time build metrics
