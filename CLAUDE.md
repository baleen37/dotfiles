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

# Run specific test categories
nix run .#test-unit               # Unit tests only
nix run .#test-integration        # Integration tests only  
nix run .#test-e2e                # End-to-end tests only
nix run .#test-perf               # Performance tests only
nix run .#test-smoke              # Quick smoke tests

# Run specific test file
nix eval --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').simple
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

# 6. Create PR
gh pr create --assignee @me
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
     darwinConfigurations."aarch64-darwin" = ...;
     nixosConfigurations."x86_64-linux" = ...;
     apps.{system}.{build,switch,rollback} = ...;
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
- `apps/{architecture}/`: Platform-specific shell scripts
- `tests/`: Unit and integration tests
- `lib/`: Shared Nix functions (especially `get-user.nix`)
- `scripts/`: Management and development tools

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

3. **Next steps:**
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
- **No AI attribution**: Act as if Claude Code was not used - do not mention AI assistance in commits or PRs
- **sudo requirements**: `nix run .#build-switch` can only be executed with root privileges
- **Tab navigation**: Maintain tab navigation functionality in UI components

### Legacy Information

- System uses `build-switch` command for immediate configuration application
- All builds require USER environment variable to be set
- Root privileges are required for system-level configuration changes