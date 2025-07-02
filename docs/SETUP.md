# Nix Dotfiles Setup Guide

> **Complete installation and configuration guide for new users**

This guide provides step-by-step instructions for setting up the Nix dotfiles system on macOS or NixOS.

## Prerequisites

### System Requirements

- **Supported Platforms**:
  - macOS 11+ (Intel and Apple Silicon)
  - NixOS 21.11+
  - Administrative privileges required

### Required Software

1. **Nix Package Manager** with flakes support:
   ```bash
   # Install Nix (if not already installed)
   curl -L https://nixos.org/nix/install | sh -s -- --daemon

   # Enable flakes (add to ~/.config/nix/nix.conf)
   experimental-features = nix-command flakes
   ```

2. **Git** for repository management:
   ```bash
   # macOS (via Homebrew)
   brew install git

   # NixOS (usually pre-installed)
   nix-env -iA nixos.git
   ```

## Installation

### 1. Repository Setup

```bash
# Clone the repository
git clone https://github.com/baleen37/dotfiles.git
cd dotfiles

# Set user context (required)
export USER=$(whoami)
```

### 2. System Validation

```bash
# Quick flake validation
make smoke

# Platform information
make platform-info
```

### 3. Build Verification

```bash
# Build all configurations (8-12 minutes)
make build

# OR build current platform only (1-2 minutes)
make build-current
```

### 4. System Application

```bash
# Apply configuration to current system
nix run --impure .#build-switch
```

**Note**: `build-switch` handles sudo permissions automatically. It will:
1. Request administrator password once at start
2. Build the configuration
3. Apply to your system
4. Clean up permissions

## Post-Installation

### Verification

```bash
# Verify installation
make test

# Check system status
make platform-info
```

### Shell Configuration

Add persistent user setting to your shell profile:

```bash
# For Zsh (default on macOS)
echo "export USER=\$(whoami)" >> ~/.zshrc

# For Bash
echo "export USER=\$(whoami)" >> ~/.bashrc

# Reload configuration
source ~/.zshrc  # or ~/.bashrc
```

### Claude Code Integration (Optional)

If you use Claude Code, the AI integration is automatically configured:

```bash
# Restart Claude Code to load new configuration
# Verify with: /help
```

## Common Operations

### Daily Usage

```bash
# Before making changes
export USER=$(whoami)

# Development workflow
make lint           # Code quality checks
make build-current  # Fast current platform build
make test           # Run test suite
make switch         # Apply changes
```

### Package Management

```bash
# Add cross-platform packages
# Edit: modules/shared/packages.nix

# Add macOS-specific packages
# Edit: modules/darwin/packages.nix

# Add macOS GUI applications
# Edit: modules/darwin/casks.nix

# Add NixOS-specific packages
# Edit: modules/nixos/packages.nix
```

### Global Tools Installation

```bash
# Install bl command system
./scripts/install-setup-dev

# Available commands
bl setup-dev <project>    # Create Nix project
bl list                   # Show commands
```

## Troubleshooting

### Build Issues

**Flake validation errors**:
```bash
# Check flake structure
nix flake check --impure --no-build

# Update flake inputs
nix flake update
```

**Permission problems**:
```bash
# Ensure sudo access
sudo -v

# Manual permission handling
sudo -E USER=$USER nix run --impure .#build-switch
```

**Environment variable issues**:
```bash
# Verify USER is set
echo $USER

# Set if missing
export USER=$(whoami)
```

### Platform-Specific Issues

**macOS**:
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Restart terminal after Nix installation

**NixOS**:
- Ensure system is up to date: `sudo nixos-rebuild switch --upgrade`
- Check disk space: `df -h`

### Getting Help

1. **Documentation**: Review [troubleshooting guide](./TROUBLESHOOTING.md)
2. **Testing**: Run `./scripts/test-all-local` for comprehensive validation
3. **Support**: Open [GitHub issues](https://github.com/baleen37/dotfiles/issues) for bugs

## Advanced Configuration

### Custom Modifications

1. **Module Structure**: Follow the modular architecture in `modules/`
2. **Testing**: Always run `make lint && make build && make test`
3. **Backup**: Configuration changes are automatically backed up

### Performance Optimization

```bash
# Fast builds for development
make build-fast

# Parallel testing
make test-parallel

# Build time comparison
make build-time
```

### Auto-Updates

```bash
# Enable automatic updates (respects 1-hour TTL)
./scripts/auto-update-dotfiles

# Force immediate update
./scripts/auto-update-dotfiles --force
```

## Next Steps

1. **Explore**: Run `make help` to see all available operations
2. **Customize**: Add your preferred packages and configurations
3. **Learn**: Study the [architecture documentation](./architecture.md)
4. **Contribute**: Review [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines

---

**Success**: You now have a complete, reproducible development environment with 50+ tools, optimized configurations, and optional AI integration.
