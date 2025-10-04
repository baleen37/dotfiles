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
- **Architecture**: dustinlyons-inspired direct import patterns (simplified from complex abstractions)
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
│   │   ├── packages.nix   #   Package definitions only
│   │   ├── programs.nix   #   Program configurations only
│   │   └── home-manager.nix #  Home Manager settings only
│   ├── darwin/            #   macOS-specific modules
│   │   ├── packages.nix   #   macOS packages
│   │   ├── casks.nix      #   Homebrew casks
│   │   └── system.nix     #   System settings
│   └── nixos/             #   NixOS-specific modules
│       ├── packages.nix   #   NixOS packages
│       ├── services.nix   #   Service configurations
│       └── system.nix     #   System settings
│
├── hosts/                 # Host-specific configurations
│   ├── darwin/            #   macOS system definitions
│   └── nixos/             #   NixOS system definitions
│
├── lib/                   # Nix utility functions and builders
│   ├── core/              #   Core utilities
│   ├── testing/           #   Testing framework (MOVED)
│   ├── performance/       #   Performance optimization (MOVED)
│   └── automation/        #   CI/CD functionality (MOVED)
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

## Current Development: Nix Best Practices Refactoring

**Status**: Architecture planning phase  
**Branch**: feature/tests-modernization  
**Goal**: Apply dustinlyons/nixos-config best practices while preserving advanced features

### Refactoring Objectives

- **Structural Clarity**: Adopt dustinlyons' clean organizational patterns
- **Dynamic User Resolution**: Maintain flexible user configuration without hardcoding
- **Module Simplification**: Reduce complexity while maintaining functionality
- **Single Responsibility**: Each file focuses on one specific concern

### Best Practices Integration

1. **Clean flake.nix Organization**: Move complex logic to dedicated lib files
2. **Simple Module Imports**: Use direct import patterns like `import ../shared/files.nix`
3. **Platform App Structure**: Organize apps by architecture with clear naming
4. **Dynamic User Handling**: Keep existing user resolution system but simplify interface
5. **File Purpose Clarity**: packages.nix for packages, programs.nix for programs

### Key Improvements

- **Simplified Structure**: Maintain advanced features with cleaner organization
- **Modular Design**: Single responsibility modules following dustinlyons patterns
- **Preserved Features**: Keep 87% optimized testing framework and performance monitoring
- **Better Maintainability**: Clear separation of concerns across all modules

## Development Workflow

### Standard Process

1. **Test-Driven Development**: Write failing tests first
2. **Configuration Updates**: Implement NixOS/darwin changes
3. **Auto-Formatting**: Use `make format` to ensure code quality and consistency
4. **Service Deployment**: Test system integration
5. **Validation**: Verify functionality and performance
6. **Documentation**: Update relevant documentation

### Code Quality Enforcement

**Auto-Formatting Workflow**: Leverage automated formatting for consistent code quality:

- Use `make format` to automatically fix formatting and lint issues
- NEVER manually fix formatting issues - let automation handle it
- **Pre-commit Hook Compliance**: Ensure pre-commit hooks are installed and never bypassed:
  - NEVER use `git commit -n` or `--no-verify` flags
  - If pre-commit fails, run `make format` instead of manual fixes
  - Pre-commit hooks handle all formatting, linting, and basic validation automatically

**Efficient Development**: The auto-formatting system eliminates manual formatting work:

- `make format-nix`: Format all Nix files with nixfmt
- `make format-yaml`: Format YAML files with yamlfmt
- `make format-json`: Format JSON files with jq
- `make format-markdown`: Format Markdown files with prettier
- `make format`: Run all formatters in parallel for maximum efficiency

### Quality Assurance

- **Multi-tier Testing**: Unit, integration, end-to-end, performance tests
- **CI/CD Pipeline**: Automated testing and validation
- **Auto-Formatting**: Automated code quality with `make format` eliminating manual formatting work
- **Code Quality**: Pre-commit hooks and standardized formatting
- **Claude Code Integration**: AI-assisted development and review

## Recent Achievement: dustinlyons Refactoring Complete ✅

**Status**: Successfully completed (October 2025)  
**Impact**: 91-line code reduction (-30%) while preserving all functionality

### Refactoring Results

