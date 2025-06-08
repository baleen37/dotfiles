# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Nix flake-based dotfiles repository for managing macOS and NixOS development environments declaratively. It supports x86_64 and aarch64 architectures on both platforms.

## Essential Commands

### Development Workflow
```bash
# Required: Set USER environment variable (or use --impure flag)
export USER=<username>

# Core development commands
make lint           # Run pre-commit hooks (MUST pass before committing)
make smoke          # Quick flake validation without building
make test           # Run all unit and e2e tests
make build          # Build all configurations
make switch HOST=<host>  # Apply configuration to current system

# Platform-specific builds
nix run .#build     # Build for current system
nix run .#switch    # Build and switch for current system

# Project initialization
./scripts/setup-dev [project-dir]  # Initialize new Nix project with flake.nix and direnv
nix run .#setup-dev [project-dir]  # Same as above, using nix flake app

# Global installation (bl command system)
./scripts/install-setup-dev        # Install bl command system (run once)
```

### Testing Requirements (Follow CI Pipeline)
Before submitting any changes, run these commands in order:
```bash
make lint   # pre-commit run --all-files  
make smoke  # nix flake check --all-systems --no-build
make build  # build all NixOS/darwin configurations
make smoke  # final flake check after build
```

### Running Individual Tests
```bash
# Run specific test file
nix eval --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').simple

# Run all tests for current system
nix flake check --impure
```

## Architecture Overview

### Module System
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

## Critical Development Notes

1. **Always use `--impure` flag** when running nix commands that need environment variables:
   ```bash
   nix run --impure .#build
   ```

2. **Module Dependencies**: When modifying modules, check both direct imports and any modules that might transitively import your changes.

3. **Platform Testing**: Changes to shared modules should be tested on all four platforms:
   - x86_64-darwin
   - aarch64-darwin  
   - x86_64-linux
   - aarch64-linux

4. **Configuration Application**: 
   - Darwin: Uses `darwin-rebuild switch`
   - NixOS: Uses `nixos-rebuild switch`
   - Both are wrapped by platform-specific scripts in `apps/`

5. **Home Manager Integration**: User-specific configurations are managed through Home Manager, integrated into both Darwin and NixOS system configurations.

## Agent Guidelines

Refer to `AGENTS.md` for specific guidelines when making automated changes. Key points:
- Test changes using the testing workflow before committing
- Update documentation when adding new modules or changing architecture
- Follow existing code patterns and conventions
- Use Korean language in AGENTS.md updates

## Common Tasks

### Adding a New Package
1. For all platforms: Edit `modules/shared/packages.nix`
2. For macOS only: Edit `modules/darwin/packages.nix`
3. For NixOS only: Edit `modules/nixos/packages.nix`
4. For Homebrew casks: Edit `modules/darwin/casks.nix`

### Adding a New Module
1. Create module file in appropriate directory
2. Import it in relevant host configurations or parent modules
3. Test on all affected platforms
4. Document any new conventions in AGENTS.md

### Creating a New Nix Project

1. Run `./scripts/setup-dev [project-directory]` to initialize a new project
2. The script creates:
   - Basic `flake.nix` with development shell
   - `.envrc` for direnv integration
   - `.gitignore` with Nix patterns
3. Customize `flake.nix` to add project-specific dependencies
4. Use `nix develop` or let direnv auto-activate the environment

### Script Reusability

- Copy `scripts/setup-dev` to any location for standalone use
- No dependencies on dotfiles repository structure
- Includes help with `-h` or `--help` flag

### Global Installation (bl command system)

Run `./scripts/install-setup-dev` to install the `bl` command system:
- Installs `bl` dispatcher to `~/.local/bin`
- Sets up command directory at `~/.bl/commands/`
- Installs `setup-dev` as `bl setup-dev`

After installation:
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

### Debugging Build Failures
```bash
# Show detailed error trace
nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system

# Check flake outputs
nix flake show --impure

# Validate flake structure
nix flake check --impure --no-build
```

## Memories
- `nix run .#build-switch 로 실행시켜야지 switch하는거야`: Note for using build-switch command in Nix for system configuration