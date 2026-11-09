# Nix Dotfiles

Nix flakes-based dotfiles that build reproducible macOS (nix-darwin) and NixOS
systems, plus standalone Home Manager profiles, from one shared user
configuration. Tests are Nix derivations: `make test-build` executes unit and integration
checks; NixOS VM tests require Linux with KVM.

## Highlights

- **Host platforms**: macOS `aarch64-darwin` and NixOS-WSL `x86_64-linux`; shared checks and tools also support `aarch64-linux`
- **Windows**: NixOS-WSL (`wsl` host) inside WSL2, plus GUI apps from `winget configure` — see [machines/windows/README.md](machines/windows/README.md)
- **Native remote access**: `./switch.sh` uses Nix/Homebrew on macOS and APT on Debian, then applies shared sops-backed policy — see [docs/remote-access.md](docs/remote-access.md)
- **Typed host declarations**: every machine is one entry in `flake-modules/hosts.nix`
- **One user configuration**: `users/shared/` is shared by every host and Home Manager profile
- **Assertions as derivations**: unit, integration, and NixOS VM tests all run through `nix flake check`
- **Claude Code setup**: `CLAUDE.md`, settings, and statusline deployed to `~/.claude`

## Quick Start

```bash
git clone https://github.com/baleen37/dotfiles.git
cd dotfiles
./bootstrap.sh
./switch.sh
```

Run these commands as your normal user. You need Git and administrator access;
bootstrap installs missing Xcode Command Line Tools, Determinate Nix and the
selected host's Homebrew prerequisites. Installer downloads are hash-verified.
Apple's CLT dialog and initial authentication may require your input.

| Command                            | What it does                                                           |
| ---------------------------------- | ---------------------------------------------------------------------- |
| `./bootstrap.sh`                   | Prepare tools and the existing age identity; never activate the system |
| `./switch.sh --build`              | Build without activation; on Debian, validate declarations only        |
| `./switch.sh`                      | Check secrets and apply the selected configuration                     |
| `HM_USER=baleen-linux ./switch.sh` | Select a standalone profile on Linux outside NixOS and Debian          |

Both scripts select the local host with `hostname -s`; host arguments and
`NIXNAME` overrides are not supported for local bootstrap or switch.
Every normal switch requires a valid age identity, even without declared secrets.
Build-only verification skips identity and decryption checks.
Unknown Macs receive a minimal registration in the ignored
`flake-modules/hosts.local.nix`: Zsh, Git, the SSH client and age, without GUI apps
or optional development tools. Select additional features in a machine file.

### 1Password and secret preparation

Bootstrap prepares the pinned 1Password CLI without installing or opening the
desktop app. Existing hosts install their selected desktop app during switch.

1. Bootstrap validates and preserves an existing age identity if present.
2. Otherwise, it reuses 1Password desktop authentication when available. Approve
   the access request. If unavailable, it falls back to terminal `op account add`
   and `op signin`; have your sign-in address, email, Secret Key and password ready.
3. It reads `Private / dotfiles/sops / age-key`, validates the identity, and
   installs it at `~/.config/sops/age/keys.txt` with mode `0600`.
4. It checks decryption of declared SOPS files before reporting readiness.

| Secure Note field | Type      | Contents                                |
| ----------------- | --------- | --------------------------------------- |
| `age-key`         | Concealed | Existing age private key                |
| `age-recipient`   | Text      | Public `age1…` recipient for encryption |

The default reference uses vault/item IDs so renaming the note is safe. Override
it with `DOTFILES_AGE_KEY_REF=op://vault/item/field`; never pass
key material as an argument. Set `OP_BIOMETRIC_UNLOCK_ENABLED=false` for terminal
authentication only. Existing CLI sessions or `OP_SERVICE_ACCOUNT_TOKEN` also work.

