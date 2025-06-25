# Nix Dotfiles: Cross-Platform Development Environment

> **Complete, reproducible development environments for macOS and NixOS**

Declaratively manage your entire development environment using Nix flakes. Everything from packages and configurations to system settings is version-controlled and instantly reproducible across machines.

**🤖 Enhanced with Claude Code Integration** - Get AI-powered development assistance with 20+ specialized commands, smart configuration management, and context-aware project guidance.

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

### 📖 Getting Started

1. **[Complete Setup Guide](./docs/CLAUDE-SETUP.md)** - Installation, configuration, and troubleshooting
2. **[Command Reference](./docs/CLAUDE-COMMANDS.md)** - All 20+ commands with examples and usage patterns
3. **[Development Scenarios](./docs/DEVELOPMENT-SCENARIOS.md)** - Real-world workflow examples

### 🛠️ Advanced Configuration

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
