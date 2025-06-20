# CLAUDE.md

> **Last Updated:** 2025-01-06  
> **Version:** 2.0  
> **For:** Claude Code (claude.ai/code)

This file provides comprehensive guidance for Claude Code when working with this Nix flake-based dotfiles repository.

## Quick Start

### TL;DR - Essential Commands
```bash
# Setup (run once)
export USER=<username>

# Daily workflow
make lint    # Always run before committing
make build   # Test your changes
make switch HOST=<host>  # Apply to system

# Emergency fixes
nix run --impure .#build-switch  # Build and switch (requires sudo)
```

### First Time Setup
1. Set user environment: `export USER=<username>`
2. Test the build: `make build`
3. Apply configuration: `make switch HOST=<host>`
4. Install global tools: `./scripts/install-setup-dev`

## Repository Overview

This is a Nix flake-based dotfiles repository for managing macOS and NixOS development environments declaratively. It supports x86_64 and aarch64 architectures on both platforms.

**Key Features:**
- Declarative environment management with Nix flakes
- Cross-platform support (macOS via nix-darwin, NixOS via nixos-rebuild)
- Comprehensive testing suite with CI/CD
- Modular architecture for easy customization
- Global command system (`bl`) for project management

## Essential Commands

### Development Workflow
```bash
# Required: Set USER environment variable (or use --impure flag)
export USER=<username>

# Core development commands (in order of frequency)
make lint           # Run pre-commit hooks (MUST pass before committing)
make smoke          # Quick flake validation without building
make test           # Run all unit and e2e tests
make build          # Build all configurations
make switch HOST=<host>  # Apply configuration to current system
make help           # Show all available Makefile targets

# Platform-specific builds
nix run .#build     # Build for current system
nix run .#switch    # Build and switch for current system
nix run .#build-switch  # Build and switch with sudo (immediate application)
```

### Testing Requirements (Follow CI Pipeline)
**Always run these commands in order before submitting changes:**
```bash
make lint   # pre-commit run --all-files  
make smoke  # nix flake check --all-systems --no-build
make build  # build all NixOS/darwin configurations
make smoke  # final flake check after build
```

### Running Individual Tests
```bash
# Run all tests for current system
nix run .#test                    # Run comprehensive test suite
nix flake check --impure          # Run flake checks

# Run specific test categories using Makefile (recommended)
make test-unit                    # Unit tests only (Darwin only)
make test-integration             # Integration tests only (Darwin only)
make test-e2e                     # End-to-end tests only (Darwin only)
make test-perf                    # Performance tests only (Darwin only)
make test-status                  # Check test framework status

# Direct nix commands for specific test categories
nix run .#test-unit               # Unit tests (Darwin only)
nix run .#test-integration        # Integration tests (Darwin only)
nix run .#test-e2e                # End-to-end tests (Darwin only)
nix run .#test-perf               # Performance tests (Darwin only)
nix run .#test-smoke              # Quick smoke tests (all platforms)

# Platform availability:
# - Darwin systems: Full test suite available
# - Linux systems: Basic tests (test, test-smoke, test-list) only
```

## Development Workflows

### 🔄 Daily Development Cycle
```bash
# 1. Start work
git checkout -b feature/my-change
export USER=<username>

# 2. Make changes
# ... edit files ...

# 3. Test changes
make lint && make build

# 4. Apply locally (optional)
make switch HOST=<host>

# 5. Commit and push
git add . && git commit -m "feat: description"
git push -u origin feature/my-change

# 6. Create PR with auto-merge
gh pr create --assignee @me
gh pr merge --auto --squash  # Enable auto-merge after CI passes
```

### 🚀 Quick Configuration Apply
```bash
# For immediate system changes (requires sudo)
nix run --impure .#build-switch

# For testing without system changes
make build
```

### 🔧 Adding New Software
```bash
# 1. Identify target platform
# All platforms: modules/shared/packages.nix
# macOS only: modules/darwin/packages.nix  
# NixOS only: modules/nixos/packages.nix
# Homebrew casks: modules/darwin/casks.nix

# 2. Edit appropriate file
# 3. Test the change
make build

# 4. Apply if successful
make switch HOST=<host>
```

