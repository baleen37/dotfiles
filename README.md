# Professional Nix Dotfiles System

> **Enterprise-grade development environment with AI-powered tooling**

Modern Nix flakes-based dotfiles providing reproducible cross-platform development environments for macOS and NixOS. Built following 2024 best practices with comprehensive testing, AI integration, and zero-configuration deployment.

## Why This System?

- **RFC-Compliant Architecture**: Follows RFC 166 formatting and RFC 145 documentation standards
- **Cross-Platform Excellence**: Native support for Apple Silicon macOS and NixOS (x86_64 + ARM64)
- **AI-First Development**: Deep Claude Code integration with 20+ specialized commands and MCP servers
- **Assertions as Derivations**: every check is a Nix build, so `nix flake check` is the whole test runner
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
make install-hooks     # Install pre-commit hooks for quality enforcement

# 3. Build and validate system
make test             # Evaluate all checks
make test-build       # Build every unit + integration assertion

# 4. Deploy system configuration
make switch                      # Apply configuration (requires sudo)
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

### Nix Cache Behavior

Local builds are accelerated by binary substituters, especially `https://baleen-nix.cachix.org`, `https://nix-community.cachix.org`, and `https://cache.nixos.org/`. When CI pushes a built closure to Cachix on `main` or tags, local `nix build` and `make switch` can download matching store paths instead of rebuilding them.

GitHub `actions/cache` is CI-only. It can speed repeated workflow runs on GitHub-hosted runners, but it does not make local macOS builds faster. Do not store credentials in cached paths.

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
nix build '.#darwinConfigurations.macbook-pro.system'   # Build (substitute your machine)
make switch            # Apply changes
make test-build        # Run the assertions
make format            # Auto-format (wraps nix fmt)

# Quick operations
make test-build        # Build every unit + integration assertion
make switch            # Build and apply together
nix fmt                # Direct Nix formatting (alternative)
```

### Platform-Specific Operations

```bash
# Targeted builds
nix build '.#darwinConfigurations.macbook-pro.system'   # macOS
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'   # NixOS

# Direct operations
make switch             # Build and apply with sudo handling
make test               # Evaluate all checks
make test-build         # Build every unit + integration assertion
```

**Supported Platforms**: macOS (Apple Silicon) and NixOS (x86_64/ARM64)

### Platform Capability Matrix

| Make target         | macOS (Apple Silicon) | NixOS (x86_64) | NixOS (ARM64) |
| ------------------- | :-------------------: | :------------: | :-----------: |
| **Core Operations** |                       |                |               |
| switch              |          ✅           |       ✅       |      ✅       |
| switch-home         |          ✅           |       ✅       |      ✅       |
| format              |          ✅           |       ✅       |      ✅       |
| **Testing**         |                       |                |               |
| test                |          ✅           |       ✅       |      ✅       |
| test-build          |          ✅           |       ✅       |      ✅       |
| test-containers     |          ❌¹          |      ✅²       |      ✅²      |
| **Secrets**         |                       |                |               |
| secrets/backup      |          ✅           |       ✅       |      ✅       |
| secrets/restore     |          ✅           |       ✅       |      ✅       |

¹ NixOS VM tests need a Linux builder; Determinate Nix disables the macOS
linux-builder, so run them in CI or a Linux VM.
² Requires `/dev/kvm`. Where it is missing, `make test` degrades to
`nix flake check --no-build`, which evaluates checks without running assertions.
`make test-build` runs the unit and integration assertions on any platform, but it
deliberately excludes the NixOS VM tests — those need `make test-containers` or CI.

## Configuration

This system follows evantravers' minimalist approach with user-centric configuration files.

### User Configuration Structure

```bash
users/shared/
├── home-manager.nix    # Main user configuration, imports everything below
├── darwin/            # macOS-specific settings
├── programs/          # One file (or directory) per tool
│   ├── git.nix
│   ├── vim.nix
│   ├── zsh/
│   └── tmux.nix
├── packages/          # Categorised package lists
└── .config/claude/   # Claude Code configuration
```

### Home Manager Profile Selection

Flake evaluation is pure. `make switch-home` selects its standalone Home Manager
profile with `HM_USER`, which defaults to the current shell user:

```bash
make switch-home HM_USER=jito.hello
```

For detailed configuration options, see [Configuration Guide](docs/CONFIGURATION.md).

## Architecture

### Directory Structure

```text
dotfiles/
├── flake.nix           # Inputs; outputs are assembled by flake-modules/
├── flake-modules/      # hosts, systems, home, checks, packages, formatter
├── lib/
│   ├── mksystem.nix    # System factory
│   ├── cache-config.nix
│   ├── overlays.nix
│   └── user-info.nix   # Single source of truth for git identity
├── machines/           # Hardware and system settings
│   ├── darwin/common.nix
│   └── nixos/
├── users/shared/       # User configuration (see above)
└── tests/              # unit/, integration/, containers/, lib/
```

## Commands

```bash
# Build current system
nix build '.#darwinConfigurations.macbook-pro.system'

