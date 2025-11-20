# Testing Guide

This guide provides comprehensive documentation for writing, running, and maintaining tests in the dotfiles repository.

## Overview

The testing system follows a multi-tier approach with enhanced error reporting, platform-specific testing, and standardized naming conventions. It's designed to ensure reproducible development environments across macOS and NixOS.

## Test Structure

```
tests/
├── lib/                    # Test utilities and helpers
│   ├── enhanced-assertions.nix    # Enhanced assertion helpers
│   ├── test-runner.nix           # Test suite runner
│   └── platform-helpers.nix      # Platform-specific utilities
├── unit/                   # Unit tests (fast, isolated)
│   ├── enhanced-assertions-test.nix
│   ├── test-runner-test.nix
│   ├── platform-helpers-test.nix
│   └── functions/         # Core function tests
│       └── mksystem-factory-validation.nix
├── integration/            # Integration tests (component interaction)
│   └── home-manager/      # Home Manager specific tests
│       └── git-config-generation.nix
├── e2e/                   # End-to-end tests (complete workflows)
├── performance/           # Performance benchmarks
└── default.nix            # Test discovery and orchestration
```

## Naming Conventions

### Feature-Scenario-ExpectedResult Pattern

All tests must follow the **Feature-Scenario-ExpectedResult** naming convention:

```nix
# Format: {feature}-{scenario}-{expectedResult}
examples:
- mksystem-file-importability-succeeds
- git-config-generation-creates-valid-file
- darwin-homebrew-integration-works
- enhanced-assertions-detailed-error-reporting
- platform-helpers-current-platform-detection
```

**Components:**
- **Feature**: The component or functionality being tested (e.g., `mksystem`, `git-config`)
- **Scenario**: The specific test condition or context (e.g., `file-importability`, `generation`)
- **ExpectedResult**: The expected outcome (e.g., `succeeds`, `creates-valid-file`, `works`)

### File Naming

Test files must end with `-test.nix`:
- `enhanced-assertions-test.nix`
- `mksystem-factory-validation.nix` (in functions/ directory)
- `git-config-generation.nix` (in integration/home-manager/)

## Enhanced Assertions

The testing system provides enhanced assertions with detailed error reporting through `tests/lib/enhanced-assertions.nix`:

### assertTestWithDetails

Enhanced assertion with comprehensive error reporting:

```nix
helpers.assertTestWithDetails "test-name" condition "message" ?expected ?actual ?file ?line
```

**Parameters:**
- `name`: Test name following Feature-Scenario-ExpectedResult pattern
- `condition`: Boolean condition to test
- `message`: Descriptive test message
- `expected`: (Optional) Expected value for comparison
- `actual`: (Optional) Actual value for comparison
- `file`: (Optional) File location for debugging
- `line`: (Optional) Line number for debugging

**Example:**
```nix
(helpers.assertTestWithDetails "mksystem-file-importability-succeeds"
  (builtins.isFunction subject)
  "mkSystem.nix should be importable and return function"
  (builtins.typeOf subject)
  "lambda"
  ../../../lib/mksystem.nix)
```

### assertFileContent

File content validation with diff-like comparison:

```nix
helpers.assertFileContent "name" expectedPath actualPath
```

**Example:**
```nix
(helpers.assertFileContent "git-config-file-generated"
  (pkgs.runCommand "git-test-home" { } ''
    export HOME=$(pwd)
    ${pkgs.home-manager}/bin/home-manager -f ${testConfig} build
    cat $HOME/.gitconfig
  '')
  testConfig.home.file.".gitconfig-test".text)
```

## Test Suite Runner

The test suite runner provides filtering, performance monitoring, and structured output through `tests/lib/test-runner.nix`:

```nix
runner.mkTestSuite "suite-name" tests ?verbose ?filter
```

**Features:**
- **Regex filtering**: Run specific test subsets
- **Pass/fail counters**: Comprehensive test results
- **Emoji-based output**: Visual status indicators
- **Error aggregation**: Collect all failures before exiting

**Usage Examples:**
```nix
# Run all tests
testSuiteBasic = runner.mkTestSuite "mock-suite" mockTests;

# Run filtered tests (only tests matching "pass" pattern)
testSuiteFiltered = runner.mkTestSuite "filtered-suite" mockTests {
  filter = "pass";
};
```

