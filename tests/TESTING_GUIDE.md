# Comprehensive Testing Framework Guide

A production-ready, multi-tier testing framework for the Nix dotfiles system providing complete coverage across unit, contract, integration, and end-to-end test layers.

## 🎯 Framework Purpose

This comprehensive testing framework validates the entire dotfiles system through multiple test layers:

- **Unit Tests**: Component-level validation using nix-unit
- **Contract Tests**: Interface and API validation using BATS
- **Integration Tests**: Module interaction verification
- **E2E Tests**: Complete system workflow validation
- **Performance Tests**: Execution time and resource monitoring

## 📁 Testing Framework Structure

```text
tests/
├── TESTING_GUIDE.md              # This comprehensive guide
├── run-tests.sh                  # Main test runner with parallel execution
├── examples/                     # Example tests for each layer
│   ├── unit-example.nix         # Unit test examples
│   ├── contract-example.bats    # Contract test examples
│   ├── integration-example.bats # Integration test examples
│   └── e2e-example.nix         # E2E test examples
├── unit/                        # Component-level tests
│   ├── nix/                     # Nix function tests
│   │   └── test-lib-functions.nix
│   └── lib/                     # Library tests
│       ├── test-builders.nix
│       └── test-coverage.nix
├── contract/                    # Interface validation tests
│   ├── test-runner-contract.bats
│   ├── test-coverage-contract.bats
│   ├── test-platform-contract.bats
│   └── flake-contracts/
│       └── test-flake-outputs.nix
├── integration/                 # Module interaction tests
│   ├── build-integration/
│   │   └── test-build-workflow.bats
│   └── platform-integration/
│       └── test-cross-platform.bats
├── e2e/                        # End-to-end workflow tests
│   ├── full-system/
│   │   └── test-complete-deployment.nix
│   └── cross-platform/
│       └── test-darwin-nixos.nix
├── performance/                # Performance and benchmarking
│   └── test-benchmark.nix     # Comprehensive performance benchmarks
├── config/                     # Test configuration files
│   ├── unit-test-config.nix
│   ├── coverage-config.nix
│   └── ci-test-matrix.nix
└── lib/                       # Shared test utilities
    ├── test-framework/        # Framework helpers
    │   ├── helpers.sh
    │   └── contract-helpers.sh
    ├── coverage-tools/        # Coverage reporting
    │   └── reporter.nix
    └── reporting/             # Test result formatting
        └── formatter.nix
```

## 🚀 Quick Start

### Run All Tests

```bash
# Run complete test suite from project root
./tests/run-tests.sh

# Run with coverage reporting
./tests/run-tests.sh --coverage

# Run with parallel execution (default)
./tests/run-tests.sh --parallel

# Run with verbose output
./tests/run-tests.sh --verbose
```

### Run Individual Test Layers

```bash
# Unit tests only (fast, isolated)
./tests/run-tests.sh --unit-only

# Contract tests only (interface validation)
./tests/run-tests.sh --contract-only

# Integration tests only (module interactions)
./tests/run-tests.sh --integration-only

# E2E tests only (complete workflows)
./tests/run-tests.sh --e2e-only

# Performance benchmarks only
./tests/run-tests.sh --performance-only
```

### Development Workflow

```bash
# Quick validation during development
./tests/run-tests.sh --unit-only --fast

# Pre-commit validation
./tests/run-tests.sh --coverage --ci

# Full validation before PR
./tests/run-tests.sh --verbose --coverage --performance
```

## 📋 Test Layer Types

### 1. Unit Tests

**Purpose**: Fast, isolated component testing using nix-unit framework

**Files**:

- `tests/unit/nix/test-lib-functions.nix` - Core Nix function validation
- `tests/unit/lib/test-builders.nix` - Test builder utility validation  
- `tests/unit/lib/test-coverage.nix` - Coverage system validation

**What's Tested**:

