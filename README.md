# dotfiles: Declarative macOS & NixOS Environment

> **Complete development environment management with Nix flakes, Home Manager, and nix-darwin**

Fully reproducible, cross-platform development environments managed as code. Deploy identical setups across macOS and NixOS systems with a single command.

## 🚀 Overview

This repository provides a comprehensive solution for managing development environments using **Nix flakes**, **Home Manager**, and **nix-darwin**. Everything is declaratively configured as code, ensuring complete reproducibility across different machines and platforms.

### ✨ Key Features

- **🔄 Complete Reproducibility**: Every setting, package, and configuration managed as code
- **🌐 Multi-Platform Support**: macOS (Intel/Apple Silicon) and NixOS (x86_64/aarch64)
- **🛡️ Smart Configuration Preservation**: Automatic preservation of user customizations during updates
- **🧪 Comprehensive Testing**: Full CI/CD pipeline with unit, integration, and e2e tests
- **⚡ Developer-Friendly Tools**: `bl` command system and automated project initialization
- **📦 Advanced Package Management**: Custom overlays and cross-platform package resolution

## 🏗️ Architecture

### System Structure
- **Nix Flakes Foundation**: Fully reproducible environment declarations
- **Modular Design**: Shared, platform-specific, and host-specific modules
- **Integrated Management**: Home Manager + nix-darwin + NixOS unified approach

### Supported Platforms
- **macOS**: Intel (x86_64) and Apple Silicon (aarch64)
- **NixOS**: x86_64 and aarch64 architectures
- **Cross-Platform**: Unified package and configuration management

### Development Tools
- **bl Command System**: Global command dispatcher and tool management
- **setup-dev**: Automated Nix project initialization with flake.nix and direnv
- **auto-update-dotfiles**: TTL-based automatic system updates with safety checks
- **merge-claude-config**: Interactive configuration merger for safe updates
- **test-all-local**: Comprehensive local testing mirroring CI pipeline
- **Smart Configuration Preservation**: Intelligent user customization protection
- **Integrated Workflows**: Makefile-based development processes

### Quality Assurance
- **CI/CD Pipeline**: GitHub Actions with multi-platform matrix testing
- **Comprehensive Testing**: Unit, integration, e2e, and performance test suites
- **Code Quality**: Automated pre-commit hooks and linting
- **Build Validation**: Cross-platform build verification

## 📚 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Comprehensive guide for working with this repository
- **[Architecture Overview](./docs/architecture.md)** - System design and module hierarchy
- **[API Reference](./docs/api-reference.md)** - Complete function and module documentation
- **[Testing Framework](./docs/testing-framework.md)** - Test structure and guidelines
- **[Module Library](./docs/MODULE-LIBRARY.md)** - Available modules and their usage
- **[Development Scenarios](./docs/DEVELOPMENT-SCENARIOS.md)** - Common workflow examples

## 📁 Project Structure

```
.
├── flake.nix              # Main Nix flake configuration
├── flake.lock             # Flake input locks
├── Makefile               # Development workflow commands
├── CLAUDE.md              # Claude Code integration guide
├── apps/                  # Platform-specific executable apps
│   ├── aarch64-darwin/    # macOS Apple Silicon executables
│   ├── x86_64-darwin/     # macOS Intel executables
│   ├── aarch64-linux/     # Linux ARM64 executables
│   └── x86_64-linux/      # Linux x86_64 executables
├── hosts/                 # Host-specific configurations
│   ├── darwin/            # macOS host configurations
│   └── nixos/             # NixOS host configurations
├── modules/               # Reusable Nix modules
│   ├── darwin/            # macOS-specific modules
│   ├── nixos/             # NixOS-specific modules
│   └── shared/            # Cross-platform modules
├── lib/                   # Nix utility functions
│   └── get-user.nix       # Dynamic user resolution
├── overlays/              # Custom package overlays
├── scripts/               # Management and development tools
│   ├── bl                 # Command system dispatcher
│   ├── setup-dev          # Project initialization
│   ├── install-setup-dev  # Global tool installer
│   └── merge-claude-config # Configuration merger
├── tests/                 # Comprehensive test suite
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   ├── e2e/               # End-to-end tests
│   └── performance/       # Performance benchmarks
└── docs/                  # Additional documentation
    ├── overview.md
    ├── structure.md
    └── testing-framework.md
```

### Key Components

