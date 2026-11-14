# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nix flakes-based dotfiles system providing reproducible development environments for macOS and NixOS. Uses mitchellh-style machine, user OS, and Home Manager composition while retaining flake-parts.

## Essential Commands

### Environment Setup

Flake evaluation is pure and requires no user environment variable. `HM_USER`
only selects a standalone Home Manager profile; typed `dotfiles.hosts` entries
declare permanent host system users.

### Bootstrap and activation

Use `./bootstrap.sh` to prepare tools and the existing age identity, then
`./switch.sh` to apply. Both select the local host with `hostname -s`; host
arguments and local `NIXNAME` overrides are unsupported. Bootstrap never activates
the host. `DOTFILES_AGE_KEY_REF` overrides the 1Password reference, never key material.
Every normal switch requires a valid identity, even without declared secrets;
`./switch.sh --build` skips identity and decryption checks without activation.
Linux outside NixOS and Debian automatically uses standalone Home Manager;
`HM_USER` selects its profile. Debian bootstrap prepares native packages and the
identity; switch applies secrets and services without retrieving keys. Debian
`--build` validates declarations only; `SOPS_AGE_KEY_FILE` selects its identity path.

User secrets are declared with sops-nix under the selected Home Manager config.
Private keys and decrypted data stay outside Nix evaluation and the store.
`modules.secrets.gpgImports` lists declared SOPS secret names containing exported
GPG keys. SOPS installs synchronously before linking dependent home files; GPG
imports run after successful decryption. No actual personal secrets are supplied
in this repository until the user provides recipients and encrypted files.

### Common Operations

```bash
# Evaluate the full platform matrix
nix flake check --no-build --all-systems --show-trace

# Build configuration closures without activation
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#homeConfigurations.baleen-linux.activationPackage'

# Activate a standalone Home Manager profile on Linux outside NixOS and Debian
HM_USER=baleen-linux ./switch.sh
```

**Caveat**: container tests need Linux and `/dev/kvm`. Without them `make test`
falls back to `nix flake check --no-build`, which only evaluates checks — a false
assertion is never built and so never fails. `make test-build` builds the
`all-assertions` aggregate, which excludes the container VMs and therefore works
on any platform.

### Platform-Specific Commands

```bash
# Darwin aarch64-darwin
nix build '.#darwinConfigurations.macbook-pro.system'

# Standalone Linux Home Manager x86_64-linux
nix build '.#homeConfigurations.baleen-linux.activationPackage'

```

## Architecture

### System Factory Pattern (lib/mksystem.nix)

The `mkSystem` function provides unified system creation:

- Takes `name`, `system`, `user`, `darwin`, and host modules
- Returns darwinSystem or nixosSystem based on platform
- Handles Home Manager integration automatically
- Imports `users/shared/darwin.nix` or `users/shared/nixos.nix` for platform policy and caches

Key specialArgs passed to all modules:

- `currentSystemUser`: The actual username (e.g., "baleen" or "jito.hello")
- `isDarwin`: Boolean for platform-specific logic

### User Configuration Structure

All user configurations are in `users/shared/` using flat, tool-specific files:

```text
users/shared/
├── home-manager.nix       # Main entry point; programs/ and packages/ are discovered by lib/home-modules.nix
├── darwin.nix             # macOS system policy (Determinate Nix, caches)
├── nixos.nix              # NixOS system policy (Nix, GC, login shell)
├── development.nix        # Explicit shared development-tool selection
├── darwin/
│   ├── system/            # Optional OS preferences, Homebrew and activation
│   └── home/              # HM input and LaunchServices configuration
├── programs/             # Tool-specific configuration modules
│   ├── git.nix          # Git configuration with aliases
│   ├── vim.nix          # Vim/Neovim setup
│   ├── zsh/             # Zsh configuration (default.nix, claude-wrappers.nix, ...)
│   ├── tmux.nix         # Terminal multiplexer
│   ├── powerlevel10k.nix # Shell prompt
│   ├── claude-code.nix  # Claude Code configuration
│   ├── .config/claude/  # CLAUDE.md, settings, statusline deployed to ~/.claude
│   └── ...              # codex, hammerspoon, karabiner
└── packages/             # Categorized package lists
    ├── core.nix         # Core CLI utilities
    ├── dev.nix          # Development tools
    ├── nix-tools.nix    # Nix tooling
    ├── cloud.nix        # Cloud CLIs
    ├── security.nix     # Security tools
    ├── ssh.nix          # SSH-related packages
    ├── media.nix        # Media tools
    ├── fonts.nix        # Fonts
    ├── databases.nix    # Database clients
    └── ai.nix           # AI tooling
```

