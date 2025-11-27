# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Professional Nix flakes-based dotfiles providing reproducible cross-platform development environments for macOS (Intel/ARM) and NixOS (x86_64/ARM64). Uses the evantravers minimalist user-centric architecture pattern.

## Essential Commands

```bash
# Required before any nix operation
export USER=$(whoami)

# Core workflow
make switch            # Apply configuration (requires sudo)
make test              # Fast validation (2-5 sec on macOS, full on Linux)
make test-all          # Complete validation including integration tests
make build             # Build current system configuration

# Direct nix operations
nix run --impure .#build-switch   # Build + apply in one step
nix flake check --impure          # Run all tests
nix run .#format                  # Format with nixfmt-rfc-style
```

## Architecture

### System Factory Pattern
`lib/mksystem.nix` provides a unified interface for building both Darwin and NixOS systems. It dynamically resolves users via `$USER` environment variable (requires `--impure` flag).

### User-Centric Configuration
All user configuration lives in `users/shared/` with one file per tool:
- `home-manager.nix` - Main aggregator importing all tool configs
- `git.nix`, `vim.nix`, `zsh.nix`, `tmux.nix` - Individual tool configs
- `.config/claude/` - Claude Code commands, skills, and hooks

### Machine Definitions
`machines/` contains hardware-specific configurations:
- `macbook-pro.nix`, `baleen-macbook.nix` - Use dynamic `$USER`
- `kakaostyle-jito.nix` - Hardcoded to user "jito.hello"

## Testing

### Test Hierarchy
```
tests/
├── unit/           # Individual components (<5 sec each)
├── integration/    # Module interactions (5-60 sec)
├── e2e/            # Complete workflows (3-10 min)
└── lib/            # test-helpers.nix framework
```

### Writing Tests
Use the standard helper pattern:
```nix
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
helpers.testSuite "feature-name" [
  (helpers.assertTest "test-name" condition "failure-message")
]
```

### Platform-Specific Testing
- **macOS**: Validation mode (`--no-build`) - syntax/config validation only
- **Linux**: Full container-based execution with real builds

## Development Workflow

### Pre-commit Sequence
```bash
make lint       # pre-commit run --all-files
make test       # Fast validation
make test-all   # Complete validation
make build      # Build all configurations
```

### Adding Packages
1. Determine location: `users/shared/` for the appropriate tool file
2. Follow existing patterns in that file
3. Run `make test && make build` to verify

### Creating New Tool Configurations
1. Create `users/shared/tool-name.nix`
2. Import in `users/shared/home-manager.nix`
3. Add tests in `tests/unit/tool-name-test.nix`

## Nix Conventions

- Use `nixfmt-rfc-style` formatting (enforced via pre-commit)
- `pkgs.unstable` overlay available for bleeding-edge packages
- Special args include: `currentSystemUser`, `isDarwin`, `inputs`, `self`

## VM Management

```bash
# Environment variables required
export NIXADDR=<vm-ip>
export NIXPORT=22
export NIXUSER=root

# Commands
make vm/bootstrap0   # Fresh NixOS VM installation
make vm/bootstrap    # Complete VM setup
make vm/copy         # Sync config to VM
make vm/switch       # Apply config on VM
```

## Secrets

```bash
make secrets/backup   # Backup SSH keys + GPG keyring
make secrets/restore  # Restore from backup.tar.gz
```