- **`flake.nix`**: Entry point defining all system configurations and applications
- **`apps/`**: Platform-specific executables accessible via `nix run .#command`
- **`hosts/`**: Individual machine configurations using nix-darwin or NixOS
- **`modules/`**: Reusable configuration modules (shared, darwin-specific, nixos-specific)
- **`lib/get-user.nix`**: Dynamic user resolution supporting `$USER` environment variable
- **`scripts/`**: Development and management utilities
- **`tests/`**: Hierarchical test structure ensuring code quality across platforms

## 🚀 Quick Start

### Prerequisites

Before getting started, ensure you have the following requirements:

1. **Nix Package Manager** with flakes support
2. **Git** for cloning the repository
3. **Administrative access** for system-level configurations

### Installation

#### Step 1: Install Nix

**macOS:**
```bash
# Install Command Line Tools
xcode-select --install

# Install Nix with the Determinate Systems installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Linux:**
```bash
# Install Nix with flakes support
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Enable Flakes (if using traditional Nix install):**
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### Step 2: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/baleen/dotfiles.git
cd dotfiles

# Set the target user (required for build/evaluation)
export USER=<your-username>

# Test the configuration
make smoke
```

#### Step 3: Deploy Configuration

**For macOS:**
```bash
# Build and apply configuration
make build
make switch HOST=aarch64-darwin  # or x86_64-darwin for Intel Macs
```

**For NixOS:**
```bash
# Build and apply configuration
make build
make switch HOST=x86_64-linux   # or aarch64-linux for ARM systems
```

**Quick Deploy (Build + Apply):**
```bash
# Requires sudo privileges - builds and applies immediately
nix run --impure .#build-switch
```

### Environment Variables

**USER Variable**: Required for proper system evaluation and user resolution.

```bash
# Method 1: Export before commands
export USER=<your-username>
make build

# Method 2: Inline with command
USER=<your-username> nix run .#build

# Method 3: Use impure evaluation (reads environment automatically)
nix run --impure .#build
```

The system uses `lib/get-user.nix` to dynamically resolve the target user, supporting both `$USER` and `$SUDO_USER` environment variables.

## ⚡ Essential Commands

### Core Development Workflow

```bash
# Essential: Set USER environment variable
export USER=<username>

# Primary development commands (in order of usage frequency)
make lint           # Run pre-commit hooks (MUST pass before committing)
make smoke          # Quick flake validation without building
make test           # Run comprehensive test suite
make build          # Build all configurations
make switch HOST=<host>  # Apply configuration to current system
make help           # Show all available Makefile targets
```

### Platform-Specific Operations

```bash
# Direct Nix commands
nix run .#build         # Build for current system
nix run .#switch        # Build and switch for current system  
nix run .#build-switch  # Build and switch with sudo (immediate application)

# Platform-specific builds
make build-darwin       # Build all macOS configurations
make build-linux        # Build all NixOS configurations
```

### Project Initialization Tools

#### setup-dev: New Project Creation
```bash
# Local execution
./scripts/setup-dev [project-directory]

# Via flake app
nix run .#setup-dev [project-directory]

# Creates: flake.nix, .envrc, .gitignore with Nix patterns
```

#### bl Command System: Global Tool Management
```bash
# One-time installation
./scripts/install-setup-dev

# After installation - globally available commands
bl list                 # List available commands
bl setup-dev my-app     # Initialize Nix project
bl setup-dev --help     # Get help for setup-dev
```

### Testing and Quality Assurance

**Pre-commit Workflow (Follow CI Pipeline):**
```bash
make lint     # pre-commit run --all-files  
make smoke    # nix flake check --all-systems --no-build
make build    # build all NixOS/darwin configurations
make smoke    # final flake check after build
```

**Individual Test Categories:**
```bash
# Comprehensive testing
nix run .#test                    # Run full test suite
nix flake check --impure          # Run flake checks

# Makefile targets (recommended)
make test-unit                    # Unit tests only
make test-integration             # Integration tests only  
make test-e2e                     # End-to-end tests only
make test-perf                    # Performance tests only
make test-status                  # Check test framework status

# Direct nix commands for specific test categories
nix run .#test-unit               # Unit tests
nix run .#test-integration        # Integration tests
nix run .#test-e2e                # End-to-end tests
nix run .#test-perf               # Performance benchmarks
nix run .#test-smoke              # Quick smoke tests
```

> **Note**: Makefile targets internally run `nix` with `--extra-experimental-features 'nix-command flakes'` and `--impure`, ensuring USER environment variable support even if flakes aren't globally enabled.

## 🛠️ Advanced Tools and Automation

### Automatic Update System

The repository includes an intelligent auto-update system that keeps your environment current while preserving your customizations.

```bash
# Manual update check (respects 1-hour TTL)
./scripts/auto-update-dotfiles

