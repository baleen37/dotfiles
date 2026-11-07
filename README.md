# Nix Dotfiles

Nix flakes-based dotfiles that build reproducible macOS (nix-darwin) and NixOS
systems, plus standalone Home Manager profiles, from one shared user
configuration. Every test is a Nix derivation, so `nix flake check` is the test
runner.

## Highlights

- **Three platforms**: Darwin `aarch64-darwin`; NixOS `x86_64-linux` and `aarch64-linux`
- **Windows**: NixOS-WSL (`wsl` host) inside WSL2, plus GUI apps from `winget configure` — see [machines/windows/README.md](machines/windows/README.md)
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

Prepare the machine first, then apply its configuration separately:

```bash
./bootstrap.sh
./switch.sh
```

`bootstrap.sh [host]` installs missing CLT and Nix, builds the pinned bootstrap
packages, and prepares 1Password CLI without installing or opening the desktop
app. It enables CLI desktop integration for this run with the official
`OP_BIOMETRIC_UNLOCK_ENABLED=true` environment variable and tries existing
authentication first. It does not change the app's persistent preferences.
With desktop integration enabled, approve access when 1Password asks; no manual
account registration is needed. If authentication is unavailable, bootstrap
falls back to terminal-only `op account add` and `op signin`. Have your sign-in
address, email, Secret Key and account password ready for that fallback.
Set `OP_BIOMETRIC_UNLOCK_ENABLED=false` to use only terminal authentication.
Existing sessions or `OP_SERVICE_ACCOUNT_TOKEN` can authenticate without a GUI.
The default identity is stored in the `Private` vault's `dotfiles/sops` Secure
Note. Its fields are:

| Field           | Type      | Contents                                            |
| --------------- | --------- | --------------------------------------------------- |
| `age-key`       | Concealed | Existing age private key, restored into `keys.txt`  |
| `age-recipient` | Text      | Public `age1…` recipient used to encrypt SOPS files |

Bootstrap reads `age-key` with `op read`, using vault/item IDs so renaming the
item does not break restoration. Override the reference with `--age-key-ref` or
`DOTFILES_AGE_KEY_REF`; never pass the private key itself. The original document
is preserved as `dotfiles/sops (attachment)`. Existing hosts still install their
selected 1Password desktop app during `switch.sh`.

The existing age identity is fetched into a private temporary file, validated,
and installed at `~/.config/sops/age/keys.txt` with mode `0600`. A nonempty existing
identity is checked and preserved. Empty, invalid or symlinked identities fail
without replacement. Declared SOPS files must decrypt before bootstrap reports
secret readiness. When no secrets have been declared, bootstrap validates only
the identity and says so; it does not claim that personal secrets were restored.

For tools without secret restoration, use `./bootstrap.sh --skip-secrets`.
Unknown Macs are registered minimally in the ignored
`flake-modules/hosts.local.nix`. Other selected GUI applications still use
Homebrew; bootstrap prepares it only when the chosen host enables Homebrew.
Every script evaluates a temporary source snapshot containing Git-tracked and
unignored files, plus the explicitly allowed `flake-modules/hosts.local.nix`.
Ignored keys, plaintext backups and private directories are excluded before Nix
can copy the source to the store. Symlinks are preserved rather than followed.
A Git checkout is required, and the snapshot is removed when the script exits.
Both installer downloads retain pinned hashes. Bootstrap never activates the
full system or imports GPG keys. A failed stage exits nonzero; rerun the same
command after resolving the error.

Before a macOS system installation, bootstrap and switch check App Management
permission when the selected host manages GUI apps. If permission is denied or
cannot be checked, they open **System Settings > Privacy & Security > App
Management** and stop before building or activating the system. Allow the app
hosting the terminal (for example Herdr Core), quit and reopen it, then rerun the
same command. `sudo` does not replace this consent. Build-only, standalone Home
Manager, Linux and minimal hosts without GUI apps skip this requirement. On a
fresh Mac, bootstrap installs CLT/Nix first so it can evaluate the host's needs.
App-specific permissions such as Accessibility are granted to those apps when
they run; the installation check does not claim they are ready.
See [ADR 0001](docs/adr/0001-macos-permission-preflight.md) for the decision and
limits of the read-only macOS query.

`switch.sh [host]` checks the selected user's secrets before activation. It
supports the first nix-darwin activation, subsequent Darwin/NixOS switches, and
standalone Home Manager (`HM_USER=jito.hello ./switch.sh --home`).
`./switch.sh --build` builds without activating. Neither switch mode fetches a
key from 1Password. Legacy `./switch.sh` / `make switch-home` delegate to these
scripts. Initial administrator and 1Password authentication remain interactive.

Manual steps:

```bash
# 1. Clone
git clone https://github.com/baleen37/dotfiles.git
cd dotfiles

# 2. Install pre-commit and pre-push hooks
make install-hooks

# 3. Evaluate every supported system
nix flake check --no-build --all-systems --show-trace

# 4. Build a configuration without activating it
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'

# 5a. Activate a standalone Home Manager profile
HM_USER=jito.hello ./switch.sh --home

# 5b. Or activate the full system for this host (see "System Activation")
./switch.sh
```

