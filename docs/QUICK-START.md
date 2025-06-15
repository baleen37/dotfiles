# Quick Start Guide

> **Get up and running with Nix dotfiles in 10 minutes**

This guide will walk you through installing and configuring the Nix dotfiles system from scratch, even if you've never used Nix before.

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

# Install Nix with flakes support
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**For Linux:**
```bash
# Install Nix with flakes support
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Option B: Official Nix Installer

If you prefer the official installer, you'll need to enable flakes manually.

```bash
# Install Nix
curl -L https://nixos.org/nix/install | sh

# Enable flakes (after installation)
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Verify Installation

```bash
# Check Nix version (should be 2.4+)
nix --version

# Test flakes support
nix flake --help
```

**Expected output:**
```
nix (Nix) 2.19.2
Usage: nix flake COMMAND
```

## 📥 Step 2: Clone and Validate

### Clone the Repository

```bash
# Navigate to your preferred directory
cd ~

# Clone the dotfiles repository
git clone https://github.com/baleen/dotfiles.git
cd dotfiles
```

### Set Required Environment Variable

The system needs to know which user to configure for:

```bash
# Set USER environment variable (required for all operations)
export USER=$(whoami)

# Verify it's set correctly
echo "User: $USER"
```

### Quick Validation

Before making any system changes, let's validate the configuration:

```bash
# Quick syntax and structure check (no building)
make smoke
```

**Expected output:**
```
✅ USER is set to: yourusername
nix flake check --impure --all-systems --no-build
warning: Git tree '/path/to/dotfiles' is dirty
```

**Note:** The "dirty" warning is normal if you've made any local changes.

## 🏗️ Step 3: Build Configuration

### Test Build Without Applying

First, let's build everything to make sure it works:

```bash
# Build all platform configurations
make build
```

This process will:
- Download and cache all required packages
- Build system configurations for all platforms
- Validate all module dependencies
- **Take 10-30 minutes on first run** (subsequent builds are much faster)

**Expected output:**
```
🔨 Building Linux configurations with USER=yourusername...
🔨 Building Darwin configurations with USER=yourusername...
✅ All builds completed successfully with USER=yourusername
```

### What Gets Installed

When you apply the configuration, you'll get:

**Core Development Tools:**
- Git, Vim, Curl, jq, tree, htop
- Programming languages and tools
- Shell utilities and productivity tools
- **46+ packages total**

**macOS Additional Features:**
- **34+ GUI applications** via Homebrew casks
- Docker, Visual Studio Code, browsers
- Productivity and development apps

## ⚡ Step 4: Apply to Your System

### Option A: Quick Apply (Recommended)

Apply the configuration immediately with a single command:

```bash
# Build and apply in one step (requires sudo)
sudo nix run --impure .#build-switch
```

**What happens:**
1. Builds the configuration for your current platform
2. Applies it to your system immediately
3. Updates system settings and installs packages
4. Preserves existing user data and settings

### Option B: Step-by-Step Apply

If you prefer more control:

```bash
# Build first
make build

# Then apply (will auto-detect your system)
make switch
```

### Platform-Specific Application

If auto-detection doesn't work or you want to be explicit:

```bash
# For Apple Silicon Mac
make switch HOST=aarch64-darwin

# For Intel Mac  
make switch HOST=x86_64-darwin

# For x86_64 Linux
make switch HOST=x86_64-linux

# For ARM64 Linux
make switch HOST=aarch64-linux
```

## ✅ Step 5: Verify Installation

### Test Core Commands

```bash
# Test that new packages are available
jq --version
tree --version
git --version

# On macOS, test GUI apps
open -a "Visual Studio Code"  # Should open if you have casks enabled
```

### Test Development Workflow

```bash
# Create a test project
nix run .#setup-dev test-project
cd test-project

# Should have created:
ls -la
# Expected: flake.nix, .envrc, .gitignore
```

### Test Auto-Update System

```bash
# Test the auto-update system (won't actually update if recent)
./scripts/auto-update-dotfiles
```

## 🔧 Step 6: Basic Customization

### Add Your First Package

Let's add a package to see how customization works:

```bash
# Edit the shared packages file
$EDITOR modules/shared/packages.nix

# Add a package to the list (keep alphabetical order)
# For example, add 'htop' if it's not already there
```

**Example edit:**
```nix
{ pkgs }:

with pkgs; [
  # ... existing packages ...
  htop          # System monitor (your addition)
  # ... more packages ...
]
```

### Test Your Change

```bash
# Build with your change
make build

# Apply if build succeeds
make switch
```

### Verify Your Package

```bash
# Test that your new package works
htop --version
which htop
```

## 🎯 Next Steps

Now that you have a working system, here are recommended next steps:

### 1. Explore Available Commands
```bash
# See all available development commands
make help

# List all available nix apps
nix flake show
```

### 2. Install Global Tools
```bash
# Install the 'bl' command system for global project management
./scripts/install-setup-dev

# After installation, you can use 'bl' commands anywhere
bl list
bl setup-dev my-new-project
```

### 3. Learn the Testing System
```bash
# Run comprehensive local tests
./scripts/test-all-local
```

### 4. Understand the Architecture
```bash
# Read the comprehensive guides
cat CLAUDE.md                    # Claude Code integration
cat CONTRIBUTING.md              # Development workflow
cat docs/ARCHITECTURE.md         # System design
```

### 5. Set Up Persistent Environment

Add to your shell profile to make the USER variable persistent:

**For Bash:**
```bash
echo "export USER=\$(whoami)" >> ~/.bashrc
source ~/.bashrc
```

**For Zsh:**
```bash
echo "export USER=\$(whoami)" >> ~/.zshrc
source ~/.zshrc
```

## 🚨 Common Issues and Solutions

### "USER variable not set" Error

```bash
# Solution: Always export USER before nix commands
export USER=$(whoami)

# Or use the impure flag
nix run --impure .#build
```

### Build Takes Too Long

```bash
# Use smoke test for quick validation
make smoke

# Clear cache if builds seem stuck
nix store gc
```

### Permission Denied During Switch

```bash
# Ensure you use sudo for build-switch
sudo nix run --impure .#build-switch

# Or use the two-step process
make build
sudo make switch
```

### macOS Command Line Tools Missing

```bash
# Install XCode Command Line Tools
xcode-select --install

# Wait for installation to complete, then retry
```

### Homebrew Integration Issues (macOS)

```bash
# If Homebrew apps don't install, try rebuilding
sudo nix run --impure .#build-switch

# Check Homebrew status
brew doctor
```

## 📚 Getting Help

- **Complete command reference**: [docs/REFERENCE.md](./REFERENCE.md)
- **Development guides**: [docs/DEVELOPMENT-SCENARIOS.md](./DEVELOPMENT-SCENARIOS.md)
- **Claude Code integration**: [CLAUDE.md](../CLAUDE.md)
- **Contributing guidelines**: [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Architecture details**: [docs/ARCHITECTURE.md](./ARCHITECTURE.md)

## 🎉 Success!

You now have a complete, reproducible development environment!

The system will:
- ✅ Keep your packages and configurations in sync
- ✅ Allow you to reproduce this exact setup on any supported machine
- ✅ Automatically preserve your personal customizations during updates
- ✅ Provide comprehensive testing and quality assurance tools

Welcome to declarative system management with Nix!
