# CLAUDE.md - Professional Nix Dotfiles System

## Project Overview

**Enterprise-grade dotfiles management system** providing reproducible development environments across macOS and NixOS using Nix flakes, Home Manager, and nix-darwin.

### Core Purpose

Professional Nix dotfiles system supporting:

- **Cross-platform compatibility**: macOS (Intel + Apple Silicon) and NixOS (x86_64 + ARM64)
- **50+ development tools**: git, vim, docker, terraform, nodejs, python, and comprehensive toolchains
- **AI-powered development support**: 20+ specialized Claude Code commands
- **Enterprise automation**: auto-updates, configuration preservation, intelligent build optimization

## Technical Architecture

### Technology Stack

- **Core**: Nix Flakes, Home Manager, nix-darwin, NixOS
- **Languages**: Nix (configuration), YAML (settings), JSON (Claude Code), Lua (GUI apps), bash (automation)
- **Development**: Pre-commit hooks, GitHub Actions CI/CD, comprehensive testing framework
- **Platforms**: macOS (x86_64/aarch64-darwin), NixOS (x86_64/aarch64-linux)

### Codebase Structure

```text
├── flake.nix              # Flake entry point and outputs
├── Makefile               # Development workflow automation
├── CLAUDE.md              # Claude Code project guidelines
├── CONTRIBUTING.md        # Development standards
│
├── modules/               # Modular configuration system
│   ├── shared/            #   Cross-platform settings
│   ├── darwin/            #   macOS-specific modules
│   └── nixos/             #   NixOS-specific modules
│
├── hosts/                 # Host-specific configurations
│   ├── darwin/            #   macOS system definitions
│   └── nixos/             #   NixOS system definitions
│
├── lib/                   # Nix utility functions and builders
├── scripts/               # Automation and management tools
├── tests/                 # Multi-tier testing framework (87% optimized)
│   ├── unit/              #   Component-level testing (6 files)
│   ├── integration/       #   Module interaction testing (6 files)
│   ├── e2e/               #   End-to-end workflow testing (5 files)
│   ├── performance/       #   Performance and memory monitoring
│   ├── lib/               #   Shared test utilities and frameworks
│   └── config/            #   Test environment configurations
├── docs/                  # Comprehensive documentation
├── config/                # Externalized configuration files
└── overlays/              # Custom package definitions and patches
```

### Module Architecture

1. **Platform Modules** (`modules/{darwin,nixos}/`): OS-specific configurations
2. **Shared Modules** (`modules/shared/`): Cross-platform functionality
3. **Host Configurations** (`hosts/`): Individual machine definitions
4. **Library Functions** (`lib/`): Reusable Nix utilities

## Current Development: VSCode Remote Tunnel Integration

**Status**: Implementation phase  
**Branch**: main  
**Goal**: Enable `code` command from SSH sessions to open local VSCode

### Implementation Details

- **Service Type**: systemd user service (security-focused)
- **Authentication**: GitHub OAuth via Microsoft tunnel service
- **CLI Management**: Dynamic VSCode CLI download (not Nix package)
- **Integration**: Native NixOS configuration integration

### Key Files

- `hosts/nixos/default.nix`: Main NixOS configuration
- `specs/002-/spec.md`: Complete feature specification
- `specs/002-/plan.md`: Implementation plan
- `tests/integration/`: TDD service integration tests

### Development Status

- [x] Specification and planning complete
- [x] Research and design finalized
- [ ] Integration tests implementation (TDD approach)
- [ ] NixOS configuration updates
- [ ] Service validation and testing

### Testing Strategy

- **TDD Approach**: RED-GREEN-Refactor cycle enforcement
- **Integration Testing**: Real systemd service validation
- **Network Validation**: Connectivity and tunnel testing
- **End-to-End**: Complete `code` command workflow testing

## Development Workflow

### Standard Process

1. **Test-Driven Development**: Write failing tests first
2. **Configuration Updates**: Implement NixOS/darwin changes
3. **Service Deployment**: Test system integration
4. **Validation**: Verify functionality and performance
5. **Documentation**: Update relevant documentation

### Code Quality Enforcement

**Pre-commit Hook Compliance**: Ensure pre-commit hooks are installed and never bypassed:

- NEVER use `git commit -n` or `--no-verify` flags
- If pre-commit fails, fix the issues rather than bypassing
- Pre-commit hooks handle all formatting, linting, and basic validation automatically

### Quality Assurance

- **Multi-tier Testing**: Unit, integration, end-to-end, performance tests
- **CI/CD Pipeline**: Automated testing and validation
- **Code Quality**: Pre-commit hooks and standardized formatting
- **Claude Code Integration**: AI-assisted development and review

## Project Philosophy

### Design Principles

**Modular Architecture**: Single responsibility modules with clear platform separation and cross-platform reusability through shared utilities.

**Declarative Configuration**: External YAML-based settings with environment variable overrides and comprehensive validation.

**Performance-First Development**: Optimized testing framework achieving 87% file reduction (133→17), 50% faster execution, and 30% memory reduction.

**Quality Assurance**: Multi-tier testing strategy (unit, integration, e2e, performance) with TDD methodology and automated CI/CD pipelines.

### Testing Philosophy

**Comprehensive Coverage**: Component-level validation through unit tests, module interaction verification via integration tests, and complete workflow validation with end-to-end testing.

**Performance Optimization**: Parallel execution with thread pools, memory management through efficient allocation, and smart caching to reduce redundant operations.

**Development Workflow**: Test-driven development with RED-GREEN-Refactor cycles, early failure detection, and dependency-aware test ordering.

### Configuration Management

**Separation of Concerns**: Platform-specific modules (`darwin/`, `nixos/`) with shared cross-platform functionality and externalized configuration files.

**Reproducibility**: Flake-based dependency management and SHA256-based change detection.

**Safety**: Configuration preservation during updates and manual merge conflict resolution tools.

## Key Features

- **Global Command System**: `bl` dispatcher for cross-project development
- **Homebrew Integration**: 34+ GUI applications declaratively managed on macOS
- **Advanced Testing**: 87% optimized test suite with parallel execution and memory management
- **Claude Code Integration**: AI-assisted development with 20+ specialized commands
- **Performance Monitoring**: Real-time build time and resource usage tracking
- **Comprehensive Toolchain**: Complete development environment with security best practices