# Run tests
make test-build

# Switch to new config
make switch
```

### evantravers Architecture

The system follows evantravers' minimalist user-centric architecture:

1. **System Factory** (`lib/mksystem.nix`) provides a unified interface for building systems
2. **User Configuration** (`users/shared/`) contains all user-specific settings in flat files
3. **Machine Definitions** (`machines/`) define hardware-specific configurations
4. **Test Framework** (`tests/`) provides comprehensive TDD-based validation

Host metadata is internal to the flake: `flake-modules/hosts.nix` declares typed
`dotfiles.hosts` entries with their platform, class, explicit system user, and
machine modules. `flake-modules/systems.nix` turns them into Darwin and NixOS
outputs.

## Customization

Add packages to the matching category in `users/shared/packages/` (e.g. `dev.nix`), or configure a tool in `users/shared/programs/`.

## Structure

- `users/shared/` - User-centric configuration files (one file per tool)
- `lib/mksystem.nix` - System factory following evantravers pattern
- `machines/` - Machine-specific system configurations
- `tests/` - TDD-based test framework with helpers

### Nix-Based Tooling

The project uses declarative Nix solutions for development tooling:

- **Formatting**: `flake-modules/formatter.nix` wires up treefmt (invoked via `make format`)
- **Testing**: Native `nix flake check` for validation
- **Building**: `make switch` wraps darwin-rebuild / nixos-rebuild / home-manager

## Testing

Every check is a Nix derivation that builds if an assertion holds. See
[tests/README.md](tests/README.md) for the contract and helper inventory.

```bash
make test             # Evaluate all checks
make test-build       # Build every unit + integration assertion
make test-containers  # NixOS VM tests (Linux + /dev/kvm)
```

**Container Test Coverage:**

- Basic system functionality validation
- User configuration testing
- Services verification (SSH, Docker)
- Package installation validation

## NixOS VM Management

This project includes NixOS VM management commands for development and testing environments.

### VM Setup Commands

For NixOS VM workflows, build with:

```bash
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
```

See `machines/nixos/` for available VM configurations.

### VM Configuration

The VM management system supports:

- SSH-based deployment and management
- Automated NixOS installation
- Configuration synchronization
- Secrets management

### Environment Variables

```bash
# Required for VM commands
export NIXADDR=192.168.64.2    # VM IP address
export NIXPORT=22              # SSH port (default: 22)
export NIXUSER=root            # SSH user (default: root)
```

### Platform Support

- ✅ macOS (Apple Silicon)
- ✅ Linux (x86_64/aarch64)
- ✅ Windows (via WSL2)

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
- `/commit-push-pr` - Commit changes, push, and create pull request
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
nix store gc            # Clear cache
nix build '.#darwinConfigurations.<your-machine>.system'  # Retry
```

**Permission issues:**

```bash
make switch
```

See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for more solutions.

## Next Steps

1. Run `nix flake show --all-systems` to see all configurations
2. Add packages in `users/shared/packages/<category>.nix` or a tool module
3. Check [CONTRIBUTING.md](./CONTRIBUTING.md) for development

---

_Nix flakes + evantravers pattern for declarative, reproducible environments._