# Force immediate check and update
./scripts/auto-update-dotfiles --force

# Run silently in background (used by shell startup)
./scripts/auto-update-dotfiles --silent
```

**Features:**
- **TTL-based checking**: Only checks for updates every hour to avoid overhead
- **Local change detection**: Automatically skips updates if you have uncommitted changes
- **Safe application**: Uses `build-switch` for immediate system integration
- **Background operation**: Integrated into shell startup for seamless experience

### Configuration Merge Tools

When system updates conflict with your personal configurations, use the interactive merge tool:

```bash
# List files needing merge attention
./scripts/merge-claude-config --list

# Interactively merge a specific file
./scripts/merge-claude-config settings.json

# View differences without merging
./scripts/merge-claude-config --diff CLAUDE.md

# Merge all pending files interactively
./scripts/merge-claude-config
```

**Capabilities:**
- **JSON merging**: Key-by-key selection for settings.json
- **Text merging**: Multiple strategies for markdown and config files
- **Backup creation**: Automatic backups before any changes
- **Conflict resolution**: Interactive resolution of configuration conflicts

### Local Testing Suite

Run the complete CI/CD pipeline locally to catch issues before pushing:

```bash
# Run all tests (mirrors CI exactly)
./scripts/test-all-local

# Results include comprehensive reporting
========================
    TEST RESULTS SUMMARY
========================
Total Tests: 7
Passed: 7
Failed: 0
Log File: test-results-20240106-143022.log
========================
```

**Test Coverage:**
- Pre-commit lint checks
- Smoke tests (flake validation)
- Unit tests (individual components)
- Integration tests (module interactions)
- Build tests (full configurations)
- End-to-end tests (complete workflows)

## 🛠️ Development and Customization

### Module System Architecture

The codebase follows a strict modular hierarchy designed for maintainability and cross-platform compatibility:

#### 1. Platform-Specific Modules
- **Location**: `modules/darwin/`, `modules/nixos/`
- **Purpose**: OS-specific configurations (Homebrew casks, systemd services, platform-specific packages)
- **Import Scope**: Only imported by respective platform configurations

#### 2. Shared Modules
- **Location**: `modules/shared/`
- **Purpose**: Cross-platform configurations (packages, dotfiles, shell setup)
- **Import Scope**: Available to both Darwin and NixOS configurations

#### 3. Host Configurations
- **Location**: `hosts/`
- **Purpose**: Individual machine configurations
- **Function**: Import appropriate platform and shared modules, define host-specific settings

### Key Architectural Patterns

#### User Resolution System
The system uses `lib/get-user.nix` to dynamically resolve the target user:
```nix
# Supports USER environment variable and SUDO_USER fallback
let user = import ./lib/get-user.nix { };
```

#### Flake Output Structure
```nix
{
  darwinConfigurations."aarch64-darwin" = ...;
  nixosConfigurations."x86_64-linux" = ...;
  apps.{system}.{build,switch,rollback} = ...;
  checks.{system}.{test-name} = ...;
}
```

#### Module Import Pattern
```nix
imports = [
  ../../modules/darwin/packages.nix
  ../../modules/shared/packages.nix
  ./configuration.nix
];
```

### Adding and Modifying Components

#### Package Management
- **All platforms**: Edit `modules/shared/packages.nix`
- **macOS only**: Edit `modules/darwin/packages.nix`
- **NixOS only**: Edit `modules/nixos/packages.nix`
- **Homebrew casks**: Edit `modules/darwin/casks.nix`

#### Module Development
1. **Create** module file in appropriate directory
2. **Import** in relevant host configurations or parent modules
3. **Test** on all affected platforms (x86_64-darwin, aarch64-darwin, x86_64-linux, aarch64-linux)
4. **Document** any new conventions or patterns

#### Host-Specific Configurations
- **User settings**: `hosts/<platform>/<host>/home.nix`
- **System settings**: `hosts/<platform>/<host>/configuration.nix`

### Testing and Quality Assurance

#### Pre-commit Workflow
Always run these commands in order before submitting changes:
```bash
make lint     # pre-commit run --all-files  
make smoke    # nix flake check --all-systems --no-build
make build    # build all NixOS/darwin configurations
make smoke    # final flake check after build
```

#### Test Categories
- **Unit Tests**: Individual functions and modules (`tests/unit/`)
- **Integration Tests**: Module interactions and dependencies (`tests/integration/`)
- **E2E Tests**: Complete workflows and system behavior (`tests/e2e/`)
- **Performance Tests**: Build times and resource usage (`tests/performance/`)

#### Continuous Integration
The GitHub Actions pipeline runs comprehensive tests across all supported platforms and architectures, ensuring reliability and cross-platform compatibility.

## 🔧 Claude Configuration Preservation System

This dotfiles repository includes a **Smart Claude Configuration Preservation System** that automatically safeguards user customizations during system updates.

### How It Works
1. **Automatic Change Detection**: Uses SHA256 hashes to detect user modifications
2. **Priority-based Preservation**: Critical files (`settings.json`, `CLAUDE.md`) are always preserved
3. **Safe Updates**: New versions saved as `.new` files for safe updating
4. **User Notifications**: Automatic notifications when updates occur
5. **Merge Tools**: Interactive merge tools for configuration integration

### Key Features
- ✅ **Lossless Preservation**: User settings never lost
- ✅ **Automatic Backups**: Automatic backup creation on all changes
- ✅ **Interactive Merging**: JSON and text file merge support
- ✅ **Custom File Protection**: Complete preservation of user-added command files
- ✅ **Clean Maintenance**: Automatic cleanup of temporary files after merging

### Usage

#### Manual Merging (when update notices appear)
```bash
# Check files needing merge
./scripts/merge-claude-config --list