- ✅ Pure Nix function behavior
- ✅ Library utility functions
- ✅ Test builder correctness
- ✅ Coverage measurement accuracy
- ✅ Error handling and edge cases

**Execution**:

```bash
# Run all unit tests
./tests/run-tests.sh --unit-only

# Run specific unit test
nix-unit --flake .# tests.unit.lib-functions

# Run with verbose output
./tests/run-tests.sh --unit-only --verbose
```

**Characteristics**:

- **Speed**: < 30 seconds total
- **Isolation**: No external dependencies
- **Scope**: Single functions/components
- **Framework**: nix-unit with custom test builders

### 2. Contract Tests

**Purpose**: Interface and API validation using BATS framework

**Files**:

- `tests/contract/test-runner-contract.bats` - Test runner interface contracts
- `tests/contract/test-coverage-contract.bats` - Coverage provider contracts
- `tests/contract/test-platform-contract.bats` - Platform adapter contracts
- `tests/contract/flake-contracts/test-flake-outputs.nix` - Flake output contracts

**What's Tested**:

- ✅ Test runner interface compliance
- ✅ Coverage reporting contracts
- ✅ Platform adapter behavior
- ✅ Flake output structure validation
- ✅ API stability and backward compatibility

**Execution**:

```bash
# Run all contract tests
./tests/run-tests.sh --contract-only

# Run specific contract test
bats tests/contract/test-runner-contract.bats

# Run with timing information
bats tests/contract/ --timing
```

**Characteristics**:

- **Speed**: < 60 seconds total
- **Scope**: Interface validation
- **Framework**: BATS for shell, nix-unit for Nix
- **Purpose**: Prevent breaking changes

### 3. Integration Tests

**Purpose**: Module interaction and build workflow validation

**Files**:

- `tests/integration/build-integration/test-build-workflow.bats` - Build system integration
- `tests/integration/platform-integration/test-cross-platform.bats` - Cross-platform compatibility

**What's Tested**:

- ✅ Build system workflows
- ✅ Module interdependencies
- ✅ Cross-platform compatibility
- ✅ Configuration loading and merging
- ✅ Service integration

**Execution**:

```bash
# Run all integration tests
./tests/run-tests.sh --integration-only

# Run specific integration test
bats tests/integration/build-integration/

# Run with detailed output
./tests/run-tests.sh --integration-only --verbose
```

**Characteristics**:

- **Speed**: < 90 seconds total
- **Scope**: Module interactions
- **Dependencies**: May require system services
- **Environment**: Isolated test environments

### 4. End-to-End Tests

**Purpose**: Complete system workflow validation using NixOS tests

**Files**:

- `tests/e2e/full-system/test-complete-deployment.nix` - Full system deployment
- `tests/e2e/cross-platform/test-darwin-nixos.nix` - Cross-platform workflows

**Test Scenarios**:

- 🆕 **Fresh Installation**: New user setting up dotfiles from scratch
- 🔄 **System Updates**: Existing configuration updates and migrations
- 🔧 **Cross-Platform**: macOS and NixOS compatibility validation
- 📦 **Package Management**: Homebrew and Nix package integration
- 🧹 **Cleanup**: Proper handling of removed configurations

**Execution**:

```bash
# Run all E2E tests
./tests/run-tests.sh --e2e-only

# Run specific E2E test
nix build .#checks.x86_64-linux.e2e-full-system

# Run with full logging
./tests/run-tests.sh --e2e-only --verbose
```

**Characteristics**:

- **Speed**: < 120 seconds total
- **Scope**: Complete workflows
- **Framework**: NixOS test framework
- **Environment**: Full system simulation

### 5. Performance Tests

**Purpose**: Execution time and resource usage monitoring

**Files**:

- `tests/performance/test-benchmark.nix` - Comprehensive performance benchmarks

**What's Measured**:

- ✅ Test execution time per layer
- ✅ Memory usage patterns
- ✅ Parallel execution efficiency
- ✅ Resource utilization
- ✅ Performance regression detection

