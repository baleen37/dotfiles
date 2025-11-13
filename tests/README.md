# Testing Guidelines and Helper Documentation

This document provides comprehensive guidelines for writing and maintaining tests in this dotfiles repository.

## Table of Contents

- [Overview](#overview)
- [Standard Test Structure](#standard-test-structure)
- [Available Helpers](#available-helpers)
- [Test Types](#test-types)
- [Writing New Tests](#writing-new-tests)
- [Test Examples](#test-examples)
- [Best Practices](#best-practices)
- [Running Tests](#running-tests)

## Overview

The testing framework follows a consistent pattern using helper functions from `tests/lib/test-helpers.nix`. This ensures all tests have uniform structure, output formatting, and error handling.

### Key Principles

- **Consistency**: All unit tests use the same helper pattern
- **Clarity**: Test names and messages clearly describe what is being tested
- **Maintainability**: Helper functions reduce code duplication and centralize test logic
- **TDD**: Tests are written first, then implementation follows

## Standard Test Structure

All unit tests should follow this standard pattern:

```nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test data and helper functions specific to this test
  testData = {
    # ... your test data here
  };

  # Validation functions
  validateSomething = input:
    # ... your validation logic here
    ;

in
helpers.testSuite "test-name" [
  # Individual test cases using assertTest
  (helpers.assertTest "test-case-name" (
    # Test expression that evaluates to true/false
    validateSomething testData.someInput
  ) "Descriptive message explaining what the test verifies")

  # More test cases...
]
```

## Available Helpers

### `helpers.testSuite`

The main wrapper for creating a test suite.

```nix
helpers.testSuite "suite-name" [
  (helpers.assertTest "test-1" true "Test 1 description")
  (helpers.assertTest "test-2" false "Test 2 description")
  # ... more tests
]
```

**Parameters:**
- `suite-name`: String identifier for the test suite
- List of `assertTest` calls

### `helpers.assertTest`

Creates an individual test case within a test suite.

```nix
helpers.assertTest "test-name" test-expression "failure-message"
```

**Parameters:**
- `test-name`: Unique name for this test case
- `test-expression`: Boolean expression that should evaluate to `true` for the test to pass
- `failure-message`: Descriptive message explaining what the test verifies

### `helpers.runTestList`

Utility for testing multiple scenarios with the same validation function.

```nix
helpers.runTestList "test-group-name" [
  {
    name = "test-case-1";
    expected = true;
    actual = validateSomething input1;
  }
  {
    name = "test-case-2";
    expected = false;
    actual = validateSomething input2;
  }
]
```

### `helpers.mkTest`

Legacy helper for creating shell-based tests (use `testSuite` for new tests).

```nix
helpers.mkTest "test-name" ''
  # Shell script that writes to $out to indicate success
  echo "Test passed"
  touch $out
''
```

## Test Types

### Unit Tests (`tests/unit/`)

Test individual components, functions, and configurations in isolation.

**Examples:**
- Configuration validation
- Function behavior testing
- Data structure validation
- Edge case handling

**Standard Pattern**: Always use `helpers.testSuite`

### Integration Tests (`tests/integration/`)

Test how multiple components work together.

**Examples:**
- Home Manager with system configuration
- Cross-platform behavior
- Service interactions
- Tool integration

### End-to-End Tests (`tests/e2e/`)

Test complete workflows and real-world scenarios.

**Examples:**
- Full system switch process
- Application installation and configuration
- Development environment setup

## Writing New Tests

### Step 1: Create Test File

Create a new file in the appropriate directory:
- `tests/unit/` for component tests
- `tests/integration/` for integration tests
- `tests/e2e/` for end-to-end tests

File naming convention: `component-name-test.nix`

### Step 2: Use Standard Template

```nix
# Brief description of what this test covers
#
# Additional context about what's being tested and why it's important

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test data and setup
  testData = {
    # ... test-specific data
  };

  # Validation functions
  validateFeature = input:
    # ... validation logic
    ;

in
helpers.testSuite "component-name" [
  # Test cases go here
]
```

### Step 3: Add Test Cases

For each test case:

1. **Use descriptive names**: `feature-works-correctly`, `error-handling`, `edge-case-validation`
2. **Write clear failure messages**: Explain what should happen and why it's important
3. **Test both success and failure cases**: Validate both positive and negative scenarios
4. **Keep tests focused**: Each test should verify one specific behavior

### Step 4: Verify Test Discovery

Ensure your test is discoverable by checking it appears in:
```bash
make test  # Should include your new test
```

## Test Examples

### Basic Configuration Test

```nix
helpers.testSuite "darwin" [
  # Test system settings exist
  (helpers.assertTest "darwin-has-system-settings" (
    darwinConfig ? system
  ) "Darwin config should have system settings")

  # Test Homebrew config exists
  (helpers.assertTest "darwin-has-homebrew" (
    darwinConfig ? homebrew
  ) "Darwin config should have Homebrew configuration")
]
```

### Function Behavior Test

```nix
helpers.testSuite "mksystem" [
  # Test function exists
  (helpers.assertTest "mksystem-function-exists" testFunctionExists
    "mkSystem function should exist and be callable")

  # Test function accepts inputs
  (helpers.assertTest "mksystem-accepts-inputs" canCallWithInputs.success
    "mkSystem should accept inputs parameter")
]
```

### Edge Case Test

```nix
helpers.testSuite "edge-case-user-config" [
  # Test minimum username length
  (helpers.assertTest "username-min-length" (
    builtins.stringLength username >= 1
  ) "Single character username should be valid")

  # Test unusual username formats
  (helpers.assertTest "unusual-username-format" (
    builtins.match "^[a-z][a-z0-9-]*[a-z0-9]$" username != null
  ) "Username with numbers and hyphens should be valid")
]
```

## Best Practices

### DOs

✅ **Use consistent helper patterns** - Always use `helpers.testSuite` for unit tests
✅ **Write descriptive test names** - Use clear, specific names that describe what's being tested
✅ **Provide clear failure messages** - Explain what should happen and why it's important
✅ **Test both positive and negative cases** - Validate both success and failure scenarios
✅ **Keep tests focused** - Each test should verify one specific behavior
✅ **Follow TDD methodology** - Write failing tests first, then implement to pass
✅ **Use meaningful test data** - Test with realistic data and edge cases
✅ **Validate behavior, not just structure** - Test that functionality works, not just that files exist

### DON'Ts

❌ **Mix testing patterns** - Don't combine `pkgs.runCommand` with `helpers.testSuite` in the same test
❌ **Write vague test names** - Avoid names like `test-1`, `test-basic`, `simple-test`
❌ **Skip failure messages** - Always provide descriptive messages for assertTest
❌ **Test implementation details** - Test behavior, not how it's implemented
❌ **Write complex test logic** - Keep validation functions simple and focused
❌ **Ignore edge cases** - Test boundary conditions and unusual but valid inputs
❌ **Hardcode system-specific paths** - Use platform-independent approaches

### Test Data Management

- **Local test data**: Define within the test file using `let` blocks
- **Shared test data**: Use `tests/lib/` for common test utilities
- **External dependencies**: Avoid when possible; prefer pure Nix tests
- **Platform-specific tests**: Use conditional logic for cross-platform compatibility

## Running Tests

### Quick Validation (macOS)

```bash
export USER=$(whoami)
make test
```

This runs validation mode on macOS, ensuring all test configurations evaluate correctly.

### Full Test Suite (Linux/CI)

```bash
export USER=$(whoami)
make test-all
```

This runs the complete test suite including container-based integration tests.

### Individual Test Categories

```bash
# Unit tests only
make test-unit

# Integration tests only
make test-integration

# End-to-end tests only
make test-e2e
```

### Test Discovery

All tests are automatically discovered and included in the test suite. Test files follow the naming pattern:
- `*-test.nix` in appropriate test directory
- Tests are grouped by type: unit, integration, e2e

## Test Framework Evolution

### Legacy Tests

Some existing tests use `pkgs.runCommand` instead of the standard helper pattern. While these continue to work, new tests should use `helpers.testSuite` for consistency.

### Migration Path

When updating legacy tests:
1. Preserve existing test logic and validation
2. Convert `pkgs.runCommand` to `helpers.testSuite` pattern
3. Maintain test coverage and edge cases
4. Verify test behavior remains unchanged

## Troubleshooting

### Common Issues

**Tests not discovered**: Ensure file follows naming pattern (`*-test.nix`) and is in correct directory

**Helper function not found**: Verify import path `../lib/test-helpers.nix` is correct relative to test file location

**Test evaluation fails**: Check for syntax errors, missing imports, or incorrect helper usage

**Platform-specific failures**: Use conditional logic or skip tests on incompatible platforms

### Debug Tips

- Use `nix-instantiate --eval` to test individual expressions
- Check test output for specific failure messages
- Verify test data and validation functions are working correctly
- Use `make test-nix-dry` to validate configuration without running tests

## Contributing

When adding new tests:

1. **Follow the standard pattern** - Use `helpers.testSuite` and `helpers.assertTest`
2. **Provide comprehensive coverage** - Include edge cases and error conditions
3. **Document test purpose** - Use comments to explain what and why you're testing
4. **Verify test discovery** - Ensure tests are included in the overall test suite
5. **Update this documentation** - Add examples and patterns for new test types

---

*This documentation should be updated as the testing framework evolves. Last updated: 2025-01-14*
