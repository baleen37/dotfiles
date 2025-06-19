# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Nix flake-based dotfiles repository for managing macOS and NixOS development environments declaratively. It supports x86_64 and aarch64 architectures on both platforms.

## Essential Commands

### Quick Start (Daily Workflow)
```bash
# Required setup
export USER=<username>

# Core commands (in order of importance)
make lint           # Run pre-commit hooks - MUST pass before committing
make build          # Build all configurations
make switch HOST=<host>  # Apply configuration to current system

# Emergency fix
nix run --impure .#build-switch  # Build and switch immediately (requires sudo)
```

### Testing Commands
```bash
# Run tests before submitting changes
make test           # All tests
make test-unit      # Unit tests only (Darwin only)
make test-integration  # Integration tests (Darwin only)
make test-e2e       # End-to-end tests (Darwin only)

# Quick validation
make smoke          # Fast flake check without building
```

### Single Test Execution
```bash
# Run specific test file
nix build .#checks.aarch64-darwin.<test-name> --impure

# Example: Run claude config test
nix build .#checks.aarch64-darwin.claude-config-overwrite-unit --impure
```

## Architecture

### Module Hierarchy
1. **Platform modules** (`modules/darwin/`, `modules/nixos/`) - OS-specific configurations
2. **Shared modules** (`modules/shared/`) - Cross-platform configurations  
3. **Host configs** (`hosts/`) - Machine-specific settings

### Key Patterns
- **User Resolution**: System reads `$USER` environment variable via `lib/get-user.nix`
- **Flake Outputs**: Platform-specific configurations and apps generated with `genAttrs`
- **Module Imports**: Follow strict hierarchy (platform → shared → host)
- **Overlay System**: Custom packages in `overlays/` auto-applied to nixpkgs

### Adding Packages
- All platforms: `modules/shared/packages.nix`
- macOS only: `modules/darwin/packages.nix`
- NixOS only: `modules/nixos/packages.nix`
- Homebrew casks: `modules/darwin/casks.nix`

## Development Workflows

### Creating New Features
```bash
# 1. Create feature branch
git checkout -b feature/my-change

# 2. Make changes and test
make lint && make build

# 3. Commit with conventional format
git commit -m "feat: add new functionality"

# 4. Push and create PR
git push -u origin feature/my-change
gh pr create --assignee @me
gh pr merge --auto --squash  # Enable auto-merge
```

### Global Command System (bl)
```bash
# Install once
./scripts/install-setup-dev

# Use globally
bl setup-dev my-project   # Create new Nix project
bl list                   # List available commands
```

## Auto-Update System

The repository includes an auto-update system (`scripts/auto-update-dotfiles`) that:
- Checks for main branch updates every hour (TTL-based)
- Runs `nix run --impure .#build-switch` when updates detected
- Skips if local changes exist
- Creates backups before updates
- Can rollback on failure

Started automatically from shell via `modules/shared/home-manager.nix`.

## Claude Configuration Preservation

User modifications to Claude settings are automatically preserved during system updates:
- SHA256 hash-based change detection
- High-priority files (`settings.json`, `CLAUDE.md`) always preserved
- New versions saved as `.new` files
- Interactive merge tool: `./scripts/merge-claude-config`

## Critical Notes

1. **Always use `--impure` flag** when running nix commands needing environment variables
2. **Platform Testing**: Test changes on all 4 platforms (x86_64/aarch64 × darwin/linux)
3. **Module Dependencies**: Check both direct imports and transitive dependencies
4. **sudo Requirements**: `build-switch` requires root privileges from start
5. **Pre-commit Required**: `make lint` must pass before any commit

## Working with Claude Code

See `modules/shared/config/claude/CLAUDE.md` for detailed development rules including:
- Test-Driven Development requirements
- Version control practices
- Debugging methodology
- Code style guidelines

The global commands in `modules/shared/config/claude/commands/` are language/framework agnostic and work across all projects.