## Architecture Overview

### Module System Hierarchy
The codebase follows a strict modular hierarchy:

1. **Platform-specific modules** (`modules/darwin/`, `modules/nixos/`)
   - Contains OS-specific configurations (e.g., Homebrew casks, systemd services)
   - Imported only by respective platform configurations

2. **Shared modules** (`modules/shared/`)
   - Cross-platform configurations (packages, dotfiles, shell setup)
   - Can be imported by both Darwin and NixOS configurations

3. **Host configurations** (`hosts/`)
   - Individual machine configurations
   - Import appropriate platform and shared modules
   - Define host-specific settings

### Key Architectural Patterns

1. **User Resolution**: The system dynamically reads the `$USER` environment variable via `lib/get-user.nix`. Always ensure this is set or use `--impure` flag.

2. **Flake Outputs Structure**:
   ```nix
   {
     # Generated for all systems using genAttrs
     darwinConfigurations = genAttrs darwinSystems (system: ...);
     nixosConfigurations = genAttrs linuxSystems (system: ...);

     # Platform-specific apps with different availability
     apps = {
       aarch64-darwin = { build, build-switch, apply, rollback, test-unit, ... };
       x86_64-darwin = { build, build-switch, apply, rollback, test-unit, ... };
       aarch64-linux = { build, build-switch, apply, install, test, ... };
       x86_64-linux = { build, build-switch, apply, install, test, ... };
     };

     checks.{system}.{test-name} = ...;
   }
   ```

3. **Module Import Pattern**:
   ```nix
   imports = [
     ../../modules/darwin/packages.nix
     ../../modules/shared/packages.nix
     ./configuration.nix
   ];
   ```

4. **Overlay System**: Custom packages and patches are defined in `overlays/` and automatically applied to nixpkgs.

### File Organization

- `flake.nix`: Entry point defining all outputs
- `hosts/{platform}/{host}/`: Host-specific configurations
- `modules/{platform}/`: Platform-specific modules
- `modules/shared/`: Cross-platform modules
- `apps/{architecture}/`: Platform-specific shell scripts (actual availability varies by platform)
- `tests/`: Hierarchical test structure (unit/, integration/, e2e/, performance/)
- `lib/`: Shared Nix functions (especially `get-user.nix`)
- `scripts/`: Management and development tools
- `docs/`: Additional documentation (overview.md, structure.md, testing-framework.md)
- `overlays/`: Custom packages and patches

## Common Tasks

### Adding a New Package
1. **For all platforms**: Edit `modules/shared/packages.nix`
2. **For macOS only**: Edit `modules/darwin/packages.nix`
3. **For NixOS only**: Edit `modules/nixos/packages.nix`
4. **For Homebrew casks**: Edit `modules/darwin/casks.nix`

**Testing checklist:**
- [ ] `make lint` passes
- [ ] `make build` succeeds
- [ ] Package installs correctly on target platform(s)
- [ ] No conflicts with existing packages

### Adding a New Module
1. Create module file in appropriate directory
2. Import it in relevant host configurations or parent modules
3. Test on all affected platforms:
   - x86_64-darwin
   - aarch64-darwin  
   - x86_64-linux
   - aarch64-linux
4. Document any new conventions

### Creating a New Nix Project

1. **Using setup-dev script:**
   ```bash
   ./scripts/setup-dev [project-directory]  # Local execution
   nix run .#setup-dev [project-directory]  # Via flake app
   ```

2. **What it creates:**
   - Basic `flake.nix` with development shell
   - `.envrc` for direnv integration
   - `.gitignore` with Nix patterns

3. **Global installation (bl command system):**
   ```bash
   ./scripts/install-setup-dev        # Install once to enable bl commands
   bl setup-dev [project-directory]   # Use globally after installation
   bl list                            # List available commands
   ```

