# Herdr Setup Design

## Goal

Install Herdr through the existing Nix/Home Manager configuration and give it
the small set of tmux-compatible defaults the user explicitly selected.

Success means:

- `herdr` is provided by the pinned nixpkgs revision, currently version 0.7.5.
- `~/.config/herdr/config.toml` is reproducible from this repository.
- The prefix is `Ctrl-a`.
- Detach and pane splitting use the same keys as the existing tmux setup.
- The manually installed Homebrew copy no longer shadows the Nix binary.
- The Nix configuration and Herdr configuration both validate.

## Current State

- Homebrew provides Herdr 0.7.4 at `/opt/homebrew/bin/herdr`.
- The pinned nixpkgs exposes `pkgs.herdr` 0.7.5.
- No Herdr config file exists.
- No Herdr server is running, so replacing the binary will not terminate an
  active Herdr session.
- Shared programs are implemented as opt-in Home Manager modules under
  `users/shared/programs/` and enabled in `users/shared/home-manager.nix`.

## Approaches Considered

### Minimal tmux-compatible module

Add a dedicated Home Manager module that installs `pkgs.herdr` and declares
only the settings that differ from useful Herdr defaults. This keeps the
configuration small while making the selected tmux habits reproducible.

This is the chosen approach.

### Package and onboarding setting only

Install the package and disable onboarding, leaving Herdr's `Ctrl-b` prefix and
`prefix+q` detach binding unchanged. This is simpler but contradicts the
selected `Ctrl-a` behavior.

### Broad tmux keymap clone

Override most Herdr bindings to mimic tmux. This adds configuration without a
demonstrated need and risks hiding or conflicting with Herdr-specific workspace
and agent controls.

## Home Manager Structure

Create `users/shared/programs/herdr.nix` with:

- `modules.programs.herdr.enable`, following the existing shared-program module
  pattern.
- `home.packages = [ pkgs.herdr ];`.
- A declarative `xdg.configFile."herdr/config.toml"` entry.

Import the module and enable it in `users/shared/home-manager.nix`, next to the
other terminal programs.

No new flake input is needed because the pinned nixpkgs already contains the
required stable package. Shell completions come from the nixpkgs package and do
not need a separate generated file.

## Herdr Configuration

The managed TOML file contains only:

```toml
onboarding = false

[update]
channel = "stable"
version_check = false

[keys]
prefix = "ctrl+a"
detach = "prefix+d"
split_vertical = "prefix+|"
split_horizontal = "prefix+minus"
```

`version_check` is disabled because Nix, rather than Herdr's self-updater,
owns upgrades. The stable channel remains explicit so Herdr's other
channel-aware behavior does not opt into previews.

Herdr's existing defaults already provide tmux-like new-tab, previous/next-tab,
close-pane, and `h/j/k/l` pane navigation bindings. They will not be repeated.
Theme, mouse behavior, notifications, agent integrations, and experimental
features remain unchanged.

## Migration

Apply the Home Manager/nix-darwin configuration first and verify that the Nix
profile contains Herdr 0.7.5. Then uninstall the Homebrew formula so
`/opt/homebrew/bin/herdr` no longer wins earlier in `PATH`.

Before removal, recheck that no Herdr server is running. If one has started in
the meantime, do not stop it automatically because server shutdown terminates
its pane processes; report that the migration cleanup must wait instead.

The existing runtime logs, sockets, release notes, and session metadata under
`~/.config/herdr/` are not deleted.

## Verification

1. Format and evaluate the Nix configuration.
2. Build the target nix-darwin configuration.
3. Apply it to the current machine.
4. Validate the managed TOML with `herdr config check`.
5. Confirm `herdr --version` reports 0.7.5 and `command -v herdr` resolves to
   the Nix-managed profile rather than Homebrew.
6. Confirm the Homebrew formula is absent.

No interactive Herdr session is launched during verification because doing so
would create runtime state and take over the current terminal.
