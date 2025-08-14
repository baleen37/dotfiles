# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Dotfiles Repository Context

This is a Nix-based dotfiles repository for macOS and NixOS systems, using Nix flakes, Home Manager, and nix-darwin.

## Essential Commands

### Building and Applying Configurations

```bash
# Always set USER first
export USER=$(whoami)

# Build and apply in one step (recommended)
./apps/x86_64-linux/build-switch   # For NixOS
./apps/aarch64-darwin/build-switch # For macOS ARM
./apps/x86_64-darwin/build-switch  # For macOS Intel

# Alternative: Use make commands
make build          # Build all configurations
make switch         # Build and apply current platform
make build-switch   # One-step build and apply
```

### Testing

```bash
make test           # Run all tests
make test-core      # Fast essential tests
make test-workflow  # End-to-end workflow tests  
make smoke          # Quick validation check
```

### Platform-Specific Operations

```bash
# Direct Nix operations
nix run --impure .#build         # Build current platform
nix run --impure .#build-switch  # Build and apply with sudo handling
nix run --impure .#test-core     # Run core tests directly
```

## Architecture

### Core Structure
- **`flake.nix`**: Main entry point using `lib/flake-config.nix`
- **`lib/`**: System utilities, platform detection (`platform-system.nix`, `user-resolution.nix`)
- **`modules/`**: Modular configurations
  - `shared/`: Cross-platform configurations
  - `darwin/`: macOS-specific settings
  - `nixos/`: NixOS-specific settings
- **`hosts/`**: System configurations (`darwin/default.nix`, `nixos/default.nix`)
- **`scripts/`**: Build automation and utilities

### Home Manager Architecture Rules
- **`modules/shared/home-manager.nix`**: Contains ONLY cross-platform configurations
- **`modules/darwin/home-manager.nix`**: Darwin-specific, imports shared
- **`modules/nixos/home-manager.nix`**: NixOS-specific, imports shared
- **NEVER import shared directly at system level** - always through platform modules
- Use `lib.optionalString isDarwin/isLinux` for conditional configurations

### Package Management
- **`modules/shared/packages.nix`**: Core packages installed via Nix
- **`modules/darwin/casks.nix`**: macOS GUI applications via Homebrew
- **Python tools**: Managed via `uv` (fast Python package installer)
- **All installations must be managed via Nix** - no ad-hoc installations

### Build System
- **Platform detection**: Automatic via `lib/platform-system.nix`
- **User resolution**: Dynamic via `lib/user-resolution.nix`
- **Build scripts**: Located in `apps/[platform]/build-switch`
- **Common logic**: `scripts/build-switch-common.sh`

## Claude Code Integration

### MCP Servers
- Context7, Sequential, Playwright configured
- Setup: `make setup-mcp`

### Custom Commands
Located in `modules/shared/config/claude/commands/`:
- `/analyze`, `/build`, `/commit`, `/create-pr`, `/debug`, `/implement`, `/spawn`, `/task`, `/test`
- PR workflow: `/fix-pr`, `/update-pr`  
- State management: `/save`, `/restore`

### Specialized Agents
Located in `modules/shared/config/claude/agents/`:
- `backend-engineer`, `frontend-specialist`, `system-architect`, `test-automator`
- `python-ultimate-expert`, `typescript-pro`, `golang-pro`
- `debugger`, `code-reviewer`, `devops-engineer`

### Configuration Activation
Claude configurations are automatically deployed to `~/.claude/` during system build.

## Testing Standards
- **Required**: Unit + integration + E2E tests for all changes
- **Test categories**: core, workflow, performance
- **Quick validation**: `make smoke` before commits
- **Full suite**: `make test` before PRs

## Development Policies
- **All installations via Nix** - maintain declarative configuration
- **Platform-specific code** goes in respective modules (darwin/nixos)
- **Cross-platform code** in shared modules with proper conditionals
- **Test before commit** - use `make test-core` at minimum

## Global Commands
- **`bl`**: Custom command dispatcher system
- Commands stored in `~/.bl/commands/`
- Extensible through Nix configuration