4. **Next steps:**
   - Customize `flake.nix` to add project-specific dependencies
   - Use `nix develop` or let direnv auto-activate the environment

## Troubleshooting & Best Practices

### 🔍 Common Issues & Solutions

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

### 🔒 Security Best Practices

1. **Never commit secrets**
   - Use `age` encryption for sensitive files
   - Store secrets in separate encrypted repository
   - Use environment variables for dynamic secrets

2. **Verify package sources**
   - Only use packages from nixpkgs or trusted overlays
   - Review custom overlays before applying

3. **Limit sudo usage**
   - Only use `build-switch` when necessary
   - Test builds without sudo first

### ⚡ Performance Optimization

1. **Build optimization**
   - Use `make smoke` for quick validation
   - Run `nix store gc` regularly to clean cache
   - Use `--max-jobs` flag for parallel builds

2. **Development workflow**
   - Use `direnv` for automatic environment activation
   - Keep separate dev shells for different projects
   - Cache frequently used packages

### 📋 Pre-commit Checklist

- [ ] `export USER=<username>` is set
- [ ] `make lint` passes without errors
- [ ] `make smoke` validates flake structure
- [ ] `make build` completes successfully
- [ ] Changes tested on target platform(s)
- [ ] Documentation updated if needed
- [ ] No secrets or sensitive information committed

## Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality.

### Installation and Setup

```bash
# Install pre-commit (using pip or conda)
pip install pre-commit

# Or install with nix (recommended)
nix-shell -p pre-commit

# Install hooks
pre-commit install

# Run hooks on all files
pre-commit run --all-files
```

### Currently Configured Hooks

- **Nix Flake Check**: Runs `nix flake check --all-systems --no-build` when any `.nix` file changes
- Provides fast syntax checking and flake validation

### Usage

```bash
# Auto-runs before commit (after hooks installed)
git commit -m "your commit message"

# Manually check all files
pre-commit run --all-files

# Check specific files only
pre-commit run --files flake.nix

# Bypass hooks (not recommended)
git commit --no-verify -m "emergency commit"
```

### Troubleshooting

```bash
# Clean pre-commit cache
pre-commit clean

# Reinstall hooks
pre-commit uninstall
pre-commit install

# Disable specific hook (temporarily)
SKIP=nix-flake-check git commit -m "message"
```

## Advanced Topics

### Global Installation (bl command system)

Run `./scripts/install-setup-dev` to install the `bl` command system:
- Installs `bl` dispatcher to `~/.local/bin`
- Sets up command directory at `~/.bl/commands/`
- Installs `setup-dev` as `bl setup-dev`

**Available commands after installation:**
```bash
bl list              # List available commands
bl setup-dev my-app  # Initialize Nix project
bl setup-dev --help  # Get help
```

### Adding Custom Commands

To add new commands to the bl system:
1. Create executable script in `~/.bl/commands/`
2. Use `bl <command-name>` to run it
3. All arguments are passed through to your script

### Script Reusability

- Copy `scripts/setup-dev` to any location for standalone use
- No dependencies on dotfiles repository structure
- Includes help with `-h` or `--help` flag

## Claude Settings Preservation System

This dotfiles includes a **Smart Claude Settings Preservation System** that safely preserves user-personalized Claude settings even during system updates.

### How It Works

1. **Automatic Modification Detection**: Automatically detects user modifications via SHA256 hashing
2. **Priority-based Preservation**: Important files (`settings.json`, `CLAUDE.md`) are always preserved
3. **Safe Updates**: Provides safe updates by saving new versions as `.new` files
4. **User Notifications**: Automatically generates notifications when updates occur
5. **Merge Tool**: Supports settings integration with an interactive merge tool

### Key Features

- ✅ **Lossless Preservation**: User settings are never lost
- ✅ **Automatic Backup**: Creates automatic backups on every change
- ✅ **Interactive Merge**: Supports merging for JSON and text files
- ✅ **Custom File Protection**: Completely preserves user-added command files
- ✅ **Clean Cleanup**: Automatically cleans temporary files after merge

### Usage

