# Installation Guide

> **Complete setup guide for Nix dotfiles - get running in 10 minutes**

This guide walks you through installing and configuring the Nix dotfiles system from scratch, covering everything from Nix installation to system configuration.

## 📋 Prerequisites

### System Requirements
- **macOS 10.15+** or **NixOS 22.05+** or **Linux with Nix installed**
- **Administrator/sudo access** for system-level configuration
- **Internet connection** for downloading packages
- **Git** for version control

### Supported Platforms
- ✅ **macOS Apple Silicon** (aarch64-darwin)
- ✅ **macOS Intel** (x86_64-darwin)
- ✅ **Linux x86_64** (x86_64-linux)
- ✅ **Linux ARM64** (aarch64-linux)

## 🚀 Step 1: Install Nix

### Option A: Determinate Systems Installer (Recommended)

This installer provides the best experience with flakes enabled by default.

**For macOS:**
```bash
# Install Command Line Tools first
xcode-select --install

# Install Nix with Determinate Systems installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**For Linux:**
```bash
# Install Nix with Determinate Systems installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Option B: Official Nix Installer

If you prefer the official installer:

```bash
# Install Nix
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# Enable flakes (add to ~/.config/nix/nix.conf)
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Verify Installation

```bash
# Verify Nix is installed and flakes are enabled
nix --version
nix flake --help
```

## 📦 Step 2: Clone Repository

```bash
# Clone the dotfiles repository
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# Make sure you're on the main branch
git checkout main
```

## ⚙️ Step 3: Initial Configuration

### Set Your Username
```bash
# Set your username environment variable
export USER=$(whoami)

# Or set a specific username
export USER=your-username
```

### Choose Your Configuration Method

#### Method A: Quick Apply (Recommended for First Time)
```bash
# Run the apply script for your platform
./apps/$(nix eval --impure --raw --expr 'builtins.currentSystem')/apply
```

#### Method B: Build and Switch Separately
```bash
# Build the configuration first
make build

# Then apply it
make switch HOST=your-hostname
```

### Platform-Specific Notes

**macOS:**
- The system will prompt for administrator password
- Homebrew packages will be installed automatically
- System preferences will be configured

**NixOS:**
- Requires sudo privileges for system rebuild
- Network configuration may be updated
- System will reboot if kernel changes are made

## 🔧 Step 4: Customization

### Basic Customization
1. **Edit packages**: Modify `modules/shared/packages.nix`
2. **Configure shell**: Update shell settings in `modules/shared/`
3. **Add dotfiles**: Place configuration files in `modules/shared/config/`

### Advanced Configuration
- **Platform-specific packages**: Edit `modules/darwin/packages.nix` or `modules/nixos/packages.nix`
- **System settings**: Modify platform-specific configurations
- **Custom overlays**: Add packages to `overlays/`

## ✅ Step 5: Verification

### Test Your Installation
```bash
# Verify core tools are available
which git zsh vim

# Test build system
make build

# Check system status
nix flake check --impure
```

### Common Issues

**Issue: Flakes not enabled**
```bash
# Solution: Enable flakes in Nix configuration
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**Issue: Permission denied during build**
```bash
# Solution: Ensure USER environment variable is set
export USER=$(whoami)
```

**Issue: Build fails on macOS**
```bash
# Solution: Install Command Line Tools
xcode-select --install
```

## 🔄 Regular Updates

### Update System
```bash
# Update flake inputs
nix flake update

# Rebuild system
make build && make switch HOST=your-hostname
```

### Backup and Recovery
```bash
# Create backup before major changes
git checkout -b backup/$(date +%Y-%m-%d)

# Rollback if needed (NixOS)
sudo nixos-rebuild switch --rollback

# Rollback if needed (macOS)
nix-env --rollback
```

## 📚 Next Steps

After successful installation:

1. **Read CLAUDE.md** for comprehensive usage guide
2. **Explore modules** in `modules/shared/` for configuration options
3. **Set up development tools** with `./scripts/setup-dev`
4. **Configure Claude integration** (see docs/CLAUDE-INTEGRATION.md)

## 🆘 Getting Help

- **Documentation**: See other files in `docs/` directory
- **Troubleshooting**: Check `docs/TROUBLESHOOTING.md`
- **Issues**: Create GitHub issue with system information
