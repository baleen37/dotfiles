# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nix flakes-based dotfiles system providing reproducible development environments for macOS and NixOS. Uses the evantravers user-centric architecture pattern with dynamic user resolution and comprehensive TDD testing.

## Essential Commands

### Environment Setup

All build operations require the USER environment variable. When working
inside the project directory, direnv sets this automatically. For shells
without direnv:

```bash
export USER=$(whoami)
```

### Common Operations

```bash
# Core workflow
make test              # Evaluate all checks (see caveat below)
make test-build        # Actually build every unit + integration assertion
make switch            # Build and apply configuration (uses sudo internally)
make format            # Format all Nix files

# Build operations
nix flake check --impure         # Evaluate all checks directly

# Testing
nix build '.#checks.aarch64-darwin.unit-darwin-sudo' --impure  # Specific check
make test-containers                                           # NixOS VM tests (Linux + KVM)
```

**Caveat**: container tests need Linux and `/dev/kvm`. Without them `make test`
falls back to `nix flake check --no-build`, which only evaluates checks — a false
assertion is never built and so never fails. `make test-build` builds the
`all-assertions` aggregate, which excludes the container VMs and therefore works
on any platform.

### First-Time Bootstrap (macOS)

`make switch` invokes `darwin-rebuild`, which only exists after nix-darwin has been installed. For a brand-new machine, bootstrap once with:

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#$(hostname -s)"
```

After that succeeds, use `make switch` for all subsequent rebuilds.

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
├── home-manager.nix       # Main entry point, imports all modules
├── darwin/                # macOS system settings
│   ├── default.nix       # Dock, Finder, masApps, primary user
│   ├── homebrew.nix      # Homebrew casks and brews
│   └── scripts.nix       # App cleanup and helper scripts
├── programs/             # Tool-specific configuration modules
│   ├── git.nix          # Git configuration with aliases
│   ├── vim.nix          # Vim/Neovim setup
│   ├── zsh.nix          # Zsh shell configuration
│   ├── tmux.nix         # Terminal multiplexer
│   ├── zellij.nix       # Zellij multiplexer, tmux-shaped keybindings
│   ├── starship.nix     # Shell prompt
│   ├── claude-code.nix  # Claude Code configuration
│   └── ...              # codex, opencode, ghostty, hammerspoon, karabiner
├── packages/             # Categorized package lists
│   ├── core.nix         # Core CLI utilities
│   ├── dev.nix          # Development tools
│   ├── lsp.nix          # Language servers
│   ├── nix-tools.nix    # Nix tooling
│   ├── cloud.nix        # Cloud CLIs
│   ├── security.nix     # Security tools
│   ├── ssh.nix          # SSH-related packages
│   ├── media.nix        # Media tools
│   ├── fonts.nix        # Fonts
│   ├── databases.nix    # Database clients
│   └── ai.nix           # AI tooling
└── .config/claude/       # Claude Code commands, skills, hooks
```

**Important**: The `currentSystemUser` variable contains the actual username. User info (name, email) is centralized in `lib/user-info.nix`.

### Machine Configurations

Hosts are declared in `flake-modules/hosts.nix` (system, class, user, optional
`homeModules` overrides); `flake-modules/systems.nix` turns each entry into a
darwinConfiguration or nixosConfiguration via `lib/mksystem.nix`.

Hardware and system settings live under `machines/`:

```text
machines/
├── darwin/
│   └── common.nix              # Shared by every Darwin host
└── nixos/
    ├── vm-aarch64-utm.nix      # ARM64 NixOS VM
    ├── vm-x86_64-utm.nix       # x86_64 NixOS VM
    ├── vm-shared.nix           # Shared NixOS settings
    └── hardware/vm-utm.nix     # virtio profile shared by both VMs
```

Darwin hosts all share `machines/darwin/common.nix`; per-host differences are
expressed in `hosts.nix` rather than in a per-machine file. NixOS hosts keep one
file each, named after the host — `mkSystem` resolves
`machines/nixos/<name>.nix` from the host name.

### Testing Framework

Every check is a derivation that builds iff an assertion holds. See
`tests/README.md` for the full contract.

```text
tests/
├── default.nix                # Discovery -> flake checks
├── unit/*-test.nix            # One module or library, auto-discovered
├── integration/*-test.nix     # Configurations against each other, auto-discovered
├── containers/*.nix           # NixOS VM tests (Linux + KVM), wired up explicitly
└── lib/                       # Shared assertions and fixtures
    ├── test-helpers.nix       # assertTest, testSuite
    ├── common-assertions.nix  # assertions with generated failure messages
    ├── platform-helpers.nix   # `platforms` metadata filtering
    ├── constants.nix          # values shared by a module and its test
    └── mock-config.nix        # minimal `config` for direct module imports
```

