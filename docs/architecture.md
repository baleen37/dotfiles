# Architecture & Reference Guide

> **Complete architectural overview, module reference, and implementation details**

This document covers the system architecture, module organization, library functions, and detailed reference information for the Nix flake-based dotfiles repository.

## 🏗️ System Architecture

### High-Level Structure
```
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
```

### Core Principles

1. **Flake-Based Architecture**: Reproducible builds with locked dependencies
2. **Modular Design**: Platform-specific and shared modules for maintainability
3. **Cross-Platform Support**: Unified configuration for macOS (Darwin) and Linux (NixOS)
4. **User Resolution**: Dynamic username handling via `lib/get-user.nix`
5. **Testing Integration**: Comprehensive test framework with multiple test types

## 📁 Directory Structure

```
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
```

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
```
tests/
├── unit/                    # Unit tests (fast, isolated)
├── integration/             # Integration tests (system-level)
├── e2e/                     # End-to-end tests (full workflows)
└── performance/             # Performance tests
```

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
