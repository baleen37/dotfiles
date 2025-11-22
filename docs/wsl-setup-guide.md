# WSL Setup Guide for baleen37/dotfiles

## Prerequisites

### Windows Requirements
- Windows 11 (recommended) or Windows 10 version 2004+
- WSL2 installed and enabled

### WSL Distribution Options

1. **NixOS-WSL (Recommended)**
   ```bash
   # Install NixOS-WSL
   wsl --import NixOS C:\WSL\NixOS nixos-wsl.tar.gz
   ```

2. **Ubuntu WSL2 with Nix**
   ```bash
   # Install Nix in Ubuntu
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

## Installation

### Step 1: Clone Repository
```bash
git clone https://github.com/baleen37/dotfiles.git
cd dotfiles
```

### Step 2: Apply Configuration
```bash
export USER=nixos
make switch
```

### Step 3: Verify Installation
```bash
# Test basic tools
git --version
zsh --version

# Test aliases
alias | grep -E "(ga|gc|la)"
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**
   ```bash
   # Fix file permissions
   sudo chown -R $USER:$USER ~/.nix-defexpr
   ```

2. **Nix store issues**
   ```bash
   # Clean nix store
   nix-collect-garbage -d
   ```

3. **Home Manager failures**
   ```bash
   # Rebuild home configuration
   nix run .#homeConfigurations.nixos.activationPackage
   ```