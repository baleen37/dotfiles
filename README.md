# Professional Nix Dotfiles System

> **Enterprise-grade, declarative development environments for macOS and NixOS**

A comprehensive Nix flakes-based dotfiles system that provides reproducible, version-controlled development environments across multiple platforms. Features advanced module architecture, comprehensive testing framework, and integrated AI development assistance.

## System Overview

This repository implements a sophisticated dotfiles management system using Nix flakes with the following core capabilities:

- **Cross-platform compatibility**: Native support for macOS (Intel + Apple Silicon) and NixOS (x86_64 + ARM64)
- **Modular architecture**: Clean separation between platform-specific and shared configurations
- **Comprehensive testing**: Unit, integration, end-to-end, and performance test suites
- **Claude Code integration**: AI-powered development assistance with 20+ specialized commands
- **Advanced automation**: Auto-update system, configuration preservation, and intelligent build optimization

## Quick Start

### System Requirements

- **Nix** with flakes support ([installation guide](https://nixos.org/download))
- **Git** for version control
- **Administrative privileges** for system-level configuration
- **Supported platforms**: macOS 11+, NixOS 21.11+

### Installation

```bash
# 1. Clone and enter repository
git clone https://github.com/baleen37/dotfiles.git
cd dotfiles

# 2. Set user context (required)
export USER=$(whoami)

# 3. Validate system compatibility
make smoke

# 4. Build all platform configurations
make build

# 5. Apply to current system
nix run --impure .#build-switch
```

**Result**: A complete, reproducible development environment with 50+ tools, optimized configurations, and AI integration.

## System Capabilities

### Package Management

- **50+ development tools**: Comprehensive toolchain including git, vim, docker, terraform, nodejs, python
- **Platform-optimized**: Automatic package selection based on macOS/NixOS platform
- **Homebrew integration**: 34+ GUI applications managed declaratively on macOS
- **Version consistency**: Reproducible package versions across all environments

### Development Infrastructure

- **Global command system**: `bl` dispatcher for cross-project development tasks
- **Project initialization**: `setup-dev` creates instant Nix development environments
- **Configuration preservation**: Intelligent preservation of user customizations during updates
- **Auto-update mechanism**: TTL-based update system with safety validation

### Quality Assurance Framework

- **Multi-tier testing**: Unit (component), integration (module), end-to-end (workflow), performance
- **CI/CD pipeline**: Comprehensive GitHub Actions workflow with multi-platform validation
- **Development lifecycle**: Pre-commit hooks, automated testing, build validation
- **Local testing capability**: Full CI pipeline replication via `./scripts/test-all-local`

## Core Operations

### Development Workflow

```bash
# Set user context (required)
export USER=$(whoami)

# Quality assurance
make lint           # Run pre-commit hooks and code quality checks
make smoke          # Fast flake validation without building
make test           # Execute comprehensive test suite

# Build and deployment
make build          # Build all platform configurations
make build-current  # Build current platform only (faster)
make switch         # Apply configuration to current system
```

### Platform-Specific Operations

```bash
# Targeted builds
make build-darwin   # macOS configurations (x86_64, aarch64)
make build-linux    # NixOS configurations (x86_64, aarch64)

# Direct operations
nix run .#build         # Build current platform
nix run .#build-switch  # Build and apply with sudo handling
nix run .#test          # Run platform-appropriate test suite
```

### Platform Capability Matrix

| Operation | macOS (Intel) | macOS (ARM) | NixOS (x86_64) | NixOS (ARM64) |
|-----------|:-------------:|:-----------:|:--------------:|:-------------:|
| **Core Operations** | | | | |
| build | ✅ | ✅ | ✅ | ✅ |
| build-switch | ✅ | ✅ | ✅ | ✅ |
| apply | ✅ | ✅ | ✅ | ✅ |
| rollback | ✅ | ✅ | ❌ | ❌ |
| **Testing Framework** | | | | |
| test | ✅ | ✅ | ✅ | ✅ |
| test-unit | ✅ | ✅ | ❌¹ | ❌¹ |
| test-integration | ✅ | ✅ | ❌¹ | ❌¹ |
| test-e2e | ✅ | ✅ | ❌¹ | ❌¹ |
| **Development Tools** | | | | |
| setup-dev | ✅ | ✅ | ✅ | ✅ |
| SSH key management | ✅ | ✅ | ✅ | ✅ |

¹ Linux systems use consolidated testing approach due to platform limitations

## Architecture

### Repository Structure

```
├── flake.nix              # Flake entry point and output definitions
├── Makefile               # Development workflow automation
├── CLAUDE.md              # Claude Code project instructions
├── CONTRIBUTING.md        # Development guidelines and standards
│
├── modules/               # Modular configuration system
│   ├── shared/            #   Cross-platform configurations
│   ├── darwin/            #   macOS-specific modules
│   └── nixos/             #   NixOS-specific modules
│
├── hosts/                 # Host-specific configurations
│   ├── darwin/            #   macOS system definitions
│   └── nixos/             #   NixOS system definitions
│
├── lib/                   # Nix utility functions and builders
├── scripts/               # Automation and management tools
├── tests/                 # Multi-tier testing framework
├── docs/                  # Comprehensive documentation
└── overlays/              # Custom package definitions and patches
```

### Module Hierarchy

The system follows a strict modular architecture:

1. **Platform modules** (`modules/{darwin,nixos}/`) contain OS-specific configurations
2. **Shared modules** (`modules/shared/`) provide cross-platform functionality
3. **Host configurations** (`hosts/`) define individual machine setups
4. **Library functions** (`lib/`) provide reusable Nix utilities

## Customization

### Package Management

**Cross-platform packages** (`modules/shared/packages.nix`):
```nix
{ pkgs }: with pkgs; [
  # Development tools
  your-development-tool

  # System utilities
  your-utility-package
]
```

**Platform-specific packages**:
- macOS packages: `modules/darwin/packages.nix`
- macOS GUI apps: `modules/darwin/casks.nix`
- NixOS packages: `modules/nixos/packages.nix`

### Validation Workflow

```bash
# Comprehensive validation
make lint           # Code quality and formatting
make smoke          # Fast flake structure validation
make build          # Multi-platform build verification
make test           # Full test suite execution

# Local application
make switch         # Apply to current system
```

### Testing Strategy

1. **Unit tests**: Individual component validation
2. **Integration tests**: Module interaction verification
3. **End-to-end tests**: Complete workflow validation
4. **Performance tests**: Build time and resource monitoring

## Advanced Features

### Configuration Preservation System

Intelligent preservation of user customizations during system updates:

- **Change detection**: SHA256-based modification tracking
- **Safe update mechanism**: New versions preserved as `.new` files with user notification
- **Interactive conflict resolution**: `./scripts/merge-claude-config` for manual merging
- **Automatic backup**: Timestamped backups with 30-day retention policy

### Automated Update Framework

TTL-based update system with safety validation:

```bash
# Automatic updates (respects 1-hour TTL)
./scripts/auto-update-dotfiles

# Force immediate update
./scripts/auto-update-dotfiles --force

# Silent background updates
./scripts/auto-update-dotfiles --silent
```

### Global Development Tools

Cross-project development assistance:

```bash
# Install global command system
./scripts/install-setup-dev

# Available commands
bl setup-dev <project>    # Initialize Nix development environment
bl list                   # Show available commands
bl --help                 # Usage information
```

### Performance Optimization

- **Build optimization**: Parallel builds with optimal job configuration
- **Platform-specific builds**: Target current platform for faster iteration
- **Intelligent caching**: Build artifact caching and reuse
- **Resource monitoring**: Build time and memory usage tracking

## 🤖 Claude Code Integration

Transform your development workflow with AI-powered assistance. This dotfiles repository includes comprehensive Claude Code integration with specialized commands, smart configuration management, and context-aware guidance.

### ⚡ Quick Claude Setup

```bash
# 1. Apply Claude configuration (included in dotfiles)
make switch

# 2. Restart Claude Code to load new configuration
# (Quit and reopen Claude Code application)

# 3. Verify integration
# In Claude Code, try: /help
```

### 🎯 Key Features

**20+ Specialized Commands**
- `/do-plan` - Create detailed implementation plans
- `/build` - Build and test dotfiles with comprehensive validation
- `/commit` - Generate semantic commit messages
- `/create-pr` - Create comprehensive pull requests
- `/do-issue` - Systematically work on GitHub issues

**Smart Configuration Management**
- **Automatic preservation** of your Claude customizations
- **Safe updates** during dotfiles system updates
- **Interactive merging** for configuration conflicts
- **Automatic backups** of all configuration changes

**Development Workflow Integration**
- **Context-aware assistance** for Nix, Git, and system operations
- **Pre-configured permissions** for development tools
- **MCP server integration** for enhanced capabilities
- **Dotfiles-specific guidance** and best practices

### 🚀 Common Workflows

**Starting a New Feature**
```
User: I want to add dark mode support

Claude: I'll help you plan and implement dark mode support.
/do-plan

## Implementation Plan: Dark Mode Support
[Detailed plan with phases, tasks, and timeline]
```

**Working on GitHub Issues**
```
User: Work on issue #180

Claude: I'll systematically address issue #180.
/do-issue 180

[Analyzes issue, creates implementation plan, tracks progress]
```

**Building and Testing Changes**
```
User: Test my configuration changes

Claude: I'll run comprehensive build and test validation.
/build

[Validates all platforms, runs tests, provides detailed results]
```

### Documentation

1. **[Complete Setup Guide](./docs/CLAUDE-SETUP.md)** - Installation, configuration, and troubleshooting
2. **[Command Reference](./docs/CLAUDE-COMMANDS.md)** - All 20+ commands with examples and usage patterns
3. **[Development Scenarios](./docs/DEVELOPMENT-SCENARIOS.md)** - Real-world workflow examples

### Advanced Configuration

**Custom Commands**: Add your own specialized prompts
**Permission Management**: Fine-tune tool access and security
**MCP Integration**: Connect additional context servers
**Workflow Automation**: Chain commands for complex processes

[Learn more →](./docs/CLAUDE-SETUP.md)

## 📚 Documentation

### 🤖 Claude Code Integration
- **[Claude Setup Guide](./docs/CLAUDE-SETUP.md)** - Complete installation and configuration
- **[Claude Commands Reference](./docs/CLAUDE-COMMANDS.md)** - All 20+ available commands with examples
- **[CLAUDE.md](./CLAUDE.md)** - Project-specific instructions for Claude

### 🛠️ Development
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

### CI/CD and Pre-commit Issues

**Nix warnings and noise:**
- Recent improvements filter out trusted user warnings and git dirty tree warnings
- Set `CI_MODE=local` for consistent behavior between local and CI environments
- Use `nix run --impure .#test-smoke` for quick validation

**Pre-commit vs CI inconsistencies:**
- Pre-push hooks now run the same tests as CI (unit, integration, perf)
- Warning filtering ensures clean output while preserving actual errors
- Tests are executed with environment variables matching CI configuration

**Performance optimization:**
- Consider setting up as a trusted user for better build performance
- Use `nix.settings.trusted-users = ["your-username"]` in system configuration
- cachix substituter will be utilized when trusted user is configured

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
