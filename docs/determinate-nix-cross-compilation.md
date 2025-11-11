# Determinate Nix Cross-Compilation Guide

## Overview

This document provides practical approaches for cross-compilation and remote building when using Determinate Nix on macOS.

### Current Situation

- **Determinate Nix**: Manages Nix installation independently
- **nix-darwin**: `nix.enable = false` for compatibility
- **linux-builder**: Disabled (incompatible with Determinate Nix)

## Recommended Solutions

### 1. Standard Nix Distributed Builds

The recommended approach for Determinate Nix users is standard Nix distributed builds.

#### Setup Requirements

1. **Remote Builder Machine** (Linux VM, cloud instance, or dedicated server):
   - Nix installed
   - SSH server running
   - User in `trusted-users` configuration

2. **SSH Configuration**:
```bash
# SSH key setup
ssh-keygen -t ed25519 -C "determinate-nix-builder"
ssh-copy-id user@remote-builder

# Test connection
ssh user@remote-builder "nix --version"
```

#### Configuration

**Option A: Command Line (Temporary)**
```bash
export NIX_REMOTE_SYSTEMS="aarch64-linux=user@remote-builder x86_64-linux=user@remote-builder"
nix build --impure --expr '(with import <nixpkgs> { system = "aarch64-linux"; }; hello)'
```

**Option B: Configuration File (Permanent)**
```bash
# Create ~/.config/nix/machines
mkdir -p ~/.config/nix
cat > ~/.config/nix/machines << EOF
aarch64-linux ssh://user@remote-builder 4 1 big-parallel kvm benchmark
x86_64-linux ssh://user@remote-builder 4 1 big-parallel kvm benchmark
EOF
```

**Option C: Environment Variables**
```bash
# Add to shell profile (zsh, bash)
export NIX_REMOTE_SYSTEMS="aarch64-linux=user@remote-builder x86_64-linux=user@remote-builder"
```

#### Remote Builder Setup (Linux)

```bash
# On remote Linux machine
sudo mkdir -p /etc/nix
sudo tee /etc/nix/nix.conf << EOF
trusted-users = root $(whoami)
build-users-group = nixbld
EOF

# Restart Nix daemon if needed
sudo systemctl restart nix-daemon
```

### 2. Cloud-Based CI/CD Services

#### GitHub Actions

```yaml
# .github/workflows/cross-build.yml
name: Cross-Platform Build

on: [push, pull_request]

jobs:
  build-aarch64:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Install Nix
      uses: DeterminateSystems/nix-installer-action@v4

    - name: Setup Magic Nix Cache
      uses: DeterminateSystems/magic-nix-cache-action@v2

    - name: Build aarch64-linux
      run: |
        nix build --impure --system aarch64-linux .#packages.aarch64-linux.hello

    - name: Build x86_64-linux
      run: |
        nix build --impure --system x86_64-linux .#packages.x86_64-linux.hello
```

#### Determinate FlakeHub Integration

```nix
# flake.nix additions
{
  inputs = {
    # ... existing inputs

    # FlakeHub for private caching (enterprise)
    flakehub.url = "https://flakehub.com/f/DeterminateSystems/magic-nix-cache/main";
  };

  outputs = { self, nixpkgs, ... }: {
    # Your existing outputs

    # Multi-architecture packages
    packages = nixpkgs.lib.genAttrs ["aarch64-linux" "x86_64-linux"] (system: {
      your-package = nixpkgs.legacyPackages.${system}.callPackage ./your-package.nix {};
    });
  };
}
```

### 3. Local QEMU with Binary Substitutes

When remote builders aren't available, use QEMU emulation with pre-built binaries.

#### Configuration

```nix
# Add to your configuration
{
  nix.settings = {
    # Enable binary substitution
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://your-private-cache.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "your-private-cache.cachix.org-1:your-public-key"
    ];

    # QEMU settings for foreign architectures
    system-features = [ "kvm" "big-parallel" "nixos-test" ];
  };
}
```

