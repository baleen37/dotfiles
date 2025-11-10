# Makefile Commands Reference

This document provides comprehensive documentation for all available Makefile targets in the dotfiles repository.

## Overview

The Makefile provides cross-platform support for both Darwin (macOS) and NixOS systems, with automatic platform detection based on `uname`. All commands require the `USER` environment variable to be set for proper operation.

## Environment Variables

### Required Variables

| Variable | Required For | Description | Example |
|----------|--------------|-------------|---------|
| `USER` | All operations | Current username for configuration resolution | `export USER=$(whoami)` |

### Optional Variables

| Variable | Required For | Description | Default | Example |
|----------|--------------|-------------|---------|---------|
| `NIXADDR` | VM operations | IP address of target VM | `unset` | `export NIXADDR=192.168.64.2` |
| `NIXPORT` | VM operations | SSH port for VM connection | `22` | `export NIXPORT=2222` |
| `NIXUSER` | VM operations | SSH username for VM connection | `root` | `export NIXUSER=nixos` |
| `NIXNAME` | All operations | Hostname/flake configuration name | Auto-detected | `export NIXNAME=macbook-pro` |

## System Management Commands

### `switch`

Applies the complete system configuration to the current machine.

**Platform Detection:**
- **Darwin (macOS)**: Uses `nix-darwin` to apply system and user configuration
- **NixOS**: Uses `nixos-rebuild` with `sudo` to apply system configuration

**Usage:**
```bash
export USER=$(whoami)
make switch
```

**What it does:**
- Builds the entire system configuration
- Applies all system settings (kernel, services, etc.)
- Updates user environment (home-manager configuration)
- Installs/updates packages and applications

**Requirements:**
- `USER` environment variable must be set
- Appropriate permissions (sudo on NixOS)
- Valid flake configuration for detected hostname

### `test`

Performs a dry-run build to validate configuration without applying changes.

**Platform Detection:**
- **Darwin (macOS)**: Uses `nix-darwin test` command
- **NixOS**: Uses `nixos-rebuild test` with `sudo`

**Usage:**
```bash
export USER=$(whoami)
make test
```

**What it does:**
- Builds the entire system configuration
- Validates all configuration files and dependencies
- Does NOT apply any changes to the running system
- Useful for testing configuration before deployment

**Requirements:**
- `USER` environment variable must be set
- Valid flake configuration

## Cache Management

### `cache`

Builds and pushes system configuration to cachix for faster future deployments.

**Platform Detection:**
- **Darwin**: Builds `darwinConfigurations.${NIXNAME}.system`
- **NixOS**: Builds `nixosConfigurations.${NIXNAME}.config.system.build.toplevel`

**Usage:**
```bash
export USER=$(whoami)
make cache
```

**What it does:**
- Builds the complete system configuration
- Extracts all build outputs
- Pushes to `baleen-nix` cachix cache

**Requirements:**
- `USER` environment variable must be set
- `cachix` authentication configured (cachix auth token)
- Valid cachix permissions for `baleen-nix` cache

**Prerequisites:**
```bash
# Install cachix (if not already installed)
nix profile install nixpkgs#cachix

# Authenticate with cachix
cachix auth <auth-token>
```

## Secrets Management

### `secrets/backup`

Creates a compressed backup of SSH keys and GPG keyring.

**Usage:**
```bash
make secrets/backup
```

**What it does:**
- Creates `backup.tar.gz` in repository root
- Includes: `~/.ssh/` and `~/.gnupg/` directories
- Excludes temporary files, socket files, and certain config files
- Preserves file permissions and structure

**Excluded Files:**
- GPG socket files (`.#*`, `S.*`)
- GPG config files (`*.conf`)
- SSH environment file (`environment`)

**Output:**
- `backup.tar.gz` created in repository root
- Contains complete SSH and GPG setup for migration

### `secrets/restore`

Restores SSH keys and GPG keyring from backup archive.

**Usage:**
```bash
make secrets/restore
```

**What it does:**
- Extracts `backup.tar.gz` to home directory
- Restores SSH keys to `~/.ssh/`
- Restores GPG keyring to `~/.gnupg/`
- Sets appropriate file permissions
- Creates directories if they don't exist

