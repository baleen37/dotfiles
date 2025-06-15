# Complete Reference Guide

> **Comprehensive reference for all commands, APIs, and configuration options**

This document provides complete reference information for all available commands, applications, and configuration options in the dotfiles repository.

## 📋 Table of Contents

- [Makefile Targets](#makefile-targets)
- [Nix Flake Apps](#nix-flake-apps)
- [Scripts Reference](#scripts-reference)
- [Library Functions](#library-functions)
- [Test Framework](#test-framework)
- [Configuration Files](#configuration-files)

## 🔧 Makefile Targets

All Makefile targets automatically detect the `USER` environment variable and support additional arguments via `ARGS=`.

### Core Development

| Target | Description | Usage |
|--------|-------------|-------|
| `help` | Show all available targets with descriptions | `make help` |
| `check-user` | Verify USER environment variable is set | `make check-user` |
| `lint` | Run pre-commit hooks on all files | `make lint` |
| `smoke` | Run nix flake check without building | `make smoke` |

### Testing

| Target | Description | Platform Support |
|--------|-------------|------------------|
| `test` | Run comprehensive test suite | All platforms |
| `test-unit` | Run unit tests only | Darwin only |
| `test-integration` | Run integration tests only | Darwin only |
| `test-e2e` | Run end-to-end tests only | Darwin only |
| `test-perf` | Run performance tests only | Darwin only |
| `test-status` | Show test framework status | All platforms |

### Building & Deployment

| Target | Description | Requirements |
|--------|-------------|--------------|
| `build` | Build all Darwin and NixOS configurations | USER env var |
| `build-linux` | Build NixOS configurations only | USER env var |
| `build-darwin` | Build Darwin configurations only | USER env var |
| `switch` | Apply configuration to current machine | USER env var, admin access |

**Example Usage:**
```bash
# Basic usage
make build

# With custom arguments
make build ARGS="--verbose"

# With specific user
USER=myuser make build

# Switch to specific host
make switch HOST=aarch64-darwin
```

## 🚀 Nix Flake Apps

Applications available via `nix run .#<app-name>`. Platform availability varies.

### Platform Support Matrix

| App | aarch64-darwin | x86_64-darwin | aarch64-linux | x86_64-linux |
|-----|:--------------:|:-------------:|:-------------:|:------------:|
| **Core System** |
| `build` | ✅ | ✅ | ✅ | ✅ |
| `build-switch` | ✅ | ✅ | ✅ | ✅ |
| `apply` | ✅ | ✅ | ✅ | ✅ |
| `rollback` | ✅ | ✅ | ❌ | ❌ |
| **Testing** |
| `test` | ✅ | ✅ | ✅ | ✅ |
| `test-unit` | ✅ | ✅ | ❌ | ❌ |
| `test-integration` | ✅ | ✅ | ❌ | ❌ |
| `test-e2e` | ✅ | ✅ | ❌ | ❌ |
| `test-perf` | ✅ | ✅ | ❌ | ❌ |
| `test-smoke` | ✅ | ✅ | ✅ | ✅ |
| `test-list` | ✅ | ✅ | ✅ | ✅ |
| **Development** |
| `setup-dev` | ✅ | ✅ | ✅ | ✅ |
| **SSH Management** |
| `create-keys` | ✅ | ✅ | ✅ | ✅ |
| `copy-keys` | ✅ | ✅ | ✅ | ✅ |
| `check-keys` | ✅ | ✅ | ✅ | ✅ |
| **Linux-Specific** |
| `install` | ❌ | ❌ | ✅ | ✅ |

### Core System Apps

#### `build`
Build system configuration for current platform.
```bash
nix run .#build
```

#### `build-switch`
Build and immediately apply system configuration. **Requires sudo privileges.**
```bash
# Requires sudo from the start
sudo nix run --impure .#build-switch
```

#### `apply`
Apply pre-built system configuration.
```bash
nix run .#apply
```

#### `rollback` (Darwin only)
Rollback to previous system configuration.
```bash
nix run .#rollback
```

### Testing Apps

#### `test`
Run comprehensive test suite including unit, integration, and e2e tests.
```bash
nix run .#test
```

#### `test-unit` (Darwin only)
Run unit tests focusing on individual components.
```bash
nix run .#test-unit
```

#### `test-integration` (Darwin only)
Run integration tests for module interactions.
```bash
nix run .#test-integration
```

#### `test-e2e` (Darwin only)
Run end-to-end tests covering complete workflows.
```bash
nix run .#test-e2e
```

#### `test-perf` (Darwin only)
Run performance tests monitoring build times and resource usage.
```bash
nix run .#test-perf
```

#### `test-smoke`
Quick validation tests without full system builds.
```bash
nix run .#test-smoke
```

### Development Apps

#### `setup-dev`
Initialize a new Nix project with flake.nix, .envrc, and .gitignore.
```bash
# Initialize in current directory
nix run .#setup-dev

# Initialize in specific directory
nix run .#setup-dev my-project

# Show help
nix run .#setup-dev -- --help
```

**Creates:**
- `flake.nix` with development shell
- `.envrc` for direnv integration
- `.gitignore` with Nix patterns

### SSH Management Apps

#### `create-keys`
Generate SSH keys for development environments.
```bash
nix run .#create-keys
```

#### `copy-keys`
Copy SSH keys to remote hosts.
```bash
nix run .#copy-keys
```

#### `check-keys`
Verify SSH key configuration and connectivity.
```bash
nix run .#check-keys
```

## 📝 Scripts Reference

Scripts located in the `scripts/` directory.

### Core Scripts

#### `setup-dev`
Standalone project initialization script.
```bash
# Local execution
./scripts/setup-dev [project-directory]

# Show help
./scripts/setup-dev --help
```

**Features:**
- No dependencies on dotfiles repository
- Includes comprehensive help text
- Creates complete Nix project structure

#### `install-setup-dev`
Install global `bl` command system.
```bash
./scripts/install-setup-dev
```

**Installation:**
- Creates `~/.local/bin/bl` dispatcher
- Sets up `~/.bl/commands/` directory
- Installs `setup-dev` as `bl setup-dev`

#### `auto-update-dotfiles`
Intelligent auto-update system with TTL-based checking.
```bash
# Manual check (respects 1-hour TTL)
./scripts/auto-update-dotfiles

# Force immediate check and update
./scripts/auto-update-dotfiles --force

# Silent operation (for background use)
./scripts/auto-update-dotfiles --silent
```

**Features:**
- TTL-based checking (1 hour default)
- Local change detection
- Safe application using build-switch
- Background operation support

#### `merge-claude-config`
Interactive configuration merger for handling conflicts.
```bash
# List files needing merge attention
./scripts/merge-claude-config --list

# Interactively merge specific file
./scripts/merge-claude-config settings.json

# View differences without merging
./scripts/merge-claude-config --diff CLAUDE.md

# Merge all pending files
./scripts/merge-claude-config
```

**Capabilities:**
- JSON key-by-key merging
- Multiple text merge strategies
- Automatic backup creation
- Interactive conflict resolution

#### `test-all-local`
Comprehensive local testing that mirrors the CI pipeline.
```bash
./scripts/test-all-local
```

**Test Coverage:**
- Pre-commit lint checks
- Smoke tests (flake validation)
- Unit tests (individual components)
- Integration tests (module interactions)
- Build tests (full configurations)
- End-to-end tests (complete workflows)

### Additional Scripts

#### `build-with-progress`
Build system with progress indication.
```bash
./scripts/build-with-progress
```

#### `detect-user`
User detection utility for system configuration.
```bash
./scripts/detect-user
```

### Global Command System (`bl`)

After installing via `./scripts/install-setup-dev`:

```bash
# List available commands
bl list

# Initialize new Nix project
bl setup-dev my-project

# Get help for specific command
bl setup-dev --help
```

## 📚 Library Functions

Nix utility functions in the `lib/` directory.

### Core Libraries

#### `get-user.nix`
Dynamic user resolution supporting both `$USER` and `$SUDO_USER` environment variables.

```nix
# Usage in Nix expressions
let user = import ./lib/get-user.nix { };
```

**Features:**
- Automatic fallback to `$SUDO_USER` when available
- Error handling for missing environment variables
- Support for impure evaluation contexts

#### `platform-apps.nix`
Platform-specific application generation.

```nix
# Import in flake.nix
platformApps = import ./lib/platform-apps.nix { inherit nixpkgs self; };
```

**Generates:**
- Core system apps (build, apply, rollback)
- SSH management tools
- Development utilities
- Platform-specific availability matrix

#### `test-apps.nix`
Test framework application generation.

```nix
# Import in flake.nix
testApps = import ./lib/test-apps.nix { inherit nixpkgs self; };
```

**Features:**
- Hierarchical test structure (unit, integration, e2e, performance)
- Platform-specific test availability
- Test discovery and execution
- Framework status reporting

#### `performance-config.nix`
Performance optimization configurations.

```nix
# Import for performance settings
performanceConfig = import ./lib/performance-config.nix { };
```

#### `error-messages.nix`
Standardized error message formatting.

```nix
# Import for consistent error handling
errorMessages = import ./lib/error-messages.nix { };
```

#### `test-utils.nix`
Testing utility functions.

```nix
# Import for test development
testUtils = import ./lib/test-utils.nix { };
```

### Module System Libraries

#### `conditional-file-copy.nix`
Conditional file copying with user modification detection.

```nix
# Located in modules/shared/lib/
conditionalFileCopy = import ./conditional-file-copy.nix { };
```

#### `claude-config-policy.nix`
Claude configuration preservation policies.

```nix
# Located in modules/shared/lib/
claudeConfigPolicy = import ./claude-config-policy.nix { };
```

#### `file-change-detector.nix`
SHA256-based file change detection.

```nix
# Located in modules/shared/lib/
fileChangeDetector = import ./file-change-detector.nix { };
```

## 🧪 Test Framework

Hierarchical test structure with platform-specific capabilities.

### Test Categories

#### Unit Tests (`tests/unit/`)
Individual component testing.

**Available tests:**
- `basic-functionality-unit.nix` - Core functionality validation
- `claude-config-copy-unit.nix` - Claude configuration copying
- `error-handling-unit.nix` - Error handling mechanisms
- `input-validation-unit.nix` - Input validation procedures
- `platform-detection-unit.nix` - Platform detection logic
- `user-resolution-unit.nix` - User resolution mechanisms

#### Integration Tests (`tests/integration/`)
Module interaction testing.

**Available tests:**
- `cross-platform-integration.nix` - Cross-platform compatibility
- `module-dependency-integration.nix` - Module dependencies
- `package-availability-integration.nix` - Package availability
- `system-build-integration.nix` - System build processes

#### End-to-End Tests (`tests/e2e/`)
Complete workflow testing.

**Available tests:**
- `build-switch-auto-update-e2e.nix` - Auto-update workflows
- `claude-config-workflow-e2e.nix` - Claude configuration workflows
- `complete-workflow-e2e.nix` - Complete system workflows
- `system-deployment-e2e.nix` - System deployment processes

#### Performance Tests (`tests/performance/`)
Build time and resource monitoring.

**Available tests:**
- `build-time-perf.nix` - Build time monitoring
- `resource-usage-perf.nix` - Resource usage profiling

### Test Execution

#### Platform-Specific Execution
```bash
# Darwin systems (full test suite)
nix run .#test-unit
nix run .#test-integration
nix run .#test-e2e
nix run .#test-perf

# Linux systems (basic tests only)
nix run .#test
nix run .#test-smoke
```

#### Test Framework Status
```bash
# Check framework health
make test-status
nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').framework_status
```

## ⚙️ Configuration Files

### Environment Configuration

#### Environment Variables
- **`USER`**: Required for system evaluation and user resolution
- **`SUDO_USER`**: Fallback user for sudo contexts
- **`HOST`**: Target system for switch operations

#### Persistent Configuration
```bash
# Add to shell profile for persistence
echo "export USER=\$(whoami)" >> ~/.bashrc  # or ~/.zshrc
```

### Package Configuration

#### Shared Packages (`modules/shared/packages.nix`)
Cross-platform package definitions.
```nix
{ pkgs }: with pkgs; [
  # Development tools
  git
  vim
  curl
  jq
  # ... 46+ packages total
]
```

#### Darwin Packages (`modules/darwin/packages.nix`)
macOS-specific packages.
```nix
{ pkgs }: with pkgs; [
  # macOS-specific tools
]
```

#### Darwin Casks (`modules/darwin/casks.nix`)
Homebrew cask definitions.
```nix
_: [
  # GUI applications
  "visual-studio-code"
  "docker"
  # ... 34+ casks total
]
```

#### NixOS Packages (`modules/nixos/packages.nix`)
NixOS-specific packages.
```nix
{ pkgs }: with pkgs; [
  # NixOS-specific tools
]
```

### System Configuration

#### Flake Configuration (`flake.nix`)
Main system configuration entry point.

**Key sections:**
- Input definitions (nixpkgs, home-manager, darwin, etc.)
- System configurations (darwinConfigurations, nixosConfigurations)
- Application definitions (apps)
- Test definitions (checks)

#### Host Configurations (`hosts/`)
Individual machine configurations.

**Structure:**
```
hosts/
├── darwin/
│   └── default.nix     # macOS host configuration
└── nixos/
    └── default.nix     # NixOS host configuration
```

---

> **Note**: This reference is generated from actual code analysis. For the most current information, always check the source code directly.