#### Build Commands

```bash
# Build Linux packages on macOS using QEMU
export NIX_ENFORCE_PURITY=0

# ARM64 Linux package on Apple Silicon Mac
nix build --impure --system aarch64-linux .#packages.aarch64-linux.your-package

# x86_64 Linux package using QEMU emulation
nix build --impure --system x86_64-linux .#packages.x86_64-linux.your-package
```

### 4. Hybrid Approach: Determinate + Remote VM

Use a local VM for Linux builds while maintaining Determinate Nix for the host system.

#### Setup Local VM with Lima

```bash
# Install Lima (macOS Linux VM manager)
brew install lima

# Create Linux VM for builds
limactl start --name=nix-builder template://ubuntu

# Configure VM for Nix builds
limactl shell nix-builder sudo apt-get update
limactl shell nix-builder sudo apt-get install -y curl xz-utils
limactl shell nix-builder bash <(curl -fsSL https://install.determinate.systems/nix)
```

#### Configure as Remote Builder

```bash
# Get VM IP address
VM_IP=$(limactl list nix-builder --json | jq -r '.[0].sshConfig.HostName')

# Add to Nix machines
echo "aarch64-linux ssh://lima-nix-builder@${VM_IP} 4 1 big-parallel" > ~/.config/nix/machines
echo "x86_64-linux ssh://lima-nix-builder@${VM_IP} 4 1 big-parallel" >> ~/.config/nix/machines
```

## Performance Comparison

| Approach | Setup Complexity | Build Speed | Cost | Maintenance |
|----------|------------------|-------------|------|-------------|
| nix-darwin linux-builder | Low | Medium | Free | Medium |
| Determinate + Remote Builder | Medium | Fast | Variable | Medium |
| GitHub Actions | Low | Medium | Free tier | Low |
| QEMU Emulation | Low | Slow | Free | Low |
| Local VM + Lima | Medium | Fast | Free | High |

## Migration Path from nix-darwin linux-builder

If you want to switch back to nix-darwin managed Nix for linux-builder support:

1. **Remove Determinate Nix**:
```bash
sudo /nix/nix-installer uninstall
```

2. **Enable nix-darwin Nix management**:
```nix
# users/shared/darwin.nix
nix = {
  enable = true;
  # ... other settings
};
```

3. **Linux builder will auto-activate**:
```bash
# The existing configuration in machines/macbook-pro.nix will activate
make switch
```

## Troubleshooting

### Common Issues

**SSH Connection Errors**:
```bash
# Test SSH connectivity
ssh -v user@remote-builder "nix --version"

# Check authorized_keys
ssh user@remote-builder "cat ~/.ssh/authorized_keys"
```

**Permission Errors**:
```bash
# Ensure user is in trusted-users
ssh remote-builder "sudo usermod -aG nixbld \$(whoami)"
```

**Build Failures**:
```bash
# Check system features
nix show-config | grep system-features

# Enable QEMU if needed
sudo sysctl -w vm.cs_force_kill=1
```

## Best Practices

1. **Use Binary Substitutes**: Always configure caches first
2. **Start Small**: Test with simple packages before complex builds
3. **Monitor Resources**: Watch memory and disk usage with QEMU
4. **Security**: Use SSH keys, avoid password authentication
5. **Documentation**: Keep your remote builder configuration documented

## Conclusion

Determinate Nix doesn't provide built-in cross-compilation tools, but standard Nix distributed builds offer a robust solution. The main trade-off is losing the convenience of nix-darwin's linux-builder, but gaining Determinate's installation and management benefits.

For most users, the recommended approach is:
1. Use GitHub Actions for CI/CD builds
2. Set up a dedicated remote builder for local development
3. Leverage binary caches to avoid unnecessary rebuilding
4. Keep QEMU as fallback for occasional builds
