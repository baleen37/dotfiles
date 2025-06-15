# Nix Dotfiles: Cross-Platform Development Environment

> **Complete, reproducible development environments for macOS and NixOS**

Declaratively manage your entire development environment using Nix flakes. Everything from packages and configurations to system settings is version-controlled and instantly reproducible across machines.

## ⚡ Quick Start

### Prerequisites
- **Nix** with flakes support ([install guide](https://nixos.org/download))
- **Git** for version control
- **Admin access** for system-level configuration

### 5-Minute Setup

```bash
# 1. Clone the repository
git clone https://github.com/baleen/dotfiles.git
cd dotfiles

# 2. Quick validation
export USER=$(whoami)
make smoke

# 3. Build and apply to your system
make build
nix run --impure .#build-switch  # Requires sudo
```

That's it! Your system now has a complete, reproducible development environment.

## 🏗️ What You Get

### 📦 Comprehensive Package Management
- **46+ development tools** (git, vim, curl, jq, etc.)
- **Cross-platform support**: macOS (Intel + Apple Silicon) and NixOS (x86_64 + ARM64)
- **macOS apps via Homebrew**: 34+ GUI applications managed declaratively
- **Automatic package resolution** across different platforms

### 🔧 Development Tools
- **Global command system**: `bl` dispatcher for project management
- **Automated project setup**: `setup-dev` for instant Nix project initialization
- **Smart configuration preservation**: Claude settings safely preserved during updates
- **Auto-update system**: Background updates with safety checks

### 🧪 Quality Assurance
- **Comprehensive testing**: Unit, integration, e2e, and performance tests
- **CI/CD pipeline**: GitHub Actions with multi-platform validation
- **Pre-commit hooks**: Automated code quality checks
- **Local testing**: Mirror CI pipeline locally with `./scripts/test-all-local`

## 🚀 Essential Commands

### Daily Workflow
```bash
# Set USER (required for all operations)
export USER=$(whoami)

# Core development commands
make lint           # Code quality checks (run before committing)
make build          # Build all platform configurations  
make switch         # Apply configuration to current system
make test           # Run comprehensive test suite
```

### Platform-Specific Operations
```bash
# Build specific platforms
make build-darwin   # macOS configurations only
make build-linux    # NixOS configurations only

# Direct nix commands
nix run .#build         # Build current platform
nix run .#build-switch  # Build and apply immediately (requires sudo)
```

### Available Apps (per Platform)

| Command | aarch64-darwin | x86_64-darwin | aarch64-linux | x86_64-linux |
|---------|:--------------:|:-------------:|:-------------:|:------------:|
| build | ✅ | ✅ | ✅ | ✅ |
| build-switch | ✅ | ✅ | ✅ | ✅ |
| apply | ✅ | ✅ | ✅ | ✅ |
| rollback | ✅ | ✅ | ❌ | ❌ |
| test | ✅ | ✅ | ✅ | ✅ |
| test-unit | ✅ | ✅ | ❌ | ❌ |
| test-integration | ✅ | ✅ | ❌ | ❌ |
| test-e2e | ✅ | ✅ | ❌ | ❌ |
| setup-dev | ✅ | ✅ | ✅ | ✅ |
| SSH key tools | ✅ | ✅ | ✅ | ✅ |

## 📁 Repository Structure

```
├── flake.nix              # Main entry point and system configurations
├── Makefile               # Development workflow automation
├── CLAUDE.md              # Claude Code integration guide
├── CONTRIBUTING.md        # Development and contribution guidelines
├── modules/               # Modular system configuration
│   ├── shared/            #   Cross-platform packages and settings
│   ├── darwin/            #   macOS-specific configuration
│   └── nixos/             #   NixOS-specific configuration
├── hosts/                 # Individual machine configurations
│   ├── darwin/            #   macOS host setups
│   └── nixos/             #   NixOS host setups
├── lib/                   # Nix utility functions
├── scripts/               # Management and development tools
├── tests/                 # Comprehensive test suite
└── docs/                  # Additional documentation
```

## 🛠️ Customization

### Adding Packages
```nix
# For all platforms: modules/shared/packages.nix
{ pkgs }: with pkgs; [
  # Add your package here
  your-new-package
]

# For macOS only: modules/darwin/packages.nix or modules/darwin/casks.nix
# For NixOS only: modules/nixos/packages.nix
```

### Testing Changes
```bash
# Always test before committing
make lint && make build && make test

# Apply locally to test
make switch
```

## 🔧 Advanced Features

### Claude Configuration Preservation
Automatically preserves user customizations during system updates:
- **Smart detection**: SHA256-based change detection
- **Safe updates**: New versions saved as `.new` files
- **Interactive merging**: Resolve conflicts with `./scripts/merge-claude-config`

### Auto-Update System
Keeps your environment current with TTL-based checking:
```bash
./scripts/auto-update-dotfiles         # Manual check (respects 1h TTL)
./scripts/auto-update-dotfiles --force # Force immediate update
```

### Global Command System
Install once, use everywhere:
```bash
./scripts/install-setup-dev    # Install `bl` command system
bl setup-dev my-new-project    # Initialize Nix project anywhere
bl list                        # Show available commands
```

## 📚 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Complete Claude Code integration guide
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Development workflows and standards
- **[docs/ARCHITECTURE.md](./docs/architecture.md)** - System design and architecture
- **[docs/TESTING.md](./docs/testing-framework.md)** - Testing framework and strategies
- **[docs/DEVELOPMENT-SCENARIOS.md](./docs/DEVELOPMENT-SCENARIOS.md)** - Step-by-step development guides

## 🚨 Troubleshooting

### Common Issues

**Build failures:**
```bash
# Ensure USER is set
export USER=$(whoami)

# Clear cache and retry
nix store gc
make build
```

**Permission issues:**
```bash
# build-switch requires sudo from start
sudo nix run --impure .#build-switch
```

**Environment variable issues:**
```bash
# Add to your shell profile for persistence
echo "export USER=\$(whoami)" >> ~/.bashrc  # or ~/.zshrc
```

### Getting Help
- Check [troubleshooting guide](./docs/TROUBLESHOOTING.md) for detailed solutions
- Review [CLAUDE.md](./CLAUDE.md) for development-specific guidance
- Open GitHub issues for bugs or feature requests

## 🎯 Next Steps

1. **Explore the system**: Run `make help` to see all available commands
2. **Customize your setup**: Add packages in `modules/shared/packages.nix`
3. **Learn the testing**: Run `./scripts/test-all-local` to understand quality assurance
4. **Contribute**: See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines

---

> **Architecture**: This system uses Nix flakes with Home Manager and nix-darwin/NixOS for declarative, reproducible environments across all major platforms.
