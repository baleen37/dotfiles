# jito's Dotfiles

> **Pragmatic and simple development environment**

Nix-based dotfiles for macOS and NixOS. Works out of the box without complex configuration.

## Why These Dotfiles?

- **Just Works**: Install and use immediately, no complex setup required
- **Multi-Platform**: Supports macOS (Intel + Apple Silicon) and NixOS
- **Claude Code Integration**: Built-in AI development assistance
- **Auto-Updates**: Minimal maintenance hassle

## Quick Start

### Requirements
- Nix with flakes ([install guide](https://nixos.org/download))
- macOS 11+ or NixOS 21.11+

### Installation
```bash
git clone https://github.com/baleen37/dotfiles.git
cd dotfiles
export USER=$(whoami)
make build
nix run --impure .#build-switch
```

Done! You now have 50+ development tools and AI assistance ready.

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

# Claude Code setup
make setup-mcp         # Install MCP servers for AI assistance

# Quick operations  
make smoke             # Fast validation
nix run .#build-switch # Build and apply together
```

**Supported Platforms**: macOS (Intel/ARM) and NixOS (x86_64/ARM64)

## Customization

Add packages by editing `modules/shared/packages.nix` or platform-specific files in `modules/darwin/` and `modules/nixos/`.

## Structure

- `modules/shared/` - Cross-platform packages and configs
- `modules/darwin/` - macOS-specific settings
- `modules/nixos/` - NixOS-specific settings
- `hosts/` - Individual machine configurations
- `scripts/` - Automation tools

## Testing

```bash
make test    # Run all tests
make smoke   # Quick validation
make lint    # Code quality check
```

## Updates

```bash
./scripts/auto-update-dotfiles        # Automatic updates
./scripts/auto-update-dotfiles --force # Force update
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

Built-in AI development assistance with 20+ specialized commands and MCP server integration.

### Setup

```bash
make switch     # Apply configuration
make setup-mcp  # Install MCP servers for Claude Code
# Restart Claude Code
# Try: /help
```

### MCP Servers

Install Model Context Protocol servers for enhanced Claude Code functionality:

```bash
# Install essential MCP servers (recommended)
make setup-mcp

# Or use the script directly
./scripts/setup-claude-mcp --main

# List installed servers
./scripts/setup-claude-mcp --list
```

**Available MCP Servers:**
- **Filesystem** - File system access and manipulation (default)
- Additional servers can be installed manually as needed

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

*Nix flakes + Home Manager + nix-darwin/NixOS for declarative, reproducible environments.*