**Execution**:

```bash
# Run performance benchmarks
./tests/run-tests.sh --performance-only

# Run full benchmark suite
nix run .#performance-benchmark

# Monitor specific layer
nix run .#performance-benchmark.unit
```

**Performance Goals**:

- **Total Execution**: < 3 minutes (parallel)
- **Unit Tests**: < 30 seconds
- **Contract Tests**: < 60 seconds
- **Integration Tests**: < 90 seconds
- **E2E Tests**: < 120 seconds

## 🎯 Core Framework Features

### Test-Driven Development (TDD)

The framework enforces TDD methodology with clear phases:

1. **RED**: Write failing tests first
2. **GREEN**: Implement minimal code to pass tests
3. **REFACTOR**: Improve code while maintaining test passes

```bash
# TDD workflow example
./tests/run-tests.sh --unit-only           # Should fail initially
# Implement feature
./tests/run-tests.sh --unit-only           # Should pass
./tests/run-tests.sh --integration-only    # Integration validation
```

### Multi-Layer Validation

Each feature is validated across all test layers:

```text
graph TD
    A[Unit Tests] --> B[Contract Tests]
    B --> C[Integration Tests]
    C --> D[E2E Tests]
    D --> E[Performance Tests]

    A --> F[Component Level]
    B --> G[Interface Level]
    C --> H[Module Level]
    D --> I[System Level]
    E --> J[Performance Level]
```

### Coverage-Driven Quality

- **Target**: 90% minimum coverage
- **Measurement**: Line-level coverage for Nix and Bash
- **Reporting**: HTML, JSON, and console formats
- **CI Integration**: Automated coverage checks on PRs

### Parallel Execution

Optimized for performance with intelligent parallelization:

```bash
# Parallel test execution (default)
./tests/run-tests.sh --parallel

# Sequential execution (for debugging)
./tests/run-tests.sh --sequential

# Custom parallelism
./tests/run-tests.sh --parallel --jobs=4
```

## 🔧 Environment Requirements

### Required Tools

#### Core Dependencies

- `nix` (2.4+ with flakes enabled)
- `bash` (4.0+)
- `bats-core` (BATS testing framework)
- `nix-unit` (Nix unit testing)
- Standard Unix tools (`find`, `grep`, `sed`, `awk`)

#### Optional Tools

- `parallel` (for advanced parallelization)
- `bc` (for performance calculations)
- `free` (for memory monitoring)
- `timeout` (for test timeouts)

### Flake Configuration

Ensure your `flake.nix` includes the testing framework:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-unit.url = "github:nix-community/nix-unit";
    # ... other inputs
  };

  outputs = { self, nixpkgs, nix-unit, ... }: {
    # Include test checks
    checks = {
      x86_64-linux = {
        unit-tests = import ./tests/unit;
        contract-tests = import ./tests/contract;
        integration-tests = import ./tests/integration;
        e2e-tests = import ./tests/e2e;
      };
    };
  };
}
```

## 📊 Test Result Interpretation

### Success Output

```text
=================== COMPREHENSIVE TEST RESULTS ===================
Unit Tests:        PASSED (15/15)  Duration: 25s   Coverage: 95%
Contract Tests:    PASSED (12/12)  Duration: 45s   Coverage: 92%
Integration Tests: PASSED (8/8)    Duration: 75s   Coverage: 91%
E2E Tests:         PASSED (6/6)    Duration: 110s  Coverage: 89%
Performance Tests: PASSED (5/5)    Duration: 30s  

✅ ALL TESTS PASSED!
✅ Coverage target achieved: 92% (>90% required)
✅ Performance target met: 2m 45s (<3m goal)
✅ All test layers validated
==================================================================
```

### Failure Analysis

When tests fail, detailed debugging information is provided:

```text
=================== TEST FAILURE ANALYSIS ===================
FAILED: Unit Tests (2/15 failed)

