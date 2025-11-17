# Testing Best Practices for Dotfiles Project

## Overview

This document outlines the standardized testing patterns and best practices for the dotfiles project. Following these guidelines ensures maintainable, readable, and effective tests.

## Core Principles

### 1. Simplicity Over Complexity
- **Prefer** simple, focused tests over complex statistical analysis
- **Avoid** over-engineering tests with unnecessary abstractions
- **Focus** on what users actually need, not theoretical edge cases

### 2. Single Framework Approach
- **Use**: `testHelpers.mkTest` for 95% of tests
- **Use**: `nixosTest` only for VM-level tests
- **Avoid**: mixing multiple testing frameworks

### 3. Test Structure Standard
Every test should follow this pattern:

```nix
# filename-test.nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in

# Brief description of what this test validates
testHelpers.mkTest "test-name" ''
  echo "Testing [feature]..."

  # Test 1: [specific validation]
  if [condition]; then
    echo "✅ [test description]"
  else
    echo "❌ [test description] failed"
    exit 1
  fi

  # Test 2: [specific validation]
  # ... more tests

  echo "✅ All [feature] tests passed"
''
```

## Test Categories

### Unit Tests (`tests/unit/`)
- **Purpose**: Test individual functions and small components
- **Length**: 20-80 lines maximum
- **Focus**: Input/output validation, edge cases
- **Example**: `tests/unit/git-config-test.nix`

### Integration Tests (`tests/integration/`)
- **Purpose**: Test component interactions and system integration
- **Length**: 50-150 lines maximum
- **Focus**: Cross-component functionality, real workflows
- **Example**: `tests/integration/makefile-test.nix`

### E2E Tests (`tests/e2e/`)
- **Purpose**: End-to-end system validation
- **Length**: 100-300 lines maximum
- **Focus**: Complete user scenarios, VM testing
- **Example**: `tests/e2e/real-project-workflow-test.nix`

### Container Tests (`tests/containers/`)
- **Purpose**: NixOS container-based testing
- **Length**: 50-200 lines maximum
- **Focus**: System-level validation, service testing
- **Example**: `tests/containers/smoke-test.nix`

## Anti-Patterns to Avoid

### ❌ Over-Engineering
```nix
# AVOID: Complex statistical analysis
variance = if count > 1 then (lib.foldl (acc: v: acc + (v - mean) * (v - mean)) 0 values) / (count - 1) else 0;
stdDev = if variance > 0 then builtins.sqrt variance else 0;
```

```nix
# PREFER: Simple validation
if [ "$actual" = "$expected" ]; then
  echo "✅ Test passed"
else
  echo "❌ Test failed"
  exit 1
fi
```

### ❌ Multiple Frameworks
```nix
# AVOID: Mixing frameworks
testSuite = nixtest.suite "name" {
  test1 = assertTest "test1" condition "message";
  test2 = pkgs.runCommand "test2" {} ''...'';
}
```

```nix
# PREFER: Single framework
testHelpers.mkTest "feature-validation" ''
  # All validation logic here
''
```

### ❌ Excessive Abstraction
```nix
# AVOID: Complex helper functions
multiParamPropertyTest = name: property: testValueSets:
  let
    generateCombinations = valueSets: # ... 50 lines of complex logic
```

```nix
# PREFER: Simple inline testing
if [ "$result1" = "$expected1" ] && [ "$result2" = "$expected2" ]; then
  echo "✅ Property test passed"
fi
```

## Test Naming Conventions

### Files
- **Pattern**: `[feature]-test.nix`
- **Examples**: `git-config-test.nix`, `makefile-test.nix`, `flake-validation-test.nix`
- **Location**: Appropriate directory (`unit/`, `integration/`, `e2e/`)

### Test Names
- **Pattern**: `[feature]-validation` or `[component]-test`
- **Examples**: `"git-edge-cases"`, `"makefile-commands"`, `"flake-validation"`
- **Format**: lowercase-with-dashes

### Output Messages
```bash
# Standard format
echo "✅ [feature]: [specific validation passed]"
echo "❌ [feature]: [specific validation failed]"
echo "⚠️  [feature]: [warning or optional check]"
```

## Test Data Management