**Important**: The `currentSystemUser` variable contains the actual username. User info (name, email) is centralized in `lib/user-info.nix`.

### Machine Configurations

Hosts are declared through the typed internal `dotfiles.hosts` option in
`flake-modules/hosts.nix` (`system`, `class`, `user`, optional `homeModules`,
and required per-host `machineModules`); `flake-modules/systems.nix` turns each entry into a
darwinConfiguration or nixosConfiguration via `lib/mksystem.nix`.

Registered system hosts are Darwin `aarch64-darwin`. Standalone Home Manager
supports `x86_64-linux`; shared checks and tools also support `aarch64-linux`.
Debian uses native APT and systemd integration under `machines/debian/`.
Windows uses `machines/windows/configuration.winget` for native apps outside Nix
(see `machines/windows/README.md`). `dotfiles.hosts.<name>.user` is the host system
user declaration. `HM_USER` is separate and only selects a standalone Home
Manager profile.

Hardware and system settings live under `machines/`:

```text
machines/
├── darwin/
│   └── common.nix              # Shared by every Darwin host
├── debian/                     # Native APT and systemd integration
└── windows/                    # Windows side, outside Nix: winget config, SSH bootstrap
```

Darwin hosts each register `machines/darwin/<host>.nix`. Machine files import
`common.nix` and select apps, macOS settings and Home Manager features.
The NixOS system factory remains available, with no registered NixOS hosts.

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

### User Selection

Host users are declared by `dotfiles.hosts.<name>.user`. Standalone Home Manager
profiles on Linux outside NixOS and Debian use `HM_USER`, for example
`HM_USER=baleen-linux ./switch.sh`; it
does not change host metadata.

## Development Guidelines

### Adding Packages

**User packages** (CLI tools, development utilities):

- Add to the appropriate category file in `users/shared/packages/` (e.g., `dev.nix` for development tools)
- Or create/modify specific tool configuration in `users/shared/programs/*.nix`
- A new `<name>.nix` (or `<name>/default.nix`) under `programs/` or `packages/` is imported automatically by `lib/home-modules.nix`; do not edit `home-manager.nix`

**Module enable pattern** (`modules.programs.<name>`, `modules.packages.<name>`):

- Optional modules use `lib.mkEnableOption` with a false default. Git and SSH remain enabled; the shared Home Manager entry point provides basic Zsh and age.
- Select user features in `machines/<platform>/<host>.nix` under `home-manager.users.${currentSystemUser}.modules`.
- Helpers imported by a module belong inside its directory.
- Standalone Home Manager outputs explicitly select existing features in `flake-modules/home.nix`; retain `HM_USER` selection.

**macOS apps and automation**:

- Declare casks and App Store apps in each Mac's machine file.
- Keep implementations in `users/shared/`; import shared Darwin preferences, power and cleanup modules only for hosts that select them.
- Tie app configuration and activation to feature selection. A new host using only `machines/darwin/common.nix` must have no GUI apps or personal automation.

### Adding New Users

1. For permanent machine configuration, add an entry to `dotfiles.hosts` in
   `flake-modules/hosts.nix`; `hosts.nix` is the only place a host is declared,
   and `flake-modules/systems.nix` turns each entry into a
   darwinConfiguration or nixosConfiguration by its `class`:

   ```nix
   newmachine = {
     system = "aarch64-darwin";
     class = "darwin";
     user = "newusername";
     machineModules = [ ../machines/darwin/newmachine.nix ];
   };
   ```

   Note that `integration-machine-builds` asserts the exact host list, so it needs
   updating alongside.

2. Macs that set `modules.programs.syncthing.enable` in their machine file sync
   `~/wiki` (`users/shared/programs/syncthing.nix`). To pair a new one, run `make syncthing-id` on it (writes `syncthingId` into
   its `hosts.nix` entry), commit, `make switch` on each Mac, then add the device
   on the hub's web UI. Devices and folders added in a Mac's web UI are removed
   on the next switch.

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
make format           # Format with the repository treefmt config (wraps nix fmt)
nix fmt               # Direct formatter invocation
pre-commit run --all-files  # Run all pre-commit hooks
```

## macOS-Specific Notes

### Determinate Nix Integration

This system uses Determinate Nix installer on macOS:

- `nix.enable = false` is forced by the Determinate nix-darwin module (`determinateNix.enable` defaults to true)
- Cache settings managed via `determinateNix.customSettings` in `users/shared/darwin.nix`
- All Nix configuration is in `/etc/nix/nix.custom.conf`

### Performance Optimizations

macOS configuration includes:

- Disabled window animations for faster UI
- Optimized keyboard repeat rates (faster than GUI allows)
- Maximum trackpad speed
- Automated cleanup of unused default apps (GarageBand, iMovie, etc.)

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`):

