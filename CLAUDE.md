# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nix flakes-based dotfiles system providing reproducible development environments for macOS and NixOS. Uses the evantravers user-centric architecture pattern with dynamic user resolution and comprehensive TDD testing.

## Essential Commands

### Environment Setup

All build operations require the USER environment variable:

```bash
export USER=$(whoami)  # Required before any Nix commands
```

### Common Operations

```bash
# Core workflow
make test              # Fast container tests (2-5 seconds, Linux only - validation mode on macOS)
make test-all          # Full test suite including integration tests
make switch            # Build and apply configuration (uses sudo internally)
make format            # Format all Nix files

# Build operations
nix run --impure .#build-switch  # Build and switch in one step
nix flake check --impure         # Run all checks

# Testing
nix build '.#checks.aarch64-darwin.basic' --impure  # Specific check
make test-integration                                # Integration tests only
```

### Platform-Specific Commands

```bash
# macOS
darwin-rebuild switch --flake .#macbook-pro
nix build '.#darwinConfigurations.macbook-pro.system'

# NixOS
nixos-rebuild switch --flake .#vm-aarch64-utm
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
```

## Architecture

### System Factory Pattern (lib/mksystem.nix)

The `mkSystem` function provides unified system creation:

- Takes `name`, `system`, `user`, `darwin`, and `wsl` parameters
- Returns darwinSystem or nixosSystem based on platform
- Handles Home Manager integration automatically
- Manages cache configuration for both traditional Nix and Determinate Nix

Key specialArgs passed to all modules:

- `currentSystemUser`: The actual username (e.g., "baleen" or "jito.hello")
- `currentSystem`: Platform architecture (e.g., "aarch64-darwin")
- `currentSystemName`: Machine name (e.g., "macbook-pro")
- `isDarwin`: Boolean for platform-specific logic
- `isWSL`: Boolean for WSL-specific logic

### User Configuration Structure

All user configurations are in `users/shared/` using flat, tool-specific files:

```text
users/shared/
├── home-manager.nix   # Main entry point, imports all modules
├── darwin.nix         # macOS system settings (Dock, Finder, Homebrew)
├── git.nix           # Git configuration with aliases
├── vim.nix           # Vim/Neovim setup
├── zsh.nix           # Zsh shell configuration
├── tmux.nix          # Terminal multiplexer
├── starship.nix      # Shell prompt
├── claude-code.nix   # Claude Code configuration
└── .config/claude/   # Claude Code commands, skills, hooks
```

**Important**: The `currentSystemUser` variable contains the actual username. User info (name, email) is centralized in `lib/user-info.nix`.

### Machine Configurations

Machine-specific hardware and system settings:

```text
machines/
├── macbook-pro.nix        # Primary macOS machine (includes linux-builder)
├── baleen-macbook.nix     # Secondary macOS machine
├── kakaostyle-jito.nix    # Work machine (jito.hello user)
└── nixos/
    ├── vm-aarch64-utm.nix # ARM64 NixOS VM
    └── vm-shared.nix      # Shared NixOS settings
```

### Testing Framework

TDD-based testing with automatic test discovery:

```text
tests/
├── default.nix                    # Test orchestration and discovery
├── unit/                          # Fast unit tests (automatic discovery)
│   └── *-test.nix                # Auto-discovered tests
├── integration/                   # Integration tests (automatic discovery)
│   └── *-test.nix
├── containers/                    # NixOS container tests (Linux only)
│   ├── basic-system.nix
│   ├── services.nix
│   └── packages.nix
├── e2e/                          # End-to-end tests (manual, heavy)
│   └── *.nix
└── lib/                          # Test utilities
    ├── platform-helpers.nix     # Platform-aware test filtering
    ├── test-helpers.nix
    └── assertions.nix
```

**Container Tests**: Only run on Linux. On macOS, `make test` runs validation mode (config check without execution). Full container tests run in CI.

### Dynamic User Resolution

The flake supports multiple users via environment variable:

```nix
# flake.nix
user = let envUser = builtins.getEnv "USER";
       in if envUser != "" && envUser != "root" then envUser else "baleen";
```

This allows the same configuration to work for different users without hardcoding usernames.

## Development Guidelines

### Adding Packages

**User packages** (CLI tools, development utilities):

- Add to `users/shared/home-manager.nix` in the `packages` list
- Or create/modify specific tool configuration in `users/shared/*.nix`

**System packages** (macOS GUI apps):

- Add Homebrew casks to `users/shared/darwin.nix` in `homebrew-casks` list
- Add Mac App Store apps to `masApps` in `users/shared/darwin.nix`

### Adding New Users

1. No code changes needed - use environment variable:

   ```bash
   export USER=newusername
   nix run --impure .#build-switch
   ```

2. For permanent machine configuration, add to `flake.nix`:

   ```nix
   darwinConfigurations.newmachine = mkSystem "newmachine" {
     system = "aarch64-darwin";
     user = "newusername";
     darwin = true;
   };
   ```

### Adding Tests

**Unit/Integration tests** (automatic discovery):

- Create `*-test.nix` in `tests/unit/` or `tests/integration/`
- Use test helpers from `tests/lib/test-helpers.nix`
- Tests are automatically discovered and run

**Container tests** (manual):

- Add to `tests/containers/`
- Import in `tests/default.nix` containerTests
- Run with `make test` (Linux) or CI

### Formatting and Linting

```bash
make format           # Format with nixfmt-rfc-style
nix run .#format     # Direct formatter invocation
pre-commit run --all-files  # Run all pre-commit hooks
```

## macOS-Specific Notes

### Determinate Nix Integration

This system uses Determinate Nix installer on macOS:
- `nix.enable = false` in darwin.nix (required for compatibility)
- Cache settings managed via `determinate-nix.customSettings`
- All Nix configuration is in `/etc/nix/nix.custom.conf`

