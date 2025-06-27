# Unit Test Organization Strategy

## Overview

This directory contains consolidated unit tests for the dotfiles repository. We've reduced test file proliferation from 47+ files to ~24 files while maintaining comprehensive test coverage.

## Test Organization Principles

### 1. One Test File Per Feature/Module

Each major feature or module should have a single comprehensive test file that covers all aspects:

- **claude-commands-test.nix** - All Claude command copying functionality
- **claude-config-test.nix** - All Claude configuration management
- **auto-update-test.nix** - Core auto-update functionality
- **bl-auto-update-commands-unit.nix** - CLI interface layer (kept separate)
- **error-handling-test.nix** - All error handling mechanisms
- **user-resolution-test.nix** - User detection and resolution
- **platform-detection-test.nix** - Platform detection and utilities

### 2. Test Structure Within Files

Each consolidated test file follows this structure:

```nix
{ pkgs, src ? ../.., ... }:

let
  # Test environment setup
  testEnv = ...;
  
  # Helper functions
  helpers = ...;
  
  # Mock data
  mocks = ...;

in
pkgs.runCommand "feature-test" {
  buildInputs = with pkgs; [ bash jq ... ];
} ''
  echo "🧪 Comprehensive [Feature] Test Suite"
  
  # Test 1: Basic Functionality
  echo "📋 Test 1: [Description]"
  # ... test implementation ...
  
  # Test 2: Advanced Features
  echo "📋 Test 2: [Description]"
  # ... test implementation ...
  
  # ... more tests ...
  
  # Final Summary
  echo "🎉 All [Feature] Tests Completed!"
  echo "Summary:"
  echo "- Test 1: ✅"
  echo "- Test 2: ✅"
  # ... summary ...
  
  touch $out
''
```

### 3. Test Categories

Tests are numbered and organized by category within each file:

1. **Basic Functionality** - Core feature validation
2. **Advanced Features** - Complex scenarios and edge cases
3. **Integration Points** - How the feature interacts with others
4. **Error Handling** - Failure scenarios and recovery
5. **Performance** - Resource usage and optimization
6. **Platform-Specific** - OS-specific behavior
7. **Security** - Permission and security validations
8. **User Experience** - UI/UX related testing
9. **Edge Cases** - Unusual scenarios
10. **Full Workflow** - End-to-end feature testing

### 4. Consolidation Guidelines

When consolidating tests:

1. **Remove TDD Setup Tests** - Tests that check for non-existent files
2. **Merge Overlapping Tests** - Combine tests that validate the same functionality
3. **Keep Real-World Scenarios** - Preserve tests that validate actual use cases
4. **Eliminate Redundancy** - Remove duplicate test logic
5. **Maintain Coverage** - Ensure no test scenarios are lost

### 5. Benefits of Consolidation

- **Reduced CI Time**: Fewer files to load and process
- **Easier Maintenance**: Less duplication to update
- **Better Organization**: Clear feature boundaries
- **Improved Readability**: Comprehensive view of feature testing
- **Faster Development**: Easier to find and update tests

## Adding New Tests

When adding new functionality:

1. **Check Existing Files** - See if your test fits in an existing consolidated file
2. **Create New File Only If Needed** - For truly new features/modules
3. **Follow the Structure** - Use the established test file structure
4. **Update This README** - Document any new test files added

## Running Tests

```bash
# Run all tests
make test

# Run specific test category
make test-unit

# Run with detailed output
nix run --impure .#test -- --verbose

# Check test framework status
make test-status
```

## Test Naming Convention

- **Feature tests**: `{feature}-test.nix` (e.g., `error-handling-test.nix`)
- **Module tests**: `{module}-unit.nix` (e.g., `bl-auto-update-commands-unit.nix`)
- **Integration tests**: Should go in `../integration/`
- **E2E tests**: Should go in `../e2e/`

## Maintenance

Periodically review test files for:
- New redundancies that can be consolidated
- Tests that can be moved to more appropriate files
- Outdated tests that can be removed
- Missing test coverage that should be added