### Temporary Files
```bash
# Good: Use $$ for unique names
test_file="/tmp/test-$$"
echo "test content" > "$test_file"
# ... use file
rm -f "$test_file"

# Good: Cleanup in all paths
trap "rm -f /tmp/test-$$" EXIT
```

### Test Configuration
```nix
# Use testConfig from testHelpers
testConfig = {
  username = "testuser";
  homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
};
```

## Platform Testing

### Cross-Platform Tests
```nix
# Use runIfPlatform helper
darwinTest = testHelpers.runIfPlatform "darwin" (
  testHelpers.mkTest "darwin-feature" ''...''
);

linuxTest = testHelpers.runIfPlatform "linux" (
  testHelpers.mkTest "linux-feature" ''...''
);
```

### Platform-Specific Logic
```bash
# In test scripts
if [[ "$OSTYPE" == darwin* ]]; then
  # macOS-specific test
elif [[ "$OSTYPE" == linux* ]]; then
  # Linux-specific test
fi
```

## Test Organization

### Directory Structure
```
tests/
├── lib/                    # Test helpers and utilities
│   ├── test-helpers.nix    # Main test helper functions
│   └── nixtest-template.nix # Minimal testing framework
├── unit/                   # Unit tests (20-80 lines)
├── integration/            # Integration tests (50-150 lines)
├── e2e/                    # End-to-end tests (100-300 lines)
├── containers/             # NixOS container tests
└── default.nix            # Test discovery and aggregation
```

### Test Discovery
- Tests are automatically discovered via `*-test.nix` pattern
- No need to manually add tests to `default.nix`
- Use descriptive names that clearly indicate purpose

## Running Tests

### Development Workflow
```bash
# Run all tests
make test

# Run specific test category
make test-unit
make test-integration
make test-e2e

# Run individual test
nix build .#checks.x86_64-linux.unit-feature-name
```

### CI/CD Integration
- Tests run automatically on PRs
- Container tests for fast feedback (2-5 seconds)
- Full test suite for main branch validation
- Cross-platform testing (Darwin, Linux x64, Linux ARM)

## Test Metrics

### Success Criteria
- **Speed**: Unit tests < 30s, Integration < 2min, E2E < 10min
- **Coverage**: Critical user workflows covered
- **Reliability**: Tests pass consistently across platforms
- **Maintainability**: New developers can understand and modify tests

### Quality Indicators
- **Lines per test**: < 150 lines (95% of tests)
- **Test complexity**: Minimal nesting and conditionals
- **Documentation**: Clear purpose and scope comments
- **Error messages**: Helpful failure descriptions

## Review Checklist

Before submitting tests, verify:

- [ ] Test follows standard structure pattern
- [ ] Test name is descriptive and follows naming convention
- [ ] Output messages follow emoji + description format
- [ ] Test is under 150 lines (unless E2E test)
- [ ] No over-engineering or unnecessary complexity
- [ ] Platform-specific code uses appropriate helpers
- [ ] Temporary files are properly cleaned up
- [ ] Test validates actual user needs, not theoretical cases

## Migration Guidelines

When updating existing tests:

1. **Identify** the core purpose of the test
2. **Extract** essential validation logic
3. **Remove** over-engineering and complexity
4. **Refactor** to use `testHelpers.mkTest` pattern
5. **Validate** test still covers original requirements
6. **Update** naming and documentation as needed

## Examples

### Good Unit Test
```nix
# git-config-test.nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in

testHelpers.mkTest "git-config-validation" ''
  echo "Testing Git configuration..."

  # Test git availability
  if command -v git >/dev/null 2>&1; then
    echo "✅ Git is available"
  else
    echo "❌ Git is not available"
    exit 1
  fi

  # Test email validation
  test_email="test@example.com"
  if [[ "$test_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "✅ Email validation working"
  else
    echo "❌ Email validation failed"
    exit 1
  fi

  echo "✅ All Git configuration tests passed"
''
```

### Good Integration Test
```nix
# makefile-test.nix
testHelpers.mkTest "makefile-commands" ''
  echo "Testing Makefile commands..."

  # Check essential targets
  for target in "switch" "test" "cache"; do
    if grep -q "^$target:" ./Makefile; then
      echo "✅ Target '$target' found"
    fi
  done

  echo "✅ Makefile validation complete"
''
```

---

**Remember**: Tests should be simple, focused, and maintainable. The goal is to validate functionality, not to showcase complex programming techniques.