#### Normal Situations (Automatic Handling)
Automatically works during system rebuilds:
```bash
nix run --impure .#build-switch
# or
make switch HOST=<host>
```

When user modifications are detected, the following files are created:
- `~/.claude/settings.json.new` - New dotfiles version
- `~/.claude/settings.json.update-notice` - Update notification

#### Manual Merge
After receiving an update notification, use the merge tool:

```bash
# Check files that need merging
./scripts/merge-claude-config --list

# Merge specific file
./scripts/merge-claude-config settings.json

# Interactive merge for all files
./scripts/merge-claude-config

# Check differences only
./scripts/merge-claude-config --diff CLAUDE.md
```

#### Advanced Usage

**JSON Settings Merge**: `settings.json` can be selectively merged by key
```bash
./scripts/merge-claude-config settings.json
# c) Keep current value
# n) Use new value  
# s) Skip
```

**Backup Management**:
```bash
# Backup file location
ls ~/.claude/.backups/

# Backups older than 30 days are automatically cleaned
```

### Troubleshooting

#### When Update Notifications are Generated
```bash
# 1. Check notification files
find ~/.claude -name "*.update-notice"

# 2. Review changes
./scripts/merge-claude-config --diff settings.json

# 3. Decide to merge or keep current version
./scripts/merge-claude-config settings.json

# 4. Clean up after completion
rm ~/.claude/*.new ~/.claude/*.update-notice
```

#### Restore from Backup
```bash
# Check backup files
ls ~/.claude/.backups/

# Restore to desired backup
cp ~/.claude/.backups/settings.json.backup.20240106_143022 ~/.claude/settings.json
```

### Preservation Policy

| File | Priority | Action |
|------|----------|--------|
| `settings.json` | High | Preserved when modified by user, new version saved as `.new` |
| `CLAUDE.md` | High | Preserved when modified by user, new version saved as `.new` |
| `commands/*.md` (dotfiles) | Medium | Overwrite after backup |
| `commands/*.md` (user) | High | Always preserved (files not in dotfiles) |

## Important Notes

### Critical Development Guidelines

1. **Always use `--impure` flag** when running nix commands that need environment variables
2. **Module Dependencies**: When modifying modules, check both direct imports and transitive dependencies
3. **Platform Testing**: Changes to shared modules should be tested on all four platforms
4. **Configuration Application**:
   - Darwin: Uses `darwin-rebuild switch`
   - NixOS: Uses `nixos-rebuild switch`
   - Both are wrapped by platform-specific scripts in `apps/`
5. **Home Manager Integration**: User-specific configurations are managed through Home Manager

### Workflow Requirements

- **Ask before major changes**: Always confirm before proceeding with significant modifications
- **Enable auto-merge for PRs**: Always turn on auto-merge option when creating pull requests
  ```bash
  # Method 1: Enable during PR creation
  gh pr create --assignee @me
  gh pr merge --auto --squash

  # Method 2: Enable for existing PR
  gh pr merge --auto --squash <PR-number>

  # Method 3: Via GitHub web interface
  # Navigate to PR → Click "Enable auto-merge" → Select "Squash and merge"
  ```

  **Auto-merge Benefits:**
  - ✅ Automatically merges when all CI checks pass
  - ✅ Reduces manual monitoring of PR status  
  - ✅ Ensures consistent squash-and-merge workflow
  - ✅ Speeds up development cycle

  **Prerequisites for auto-merge:**
  - All required CI checks must pass (lint, test, build)
  - No merge conflicts
  - Branch must be up-to-date with main
  - Repository admin approval (if required)
- **No AI attribution**: Act as if Claude Code was not used - do not mention AI assistance in commits or PRs
- **sudo requirements**: `nix run .#build-switch` can only be executed with root privileges
- **Tab navigation**: Maintain tab navigation functionality in UI components
- **Claude config preservation**: User modifications to Claude settings are automatically preserved

### Legacy Information

- System uses `build-switch` command for immediate configuration application
- All builds require USER environment variable to be set
- Root privileges are required for system-level configuration changes
