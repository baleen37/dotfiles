# Windows

Windows native apps are declared in `configuration.winget` and applied with
`winget configure`. SSH access is prepared separately with PowerShell.

## Setup

1. **Install the apps.** In an administrator terminal, from a copy of this repository:

   ```powershell
   winget configure test -f machines\windows\configuration.winget   # what would change
   winget configure -f machines\windows\configuration.winget
   ```

2. **Enable SSH access.** In elevated PowerShell:

   ```powershell
   .\machines\windows\bootstrap-ssh.ps1
   ```

   This installs sshd and authorizes the keys from
   [baleen37.keys](https://github.com/baleen37.keys). Re-run it after changing
   keys on GitHub.

## Validating changes

`.github/workflows/windows.yml` runs `winget configure validate` on every change
under `machines/windows/`. It does not install anything.