## Platform-Specific Testing

Platform helpers enable cross-platform test development and execution through `tests/lib/platform-helpers.nix`:

### mkPlatformTest

Create platform-specific tests:

```nix
platformHelpers.mkPlatformTest "darwin" test
```

### filterPlatformTests

Filter tests based on platform requirements:

```nix
platformHelpers.filterPlatformTests tests
```

### Platform Attributes

Add platform requirements to tests:

```nix
{
  test-darwin-specific = {
    platforms = ["darwin"];
    # Test implementation
  };

  test-linux-specific = {
    platforms = ["linux"];
    # Test implementation
  };

  test-cross-platform = {
    # No platform attribute = runs on all platforms
  };
}
```

### Current Platform Detection

```nix
currentPlatform = platformHelpers.getCurrentPlatform
# Returns: "darwin", "linux", or "unknown"
```

## Test Types and Usage

### Unit Tests

Fast, isolated tests for individual functions and components:

```nix
# tests/unit/functions/mksystem-factory-validation.nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../../lib/enhanced-assertions.nix { inherit pkgs lib; };
  subject = import ../../../lib/mksystem.nix { inherit inputs self; };
in
helpers.testSuite "mksystem-factory-validation" [
  # Importability test
  (helpers.assertTestWithDetails "mksystem-file-importability-succeeds"
    (builtins.isFunction subject)
    "mkSystem.nix should be importable and return function"
    (builtins.typeOf subject)
    "lambda"
    ../../../lib/mksystem.nix)

  # Function callability test
  (helpers.assertTestWithDetails "mksystem-with-valid-inputs-returns-function"
    (builtins.isFunction (subject testInputs.valid))
    "mkSystem should return function when called with valid inputs"
    (builtins.typeOf (subject testInputs.valid))
    "lambda"
    ../../../lib/mksystem.nix)
]
```

### Integration Tests

Test component interactions and system integration:

```nix
# tests/integration/home-manager/git-config-generation.nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self,
  ...
}:

let
  helpers = import ../../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Test Home Manager configuration
  testConfig = {
    programs.git = {
      enable = true;
      userName = "Test User";
      userEmail = "test@example.com";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
in
helpers.testSuite "git-config-generation" [
  # File generation test
  (helpers.assertFileContent "git-config-file-generated"
    (pkgs.runCommand "git-test-home" { } ''
      export HOME=$(pwd)
      ${pkgs.home-manager}/bin/home-manager -f ${testConfig} build
      cat $HOME/.gitconfig
    '')
    expectedConfigText)

  # Git command functionality test
  (helpers.assertTestWithDetails "git-config-commands-work"
    (gitConfigWorks testConfig)
    "Git commands should work with generated config")
]
```

## Running Tests

### Test Commands

The project uses Nix's built-in test framework with Makefile integration:

```bash
# Required environment variables
export USER=$(whoami)  # Required for all operations

# Fast container tests (2-5 seconds)
make test

# Complete test suite with integration tests
make test-all

# Specific test execution
nix build .#checks.x86_64-linux.unit-mksystem-factory-validation

# Platform-specific tests
export USER=$(whoami) && nix build .#checks.aarch64-darwin.integration-darwin-specific
```

### Test Filtering

The test runner supports regex-based filtering:

```nix
# In test files
filteredSuite = runner.mkTestSuite "filtered" tests {
  filter = "git";  # Only tests matching "git" pattern
};
```

### CI/CD Integration

Tests run automatically across multiple platforms:

- **Darwin (macOS-15)**: Apple Silicon
- **Linux x64**: Intel/AMD
- **Linux ARM**: ARM64 with QEMU

**CI Workflow:**
```bash
# Fast container tests
export USER=${USER:-ci}
make test

# Full test suite (PRs and main)
make test-all

# Configuration validation
make -n switch
```

## TDD Workflow

Follow Test-Driven Development for all new features and bugfixes:

### 1. Write Failing Test

Create a test that clearly demonstrates the expected behavior:

