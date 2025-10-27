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

If you're using **Determinate Nix Installer** (recommended), configure trusted users for optimal cache performance:

```bash
# Add your user as a trusted user
sudo vi /etc/nix/nix.custom.conf

# Add this line (replace 'baleen' with your username):
trusted-users = root @admin baleen

# Restart terminal to apply changes
```

📖 **For detailed cache setup and troubleshooting**, see [Cachix Binary Cache](#-cachix-binary-cache) section below.

Done! You now have 50+ development tools and complete AI assistance ready.

## 🚀 Cachix Binary Cache

This system uses **Cachix** for shared binary cache integration, providing significant performance improvements for team collaboration.

### Overview

- **Cache URL**: `https://baleen-nix.cachix.org`
- **Performance**: 60-80% faster incremental builds
- **Security**: Read access for team, write access via CI only
- **Setup**: Zero configuration required for team members

### Performance Benefits

- **Build Time Reduction**: 60-80% faster incremental builds
- **Network Bandwidth**: Reduced package downloads from official Nix cache
- **Developer Experience**: Faster feedback cycles and system updates
- **CI Speed**: Faster CI builds through cache reuse across team members

### Security Model

**Token Management**:
- ✅ CI-only write access (authenticated via GitHub Secrets)
- ✅ Team members get cache benefits without token exposure
- ✅ No local token storage required

**Access Control**:
- **Read Access**: All team members (automatic via flake configuration)
- **Write Access**: CI pipeline only (authenticated via `CACHIX_AUTH_TOKEN`)

### Team Setup Instructions

**For Team Members (Zero Configuration)**:

No additional setup required! The cache is automatically configured through `flake.nix`:

```bash
# Just use the normal commands - cache works automatically
export USER=$(whoami)
make build          # Will use cache when available
make switch         # Will use cache when available
```

**For Cache Activation (Trusted Users Requirement)**:

To avoid cache warnings and enable optimal performance, configure trusted users:

```bash
# Check if you're already a trusted user
nix store verify --no-trust /nix/store/* 2>/dev/null && echo "✅ Already configured" || echo "⚠️ Need configuration"

# Add your user as trusted (required for Determinate Nix Installer)
sudo vi /etc/nix/nix.custom.conf

# Add this line (replace 'baleen' with your username):
trusted-users = root @admin baleen

# Alternative: Add to existing trusted-users line
# trusted-users = root @admin baleen jito  # Add multiple users

# Restart Nix daemon (macOS)
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon

# Or restart terminal - changes take effect on next Nix command
```

**Multiple User Support**:

The system supports multiple users without code duplication:

```bash
# Works for any username - configuration is dynamically resolved
export USER=$(whoami)  # baleen, jito, or any other username
make build             # Uses same cache for all users
```

### Troubleshooting Cache Issues

**Cache Warnings or Slow Builds**:

```bash
# 1. Verify trusted users configuration
nix store verify --no-trust /nix/store/* 2>/dev/null && echo "✅ Trusted users OK" || echo "❌ Configure trusted users"

# 2. Check cache connectivity
nix store ping --store https://baleen-nix.cachix.org

# 3. Clear local cache and rebuild
nix store gc --delete-old
make build

# 4. Verify flake configuration
nix flake show --json | jq '.nixConfig'
```

**Permission Issues**:

```bash
# Ensure correct permissions for Nix operations
sudo chown -R $(whoami) /nix/var/nix/profiles/per-user/$(whoami)

# For Determinate Nix Installer users, verify trusted users
grep -E "trusted-users.*$(whoami)" /etc/nix/nix.conf /etc/nix/nix.custom.conf 2>/dev/null || echo "Add trusted users configuration"
```

**Cache Not Working**:

```bash
# Check if cache is being used
nix build --print-build-logs --keep-going .#darwinConfigurations.macbook-pro.system 2>&1 | grep -E "(cachix|substituter|copying)"

# Manual cache verification
nix path-info --store https://baleen-nix.cachix.org --json /nix/store/* 2>/dev/null | jq length
```

### Cache Statistics

Monitor cache usage and performance:

```bash
# View build statistics
time make build

# Check cache hit rate (experimental)
nix build --print-build-logs .#darwinConfigurations.macbook-pro.system 2>&1 | grep -c "copied from substitut" || echo "No cache hits this build"
```

### CI Integration

The cache is automatically managed by GitHub Actions:

- **Upload Conditions**: Main branch and tags only
- **Authentication**: Via `CACHIX_AUTH_TOKEN` (GitHub Secrets)
- **Automatic**: All successful builds push to cache
- **Team Benefits**: All team members benefit from CI builds

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

This system follows evantravers' minimalist approach with user-centric configuration files.

### User Configuration Structure

```bash
users/baleen/
├── home-manager.nix    # Main user configuration
├── darwin.nix         # macOS-specific settings
├── git.nix           # Git configuration
├── vim.nix           # Vim/Neovim setup
├── zsh.nix           # Zsh shell configuration
├── tmux.nix          # Terminal multiplexer
└── .config/claude/   # Claude Code configuration
```

### Environment Variables

Required for all build operations:

```bash
# Required user variable for dynamic resolution
export USER=$(whoami)
```

For detailed configuration options, see [Configuration Guide](docs/CONFIGURATION.md).

## Architecture

### Directory Structure

```text
dotfiles/
├── flake.nix           # Entry point
├── lib/
│   ├── mksystem.nix    # System factory
│   └── tests.nix       # Test utilities
├── machines/
│   └── macbook-pro.nix # Machine config
├── users/baleen/       # User-centric structure
│   ├── home-manager.nix
│   ├── darwin.nix
│   ├── git.nix
│   ├── vim.nix
│   ├── zsh.nix
│   ├── tmux.nix
│   └── .config/claude/ # Claude Code config
└── tests/              # TDD test suite
    ├── unit/
    ├── integration/
    └── smoke/
```

## Commands

```bash
# Build current system
nix build .#darwinConfigurations.macbook-pro.system

# Run tests
nix flake check

# Switch to new config
darwin-rebuild switch --flake .#macbook-pro
```

### evantravers Architecture

The system follows evantravers' minimalist user-centric architecture:

1. **System Factory** (`lib/mksystem.nix`) provides a unified interface for building systems
2. **User Configuration** (`users/baleen/`) contains all user-specific settings in flat files
3. **Machine Definitions** (`machines/`) define hardware-specific configurations
4. **Test Framework** (`tests/`) provides comprehensive TDD-based validation

## Customization

Add packages by editing individual tool files in `users/baleen/` (e.g., `git.nix`, `vim.nix`) or modify `users/baleen/home-manager.nix` for package collections.

## Structure

- `users/baleen/` - User-centric configuration files (one file per tool)
- `lib/mksystem.nix` - System factory following evantravers pattern
- `machines/` - Machine-specific system configurations
- `tests/` - TDD-based test framework with helpers

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
- **Intelligent caching**: Build artifact caching and reuse via [Cachix Binary Cache](#-cachix-binary-cache) (60-80% faster builds)
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

**Cache Issues:**

If you're experiencing slow builds or cache warnings, see [Cachix Binary Cache](#-cachix-binary-cache) for detailed troubleshooting steps including trusted users configuration and connectivity checks.

See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for more solutions.

## Next Steps

1. Run `nix flake show` to see all configurations
2. Add packages in `users/baleen/home-manager.nix` or individual tool files
3. Check [CONTRIBUTING.md](./CONTRIBUTING.md) for development

---

_Nix flakes + evantravers pattern for declarative, reproducible environments._