Invalid, empty or symlinked identities fail without replacement. No personal
SOPS secrets are currently declared: `No secrets declared for this configuration`
is expected and does not mean personal SSH/GPG keys were restored. Switch never
fetches keys from 1Password. A valid identity is still required when no secrets
are declared. See [SOPS secrets](#sops-secrets) to declare them.

On Debian, bootstrap installs native prerequisites and prepares the identity;
switch applies remote-access secrets and services. `SOPS_AGE_KEY_FILE` selects
the Debian identity path. `./switch.sh --build` validates the declaration without
installing packages, retrieving keys or applying services.

### macOS permissions

For hosts managing GUI apps, bootstrap and switch check **System Settings >
Privacy & Security > App Management**. If denied or unavailable, they open that
pane and stop. Allow the app hosting the terminal (for example Herdr Core), quit
and reopen it, then rerun the command. `sudo` does not grant this consent.

Build-only, standalone Home Manager and minimal hosts without GUI apps skip this
check. On a fresh Mac, the check waits until Nix can evaluate the host. Grant
app-specific permissions, such as Hammerspoon Accessibility, when needed.
See [ADR 0001](docs/adr/0001-macos-permission-preflight.md).

### Repeated runs without a sudo password

Bootstrap requests administrator authentication only when CLT, Nix or Homebrew
actually needs installation. Re-running it with those prerequisites installed
does not request sudo authentication; 1Password authentication is separate.

The `macbook-pro.nix` machine configuration allows passwordless sudo for its
selected host's `darwin-rebuild switch` and `nh clean all --keep 3`. This includes
local host registrations and the filtered temporary source used by `switch.sh`.
Apply once interactively with `./switch.sh` to install the sudo rules; that first
application still needs administrator authentication. Other hosts keep their
existing policies. See [ADR 0003](docs/adr/0003-passwordless-repeat-bootstrap-and-switch.md).

### Hosts and profiles

| Output                                    | Names                                              |
| ----------------------------------------- | -------------------------------------------------- |
| `darwinConfigurations` (`aarch64-darwin`) | `macbook-pro`, `baleen-macbook`, `kakaostyle-jito` |
| `nixosConfigurations`                     | `wsl`                                              |
| `homeConfigurations`                      | `baleen`, `jito.hello`, `testuser`, `baleen-linux` |

Host users are declared in `flake-modules/hosts.nix`. `HM_USER` selects only a
standalone Home Manager output; it does not change a host's system user.
On Linux outside NixOS and Debian, standalone mode is selected automatically.
Without `HM_USER`, it selects the unique profile matching the login
user and platform. An explicit profile for a different platform is rejected.
For Windows/WSL installation, follow [the platform guide](machines/windows/README.md).

### Nix Cache Behavior

Local builds are accelerated by binary substituters, especially `https://baleen-nix.cachix.org`, `https://nix-community.cachix.org`, and `https://cache.nixos.org/`. When CI pushes a built closure to Cachix on `main` or tags, local `nix build` and `./switch.sh` can download matching store paths instead of rebuilding them.

GitHub `actions/cache` is CI-only. It can speed repeated workflow runs on GitHub-hosted runners, but it does not make local macOS builds faster. Do not store credentials in cached paths.

## Daily Usage

```bash
./switch.sh                          # Apply the full system for this host
make format                          # Format with treefmt (nix fmt)
make lint                            # Run all pre-commit hooks
make update                          # Update flake inputs (nix flake update)
```

### Platform Capability Matrix

| Make target         | Darwin (`aarch64-darwin`) | NixOS (`x86_64-linux`) | NixOS (`aarch64-linux`) |
| ------------------- | :-----------------------: | :--------------------: | :---------------------: |
| **Core Operations** |                           |                        |                         |
| switch              |            ✅             |           ✅           |           ✅            |
| format              |            ✅             |           ✅           |           ✅            |
| **Testing**         |                           |                        |                         |
| test                |            ✅             |           ✅           |           ✅            |
| test-build          |            ✅             |           ✅           |           ✅            |
| test-containers     |            ❌¹            |          ✅²           |           ✅²           |

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
│   ├── packages.nix     # Bootstrap tool package
│   ├── dev-shells.nix   # nix develop shell
│   └── formatter.nix    # treefmt (nixfmt, statix, deadnix, shfmt, prettier)
├── lib/
│   ├── mksystem.nix     # System factory (Darwin or NixOS + Home Manager)
│   ├── home-modules.nix # Auto-discovers users/shared/{programs,packages}
│   ├── cache-config.nix
│   ├── overlays.nix
│   └── user-info.nix    # Single source of truth for name and email
├── machines/
│   ├── darwin/
│   │   ├── common.nix         # Minimal shared system and 1Password downgrade guard
│   │   ├── macbook-pro.nix    # Per-host apps and user features
│   │   ├── baleen-macbook.nix
│   │   └── kakaostyle-jito.nix
│   ├── nixos/             # NixOS-WSL host
│   └── windows/           # winget configuration for the Windows side (not Nix)
├── users/shared/
│   ├── home-manager.nix   # Home Manager entry point
│   ├── darwin/            # macOS system settings, Homebrew casks, scripts
│   ├── programs/          # One file (or directory) per tool; .config/ holds raw config files
│   └── packages/          # Categorized package lists (core, dev, cloud, ai, ...)
└── tests/               # unit/, integration/, containers/, lib/
```

### Source and secrets boundary

Bootstrap and switch evaluate a temporary snapshot of Git-tracked and unignored
files, plus the explicitly allowed `flake-modules/hosts.local.nix`. Ignored keys
and plaintext backups are excluded before Nix copies source into the store.
Symlinks are preserved; the snapshot is removed on exit. Keep private data
outside the repository and never track it.

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
machine file. Bootstrap registers only the minimal `common.nix` import and
prepares a valid age identity before reporting readiness.

**Add a test**: create `tests/unit/<feature>-test.nix` or
`tests/integration/<feature>-test.nix`; it becomes
`checks.<system>.{unit,integration}-<feature>` automatically. Read
[tests/README.md](tests/README.md) first.

## Testing

Every check is a Nix derivation that builds if an assertion holds. For development,
install pre-commit and run `make install-hooks` once. See
[tests/README.md](tests/README.md) for the contract and helper inventory.

```bash
make test             # Linux + KVM: build all checks; elsewhere: evaluate only (--no-build)
make test-build       # Build every unit + integration assertion (any platform)
make test-containers  # NixOS VM tests (Linux + /dev/kvm)
```

The NixOS VM tests live in `tests/containers/` (smoke, basic system, services,
packages) and are registered explicitly in `tests/default.nix`.

CI (`.github/workflows/ci.yml`) runs pre-commit, `make test-build`, and a closure
build on Darwin `aarch64-darwin` and NixOS-WSL `x86_64-linux`, plus bootstrap
tools on `aarch64-linux`, then pushes successful builds to Cachix.

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

**1Password will not start after a switch:** a downgraded app may be unable to
read a database written by a newer version (`UnknownSchema` in the app log).
The Darwin package is pinned in `lib/overlays.nix`; activation refuses to replace
a newer installed version with an older one. Update the package version, download
URL and hash together, build it, then apply with `./switch.sh`. Preserve the
existing vault data; deleting it does not resolve the version mismatch.

**direnv reports a missing profile:** allow cache regeneration to finish. An
`interrupted by the user` message means it was cancelled. Rerun `direnv reload`;
a successful later entry reports `Using cached dev shell`.

**Build failures:** fix the reported evaluation or build error, then retry
`./switch.sh --build`. On Linux outside NixOS and Debian this builds the selected
standalone Home Manager profile; use `HM_USER` to select a different matching profile.

**Formatting failure in `make test`**: run `make format`, or `make fmt-diff` to
see the full treefmt diff.

**Container tests fail on macOS**: expected. Use `make test-build` locally and
leave the VM tests to CI.

---

_Nix flakes + evantravers pattern for declarative, reproducible environments._