❌ test-lib-functions.nix:25 - testStringManipulation
   Expected: "hello-world"
   Actual:   "hello_world"

❌ test-coverage.nix:15 - testCoverageCalculation
   Expected coverage >= 90%
   Actual coverage: 87%

Debugging Information:
  - Test Environment: /tmp/test-framework-123
  - Log Files: /tmp/test-framework-123/logs/
  - Coverage Report: /tmp/test-framework-123/coverage.html
===============================================================
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Permission Errors

```bash
# Fix executable permissions
chmod +x tests/**/*.sh
chmod +x tests/run-tests.sh

# Fix Nix file permissions
find tests/ -name "*.nix" -exec chmod 644 {} \;
```

#### 2. Missing Dependencies

```bash
# Install BATS
nix profile install nixpkgs#bats

# Install nix-unit
nix profile install github:nix-community/nix-unit

# Verify installation
bats --version
nix-unit --version
```

#### 3. Flake Issues

```bash
# Update flake inputs
nix flake update

# Rebuild flake
nix build .#checks.x86_64-linux.unit-tests

# Clear evaluation cache
nix eval --json .#checks --apply builtins.attrNames
```

#### 4. Test Environment Issues

```bash
# Clean test artifacts
rm -rf /tmp/test-framework-*
rm -rf tests/**/*.log

# Reset test state
./tests/run-tests.sh --clean
```

### Debug Mode

For detailed output and debugging:

```bash
# Enable verbose output
./tests/run-tests.sh --verbose

# Enable debug mode
./tests/run-tests.sh --debug

# Run specific test with debugging
bats tests/unit/test-specific.bats --verbose-run
```

## 🔄 CI/CD Integration

### GitHub Actions Configuration

```yaml
name: Comprehensive Testing Framework
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        layer: [unit, contract, integration, e2e]
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
      - name: Run ${{ matrix.layer }} tests
        run: ./tests/run-tests.sh --${{ matrix.layer }}-only --coverage
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        if: matrix.layer == 'unit'
        with:
          file: ./coverage.xml

  performance:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
      - name: Run performance benchmarks
        run: ./tests/run-tests.sh --performance-only
      - name: Store benchmark results
        uses: benchmark-action/github-action-benchmark@v1
        with:
          tool: 'customSmallerIsBetter'
          output-file-path: benchmark-results.json
```

### Pre-commit Hook Integration

```bash
# Install pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
set -e

echo "Running pre-commit tests..."
./tests/run-tests.sh --unit-only --fast

echo "Checking test coverage..."
./tests/run-tests.sh --coverage --unit-only

echo "All pre-commit tests passed!"
EOF

chmod +x .git/hooks/pre-commit
```

### Local Development Workflow

```bash
# Quick validation during development
./tests/run-tests.sh --unit-only --fast

# Pre-commit validation
./tests/run-tests.sh --unit-only --contract-only

# Pre-push validation
./tests/run-tests.sh --coverage --ci

# Full validation before PR
./tests/run-tests.sh --verbose --coverage --performance
git commit -m "feat: implement new testing framework layer"
```

## 📈 Framework Extension

### Adding New Test Layers

When adding new features, follow the multi-layer approach:

1. **Unit Tests First (TDD)**:

   ```nix
   # tests/unit/new-feature/test-new-component.nix
   { lib, ... }:
   let
     component = import ../../../lib/new-component.nix { inherit lib; };
   in
   {
     testNewComponentBasic = {
       expr = component.basicFunction "input";
       expected = "expected-output";
     };

     testNewComponentEdgeCase = {
       expr = component.basicFunction null;
       expected = null;
     };
   }
   ```