# Merge specific file
./scripts/merge-claude-config settings.json

# Interactive merge all files
./scripts/merge-claude-config

# View differences only
./scripts/merge-claude-config --diff CLAUDE.md
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### Build Failures
```bash
# Show detailed error trace
nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system

# Check flake outputs
nix flake show --impure

# Validate flake structure
nix flake check --impure --no-build

# Clear build cache
nix store gc
```

#### Environment Variable Issues
```bash
# USER not set
export USER=$(whoami)

# For CI/scripts
nix run --impure .#build

# Persistent solution
echo "export USER=$(whoami)" >> ~/.bashrc  # or ~/.zshrc
```

#### Permission Issues with build-switch
```bash
# build-switch requires sudo from the start
sudo nix run --impure .#build-switch

# Alternative: use separate commands
nix run .#build
sudo nix run .#switch
```

#### Flake Lock Issues
```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Rebuild flake.lock
rm flake.lock && nix flake lock
```

#### macOS-Specific Issues
```bash
# Command Line Tools missing
xcode-select --install

# Homebrew integration issues
nix run .#build-switch  # Rebuilds Homebrew integration

# Permission issues with darwin-rebuild
sudo chown -R $(whoami) /nix
```

#### NixOS-Specific Issues
```bash
# Boot issues after switch
sudo nixos-rebuild switch --rollback

# Hardware configuration
sudo nixos-generate-config --root /mnt

# Network issues
sudo systemctl restart NetworkManager
```

### Performance Optimization

#### Build Optimization
- Use `make smoke` for quick validation
- Run `nix store gc` regularly to clean cache
- Use `--max-jobs` flag for parallel builds

#### Development Workflow
- Use `direnv` for automatic environment activation
- Keep separate dev shells for different projects
- Cache frequently used packages

### Getting Help

#### Pre-commit Checklist
- [ ] `export USER=<username>` is set
- [ ] `make lint` passes without errors
- [ ] `make smoke` validates flake structure
- [ ] `make build` completes successfully
- [ ] Changes tested on target platform(s)
- [ ] Documentation updated if needed
- [ ] No secrets or sensitive information committed

#### Support Resources
- **Documentation**: Check `CLAUDE.md` for detailed development guidelines
- **Contributing**: See `CONTRIBUTING.md` for contribution workflow and standards
- **Development Scenarios**: Refer to `docs/DEVELOPMENT-SCENARIOS.md` for practical step-by-step guides
- **Scripts Reference**: Refer to `docs/SCRIPTS.md` for comprehensive tool documentation
- **Module Library**: See `docs/MODULE-LIBRARY.md` for advanced library functions
- **Testing**: Refer to `docs/testing-framework.md` for testing strategies
- **Architecture**: See `docs/structure.md` for system design details

## 📚 References

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

> For migration history and legacy information, refer to commit logs and any legacy/ directories.

