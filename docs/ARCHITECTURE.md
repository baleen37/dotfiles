# Architecture & Reference Guide

> **Complete architectural overview, module reference, and implementation details**

This document covers the system architecture, module organization, library functions, and detailed reference information for the Nix flake-based dotfiles repository.

## System Overview

This dotfiles system is built on a **modular, test-driven architecture** that provides:

- **Cross-platform compatibility**: Native support for macOS and NixOS
- **Externalized configuration**: YAML-based configuration system
- **Comprehensive testing**: Multi-tier testing framework (Unit, Integration, E2E, Performance)
- **TDD-driven development**: Red-Green-Refactor development cycle
- **Intelligent automation**: Auto-update, cache management, and build optimization

### Key Design Principles

1. **Modularity**: Clear separation of concerns with independent, reusable modules
2. **Configuration Externalization**: No hardcoded values, everything configurable via YAML
3. **Test-Driven Development**: All features developed using Red-Green-Refactor TDD methodology
4. **Platform Independence**: Common core with platform-specific overlays
5. **Incremental Improvement**: Preserve existing functionality while adding enhancements

### Phase 4 Architectural Improvements (2025-07-08)

#### 📁 Optimized Directory Structure

- **apps/common/**: Shared logic across all platforms
- **apps/platforms/**: Platform-specific implementations (Darwin/Linux)
- **apps/targets/**: Architecture-specific configurations
- **scripts/build/**: Modularized build system with platform separation
- **scripts/utils/**: Utility scripts and configuration loaders
- **config/**: External configuration files (YAML-based)
- **modules/platform/**: Platform-specific Nix modules organization

#### ⚙️ Configuration Externalization System

- **Unified Config Interface**: `get_unified_config()` for intelligent config access
- **Performance Caching**: Configuration loading optimization with state tracking
- **Profile System**: Environment-specific configuration profiles (dev/prod)
- **Advanced Settings**: Extended configuration for power users
- **Backward Compatibility**: Graceful fallbacks for legacy systems

## 🏗️ System Architecture

### High-Level Structure

```text
┌─────────────────────────────────────────────────────────────────┐
│                          flake.nix                              │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │   Inputs     │  │   Outputs    │  │    Libraries       │   │
│  │  - nixpkgs   │  │  - configs   │  │  - get-user       │   │
│  │  - darwin    │  │  - apps      │  │  - platform-apps  │   │
│  │  - home-mgr  │  │  - checks    │  │  - test-apps      │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Module System                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │  Platform      │  │    Shared      │  │     Host       │   │
│  │   Modules      │  │   Modules      │  │   Configs      │   │
│  │               │  │               │  │               │   │
│  │ • darwin/     │  │ • packages    │  │ • darwin/     │   │
│  │ • nixos/      │  │ • files       │  │ • nixos/      │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

## Configuration System

The system uses a **three-tier configuration approach**:

### 1. YAML Configuration Files

```textyaml
# config/platforms.yaml - Platform definitions
platforms:
  supported_systems: ["x86_64-darwin", "aarch64-darwin", "x86_64-linux", "aarch64-linux"]
  platform_configs:
    darwin: { type: "darwin", rebuild_command: "darwin-rebuild" }
    linux: { type: "linux", rebuild_command: "nixos-rebuild" }

# config/cache.yaml - Cache management
cache:
  local: { max_size_gb: 5, cleanup_days: 7 }
  binary_caches: ["https://cache.nixos.org", "https://nix-community.cachix.org"]

# config/network.yaml - Network settings
network:
  http: { connections: 50, connect_timeout: 5, download_attempts: 3 }

# config/performance.yaml - Performance tuning
performance:
  build: { max_jobs: "auto", cores: 0 }
  memory: { min_free: 1073741824, max_free: 10737418240 }

# config/security.yaml - Security policies
security:
  ssh: { key_type: "ed25519", default_dir: "$HOME/.ssh" }
  sudo: { refresh_interval: 240, session_timeout: 900 }
```text

### 2. Environment Variable Overrides

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
```text

### 3. Configuration Loading API

```bash
# scripts/utils/config-loader.sh
source scripts/utils/config-loader.sh

# Load with defaults
cache_size=$(load_cache_config "max_size_gb" "5")
connections=$(load_network_config "http_connections" "50")
rebuild_cmd=$(load_platform_config "darwin" "rebuild_command" "darwin-rebuild")
```text

## Build Process

The build system follows a **multi-stage, platform-aware approach**:

### 1. Configuration Loading

```bash
# Load platform-specific configuration
source apps/$PLATFORM_SYSTEM/config.sh

# Load common configuration
source scripts/utils/config-loader.sh
```text

### 2. Environment Preparation

```bash
# Cache initialization
init_cache_stats
optimize_cache_usage

# Sudo session management (for system builds)
setup_sudo_session
refresh_sudo_if_needed
```text

### 3. Platform-Specific Build

```bash
# Darwin systems
case "$PLATFORM_TYPE" in
  "darwin")
    REBUILD_COMMAND="darwin-rebuild"
    FLAKE_TARGET="darwinConfigurations.$SYSTEM_TYPE.system"
    ;;
  "linux")
    REBUILD_COMMAND="nixos-rebuild"
    FLAKE_TARGET="nixosConfigurations.$SYSTEM_TYPE.config.system.build.toplevel"
    ;;
esac
```text

### 4. Build Execution

```bash
# Nix build with optimization
nix build ".#$FLAKE_TARGET" \
  --max-jobs "$MAX_JOBS" \
  --cores "$BUILD_CORES" \
  --substitute-on-destination
```text

### 5. System Activation

```bash
# Apply configuration with sudo handling
if [[ "$REQUIRES_SUDO" == "true" ]]; then
  sudo "$REBUILD_COMMAND" switch --flake .
else
  "$REBUILD_COMMAND" switch --flake .
fi
```text

## Testing Framework

The testing framework implements a **four-tier testing strategy**:

### 1. Unit Tests (`tests/unit/`)

**Purpose**: Test individual functions and modules in isolation

```textnix
# Example: tests/unit/cache-management-unit.nix
{ pkgs, src ? ../. }:
pkgs.runCommand "cache-management-test" { } ''
  echo "🧪 Cache Management Unit Tests"

  # Test cache size calculation
  source ${src}/scripts/lib/cache-management.sh

  # Mock environment
  export CACHE_MAX_SIZE_GB=10

  # Test function
  if [[ $(get_cache_limit) == "10737418240" ]]; then
    echo "✅ Cache size calculation correct"
  else
    echo "❌ Cache size calculation failed"
    exit 1
  fi

  touch $out
''
```text

### 2. Integration Tests (`tests/integration/`)

**Purpose**: Test module interactions and cross-component functionality

### 3. End-to-End Tests (`tests/e2e/`)

**Purpose**: Test complete user workflows from start to finish

### 4. Performance Tests (`tests/performance/`)

**Purpose**: Measure and validate system performance characteristics

### TDD Development Cycle

```bash
# 1. Red Phase - Write failing test
nix build .#checks.aarch64-darwin.new_feature_unit
# Expected: Build fails

# 2. Green Phase - Minimal implementation
# Write code to make test pass
nix build .#checks.aarch64-darwin.new_feature_unit
# Expected: Build succeeds

# 3. Refactor Phase - Improve code quality
# Refactor while keeping tests green
nix build .#checks.aarch64-darwin.new_feature_unit
# Expected: Still succeeds
```text

### Core Principles

1. **Flake-Based Architecture**: Reproducible builds with locked dependencies
2. **Modular Design**: Platform-specific and shared modules for maintainability
3. **Cross-Platform Support**: Unified configuration for macOS (Darwin) and Linux (NixOS)
4. **User Resolution**: Dynamic username handling via `lib/get-user.nix`
5. **Testing Integration**: Comprehensive test framework with multiple test types

## 📁 Directory Structure

```text

.
├── flake.nix                    # Main flake definition
├── flake.lock                  # Locked dependency versions
├── Makefile                    # Build shortcuts and commands
├── CLAUDE.md                   # Main project documentation
│
├── lib/                        # Shared Nix library functions
│   ├── get-user.nix           # User resolution system
│   ├── platform-apps.nix      # Platform-specific app generators
│   └── test-apps.nix          # Test application builders
│
├── hosts/                      # Host-specific configurations
│   ├── darwin/                # macOS host configurations
│   └── nixos/                 # Linux host configurations
│
├── modules/                    # Modular configuration system
│   ├── shared/                # Cross-platform modules
│   ├── darwin/                # macOS-specific modules
│   └── nixos/                 # Linux-specific modules
│
├── apps/                       # Platform-specific executables
│   ├── aarch64-darwin/        # Apple Silicon apps
│   ├── x86_64-darwin/         # Intel Mac apps
│   ├── aarch64-linux/         # ARM64 Linux apps
│   └── x86_64-linux/          # x86_64 Linux apps
│
├── scripts/                    # Utility scripts and automation
│   ├── lib/                   # Script modules (modularized)
│   └── templates/             # Script templates
│
├── overlays/                   # Nix package overlays
├── tests/                      # Comprehensive test suite
└── docs/                       # Documentation
```text

## 🔧 Module System

### Module Hierarchy and Import Rules

1. **Platform-specific modules** (`modules/darwin/`, `modules/nixos/`)
   - Contains OS-specific configurations
   - Imported only by respective platform configurations

2. **Shared modules** (`modules/shared/`)
   - Cross-platform configurations (git, zsh, vim, tmux)
   - Can be imported by both Darwin and NixOS configurations
   - Layout: `config/` (non-Nix files), `cachix/` (build cache), `files.nix` (static configs), `home-manager.nix` (main config), `packages.nix` (shared packages)

3. **Host configurations** (`hosts/`)
   - Individual machine configurations
   - Import appropriate platform and shared modules

## 📚 Core Library Functions

### User Resolution System (`lib/get-user.nix`)

Dynamic username detection for cross-platform compatibility.

### Platform Applications (`lib/platform-apps.nix`)

Generate platform-specific applications and build tools.

### Test Applications (`lib/test-apps.nix`)

Test framework integration with multiple test categories.

## 🔄 Flake Output Structure

### Application Availability by Platform

| Application | Darwin | Linux | Description |
|-------------|--------|-------|-------------|
| `build` | ✅ | ✅ | Build system configuration |
| `build-switch` | ✅ | ✅ | Build and apply configuration |
| `apply` | ✅ | ✅ | Apply configuration to system |
| `test-unit` | ✅ | ❌ | Unit tests (Darwin only) |
| `test-integration` | ✅ | ❌ | Integration tests (Darwin only) |
| `test` | ✅ | ✅ | Basic tests (all platforms) |

## 🧪 Testing Architecture

### Test Framework Structure

```text

tests/
├── unit/                    # Unit tests (fast, isolated)
├── integration/             # Integration tests (system-level)
├── e2e/                     # End-to-end tests (full workflows)
└── performance/             # Performance tests
```text

### Test Categories

- **Core Tests**: Essential functionality (7 tests)
- **Workflow Tests**: End-to-end scenarios (5 tests)
- **Performance Tests**: Build time and resource usage (3 tests)

## 🚀 Build System Architecture

### Modular Build Scripts

The build system is modularized into focused components:

- **`scripts/lib/logging.sh`**: Color-coded logging and output formatting
- **`scripts/lib/performance.sh`**: Build time monitoring and optimization
- **`scripts/lib/sudo-management.sh`**: Privilege management and security
- **`scripts/lib/build-logic.sh`**: Core build and switch orchestration

### Apply Script Template System

Apply scripts are deduplicated using a template system:

- **Template**: `scripts/templates/apply-template.sh` (common logic)
- **Configs**: `apps/*/config.sh` (platform-specific variables)
- **Wrappers**: `apps/*/apply` (11-line delegation scripts)

This achieves **90% code deduplication** (656 lines → 65 lines).

## 🔒 Security Model

### Configuration Management

- **Immutable Files**: Static configurations are read-only
- **Secret Management**: Sensitive data handled via `age` encryption
- **Privilege Separation**: Build vs. runtime privilege separation

## 📊 Performance Characteristics

### Build Optimization

- **Parallel Jobs**: Auto-detection of optimal core count
- **CI Limits**: Conservative resource usage in CI environments
- **Caching**: Aggressive use of Nix binary caches

### CI Performance Optimization

**Performance Improvements** (67% faster execution):

- **Parallel Platform Builds**: All 4 platforms tested simultaneously
- **Smart Test Selection**: Draft PRs use quick smoke tests (5 min)
- **Efficient Caching**: Nix store caching across builds
- **Resource Management**: Optimal job parallelization

**CI Workflow Strategy**:

- Draft PRs: `make smoke` only (fast validation)
- Ready PRs: Full build matrix (comprehensive testing)
- Main branch: Complete test suite with performance monitoring

## 🔧 Extension Points

### Adding New Platforms

1. Create platform directory: `modules/newplatform/`
2. Add platform apps: `apps/arch-newplatform/`
3. Update flake outputs: Add to `allSystems`
4. Create host configurations: `hosts/newplatform/`

### Custom Modules

Create new modules in appropriate directories following the established patterns.

## 🔗 Integration Points

### Home Manager Integration

User-specific configurations managed through Home Manager.

### Overlay System

Custom package definitions and patches in `overlays/`.

### Claude Code Integration

- **Smart Preservation**: User settings preserved across updates
- **Command System**: 20+ specialized development commands
- **Context Awareness**: Nix and flake-aware AI assistance

## 📈 Metrics and Monitoring

### Build Metrics

- **Build Time**: Per-phase timing (build, switch, cleanup)
- **Resource Usage**: CPU, memory, disk utilization
- **Parallelization**: Job count and efficiency

### Test Metrics

- **Coverage**: Test coverage across modules and platforms
- **Performance**: Test execution time and resource usage
- **Success Rate**: Test reliability and flake detection

This architecture provides a robust, scalable foundation for cross-platform dotfiles management with comprehensive testing, security, and extensibility.