**Permissions Applied:**
- `~/.ssh/` and `~/.gnupg/`: `700` (drwx------)
- SSH files: `600` (rw-------)
- GPG files: `700` (rwx------)

**Requirements:**
- `backup.tar.gz` must exist in repository root
- Backup must be created with `secrets/backup` command

**Error Handling:**
- Fails with clear error message if backup file doesn't exist
- Continues with permission setting even if some files fail (common with empty directories)

## VM Management

All VM commands require connection variables to be set:

```bash
export NIXADDR=<vm-ip-address>
export NIXPORT=<ssh-port>      # Optional, defaults to 22
export NIXUSER=<ssh-username>  # Optional, defaults to root
```

### `vm/bootstrap0`

Initial NixOS installation on a fresh VM.

**Prerequisites:**
- Fresh VM with NixOS ISO mounted
- Root password set to "root"
- SSH access enabled
- VM IP accessible from host

**Usage:**
```bash
export NIXADDR=192.168.64.2
make vm/bootstrap0
```

**What it does:**
1. **Disk Partitioning:**
   - Creates GPT partition table
   - Sets up three partitions:
     - Primary ext4 partition (nixos, 512MB to -8GB)
     - Linux swap partition (-8GB to 100%)
     - EFI System Partition (1MB to 512MB, FAT32, bootable)

2. **Filesystem Creation:**
   - Formats primary partition as ext4 with label "nixos"
   - Creates swap partition with label "swap"
   - Formats EFI partition as FAT32 with label "boot"

3. **System Installation:**
   - Mounts filesystems to `/mnt`
   - Generates initial NixOS configuration
   - Modifies configuration with required settings:
     - Enables experimental nix features
     - Configures cachix substituters
     - Enables SSH with password authentication
     - Sets root password to "root"
   - Runs `nixos-install`
   - Reboots the system

**SSH Options Used:**
- `-o PubkeyAuthentication=no`: Don't use SSH keys
- `-o UserKnownHostsFile=/dev/null`: Don't use known hosts
- `-o StrictHostKeyChecking=no`: Don't verify host keys

**Post-Installation:**
- VM will reboot with fresh NixOS installation
- SSH access with root/root credentials
- Ready for `vm/bootstrap` command

### `vm/bootstrap`

Complete VM setup with dotfiles and configuration.

**Prerequisites:**
- VM must have completed `vm/bootstrap0`
- VM accessible via SSH with root credentials
- Dotfiles repository accessible

**Usage:**
```bash
export NIXADDR=192.168.64.2
export NIXUSER=root
make vm/bootstrap
```

**What it does:**
1. **Copy Configuration:** Runs `vm/copy` with root user
2. **Apply Configuration:** Runs `vm/switch` with root user
3. **Sync Secrets:** Runs `vm/secrets` to copy SSH/GPG keys
4. **Reboot:** Reboots VM to apply all changes

**Commands Executed:**
```bash
NIXUSER=root make vm/copy
NIXUSER=root make vm/switch
make vm/secrets
ssh root@<NIXADDR> "sudo reboot"
```

### `vm/copy`

Copies dotfiles repository to VM.

**Usage:**
```bash
export NIXADDR=192.168.64.2
export NIXUSER=nixos
make vm/copy
```

**What it does:**
- Uses rsync to copy repository to `/nix-config` on VM
- Excludes development and temporary files:
  - `vendor/`, `.git/`, `.git-crypt/`, `.jj/`, `iso/`
- Uses sudo on remote side for system-level installation
- Preserves file permissions and timestamps

**Excluded Files:**
- `vendor/` - External dependencies
- `.git/` - Git repository data
- `.git-crypt/` - Encrypted git data
- `.jj/` - Jujutsu version control data
- `iso/` - ISO image files

**SSH Options:**
- Same connection options as other VM commands
- Remote rsync executed with sudo privileges

### `vm/switch`

Applies configuration changes on VM without copying files.

**Prerequisites:**
- Files must already be copied with `vm/copy`
- VM accessible via SSH

**Usage:**
```bash
export NIXADDR=192.168.64.2
export NIXUSER=nixos
make vm/switch
```