### Hosts and Profiles

| Output                              | Names                                              |
| ----------------------------------- | -------------------------------------------------- |
| `darwinConfigurations` (aarch64)    | `macbook-pro`, `baleen-macbook`, `kakaostyle-jito` |
| `nixosConfigurations`               | `vm-aarch64-utm`, `vm-x86_64-utm`, `wsl`           |
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

Local builds are accelerated by binary substituters, especially `https://baleen-nix.cachix.org`, `https://nix-community.cachix.org`, and `https://cache.nixos.org/`. When CI pushes a built closure to Cachix on `main` or tags, local `nix build` and `./switch.sh` can download matching store paths instead of rebuilding them.

GitHub `actions/cache` is CI-only. It can speed repeated workflow runs on GitHub-hosted runners, but it does not make local macOS builds faster. Do not store credentials in cached paths.

## Daily Usage

```bash
HM_USER=jito.hello ./switch.sh --home  # Apply user configuration only (no Homebrew casks)
./switch.sh                          # Apply the full system for this host
make format                          # Format with treefmt (nix fmt)
make lint                            # Run all pre-commit hooks
make update                          # Update flake inputs (nix flake update)
```

### System Activation

`./switch.sh` activates the system configuration named after the current
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
HM_USER=jito.hello ./switch.sh --home
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

¹ NixOS VM tests need a Linux builder; Determinate Nix disables the macOS
linux-builder, so run them in CI or a Linux VM.
² Requires `/dev/kvm`. Where it is missing, `make test` degrades to
`nix flake check --no-build`, which evaluates checks without running assertions.
`make test-build` runs the unit and integration assertions on any platform, but it
deliberately excludes the NixOS VM tests — those need `make test-containers` or CI.

### SOPS secrets

Declare real encrypted files in the appropriate machine's Home Manager module:

```nix
home-manager.users.${currentSystemUser} = {
  sops.defaultSopsFile = ../../secrets/personal.yaml;
  sops.secrets.github-ssh = {
    path = "/Users/${currentSystemUser}/.ssh/id_ed25519_github";
    mode = "0600";
  };
  sops.secrets.api-token = { }; # Point the consuming app to this file path.
  sops.secrets.gpg-export = { };
  modules.secrets.gpgImports = [ "gpg-export" ];
};
```

Use the actual home directory on Linux. The example file above is not shipped:
provide your recipient public key and encrypted contents before enabling it.
Use `.sops.yaml` recipients and `sops updatekeys` when adding recipients. Never
commit the private identity, exported plaintext keys or token values.

Secrets install synchronously before dependent Home Manager files are linked.
GPG imports run only after that installation succeeds, preserve the existing
keyring, and are repeatable. Exported GPG keys are supported; ownertrust is not
automatically changed. The normal SOPS login service also restores runtime
secret files after login. Real SSH/GPG authentication still needs verification
with your actual services; synthetic fixture tests do not prove that.

The older `make secrets/backup` and `make secrets/restore` tar targets remain for
compatibility only. They are not used by bootstrap or switch and do not include
the age identity. No new real backup or encrypted personal secret is fabricated
by these scripts.

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
│   ├── nixos/             # vm-aarch64-utm, vm-x86_64-utm, vm-shared, wsl, hardware/
│   └── windows/           # winget configuration for the Windows side (not Nix)
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
   and `users/shared/packages/`. Optional features default to off. Machine files select
   `modules.<category>.<name>.enable` under `home-manager.users.${currentSystemUser}`.
   New hosts receive Zsh, Git, the SSH client and age.

## Customization

**Add a package**: add it to the matching category file in
`users/shared/packages/` (for example `dev.nix`), or configure the tool in
`users/shared/programs/<name>.nix`. New files there are imported automatically;
do not edit `home-manager.nix`.

**Add a macOS app**: edit `homebrew.casks` or `homebrew.masApps` in
`machines/darwin/<host>.nix`. Shared implementations stay in `users/shared/`.

**Disable a module on one host**: edit its machine file, for example
`home-manager.users.${currentSystemUser}.modules.programs.hammerspoon.enable = false;`.
The Mac files also tie Hammerspoon, Karabiner, RustDesk, Herdr and VS Code casks
to their feature switches. Standalone Home Manager selections live in
`flake-modules/home.nix`; `HM_USER` still selects the output.

**Add a host**: add an entry to `dotfiles.hosts` in `flake-modules/hosts.nix`,
then update the expected host list in `tests/integration/machine-builds-test.nix`.

```nix
newmachine = {
  system = "aarch64-darwin";
  class = "darwin";
  user = "newusername";
  machineModules = [ ../machines/darwin/newmachine.nix ];
};
```

Create `machines/darwin/newmachine.nix` with the minimal system import:

```nix
{ ... }:
{
  imports = [ ./common.nix ];
}
```

Import `../../users/shared/darwin` to select the shared macOS preferences,
power daemon and cleanup scripts, then declare apps and user features in this
machine file. Bootstrap registers only the minimal `common.nix` import;
`--skip-secrets` prepares the machine without restoring a key.

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
lists, and a Changes panel that `cmd+shift+c` opens and closes. To develop the plugin
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
