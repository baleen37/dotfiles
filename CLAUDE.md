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

### Context7 Integration

- **Claude Code Documentation**: Use Context7 when modifying Claude Code settings, commands, agents, or configurations
- **Settings Updates**: Always consult Context7 documentation before changing Claude settings
- **Commands & Agents**: Reference Context7 for Claude Code command patterns and agent configurations
- **Best Practices**: Context7 provides comprehensive examples for MCP integration, hooks, and workflow patterns

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

### Configuration Structure

Claude Code settings are organized in `modules/shared/config/claude/`:

```text
modules/shared/config/claude/
├── CLAUDE.md                    # Global user instructions
├── settings.json                # Permission, environment, MCP settings
├── agents/                      # Specialized AI agents (13 agents)
│   ├── backend-engineer.md
│   ├── frontend-specialist.md
│   ├── python-ultimate-expert.md
│   └── ...
├── commands/                    # Custom slash commands (24 commands)
│   ├── /create-pr.md
│   ├── /analyze.md
│   ├── /implement.md
│   └── ...
└── hooks/                       # Event-based automation hooks
    ├── user-prompt-submit-hook.sh
    ├── tool-before-use-hook.sh
    └── ...
```

### Configuration Activation

Claude configurations are automatically deployed via symbolic links during system build:

**Deployment Process**:

1. **Source**: `~/dotfiles/modules/shared/config/claude/`
2. **Target**: `~/.claude/` (Claude Code user directory)
3. **Method**: Folder-level symbolic links via `claude-activation.nix`

**Symbolic Link Structure**:

```bash
~/.claude/
├── CLAUDE.md -> ~/dotfiles/modules/shared/config/claude/CLAUDE.md
├── settings.json -> ~/dotfiles/modules/shared/config/claude/settings.json
├── agents/ -> ~/dotfiles/modules/shared/config/claude/agents/
├── commands/ -> ~/dotfiles/modules/shared/config/claude/commands/
└── hooks/ -> ~/dotfiles/modules/shared/config/claude/hooks/
```

**Activation Trigger**: Home Manager activation script in `modules/shared/home-manager.nix`

### Token Optimization

Claude Code provides settings for optimizing token usage and preventing context bloat:

**Context Bloat Prevention**:
Long outputs from bash commands, MCP tools, or file reads can quickly consume context windows, leading to:

- Increased costs per conversation
- Slower response times
- Loss of important context due to truncation
- Poor conversation quality

Token limits help maintain focused, cost-effective conversations by truncating verbose outputs while preserving essential information.

**Reference**: Use Context7 for additional Claude Code optimization patterns

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

- claude code command 를 사용할 때 flag 기반으로 하기 싫어.

- claude code command 에서 flag 개념은 안쓸거야.
- 보안은 딱히 신경 안쓰고 있어.