**What it does:**
- Runs `nixos-rebuild switch` on remote VM
- Uses flake configuration from `/nix-config`
- Applies system configuration changes immediately
- Requires sudo privileges on remote system

**Command Executed:**
```bash
ssh <NIXUSER>@<NIXADDR> "sudo nixos-rebuild switch --flake /nix-config#<NIXNAME>"
```

**Environment Variables Used:**
- `NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1` for cross-platform compatibility
- `NIXNAME` for configuration selection

### `vm/secrets`

Copies SSH keys and GPG keyring to VM.

**Usage:**
```bash
export NIXADDR=192.168.64.2
export NIXUSER=nixos
make vm/secrets
```

**What it does:**
- Copies GPG keyring from `~/.gnupg/` to VM
- Copies SSH keys from `~/.ssh/` to VM
- Excludes sensitive/temporary files:
  - GPG socket files and temporary data
  - SSH environment file
- Uses rsync with same SSH options as other VM commands

**Excluded Files:**
- GPG: `.#*`, `S.*`, `*.conf`
- SSH: `environment`

**Remote Setup:**
- Files copied to respective home directories on VM
- Preserves original permissions
- Ready for immediate use

## WSL Support

### `wsl`

Builds a Windows Subsystem for Linux installer.

**Usage:**
```bash
make wsl
```

**What it does:**
- Builds the `nixosConfigurations.wsl.config.system.build.installer` derivation
- Creates a WSL-compatible NixOS installer
- Outputs the installer to `./result`

**Output:**
- WSL installer available in `./result` directory
- Can be imported into WSL2 on Windows

## Platform-Specific Behavior

### Darwin (macOS) Operations

- Uses `nix-darwin` for system management
- No sudo required for user-level operations
- Supports both system and user configuration
- Compatible with Apple Silicon (aarch64-darwin)

### NixOS Operations

- Uses `nixos-rebuild` for system management
- Requires sudo for all system operations
- Pure NixOS configuration only
- Supports both x86_64-linux and aarch64-linux

### Cross-Platform Support

- Automatic platform detection via `uname`
- Consistent command interface across platforms
- Environment variables work identically
- Flake configuration adapts to platform automatically

## Error Handling

### Common Issues

1. **USER not set:**
   ```
   Error: USER environment variable not set
   Solution: export USER=$(whoami)
   ```

2. **NIXNAME mismatch:**
   ```
   Error: Configuration not found for hostname
   Solution: export NIXNAME=<correct-config-name>
   ```

3. **VM connection failed:**
   ```
   Error: SSH connection refused
   Solution: Check NIXADDR, NIXPORT, and VM network connectivity
   ```

4. **Cache upload failed:**
   ```
   Error: cachix authentication failed
   Solution: Run cachix auth <token> to authenticate
   ```

### Debugging

Use dry-run mode to test commands without execution:

```bash
make -n switch     # Test switch command
make -n test       # Test configuration validation
make -n cache      # Test cache upload process
```

## Integration with CI/CD

The CI pipeline validates these commands across multiple platforms:

1. **Dry-run validation** (`make -n switch`, `make -n test`)
2. **Configuration testing** (`make test`)
3. **Secrets validation** (`make -n secrets/backup`)
4. **Cache upload** (`make cache` - main branch only)

All commands work consistently across local development and CI environments.

## Best Practices

1. **Always set USER variable first:**
   ```bash
   export USER=$(whoami)
   ```

2. **Test before applying:**
   ```bash
   make test      # Validate configuration
   make switch    # Apply changes
   ```

3. **Use consistent VM connection setup:**
   ```bash
   export NIXADDR=192.168.64.2
   export NIXPORT=2222
   export NIXUSER=nixos
   ```

4. **Backup secrets before major changes:**
   ```bash
   make secrets/backup
   ```

5. **Use dry-run for debugging:**
   ```bash
   make -n <command>
   ```

## File Locations

- **Makefile:** `/Users/baleen/dotfiles/Makefile`
- **Backup output:** `/Users/baleen/dotfiles/backup.tar.gz`
- **VM installation:** `/nix-config` on remote VM
- **WSL output:** `./result` (symlink to build output)
