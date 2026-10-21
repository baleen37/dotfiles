# Windows

Nix does not run natively on Windows, so a Windows PC is set up in two layers:

- **Windows itself**: GUI apps and the WSL2 platform, declared in
  `configuration.winget` and applied with `winget configure`. This is outside
  Nix and only as declarative as winget is.
- **Inside WSL2**: the `wsl` NixOS host (NixOS-WSL), which shares
  `users/shared` Home Manager configuration with the Mac and Linux hosts.

## Setup

1. **Enable WSL and install the apps.** In an administrator terminal, from a
   copy of this repository:

   ```powershell
   winget configure test -f windows\configuration.winget   # what would change
   winget configure -f windows\configuration.winget
   ```

   On a PC that never ran WSL, run `wsl --install --no-distribution` once and
   reboot; it enables the Windows features WSL2 needs.

   To let the Macs ssh in, run `windows\bootstrap-ssh.ps1` in an elevated
   PowerShell. It installs sshd and authorizes the keys from
   https://github.com/baleen37.keys; re-run it after changing keys on GitHub.

2. **Install the NixOS-WSL distro.** Build the tarball on any `x86_64-linux`
   machine with Nix (`make wsl` writes `nixos.wsl` to the current directory), or
   download `nixos.wsl` from the
   [NixOS-WSL releases](https://github.com/nix-community/NixOS-WSL/releases/latest).
   Then on Windows:

   ```powershell
   wsl --install --from-file nixos.wsl
   ```

   Prefer the `make wsl` tarball: it already logs in as `baleen`. A release
   tarball logs in as `nixos` and needs the extra restart in step 3.

3. **First switch.** Inside the distro (`wsl -d NixOS`):

   ```sh
   nix-shell -p git --run 'git clone https://github.com/baleen37/dotfiles ~/dotfiles'
   cd ~/dotfiles
   nix-shell -p gnumake --run 'make switch NIXNAME=wsl'
   ```

   The hostname becomes `wsl`, so later runs are plain `make switch`.

   From a release tarball the login user changes from `nixos` to `baleen`, and
   NixOS-WSL requires `boot` instead of `switch` for that
   ([how-to](https://nix-community.github.io/NixOS-WSL/how-to/change-username.html)).
   Replace the `make switch` line with
   `sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild boot --flake .#wsl`,
   then in PowerShell run `wsl -t NixOS`, `wsl -d NixOS --user root exit`,
   `wsl -t NixOS`, and open the distro again.

## Validating changes

`.github/workflows/windows.yml` runs `winget configure validate` on every change
under `windows/`. It does not install anything.