**Container Tests**: Linux + `/dev/kvm` only. Elsewhere `make test` degrades to
`--no-build`, which does not run assertions — use `make test-build` for that.

### Dynamic User Resolution

The flake supports multiple users via environment variable. `resolveUser` in
`flake-modules/args.nix` supplies the fallback used by `flake-modules/hosts.nix`:

```nix
resolveUser =
  fallback:
  let
    env = builtins.getEnv "USER";
  in
  if env != "" && env != "root" then env else fallback;
```

This allows the same configuration to work for different users without hardcoding
usernames. Reading the environment is why every command needs `--impure`.

## Development Guidelines

### Adding Packages

**User packages** (CLI tools, development utilities):

- Add to the appropriate category file in `users/shared/packages/` (e.g., `dev.nix` for development tools)
- Or create/modify specific tool configuration in `users/shared/programs/*.nix`

**Module enable pattern** (`modules.programs.<name>`, `modules.packages.<name>`):

- Every program and package category exposes an `enable` option. `lib.mkEnableOption` defaults to `false`; activation happens explicitly in `users/shared/home-manager.nix`.
- Platform-conditional modules (`hammerspoon`, `karabiner`) set `default = pkgs.stdenv.hostPlatform.isDarwin` in the module itself — do **not** list them in the home-manager.nix enable block; let the module default own the decision.
- To disable a module on a specific machine, add it to that host's `homeModules` in `flake-modules/hosts.nix` (e.g., `modules.programs.hammerspoon.enable = false;`).

**System packages** (macOS GUI apps):

- Add Homebrew casks to `users/shared/darwin/homebrew.nix` in `homebrew-casks` list
- Add Mac App Store apps to `masApps` in `users/shared/darwin/default.nix`

### Adding New Users

1. No code changes needed - use environment variable:

   ```bash
   export USER=newusername
   make switch
   ```

2. For permanent machine configuration, add an entry to `flake.hosts` in
   `flake-modules/hosts.nix`; `hosts.nix` is the only place a host is declared,
   and `flake-modules/systems.nix` turns each entry into a
   darwinConfiguration or nixosConfiguration by its `class`:

   ```nix
   newmachine = {
     system = "aarch64-darwin";
     class = "darwin";
     user = "newusername";
   };
   ```

   Note that `unit-machine-builds` asserts the exact host list, so it needs
   updating alongside.

### Adding Tests

**Unit/Integration tests** (automatic discovery):

- Create `<feature>-test.nix` in `tests/unit/` or `tests/integration/`
- Use `assertTest`/`testSuite` from `tests/lib/test-helpers.nix`
- The file becomes `checks.<system>.{unit,integration}-<feature>`
- Read `tests/README.md#what-belongs-in-a-test` first — an assertion over values
  the test itself defined covers nothing

**Container tests** (manual):

- Add to `tests/containers/`
- Register it in `containerTests` in `tests/default.nix`
- Run with `make test-containers` (Linux + KVM) or CI

### Formatting and Linting

```bash
make format           # Format with nixfmt-rfc-style (wraps nix fmt)
nix fmt               # Direct formatter invocation
pre-commit run --all-files  # Run all pre-commit hooks
```

## macOS-Specific Notes

### Determinate Nix Integration

This system uses Determinate Nix installer on macOS:

- `nix.enable = false` in darwin/default.nix (required for compatibility)
- Cache settings managed via `determinate-nix.customSettings`
- All Nix configuration is in `/etc/nix/nix.custom.conf`

### Performance Optimizations

macOS configuration includes:

- Disabled window animations for faster UI
- Optimized keyboard repeat rates (faster than GUI allows)
- Maximum trackpad speed
- Automated cleanup of unused default apps (GarageBand, iMovie, etc.)

### Linux Builder

