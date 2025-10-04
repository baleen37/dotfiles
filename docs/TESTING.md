# Testing Framework

> **Simplified testing strategy for the Nix dotfiles system**

This document describes the simplified testing framework, organized into three focused categories for better maintainability.

## 🧪 Testing Philosophy

### Core Principles

1. **Simplicity First**: Focus on tests that catch real issues
2. **Clear Categories**: Three distinct test categories with clear purposes
3. **Fast Feedback**: Quick test execution for rapid development (target: <5 minutes)
4. **Maintainability**: Easy to understand and modify tests
5. **Performance Optimization**: Intelligent parallel execution with adaptive scaling
6. **Comprehensive Coverage**: 80% coverage threshold with automated tracking

### Test Categories

```text
tests/
├── default.nix        # Simplified test entry point
├── unit/             # Core functionality tests (87% optimized)
├── integration/      # Module interaction tests
├── e2e/             # End-to-end workflow tests
├── performance/     # Performance benchmarks (<5 min target)
└── lib/             # Test framework and utilities
    ├── common.bash      # Common test utilities and assertions
    ├── coverage.bash    # Coverage tracking and reporting
    ├── parallel.bash    # Parallel execution manager
    ├── performance.bash # Performance optimization engine
    └── models/         # Test data models and fixtures
```

### Unit Test Organization Strategy

**Consolidation Principles** (47+ files → ~24 files):

- **One Test File Per Feature/Module**: Each major feature has a single comprehensive test file
- **Numbered Test Categories**: 1-10 covering basic functionality to full workflow
- **Reduced Redundancy**: Eliminated TDD setup tests and overlapping validations
- **Maintained Coverage**: Preserved all real-world test scenarios

**Test File Structure**:

```nix
pkgs.runCommand "feature-test" {
  buildInputs = with pkgs; [ bash jq ... ];
} ''
  echo "🧪 Comprehensive [Feature] Test Suite"

  # Test 1: Basic Functionality
  echo "📋 Test 1: [Description]"
  # ... test implementation ...

  # Test 2-10: Advanced Features, Integration, Error Handling, etc.

  echo "🎉 All [Feature] Tests Completed!"
  touch $out
''
```

**Key Consolidated Files**:

- `claude-commands-test.nix` - All Claude command functionality
- `claude-config-test.nix` - Configuration management
- `auto-update-test.nix` - Core auto-update features
- `error-handling-test.nix` - Error scenarios and recovery
- `user-resolution-test.nix` - User detection and resolution
- `platform-detection-test.nix` - Platform detection utilities

## 📊 Simplified Test Structure

### Test Categories (20 tests total, down from 84)

| Category        | Test Count | Purpose                 | Execution Time |
| --------------- | ---------- | ----------------------- | -------------- |
| **Core**        | ~13 tests  | Essential functionality | < 2 minutes    |
| **Workflow**    | ~5 tests   | End-to-end scenarios    | < 5 minutes    |
| **Performance** | 2 tests    | Build time & resources  | < 3 minutes    |

## 🔬 Test Categories Detail

### Core Tests

**Purpose**: Validate essential functionality that must always work.

```bash
# Run core tests
make test-core
```

**Includes:**

- Flake structure validation
- Module imports and dependencies
- User resolution and platform detection
- Critical features (Claude config, auto-update, build-switch)
- Cross-platform compatibility
- Package availability

### Workflow Tests

**Purpose**: Test complete user workflows end-to-end.

```bash
# Run workflow tests
make test-workflow
```

**Includes:**

- System build and deployment
- Complete configuration workflows
- Feature-specific workflows (Claude config, build-switch)

### Performance Tests

**Purpose**: Monitor build performance and resource usage.

```bash
# Run performance tests
make test-perf
```

**Includes:**

- Build time measurements
- Resource usage profiling

## ⚡ Performance Optimization Framework

### Intelligent Parallel Execution

The test framework includes sophisticated performance optimization:

- **Adaptive Scaling**: Automatically adjusts parallelism based on system resources
- **Smart Scheduling**: Tests are weighted and scheduled optimally
- **Resource Monitoring**: Real-time CPU and memory usage monitoring
- **5-minute Target**: All tests complete within 5 minutes

### Performance Features

```bash
# Performance-optimized test execution
./tests/run-tests.sh --fast --parallel auto

# Monitor test performance
./tests/run-tests.sh --monitor --report performance.json

# Coverage tracking with 80% threshold
./tests/run-tests.sh --coverage --threshold 80
```

### Claude Code Integration

The framework integrates seamlessly with Claude Code configuration:

- **No Backup Files**: Force symlink overwrite prevents backup file creation
- **Platform-Specific Paths**: Darwin and NixOS path handling
- **Pre-Switch Cleanup**: Automatic cleanup before Home Manager activation
- **Symlink Validation**: Comprehensive symlink integrity checking

## 🚀 Running Tests

### Quick Start

```bash
# Run all tests (performance optimized)
make test

# Run with performance monitoring
make test-perf-monitor

# Run specific categories
make test-core      # Fast, essential tests
make test-workflow  # End-to-end tests
make test-perf     # Performance benchmarks

# List available tests
make test-list

# Coverage report
make test-coverage
```

### Using Nix Commands

```bash
# Run all tests
nix run --impure .#test

# Run specific categories
nix run --impure .#test-core
nix run --impure .#test-workflow
nix run --impure .#test-perf

# Quick smoke test
nix run --impure .#test-smoke
```

## 🔧 Writing Tests

### Simple Test Template

```nix
{ pkgs, flake, lib ? pkgs.lib, src }:
pkgs.runCommand "test-name" { } ''
  echo "Running test..."

  # Test logic here
  if [ condition ]; then
    echo "✓ Test passed"
  else
    echo "✗ Test failed"
    exit 1
  fi

  touch $out
''
```

### Test Guidelines

1. **Keep it simple** - Tests should be easy to understand
2. **Fast execution** - Target < 30s per test
3. **Clear output** - Use descriptive pass/fail messages
4. **One purpose** - Each test validates one specific thing

## 📋 CI Integration

The CI pipeline runs tests in this simplified order:

1. `make lint` - Code quality checks
2. `make smoke` - Quick flake validation
3. `make build` - Build configurations
4. `make test` - Run all tests

## 🛠️ Test Maintenance

### Adding a Test

1. Determine the appropriate category (core, workflow, or performance)
2. Add test file to the corresponding directory
3. Update `tests/default.nix` to include the new test
4. Run the test locally before committing

### Removing a Test

Tests should only be removed if they:

- No longer test relevant functionality
- Are redundant with other tests
- Have never caught a real bug

## 🔍 Debugging Failed Tests

```bash
# Run with verbose output
nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').test-name -L

# Check logs
nix log .#checks.$(nix eval --impure --expr 'builtins.currentSystem').test-name
```

## 📊 Benefits of Simplification

### Before

- 84 test files across 6 categories
- Complex auto-discovery system
- Parallel execution framework
- 10+ minute test runs
- High maintenance burden

### After

- ~20 test files across 3 categories
- Explicit test registration
- Simple sequential execution
- < 5 minute test runs
- Low maintenance burden

## 🎯 Focus Areas

The simplified framework focuses on testing:

1. **What has broken before** - Historical problem areas
2. **Critical paths** - User-facing functionality
3. **Integration points** - Where components interact
4. **Performance** - Build time regressions

---

> **Note**: This simplified testing framework reduces complexity while maintaining comprehensive coverage of critical functionality.