2. **Contract Tests for Interfaces**:

   ```bash
   # tests/contract/test-new-interface-contract.bats
   #!/usr/bin/env bats

   @test "new interface provides required functions" {
     run nix eval .#lib.newInterface.requiredFunction
     [ "$status" -eq 0 ]
   }

   @test "new interface follows naming convention" {
     run nix eval --json .#lib.newInterface --apply builtins.attrNames
     [[ "$output" =~ "Function$" ]]
   }
   ```

3. **Integration Tests for Module Interactions**:

   ```bash
   # tests/integration/new-feature-integration/test-module-interaction.bats
   @test "new feature integrates with existing modules" {
     run nix build .#nixosConfigurations.test.config.services.newFeature
     [ "$status" -eq 0 ]
   }
   ```

4. **E2E Tests for Complete Workflows**:

   ```nix
   # tests/e2e/new-feature/test-complete-workflow.nix
   { pkgs, ... }:
   pkgs.testers.runNixOSTest {
     name = "new-feature-e2e";
     nodes.machine = { ... }: {
       imports = [ ../../../modules/new-feature.nix ];
       services.newFeature.enable = true;
     };
     testScript = ''
       machine.start()
       machine.wait_for_unit("new-feature.service")
       machine.succeed("systemctl status new-feature")
     '';
   }
   ```

### Performance Optimization

For optimal test execution:

```bash
# Profile test execution
./tests/run-tests.sh --profile

# Optimize parallel execution
./tests/run-tests.sh --parallel --jobs=$(nproc)

# Cache-friendly execution
./tests/run-tests.sh --cache-build-deps
```

## 💡 Best Practices

### Writing Effective Tests

1. **Test Naming**: Use descriptive, hierarchical names

   ```nix
   testStringUtilsCapitalizationBasic = { /* ... */ };
   testStringUtilsCapitalizationEmptyString = { /* ... */ };
   testStringUtilsCapitalizationUnicode = { /* ... */ };
   ```

2. **Test Isolation**: Each test should be independent

   ```bash
   setup() {
     export TEST_TMPDIR=$(mktemp -d)
   }

   teardown() {
     rm -rf "$TEST_TMPDIR"
   }
   ```

3. **Meaningful Assertions**: Test behavior, not implementation

   ```nix
   # Good: tests behavior
   testConfigGeneration = {
     expr = generateConfig { enable = true; };
     expected = { services.myservice.enable = true; };
   };

   # Avoid: tests implementation details
   testConfigImplementation = {
     expr = builtins.isFunction generateConfig;
     expected = true;
   };
   ```

### Test Data Management

```bash
# Automatic cleanup
cleanup() {
  rm -rf /tmp/test-framework-*
  rm -rf tests/**/*.log
  rm -rf tests/**/result*
}
trap cleanup EXIT

# Preserve debugging data
./tests/run-tests.sh --preserve-on-failure
```

## 📚 Resources and References

### Framework Documentation

- [nix-unit Documentation](https://github.com/nix-community/nix-unit)
- [BATS Testing Framework](https://bats-core.readthedocs.io/)
- [NixOS Test Framework](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)

### Related Files

- [Test Runner Implementation](./run-tests.sh)
- [Test Builders Library](./lib/test-builders.nix)
- [Coverage System](./lib/coverage-system.nix)
- [Performance Benchmarks](./performance/test-benchmark.nix)

### Example Tests

- [Unit Test Examples](./examples/unit-example.nix)
- [Contract Test Examples](./examples/contract-example.bats)
- [Integration Test Examples](./examples/integration-example.bats)
- [E2E Test Examples](./examples/e2e-example.nix)

---

## 🎉 Contributing

The comprehensive testing framework is designed for extensibility and maintainability. When contributing:

1. **Follow TDD**: Write failing tests first
2. **Multi-layer validation**: Test at appropriate layers  
3. **Performance conscious**: Keep tests fast and parallel-friendly
4. **Documentation**: Update this guide for new features
5. **Coverage**: Maintain 90%+ coverage threshold

**Questions or suggestions? Create an issue or submit a PR!** 🚀
