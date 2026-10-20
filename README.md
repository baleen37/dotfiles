# Nix Dotfiles

Nix flakes-based dotfiles that build reproducible macOS (nix-darwin) and NixOS
systems, plus standalone Home Manager profiles, from one shared user
configuration. Every test is a Nix derivation, so `nix flake check` is the test
runner.

## Highlights

- **Three platforms**: Darwin `aarch64-darwin`; NixOS `x86_64-linux` and `aarch64-linux`
- **Typed host declarations**: every machine is one entry in `flake-modules/hosts.nix`
- **One user configuration**: `users/shared/` is shared by every host and Home Manager profile
- **Assertions as derivations**: unit, integration, and NixOS VM tests all run through `nix flake check`
- **Claude Code setup**: `CLAUDE.md`, settings, and statusline deployed to `~/.claude`

## Quick Start

### Prerequisites

- **Nix** with flakes enabled ([Determinate Nix Installer](https://install.determinate.systems/) recommended on macOS)
- **Git**
- **pre-commit** (for contributing)

### Installation

```bash
# 1. Clone
git clone git@github.com:baleen37/dotfiles.git  # or https://github.com/baleen37/dotfiles.git
cd dotfiles

# 2. Install pre-commit and pre-push hooks
make install-hooks

# 3. Evaluate every supported system
nix flake check --no-build --all-systems --show-trace

# 4. Build a configuration without activating it
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'

# 5a. Activate a standalone Home Manager profile
make switch-home HM_USER=jito.hello

# 5b. Or activate the full system for this host (see "System Activation")
make switch
```

### Hosts and Profiles

| Output                              | Names                                              |
| ----------------------------------- | -------------------------------------------------- |
| `darwinConfigurations` (aarch64)    | `macbook-pro`, `baleen-macbook`, `kakaostyle-jito` |
| `nixosConfigurations`               | `vm-aarch64-utm`, `vm-x86_64-utm`                  |
| `homeConfigurations` (Home Manager) | `baleen`, `jito.hello`, `testuser`, `baleen-linux` |

Run `nix flake show --all-systems` for the full list of outputs.

### Post-Installation Setup (macOS)

With **Determinate Nix**, add your user as a trusted user to avoid cache warnings:

```bash
sudo vi /etc/nix/nix.custom.conf

# Add this line (replace 'baleen' with your username):
trusted-users = root @admin baleen

# Restart the terminal to apply
```

### Nix Cache Behavior

Local builds are accelerated by binary substituters, especially `https://baleen-nix.cachix.org`, `https://nix-community.cachix.org`, and `https://cache.nixos.org/`. When CI pushes a built closure to Cachix on `main` or tags, local `nix build` and `make switch` can download matching store paths instead of rebuilding them.

GitHub `actions/cache` is CI-only. It can speed repeated workflow runs on GitHub-hosted runners, but it does not make local macOS builds faster. Do not store credentials in cached paths.

## Daily Usage

```bash
make switch-home HM_USER=jito.hello  # Apply user configuration only (no Homebrew casks)
make switch                          # Apply the full system for this host
make format                          # Format with treefmt (nix fmt)
make lint                            # Run all pre-commit hooks
make update                          # Update flake inputs (nix flake update)
```

### System Activation

`make switch` activates the system configuration named after the current
hostname (override with `NIXNAME=<host>`): `darwin-rebuild` on macOS,
`nixos-rebuild` on NixOS. It is an explicit operating procedure, not part of the
default development or PR workflow; run it only on the intended host after the
relevant build and verification steps.

### Home Manager Profile Selection

Flake evaluation is pure. `HM_USER` only selects a standalone Home Manager
profile from `homeConfigurations`, defaulting to the current shell user. It does
not declare a host's system user; that is the `user` field of the host entry in
`flake-modules/hosts.nix`.

```bash
make switch-home HM_USER=jito.hello
```

### Platform Capability Matrix

| Make target         | Darwin (`aarch64-darwin`) | NixOS (`x86_64-linux`) | NixOS (`aarch64-linux`) |
| ------------------- | :-----------------------: | :--------------------: | :---------------------: |
| **Core Operations** |                           |                        |                         |
| switch              |            ✅             |           ✅           |           ✅            |
| switch-home         |            ✅             |           ✅           |           ✅            |
| format              |            ✅             |           ✅           |           ✅            |
| **Testing**         |                           |                        |                         |
| test                |            ✅             |           ✅           |           ✅            |
| test-build          |            ✅             |           ✅           |           ✅            |
| test-containers     |            ❌¹            |          ✅²           |           ✅²           |
| **Secrets**         |                           |                        |                         |
| secrets/backup      |            ✅             |           ✅           |           ✅            |
| secrets/restore     |            ✅             |           ✅           |           ✅            |

¹ NixOS VM tests need a Linux builder; Determinate Nix disables the macOS
linux-builder, so run them in CI or a Linux VM.
² Requires `/dev/kvm`. Where it is missing, `make test` degrades to
`nix flake check --no-build`, which evaluates checks without running assertions.
`make test-build` runs the unit and integration assertions on any platform, but it
deliberately excludes the NixOS VM tests — those need `make test-containers` or CI.

`secrets/backup` and `secrets/restore` move `~/.ssh` and `~/.gnupg` to a new
machine through `backup.tar.gz` at the repository root.

## Architecture

### Directory Structure

```text
dotfiles/
├── flake.nix            # Inputs; outputs are assembled by flake-modules/
├── flake-modules/
│   ├── hosts.nix        # Typed dotfiles.hosts entries (the only place a host is declared)
│   ├── systems.nix      # hosts -> darwinConfigurations / nixosConfigurations
│   ├── home.nix         # Standalone homeConfigurations
│   ├── checks.nix       # tests/ -> flake checks
│   ├── packages.nix     # test-vm and other packages
│   ├── dev-shells.nix   # nix develop shell
│   └── formatter.nix    # treefmt (nixfmt, statix, deadnix, shfmt, prettier)
├── lib/
│   ├── mksystem.nix     # System factory (Darwin or NixOS + Home Manager)
│   ├── home-modules.nix # Auto-discovers users/shared/{programs,packages}
│   ├── cache-config.nix
│   ├── overlays.nix
│   └── user-info.nix    # Single source of truth for name and email
├── machines/
│   ├── darwin/common.nix  # Shared by every Darwin host
│   └── nixos/             # vm-aarch64-utm, vm-x86_64-utm, vm-shared, hardware/
├── users/shared/
│   ├── home-manager.nix   # Home Manager entry point
│   ├── darwin/            # macOS system settings, Homebrew casks, scripts
│   ├── programs/          # One file (or directory) per tool; .config/ holds raw config files
│   └── packages/          # Categorized package lists (core, dev, cloud, ai, ...)
└── tests/               # unit/, integration/, containers/, lib/
```

### How a Host Is Built

1. `flake-modules/hosts.nix` declares each host's `system`, `class`
   (`darwin` or `nixos`), system `user`, `machineModules`, and optional
   `homeModules` overrides.
2. `flake-modules/systems.nix` passes each entry to `lib/mksystem.nix`.
3. `lib/mksystem.nix` builds a `darwinSystem` or `nixosSystem` and wires in
   Home Manager with `users/shared/home-manager.nix`.
4. `lib/home-modules.nix` imports every module under `users/shared/programs/`
   and `users/shared/packages/`. Each is enabled by default through
   `modules.<category>.<name>.enable` (Darwin-only modules default to macOS only).

## Customization

**Add a package**: add it to the matching category file in
`users/shared/packages/` (for example `dev.nix`), or configure the tool in
`users/shared/programs/<name>.nix`. New files there are imported automatically;
do not edit `home-manager.nix`.

**Add a macOS app**: Homebrew casks go in `users/shared/darwin/homebrew.nix`;
Mac App Store apps go in `masApps` in `users/shared/darwin/default.nix`.

**Disable a module on one host**: set it in that host's `homeModules`, for
example `modules.programs.hammerspoon.enable = false;`.

**Add a host**: add an entry to `dotfiles.hosts` in `flake-modules/hosts.nix`,
then update the expected host list in `tests/integration/machine-builds-test.nix`.

```nix
newmachine = {
  system = "aarch64-darwin";
  class = "darwin";
  user = "newusername";
  machineModules = [ ../machines/darwin/common.nix ];
};
```

**Add a test**: create `tests/unit/<feature>-test.nix` or
`tests/integration/<feature>-test.nix`; it becomes
`checks.<system>.{unit,integration}-<feature>` automatically. Read
[tests/README.md](tests/README.md) first.

## Testing

Every check is a Nix derivation that builds if an assertion holds. See
[tests/README.md](tests/README.md) for the contract and helper inventory.

```bash
make test             # Linux + KVM: build all checks; elsewhere: evaluate only (--no-build)
make test-build       # Build every unit + integration assertion (any platform)
make test-containers  # NixOS VM tests (Linux + /dev/kvm)
```

The NixOS VM tests live in `tests/containers/` (smoke, basic system, services,
packages) and are registered explicitly in `tests/default.nix`.

CI (`.github/workflows/ci.yml`) runs pre-commit, `make test-build`, and a closure
build on Darwin `aarch64-darwin`, NixOS `x86_64-linux`, and NixOS
`aarch64-linux`, then pushes successful builds to Cachix.

## NixOS VMs

```bash
# Build a VM configuration
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'

# Disposable VM smoke test (Linux + KVM only)
nix run .#test-vm
ssh testuser@localhost -p 2222  # password: test
```

To install onto a VM over SSH, the Makefile provides `vm/bootstrap0`,
`vm/bootstrap`, `vm/copy`, `vm/switch`, and `vm/secrets`. They read these
variables:

```bash
export NIXADDR=192.168.64.2    # VM IP address (required)
export NIXPORT=22              # SSH port (default: 22)
export NIXUSER=root            # SSH user (default: root)
export NIXNAME=vm-aarch64-utm  # nixosConfiguration to switch to (default: hostname)
```

## Baleen Toolkit

Home Manager installs the `bl` command:

```bash
bl --help                 # Usage information
bl list                   # Show available commands
bl gc stats               # Show cache, disk, and stale worktree sizes
bl gc --dry-run           # Show cleanup plan without deleting
bl gc                     # Confirm and clean regenerable development data
```

## Claude Code Integration

`users/shared/programs/claude-code.nix` deploys the files in
`users/shared/programs/.config/claude/` (`CLAUDE.md`, `settings.json`,
`statusline.sh`, and a worktree hook) to `~/.claude`. `CLAUDE.md` is refreshed
on every switch; `settings.json` and other runtime-mutated files are copied only
when absent, so local edits survive rebuilds.

Commands, agents, skills, and hooks come from the external plugin
[baleen37/claude-plugins](https://github.com/baleen37/claude-plugins), not from
this repository.

## Herdr Sidebar

`users/shared/programs/herdr.nix` links the
[herdr-sim](https://github.com/baleen37/herdr-sim) plugin pinned in
`flake.lock`. It adds project, branch, and PR tokens to the Agents and Spaces
lists, and a Changes panel that `cmd+p` opens and closes. To develop the plugin
locally, run `herdr plugin link ~/dev/herdr-sim`. Switches leave a link outside
the Nix store in place. Unlink it to go back to the pinned version.

## Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Architecture and commands, written for Claude Code
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Development workflow and guidelines
- **[tests/README.md](./tests/README.md)** - Test contract and helpers
- **[docs/](./docs/)** - Design notes and plans

## Troubleshooting

**Build failures:**

```bash
nix store gc                                           # Clear unused store paths
nix build '.#darwinConfigurations.<your-host>.system'  # Retry
```

**Formatting failure in `make test`**: run `make format`, or `make fmt-diff` to
see the full treefmt diff.

**Container tests fail on macOS**: expected. Use `make test-build` locally and
leave the VM tests to CI.

---

_Nix flakes + evantravers pattern for declarative, reproducible environments._
