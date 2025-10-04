# Professional Nix Dotfiles System

> **Enterprise-grade development environment with AI-powered tooling**

Modern Nix flakes-based dotfiles providing reproducible cross-platform development environments for macOS and NixOS. Built following 2024 best practices with comprehensive testing, AI integration, and zero-configuration deployment.

## Why This System?

- **RFC-Compliant Architecture**: Follows RFC 166 formatting and RFC 145 documentation standards
- **Cross-Platform Excellence**: Native support for macOS (Intel + Apple Silicon) and NixOS (x86_64 + ARM64)
- **AI-First Development**: Deep Claude Code integration with 20+ specialized commands and MCP servers
- **Enterprise Testing**: Multi-tier testing framework (unit, integration, e2e, performance) with 87% optimization
- **Zero-Config Deployment**: Reproducible environments with flake-based dependency management
- **Production Monitoring**: Real-time build performance and resource usage tracking

## Quick Start

### Prerequisites

**System Requirements:**

- **Nix 2.19+** with flakes enabled ([Determinate Nix Installer](https://install.determinate.systems/) recommended)
- **macOS 12+** (Monterey) or **NixOS 23.05+**
- **Git 2.30+** with SSH or HTTPS access
- **8GB+ RAM** and **10GB+ disk space** for full installation

**Development Requirements:**

- **pre-commit 3.0+** for quality enforcement
- **Claude Code CLI** for AI-powered development assistance
- **Docker** (optional, for containerized testing)

### Installation

```bash
# 1. Clone repository with SSH (recommended) or HTTPS
git clone git@github.com:baleen37/dotfiles.git  # SSH
# git clone https://github.com/baleen37/dotfiles.git  # HTTPS alternative
cd dotfiles

# 2. Initialize development environment
export USER=$(whoami)  # Required for user-specific configurations
make install-hooks     # Install pre-commit hooks for quality enforcement

# 3. Build and validate system
make build             # Build all configurations (~5-10 minutes first time)
make test-smoke        # Quick validation (~30 seconds)

# 4. Deploy system configuration
nix run --impure .#build-switch  # Apply configuration (requires sudo)
```

### Post-Installation Setup (macOS)

If you're using **Determinate Nix Installer** (recommended), you need to configure trusted users to avoid cache warnings:

```bash
# Add your user as a trusted user
sudo vi /etc/nix/nix.custom.conf

# Add this line (replace 'baleen' with your username):
trusted-users = root @admin baleen

# Restart terminal to apply changes
```

Done! You now have 50+ development tools and complete AI assistance ready.

### Claude Code Setup (Optional but Recommended)

Get AI development assistance with 20+ specialized commands:

```bash
# Install Claude Code (if not already installed)
# Visit: https://claude.ai/code

# Quick setup (takes ~30 seconds)
claude /help  # Should show specialized commands like /analyze, /spawn, /task

# Test advanced features
claude /analyze "current project structure"
claude /spawn "implement user authentication system"
```

**📚 Learn More**: [Quick Start Guide](docs/CLAUDE-QUICK-START.md) | [Complete Integration Guide](docs/CLAUDE-INTEGRATION.md)

## What You Get

- **50+ tools**: git, vim, docker, nodejs, python, and more
- **GUI apps**: 34+ macOS applications via Homebrew
- **Global commands**: `bl` for project setup and utilities
- **Auto-updates**: Keeps everything current automatically
- **Testing**: Built-in quality assurance

## Daily Usage

```bash
# Essential commands
export USER=$(whoami)   # Always run this first
make build             # Build everything
make switch            # Apply changes
make test              # Run tests
make format            # Auto-format (uses nix run .#format)

# Quick operations
make smoke             # Fast validation
nix run .#build-switch # Build and apply together
nix run .#format       # Direct Nix formatting (alternative)
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

**Supported Platforms**: macOS (Intel/ARM) and NixOS (x86_64/ARM64)

### Platform Capability Matrix

| Operation             | macOS (Intel) | macOS (ARM) | NixOS (x86_64) | NixOS (ARM64) |
| --------------------- | :-----------: | :---------: | :------------: | :-----------: |
| **Core Operations**   |               |             |                |               |
| build                 |      ✅       |     ✅      |       ✅       |      ✅       |
| build-switch          |      ✅       |     ✅      |       ✅       |      ✅       |
| apply                 |      ✅       |     ✅      |       ✅       |      ✅       |
| rollback              |      ✅       |     ✅      |       ❌       |      ❌       |
| **Testing Framework** |               |             |                |               |
| test                  |      ✅       |     ✅      |       ✅       |      ✅       |
| test-unit             |      ✅       |     ✅      |      ❌¹       |      ❌¹      |
| test-integration      |      ✅       |     ✅      |      ❌¹       |      ❌¹      |
| test-e2e              |      ✅       |     ✅      |      ❌¹       |      ❌¹      |
| **Development Tools** |               |             |                |               |
| setup-dev             |      ✅       |     ✅      |       ✅       |      ✅       |
| SSH key management    |      ✅       |     ✅      |       ✅       |      ✅       |

¹ Linux systems use consolidated testing approach due to platform limitations

## Configuration

This system uses an **externalized configuration approach** that allows flexible customization across different environments.

### Configuration Files

```bash
config/
├── platforms.yaml     # Platform-specific settings
├── cache.yaml         # Cache management configuration
├── network.yaml       # Network and download settings
├── performance.yaml   # Build and system performance
└── security.yaml      # Security policies and SSH settings
```

### Environment Variables

Override any configuration using environment variables:

```bash
# Cache settings
export CACHE_MAX_SIZE_GB=10
export CACHE_CLEANUP_DAYS=14

# Network settings
export HTTP_CONNECTIONS=100
export CONNECT_TIMEOUT=10

# Platform overrides
export PLATFORM_TYPE="darwin"
export ARCH="aarch64"
```

### Configuration Validation

```bash
# Validate all configuration files
./scripts/validate-config

# Load configuration in scripts
source scripts/utils/config-loader.sh
cache_size=$(load_cache_config "max_size_gb" "5")
```

For detailed configuration options, see [Configuration Guide](docs/CONFIGURATION.md).

## Architecture

### Repository Structure

```text
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

Add packages by editing `modules/shared/packages.nix` or platform-specific files in `modules/darwin/` and `modules/nixos/`.

## Structure

- `modules/shared/` - Cross-platform packages and configs
- `modules/darwin/` - macOS-specific settings
- `modules/nixos/` - NixOS-specific settings
- `hosts/` - Individual machine configurations
- `lib/` - Nix utilities and formatters
- `scripts/` - Legacy automation tools (being phased out)

### Nix-Based Tooling

The project uses declarative Nix solutions for development tooling:

- **Formatting**: `lib/formatters.nix` provides `nix run .#format` (invoked via `make format`)
- **Testing**: Native `nix flake check` for validation
- **Building**: Flake apps for reproducible builds

## Testing

```bash
make test    # Run all tests
make smoke   # Quick validation
make lint    # Code quality check
```

## Updates

```bash
make update            # Update all packages
nix flake update       # Update flake inputs
```

Configuration changes are automatically backed up with conflict resolution.

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

Built-in AI development assistance with 20+ specialized commands and MCP server integration. Features automated workflow improvements and smart commit message generation.

### Setup

```bash
make switch     # Apply configuration
# Restart Claude Code
# Try: /help
```

### MCP Servers

Install Model Context Protocol servers for enhanced Claude Code functionality:

```bash
# Install MCP servers using Claude CLI
claude mcp add @modelcontextprotocol/server-filesystem

# List installed servers
claude mcp list
```

**Available MCP Servers:**

- **Filesystem** - File system access and manipulation
- Additional servers can be installed via `claude mcp add` as needed

### Key Commands

- `/build` - Build and test with validation
- `/commit` - Generate semantic commits
- `/create-pr` - Create pull requests
- `/update-claude` - Update Claude configuration

### Features

- **Smart config management** with automatic backups
- **Context-aware assistance** for Nix and Git
- **MCP server integration** for enhanced file system access
- **Dotfiles-specific guidance** and best practices
- **File references** using `@filesystem:path://filename`

## Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Claude Code project instructions
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Development guidelines
- **[docs/](./docs/)** - Detailed guides and references

## Troubleshooting

**Build failures:**

```bash
export USER=$(whoami)  # Ensure USER is set
nix store gc            # Clear cache
make build             # Retry
```

**Permission issues:**

```bash
sudo nix run --impure .#build-switch
```

See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for more solutions.

## Next Steps

1. Run `make help` to see all commands
2. Add packages in `modules/shared/packages.nix`
3. Check [CONTRIBUTING.md](./CONTRIBUTING.md) for development

---

_Nix flakes + Home Manager + nix-darwin/NixOS for declarative, reproducible environments._