```nix
# New test should fail initially
(helpers.assertTestWithDetails "new-feature-behavior-works"
  (featureFunction testInput)
  "New feature should behave as expected"
  expectedOutput)
```

### 2. Verify Test Fails

```bash
export USER=$(whoami)
nix build .#checks.x86_64-linux.unit-new-feature-test
# Expected: FAIL with clear error message
```

### 3. Implement Minimal Code

Write the simplest code that makes the test pass:

```nix
# Implementation in the actual feature file
featureFunction = input:
  # Minimal implementation to pass test
  if input == testInput then expectedOutput else defaultBehavior;
```

### 4. Verify Test Passes

```bash
export USER=$(whoami)
nix build .#checks.x86_64-linux.unit-new-feature-test
# Expected: PASS
```

### 5. Refactor While Keeping Tests Green

Improve implementation while maintaining test coverage.

## Best Practices

### Test Writing

- **Descriptive Names**: Use Feature-Scenario-ExpectedResult pattern
- **Clear Messages**: Include descriptive failure messages in assertions
- **Expected/Actual**: Provide expected and actual values for comparison
- **Platform Attributes**: Mark platform-specific tests appropriately
- **Isolation**: Keep tests independent and fast

### Error Reporting

- **Enhanced Assertions**: Always use `assertTestWithDetails` over simple assertions
- **Location Info**: Include file and line information for debugging
- **Structured Output**: Use emoji and formatting for readability
- **Comprehensive Messages**: Include all relevant context in failure messages

### Performance

- **Fast Unit Tests**: Unit tests should complete in seconds
- **Container Testing**: Use NixOS containers for fast integration tests
- **Lazy Evaluation**: Leverage Nix's lazy evaluation for efficient test execution
- **Platform Filtering**: Only run relevant tests on each platform

### Organization

- **Logical Grouping**: Group related tests in appropriate directories
- **Consistent Structure**: Follow established patterns for test organization
- **Documentation**: Include clear documentation for complex test scenarios
- **Version Control**: Commit tests with implementation (TDD approach)

## Examples from Implementation

### Enhanced Assertion Example

From `tests/unit/enhanced-assertions-test.nix`:

```nix
{
  test-assertTestWithDetails-pass =
    helpers.assertTestWithDetails "simple-pass" true "Should pass";

  test-assertTestWithDetails-fail =
    helpers.assertTestWithDetails "simple-fail" false "Should fail";
}
```

### Platform Helper Example

From `tests/unit/platform-helpers-test.nix`:

```nix
{
  platformDetectionWorks =
    helpers.assertTestWithDetails "platform-helpers-current-platform-detection"
      (builtins.isString currentPlatform)
      "Current platform detection should return string";

  mkPlatformTestConditional =
    platformHelpers.mkPlatformTest "linux"
      (helpers.assertTestWithDetails "linux-specific-test" true "Should only run on Linux");
}
```

### Integration Test Example

From `tests/integration/home-manager/git-config-generation.nix`:

```nix
helpers.testSuite "git-config-generation" [
  (helpers.assertFileContent "git-config-file-generated"
    generatedConfigPath
    expectedConfigText)

  (helpers.assertTestWithDetails "git-config-commands-work"
    (gitCommandsWork)
    "Git commands should work with generated config")
]
```

## Troubleshooting

### Common Issues

1. **USER Variable Not Set**: Always export USER=$(whoami) before running tests
2. **Platform Mismatch**: Ensure tests run on appropriate platforms
3. **Import Errors**: Check file paths and module dependencies
4. **Test Discovery**: Verify test files follow naming conventions

### Debugging Failed Tests

1. **Enhanced Output**: Use enhanced assertions for detailed error messages
2. **Individual Tests**: Run specific tests to isolate failures
3. **Platform Filtering**: Check platform requirements for platform-specific tests
4. **Dependency Issues**: Verify all required dependencies are available

### Performance Issues

1. **Test Speed**: Use container tests for faster execution
2. **Parallel Execution**: Leverage Nix's parallel test execution
3. **Resource Usage**: Monitor memory and CPU usage during test runs
4. **Caching**: Utilize Nix's binary cache for repeated test runs

This testing system provides a robust foundation for maintaining high-quality, reproducible dotfiles configurations across multiple platforms and use cases.