### Performance Optimizations

macOS configuration includes:

- Disabled window animations for faster UI
- Optimized keyboard repeat rates (faster than GUI allows)
- Maximum trackpad speed
- Automated cleanup of unused default apps (GarageBand, iMovie, etc.)

### Linux Builder

`machines/macbook-pro.nix` includes a Linux builder configuration for cross-platform testing, but it's disabled when using Determinate Nix (requires `nix.enable = true`).

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`):

- Runs on: macOS-15 (ARM), Ubuntu (x64 + ARM64)
- Pre-commit hooks validation
- Fast container tests (Linux) or validation mode (macOS)
- Full test suite on PRs and main branch
- Cachix upload for successful builds

Required environment variables in CI:

```bash
export USER=${USER:-ci}
export TEST_USER=${TEST_USER:-testuser}
```

## Common Patterns

### Reading Current User

```nix
# In any module that receives specialArgs
{ currentSystemUser, ... }:
{
  programs.git.userName = currentSystemUser;
  home.homeDirectory = "/Users/${currentSystemUser}";
}
```

### Platform-Specific Logic

```nix
{ pkgs, isDarwin, ... }:
{
  home.packages = with pkgs; [
    common-package
  ] ++ lib.optionals isDarwin [
    macos-only-package
  ];
}
```

### Adding Machine-Specific Settings

Machine files should be minimal - only hardware-specific settings. User preferences go in `users/shared/`.

## Troubleshooting

### Build Failures

```bash
export USER=$(whoami)  # Ensure USER is set
nix store gc            # Clear cache if needed
make build             # Retry build
```

### Container Tests Failing on macOS

This is expected - container tests require Linux. Use `make test` for validation mode or run in CI.

### Pre-commit Hook Failures

```bash
pre-commit run --all-files  # Run all hooks
make format                 # Auto-format Nix files
```

### Cache Warnings

Add your user to trusted users in `/etc/nix/nix.custom.conf`:

```text
trusted-users = root @admin yourusername
```

## Key Configuration Files

### Core Infrastructure

- **flake.nix**: Entry point, defines all system configurations and package outputs
- **lib/mksystem.nix**: System factory function, core abstraction for building Darwin/NixOS systems
- **lib/user-info.nix**: Centralized user identity (name, email) - single source of truth
- **Makefile**: High-level commands, CI integration, and cross-platform build orchestration

### User Configuration

- **users/shared/home-manager.nix**: Main user config entry point, imports all tool modules
- **users/shared/darwin.nix**: macOS system settings (300+ lines: Dock, Finder, Homebrew, performance tweaks)
- **users/shared/git.nix**: Git configuration with centralized user info from lib/user-info.nix
- **users/shared/vim.nix**: Vim setup with airline, tmux-navigator, relative line numbers
- **users/shared/zsh.nix**: Zsh environment with fzf, direnv, Claude/OpenCode aliases
- **users/shared/tmux.nix**: Tmux config with vi-mode copy-paste, session persistence
- **users/shared/starship.nix**: Minimal prompt configuration
- **users/shared/claude-code.nix**: Claude Code commands/skills/hooks deployment

### Testing and Quality

- **tests/default.nix**: Test orchestration, automatic discovery of `*-test.nix` files
- **tests/lib/test-helpers.nix**: Test assertion framework (assertTest, assertFileExists, assertHasAttr)
- **tests/lib/platform-helpers.nix**: Platform-aware test filtering for cross-platform support
- **.pre-commit-config.yaml**: Quality enforcement hooks (shellcheck, shfmt, tests)

### Continuous Integration

- **.github/workflows/ci.yml**: Multi-platform CI (macOS, Linux x64/ARM64)
- **.github/actions/setup-nix/action.yml**: Nix installation with week-based cache rotation

## Important Development Notes

### Shell Aliases and Shortcuts

The zsh configuration provides these shortcuts (defined in `users/shared/zsh.nix`):

- `cc`: Claude Code with permission checks disabled (`claude --dangerously-skip-permissions`)
- `oc`: OpenCode shortcut
- `ccw` / `oow`: Git worktree + Claude/OpenCode execution wrappers

### Tool Configuration Highlights

**Vim** (users/shared/vim.nix):

- Leader key: `,` (comma)
- Clipboard: `<Leader>,` paste, `<Leader>.` copy
- Window navigation: Ctrl+h/j/k/l
- Buffer navigation: Tab/Shift+Tab

**Tmux** (users/shared/tmux.nix):

- Prefix: Ctrl+a
- Vi-style copy mode with clipboard integration
- Cross-platform: pbcopy (macOS), xclip (Linux)
- Session persistence via resurrect/continuum plugins

**Fzf** (in zsh.nix):

- Ctrl+R: Command history search
- Ctrl+T: File search with bat preview
- Alt+C: Directory search with tree preview

### Test Writing Guidelines

Use test helpers from `tests/lib/test-helpers.nix`:

```nix
{ pkgs, lib, ... }:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  myTest = helpers.assertTest "feature-works"
    (someCondition == expectedValue)
    "Feature should work correctly";
}
```

Available assertions:

- `assertTest name condition message`: Basic assertion
- `assertFileExists name derivation path`: File readability check
- `assertHasAttr name attrName set`: Attribute existence
- `assertStringContains name haystack needle`: String content check

## References

- **flake.nix**: Entry point, defines all configurations
- **lib/mksystem.nix**: System factory, core abstraction
- **Makefile**: High-level commands and CI integration
- **.pre-commit-config.yaml**: Quality enforcement hooks
- **tests/default.nix**: Test discovery and orchestration
- **CONTRIBUTING.md**: Detailed development guidelines and workflow