- **✅ Architecture Simplified**: Complex abstractions → direct import patterns
- **✅ Code Reduced**: flake.nix (302→209 lines), total -300 lines across modules
- **✅ dustinlyons Patterns**: Direct imports, explicit configurations, minimal abstractions
- **✅ Functionality Preserved**: All builds pass, Home Manager, nix-homebrew, testing infrastructure
- **✅ Maintainability Improved**: Easier debugging, clearer intent, reduced complexity

Following dustinlyons principle: "Simple, direct solutions over sophisticated abstractions"

## Critical Development Notes

### USER Variable Requirement

```bash
export USER=$(whoami)    # MUST run this before any build operation
```

**Why**: The system uses dynamic user resolution instead of hardcoded usernames. All builds will fail without this.

### Auto-Formatting Policy

```bash
make format              # Use this, never manually format
```

**Never manually fix formatting issues** - the auto-formatting system handles:

- Nix files (nixfmt)
- YAML files (yamlfmt)
- JSON files (jq)
- Markdown files (prettier)
- Shell scripts (shfmt)

### Pre-commit Compliance

```bash
make lint-format         # Recommended workflow before commits
```

**Never use `git commit --no-verify`** - pre-commit hooks ensure code quality and are required.

### Build Optimization

```bash
make build-current       # Build only current platform (faster development)
make build-switch        # Build and apply together (production workflow)
```

**For development**: Use `build-current` to avoid building all platforms during iteration.

## Project Philosophy

### Design Principles

**Modular Architecture**: Single responsibility modules with clear platform separation and cross-platform reusability through shared utilities.

**Declarative Configuration**: External YAML-based settings with environment variable overrides and comprehensive validation.

**Performance-First Development**: Optimized testing framework achieving 87% file reduction (133→17), 50% faster execution, and 30% memory reduction.

**Quality Assurance**: Multi-tier testing strategy (unit, integration, e2e, performance) with TDD methodology, automated formatting workflow, and automated CI/CD pipelines.

### Testing Philosophy

**Comprehensive Coverage**: Component-level validation through unit tests, module interaction verification via integration tests, and complete workflow validation with end-to-end testing.

**Performance Optimization**: Parallel execution with thread pools, memory management through efficient allocation, and smart caching to reduce redundant operations.

**Development Workflow**: Test-driven development with RED-GREEN-Refactor cycles, automated formatting integration, early failure detection, and dependency-aware test ordering.

### Configuration Management

**Separation of Concerns**: Platform-specific modules (`darwin/`, `nixos/`) with shared cross-platform functionality and externalized configuration files.

**Reproducibility**: Flake-based dependency management and SHA256-based change detection.

**Safety**: Configuration preservation during updates and manual merge conflict resolution tools.

## Essential Development Commands

### Core Workflow (Always Required)

```bash
export USER=$(whoami)          # REQUIRED: Set before any build operations
make format                    # Auto-format all files (never manually format)
make lint-format              # Recommended pre-commit workflow
make build-current            # Build only current platform (fastest)
make build-switch             # Build and apply in one step
```

### Testing Workflow

```bash
make test-core                # Essential test suite
make test-nix                # Nix-based unit tests (NO bats)
make test-enhanced           # Integration tests with reporting
make smoke                   # Quick validation (flake checks)
make test-monitor           # Performance monitoring
```

**Important**: Do NOT use bats for testing. Use Nix's built-in test framework instead.

### Platform-Specific Operations

```bash
make build-darwin           # macOS configurations only
make build-linux            # NixOS configurations only
make platform-info          # Show current platform details
```

### Development Shortcuts

```bash
make format-setup           # Initialize auto-formatting environment
make format-quick           # Fast format (Nix + shell only)
make build-fast             # Optimized build with max jobs
```

## Key Features

- **Dynamic User Resolution**: Automatic user detection without hardcoding (`export USER=$(whoami)`)
- **dustinlyons Architecture**: Direct import patterns, simplified from complex abstractions
- **Global Command System**: `bl` dispatcher for cross-project development
- **Auto-Formatting System**: Automated code quality with parallel formatting targets (`make format`)
- **Homebrew Integration**: 34+ GUI applications declaratively managed on macOS
- **Advanced Testing**: 87% optimized test suite with parallel execution and memory management
- **Claude Code Integration**: AI-assisted development with 20+ specialized commands
- **Performance Monitoring**: Real-time build time and resource usage tracking
- **Platform Detection**: Automatic system detection via `lib/platform-system.nix`
