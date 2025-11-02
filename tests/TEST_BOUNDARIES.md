# Test Boundaries and Responsibilities

This document defines clear boundaries and responsibilities for each test layer in the dotfiles test suite.

## Test Layer Responsibilities

### Unit Tests (`tests/unit/`)
**Purpose**: Test pure functions, isolated logic, and individual modules without external dependencies.

**What belongs here:**
- Pure function testing (e.g., `lib/mksystem.nix` function structure)
- Module validation without importing complex configurations
- Simple configuration structure validation
- Error handling for individual components
- Platform-independent logic testing

**Examples of appropriate unit tests:**
- `mksystem-test.nix` - Tests pure factory function structure
- Simple validation functions from individual modules
- String processing utilities
- Configuration parsing logic (without full config loading)

**What does NOT belong here:**
- Loading full Home Manager configurations
- Testing cross-module interactions
- System integration validation
- VM configuration testing
- Complex behavioral testing requiring multiple modules

### Integration Tests (`tests/integration/`)
**Purpose**: Test module interactions, configuration combinations, and system integration with real dependencies.

**What belongs here:**
- Module interaction testing
- Configuration combination validation
- System integration with real dependencies (but controlled)
- Cross-platform compatibility testing
- Home Manager configuration loading and validation
- Git configuration integration with user info
- Claude configuration symlink structure validation

**Examples of appropriate integration tests:**
- `home-manager-test.nix` - Tests Home Manager config loading
- `build-test.nix` - Tests system building integration
- Module interaction validation
- Configuration file relationship testing

**What does NOT belong here:**
- Pure function testing (move to unit)
- Full system workflow testing (move to E2E)
- Simple file existence checks (move to unit)

### E2E Tests (`tests/e2e/`)
**Purpose**: Test complete user workflows, real system behavior, and full system validation.

**What belongs here:**
- Complete system builds and switches
- VM testing with real environments
- Full workflow validation (git clone → build → switch)
- Cross-platform end-to-end validation
- Performance testing with real systems
- User scenario testing

**Examples of appropriate E2E tests:**
- `comprehensive-suite-validation-test.nix`
- `vm-e2e-test.nix`
- `nixos-vm-test.nix`
- Build and switch command testing
- Complete configuration deployment testing

**What does NOT belong here:**
- Individual module testing (move to unit/integration)
- Simple validation (move to unit/integration)

## Migration Guidelines

### From Unit to Integration
- Move tests that load actual configurations
- Move behavioral tests requiring multiple modules
- Move cross-module validation

### From Integration to Unit
- Move simple structure validation
- Move file existence checks
- Move pure function testing

### From Unit/E2E to Appropriate Layer
- VM analysis tests should be in E2E
- Simple validation should be in Unit
- Complex interactions should be in Integration

## Test Naming Conventions

- Unit tests: Focus on single components (`*-test.nix`)
- Integration tests: Focus on interactions (`integration-*-test.nix`)
- E2E tests: Focus on workflows (`e2e-*-test.nix` or comprehensive naming)

## Test Dependencies

- **Unit**: No external dependencies, pure Nix evaluation
- **Integration**: Real dependencies but controlled environment
- **E2E**: Full system with real tools and environments