`machines/darwin/common.nix` includes a Linux builder configuration for cross-platform testing, but it's disabled when using Determinate Nix (requires `nix.enable = true`).

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
make switch            # Retry
```

### Container Tests Failing on macOS

This is expected — container tests require Linux and `/dev/kvm`. Use `make test-build` to run the unit and integration assertions locally, and leave the VM tests to CI.

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
- **users/shared/darwin/default.nix**: macOS system settings (Dock, Finder, masApps, performance tweaks)
- **users/shared/darwin/homebrew.nix**: Homebrew casks and brews
- **users/shared/darwin/scripts.nix**: App cleanup and helper scripts
- **users/shared/programs/git.nix**: Git configuration with centralized user info from lib/user-info.nix
- **users/shared/programs/vim.nix**: Vim setup with airline, tmux-navigator, relative line numbers
- **users/shared/programs/zsh.nix**: Zsh environment with fzf, direnv, Claude/OpenCode aliases
- **users/shared/programs/tmux.nix**: Tmux config with vi-mode copy-paste, OSC52 clipboard
- **users/shared/programs/zellij.nix**: Zellij config mirroring tmux.nix (Ctrl+a prefix chords via Zellij's tmux mode)
- **users/shared/programs/starship.nix**: Minimal prompt configuration
- **users/shared/programs/claude-code.nix**: Claude Code commands/skills/hooks deployment

### Testing and Quality

- **tests/README.md**: Test contract, helper inventory, and what is worth asserting
- **tests/default.nix**: Discovery of `*-test.nix` files into flake checks
- **tests/lib/test-helpers.nix**: `assertTest` and `testSuite`
- **tests/lib/common-assertions.nix**: Assertions with generated failure messages
- **tests/lib/platform-helpers.nix**: `platforms` metadata filtering
- **.pre-commit-config.yaml**: Quality enforcement hooks (shellcheck, shfmt, tests)

### Continuous Integration

- **.github/workflows/ci.yml**: Multi-platform CI (macOS, Linux x64/ARM64)
- **.github/actions/setup-nix/action.yml**: Nix installation with week-based cache rotation

## Important Development Notes

### Shell Aliases and Shortcuts

The zsh configuration provides these shortcuts (defined in `users/shared/programs/zsh.nix`):

- `cc`: Claude Code with permission checks disabled (`claude --dangerously-skip-permissions`)
- `oc`: OpenCode shortcut
- `wt`: Git worktree management (fzf picker, create, list, prune)

### Tool Configuration Highlights

**Vim** (users/shared/programs/vim.nix):

- Leader key: `,` (comma)
- Clipboard: `<Leader>,` paste, `<Leader>.` copy
- Window navigation: Ctrl+h/j/k/l
- Buffer navigation: Tab/Shift+Tab

**Tmux** (users/shared/programs/tmux.nix):

- Prefix: Ctrl+a
- Splits use tmux's default keys (`%` left/right, `"` top/bottom), re-bound only to keep the current pane's path
- Vi-style copy mode with tmux-native OSC52 clipboard (works over SSH)
- Cross-platform: OSC52 (no pbcopy/xclip dependency)

**Zellij** (users/shared/programs/zellij.nix):

- Ctrl+a enters Zellij's built-in `tmux` mode, so `Ctrl+a <key>` acts as a tmux prefix chord
- tmux bindings carried over: h/j/k/l focus, H/J/K/L resize, 1-9 tabs, `a` last tab, `T` session picker
- Splits stay on Zellij's tmux-mode defaults (`%` left/right, `"` top/bottom), matching tmux
- A Zellij _tab_ stands in for a tmux _window_; the compact layout puts a single status line at the bottom
- OSC52 clipboard (no `copy_command`), 50000-line scrollback — both matched to tmux.nix
- Shell auto-start is deliberately off, so Zellij never launches itself inside a tmux pane

**Fzf** (in zsh.nix):

- Ctrl+R: Command history search
- Ctrl+T: File search with bat preview
- Alt+C: Directory search with tree preview

### Test Writing Guidelines

Full contract in `tests/README.md`. The short version:

```nix
{ pkgs, lib, ... }:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  platforms = [ "any" ];             # or ["darwin"] / ["linux"]; omit for all
  value = helpers.testSuite "my-feature" [
    (helpers.assertTest "some-invariant" someCondition
      "why this matters, and what breaks when it does not hold"
    )
  ];
}
```

- `tests/lib/test-helpers.nix`: `assertTest name condition message`,
  `testSuite name tests`
- `tests/lib/common-assertions.nix`: `assertAttrEquals`, `assertAttrExists`,
  `assertAttrPathExists`, `assertListContains`, `assertListNotEmpty`,
  `assertNotNull`, `assertCondition` — each takes a trailing `message`, `null`
  for the generated one

Assert things that can break silently — a value duplicated in two files, a
setting whose loss you would not notice for weeks, a configuration that must keep
evaluating. Do not assert over values the test itself defines: it always passes
and covers nothing.

## References

- **flake.nix**: Entry point, defines all configurations
- **lib/mksystem.nix**: System factory, core abstraction
- **Makefile**: High-level commands and CI integration
- **.pre-commit-config.yaml**: Quality enforcement hooks
- **tests/default.nix**: Test discovery and orchestration
- **CONTRIBUTING.md**: Detailed development guidelines and workflow
