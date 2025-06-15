# Architecture Overview

This document describes the architectural design and structure of the Nix flake-based dotfiles repository.

## System Architecture

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
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    System Configuration                         │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │ Darwin Build  │  │  NixOS Build   │  │  Home Manager  │   │
│  │               │  │               │  │               │   │
│  │ nix-darwin   │  │ nixos-rebuild │  │  User configs │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Module Hierarchy

The module system follows a strict hierarchical structure:

```
modules/
├── shared/          # Cross-platform modules
│   ├── packages.nix
│   ├── files.nix
│   ├── home-manager.nix
│   └── lib/         # Shared libraries
│       ├── claude-config-policy.nix
│       ├── conditional-file-copy.nix
│       └── file-change-detector.nix
│
├── darwin/          # macOS-specific modules
│   ├── packages.nix
│   ├── casks.nix
│   ├── dock/
│   └── files.nix
│
└── nixos/           # NixOS-specific modules
    ├── packages.nix
    ├── disk-config.nix
    └── files.nix
```

### Import Flow

```
Host Configuration (e.g., hosts/darwin/default.nix)
    │
    ├──> Platform Modules (modules/darwin/*.nix)
    │        │
    │        └──> Shared Modules (modules/shared/*.nix)
    │
    └──> Home Manager Configuration
             │
             └──> User-specific modules
```

## Application Architecture

The repository provides various applications through Nix flake apps:

```
apps/
├── Core Apps           # Platform management
│   ├── build          # Build configuration
│   ├── switch         # Apply configuration
│   └── rollback       # Revert changes (Darwin only)
│
├── Development Apps    # Development tools
│   ├── setup-dev      # Initialize Nix projects
│   └── bl             # Global command system
│
└── Test Apps          # Testing infrastructure
    ├── test           # Run all tests
    ├── test-unit      # Run unit tests
    ├── test-integration # Run integration tests
    ├── test-e2e       # Run e2e tests
    └── test-list      # List available tests
```

## Test Architecture

The testing system is organized into four categories:

```
tests/
├── unit/              # Fast, isolated tests
├── integration/       # Module interaction tests
├── e2e/              # Full workflow tests
├── performance/       # Performance benchmarks
└── lib/              # Test utilities
    └── test-helpers.nix
```

### Test Execution Flow

```
User Command (e.g., make test-unit)
    │
    ▼
Makefile Target
    │
    ▼
Nix Flake App (e.g., .#test-unit)
    │
    ▼
test-apps.nix (Test Runner)
    │
    ▼
Individual Test Execution
    │
    ▼
Test Results & Reporting
```

## Configuration Management

### File Management Strategy

```
┌─────────────────────────┐
│   Source Files          │
│  (modules/*/config/)    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Conditional Copy       │
│  (preservation logic)   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   User Home Directory   │
│    (~/.config/...)      │
└─────────────────────────┘
```

### Claude Config Preservation Flow

```
System Rebuild Triggered
    │
    ▼
File Change Detection
    │
    ├─> No Changes: Copy normally
    │
    └─> Changes Detected:
            │
            ├─> High Priority Files:
            │     └─> Preserve user version
            │         └─> Save new as .new
            │
            └─> Low Priority Files:
                  └─> Backup and overwrite
```

## Build Pipeline

### CI/CD Pipeline Structure

```
GitHub Push/PR
    │
    ▼
┌─────────────────────────┐
│  Pre-commit Hooks       │
│  - Nix flake check      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  GitHub Actions         │
│  - Lint                 │
│  - Build (all systems)  │
│  - Cache artifacts      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Merge to main         │
│  (if all checks pass)   │
└─────────────────────────┘
```

## Security Architecture

### Secret Management

```
┌─────────────────────────┐
│  No Secrets in Repo     │
│  - Use env variables    │
│  - External secret mgmt │
└─────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  Runtime Resolution     │
│  - SSH_AUTH_SOCK        │
│  - USER variable        │
└─────────────────────────┘
```

## Platform Support Matrix

| Component | macOS (Darwin) | NixOS (Linux) |
|-----------|---------------|---------------|
| Core Packages | ✓ | ✓ |
| Platform Apps | ✓ | ✓ |
| Test Runner | Full | Basic |
| Home Manager | ✓ | ✓ |
| Homebrew | ✓ | ✗ |
| Systemd | ✗ | ✓ |

## Key Design Principles

1. **Modularity**: Each component is self-contained and reusable
2. **Platform Abstraction**: Shared code with platform-specific overrides
3. **User Preservation**: Never destroy user customizations
4. **Reproducibility**: Flake lock ensures consistent builds
5. **Testability**: Comprehensive test coverage at multiple levels
6. **Documentation**: Self-documenting code with external docs

## Future Architecture Considerations

1. **Plugin System**: Allow external modules to be dynamically loaded
2. **Remote Deployment**: Support for deploying to remote machines
3. **Monitoring**: Build and runtime monitoring integration
4. **Versioning**: Semantic versioning for configuration changes
5. **Rollback History**: Maintain multiple generations for recovery