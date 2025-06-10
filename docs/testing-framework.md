# Testing Framework Architecture

## Overview

This document outlines the comprehensive testing strategy for the Nix dotfiles repository, following best practices for unit, integration, and end-to-end testing.

## Testing Strategy

### 1. Unit Tests
**Purpose**: Test individual functions, modules, and components in isolation
**Location**: `tests/unit/`
**Naming**: `*-unit.nix`
**Scope**: 
- Individual Nix functions
- Module imports and exports
- Configuration validation
- Utility functions

### 2. Integration Tests  
**Purpose**: Test interactions between modules and system components
**Location**: `tests/integration/`
**Naming**: `*-integration.nix`
**Scope**:
- Module dependency resolution
- Cross-platform compatibility
- Package availability across systems
- Home Manager integration

### 3. End-to-End Tests
**Purpose**: Test complete workflows and system behavior
**Location**: `tests/e2e/`
**Naming**: `*-e2e.nix`
**Scope**:
- Full system builds
- Configuration switching
- App functionality
- Real-world scenarios

### 4. Performance Tests
**Purpose**: Monitor build times and resource usage
**Location**: `tests/performance/`
**Naming**: `*-perf.nix`
**Scope**:
- Build time benchmarks
- Memory usage analysis
- Flake evaluation performance

## Testing Guidelines

### Test Structure
```nix
{ pkgs }:
let
  # Test setup and helpers
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Test data and fixtures
  testData = {
    # Test-specific data
  };
in
pkgs.runCommand "test-name" { } ''
  # Test implementation
  echo "Running test..."
  
  # Assertions
  ${testHelpers.assert "condition" "error message"}
  
  # Success indicator
  touch $out
''
```

### Test Helpers Library
Common utilities for all tests:
- Assertion functions
- Mock data generators
- Platform detection helpers
- Error reporting utilities

### Continuous Integration Pipeline
```bash
# Pre-commit workflow
make lint        # Code quality checks
make smoke       # Fast validation without builds
make test        # Unit and integration tests
make build       # Full system builds
make perf        # Performance benchmarks (optional)
```

## Test Categories

### Current Test Migration
Reorganize existing tests into proper categories:

#### Unit Tests
- `simple.nix` → `unit/basic-functionality-unit.nix`
- `get-user.nix` → `unit/user-resolution-unit.nix`
- `module-validation.nix` → `unit/module-imports-unit.nix`

#### Integration Tests
- `module-dependency-integration.nix` → Keep as-is
- `package-availability.nix` → `integration/package-availability-integration.nix`
- `overlay-functionality.nix` → `integration/overlay-integration.nix`

#### E2E Tests
- `full-system-integration.nix` → `e2e/system-build-e2e.nix`
- `configuration-build.nix` → `e2e/config-switching-e2e.nix`
- `workflow-integration.nix` → `e2e/complete-workflow-e2e.nix`

## Implementation Plan

### Phase 1: Framework Setup
1. Create test directory structure
2. Implement test helpers library
3. Update discovery system

### Phase 2: Test Migration
1. Reorganize existing tests
2. Enhance test coverage
3. Add missing test categories

### Phase 3: CI Integration
1. Update Makefile targets
2. Add performance monitoring
3. Implement test reporting

### Phase 4: Documentation
1. Test writing guidelines
2. Troubleshooting guide
3. Best practices documentation

## Test Discovery System

Enhanced `tests/default.nix` to support categorized testing:

```nix
{ pkgs }:
let
  # Discover tests in all subdirectories
  discoverTests = dir: pattern:
    let
      entries = builtins.readDir dir;
      testFiles = builtins.filter (name: 
        builtins.match pattern name != null
      ) (builtins.attrNames entries);
    in builtins.listToAttrs (map (file: {
      name = sanitizeName file;
      value = import (dir + ("/" + file)) { inherit pkgs; };
    }) testFiles);
    
  # Test categories
  unitTests = if builtins.pathExists ./unit then discoverTests ./unit ".*-unit\\.nix" else {};
  integrationTests = if builtins.pathExists ./integration then discoverTests ./integration ".*-integration\\.nix" else {};
  e2eTests = if builtins.pathExists ./e2e then discoverTests ./e2e ".*-e2e\\.nix" else {};
  
  # Legacy tests (to be migrated)
  legacyTests = discoverTests ./. ".*\\.nix" // { default = null; };
  
in unitTests // integrationTests // e2eTests // legacyTests
```

## Success Metrics

- **Coverage**: All major modules have corresponding tests
- **Performance**: Build times tracked and optimized
- **Reliability**: Tests pass consistently across all platforms
- **Maintainability**: Clear test structure and documentation