- Runs on: Darwin `aarch64-darwin` (macOS-15), standalone Home Manager `x86_64-linux` (Ubuntu),
  and shared tools/checks on `aarch64-linux` (Ubuntu ARM64)
- Pre-commit hooks validation
- Fast container tests (Linux) or validation mode (macOS)
- Builds every unit and integration assertion (`make test-build`) on PRs and main
- Cachix upload for successful builds

Required environment variables in CI:

```bash
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

Machine files select apps, settings and user features. Shared implementations and option declarations stay in `users/shared/`.

## Troubleshooting

### Build Failures

```bash
nix store gc            # Clear cache if needed
./switch.sh            # Retry
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
- **users/shared/darwin/system/default.nix**: Optional macOS settings (Dock, Finder, performance tweaks)
- **users/shared/darwin/system/homebrew.nix**: Shared Homebrew implementation; app selection stays in machines
- **users/shared/darwin/system/scripts.nix**: App cleanup and helper scripts
- **users/shared/programs/git.nix**: Git configuration with centralized user info from lib/user-info.nix
- **users/shared/programs/vim.nix**: Vim setup with airline, tmux-navigator, relative line numbers
- **users/shared/programs/zsh/**: Zsh environment with fzf, direnv, Claude/Codex aliases
- **users/shared/programs/tmux.nix**: Tmux config with vi-mode copy-paste, OSC52 clipboard
- **users/shared/programs/powerlevel10k.nix**: Prompt (Pure preset, instant prompt)
- **users/shared/programs/claude-code.nix**: Deploys CLAUDE.md, settings, statusline, and worktree hook to ~/.claude (commands/skills/hooks come from an external plugin)

### Testing and Quality

- **tests/README.md**: Test contract, helper inventory, and what is worth asserting
- **tests/default.nix**: Discovery of `*-test.nix` files into flake checks
- **tests/lib/test-helpers.nix**: `assertTest` and `testSuite`
- **tests/lib/common-assertions.nix**: Assertions with generated failure messages
- **tests/lib/platform-helpers.nix**: `platforms` metadata filtering
- **.pre-commit-config.yaml**: Quality enforcement hooks (shellcheck, bashate, tests; shfmt and deadnix run via treefmt)

### Continuous Integration

- **.github/workflows/ci.yml**: Multi-platform CI (macOS, Linux x64/ARM64)
- **.github/actions/setup-nix/action.yml**: Nix installation with week-based cache rotation

## Important Development Notes

### Shell Aliases and Shortcuts

The zsh configuration provides these shortcuts (defined in `users/shared/programs/zsh/`):

- `cc`: Claude Code with permission checks disabled (`claude --dangerously-skip-permissions`)
- `wt`: Git worktree management (fzf picker, create, list, prune)

### Tool Configuration Highlights

**Vim** (users/shared/programs/vim.nix):

- Leader key: Space
- LocalLeader: `,` (comma)
- Clipboard: `<Leader>,` paste, `<Leader>.` copy
- Window navigation: Ctrl+h/j/k/l
- Buffer navigation: Tab/Shift+Tab

**Tmux** (users/shared/programs/tmux.nix):

- Prefix: Ctrl+a
- Splits use tmux's default keys (`%` left/right, `"` top/bottom), re-bound only to keep the current pane's path
- Vi-style copy mode with tmux-native OSC52 clipboard (works over SSH)
- Cross-platform: OSC52 (no pbcopy/xclip dependency)

**Fzf** (in `zsh/default.nix`):

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

## Agent skills

### Issue tracker

이슈·스펙 작업 전 `docs/agents/issue-tracker.md`를 읽는다.

### Triage labels

이슈 분류 전 `docs/agents/triage-labels.md`를 읽는다.

### Domain docs

코드 탐색과 설계 작업 전 `docs/agents/domain.md`를 읽는다.
