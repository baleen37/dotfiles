# Testing Boundaries and Guidelines

## Overview

This document defines the boundaries and responsibilities for each level of testing in the dotfiles project. Following these guidelines ensures clear separation of concerns, minimal test duplication, and comprehensive coverage.

## Test Levels

### Unit Tests (`tests/unit/`)

**Purpose**: Test individual modules and functions in isolation

**Characteristics**:
- Fast execution (< 5 seconds per test)
- No external dependencies (use mocks/stubs)
- Focus on business logic and configuration transformation
- Test edge cases and error conditions

**Examples**:
```nix
# ✅ GOOD: Test git configuration transformation logic
test-git-alias-expansion =
  let
    mockGit = { aliases = { st = "status"; co = "checkout"; }; };
    result = gitModule.processAliases mockGit;
  in
  assertTest "git-alias-expansion" (result.status == "status");

# ❌ BAD: Test actual git command execution
test-git-command-execution =
  pkgs.runCommand "test-git" { } ''
    ${pkgs.git}/bin/git status  # This should be in integration tests
  '';
```

**Module Coverage**:
- `users/shared/git.nix` - Git configuration logic
- `users/shared/vim.nix` - Vim configuration generation
- `users/shared/zsh.nix` - Shell configuration logic
- `users/shared/darwin.nix` - macOS preference logic
- `lib/mksystem.nix` - System factory functions

**Mocking Strategy**:
- Mock external executables (git, vim, curl)
- Mock file system operations
- Mock system calls and platform detection
- Use `testHelpers.testConfig` for parameterized testing

### Integration Tests (`tests/integration/`)

**Purpose**: Test module interactions and real dependency behavior

**Characteristics**:
- Medium execution time (5-60 seconds)
- Use real dependencies when possible
- Test cross-module functionality
- Validate configuration deployment

**Examples**:
```nix
# ✅ GOOD: Test home-manager applies configuration correctly
test-home-manager-activation =
  let
    homeConfig = import ../../users/shared/home-manager.nix {
      inherit pkgs lib;
      username = "testuser";
    };
  in
  pkgs.runCommand "test-home-manager" { } ''
    ${homeConfig.activationScript}
    # Verify files exist in expected locations
    test -f $HOME/.gitconfig
    test -f $HOME/.vimrc
  '';

# ❌ BAD: Test individual function behavior (should be unit test)
test-git-alias-function =
  let
    aliasFunction = import ../../users/shared/git.nix { inherit lib; };
  in
  # This should be in unit tests with mocks
```

**Test Coverage**:
- Home Manager activation and file deployment
- Cross-module configuration conflicts
- System build process
- Package installation and conflicts
- Platform-specific behavior differences

### End-to-End Tests (`tests/e2e/`)

**Purpose**: Validate complete system functionality in real environment

**Characteristics**:
- Longer execution time (3-10 minutes)
- Full system validation
- Real user scenarios
- Minimal test count (3-5 core scenarios)

**Core Scenarios**:
1. **System Build Success**
   - `nix build` completes without errors
   - All derivations build successfully
   - No dependency conflicts

2. **User Environment Functionality**
   - User can log in
   - Shell configuration loads
   - Essential tools are accessible

3. **Core Tools Verification**
   - Git can execute commands
   - Editor can be launched
   - Development environment is functional

**Examples**:
```nix
# ✅ GOOD: Test complete user workflow
test-user-development-workflow =
  pkgs.runCommand "test-workflow" { } ''
    # 1. System builds
    nix build .#darwinConfigurations.macbook-pro.system

    # 2. User can work
    git clone https://github.com/example/repo.git
    cd repo

    # 3. Tools are functional
    vim README.md
    git add README.md
    git commit -m "Initial setup"
  '';

# ❌ BAD: Test individual configuration details
test-vim-syntax-highlighting =
  # This should be in unit tests with mocked vim
```

## Anti-Patterns to Avoid

### 1. Structural Testing
```nix
# ❌ ANTI-PATTERN: Testing file existence instead of behavior
test-config-file-exists =
  assertTest "config-exists" (builtins.pathExists "./config.json");

# ✅ CORRECT: Test that configuration is valid and functional
test-config-validation =
  let
    config = import ./config.nix;
  in
  assertTest "config-valid" (lib.isDerivation config.result);
```

### 2. Boundary Blurring
```nix
# ❌ ANTI-PATTERN: Unit test using external dependencies
test-git-execution =
  pkgs.runCommand "test-git" { } ''
    git config --global user.name "Test"  # Integration test behavior
  '';

# ✅ CORRECT: Unit test with mocked dependencies
test-git-config-generation =
  let
    mockUser = { name = "Test"; email = "test@example.com"; };
    result = gitModule.generateConfig mockUser;
  in
  assertTest "git-config" (result.user.name == "Test");
```

### 3. Over-testing in E2E
```nix
# ❌ ANTI-PATTERN: Detailed module testing in E2E
test-all-git-aliases =
  # Test every single git alias - should be in unit tests

# ✅ CORRECT: Focus on core workflows
test-git-workflow-completes =
  # Test that user can complete actual development tasks
```

## Mocking Guidelines

### Unit Tests: Mock Everything External
```nix
# ✅ GOOD: Complete isolation
test-git-function-with-mocks =
  let
    mockGit = {
      config = mockFunction "git-config";
      status = mockFunction "git-status";
    };
    result = gitModule.processCommand(mockGit, "status");
  in
  assertTest "git-mock" (result.success == true);
```

### Integration Tests: Mock Slow/External Services Only
```nix
# ✅ GOOD: Mock only network calls
test-git-with-network-mock =
  let
    mockNetwork = {
      fetch = mockFunction "git-fetch-origin";
    };
    # Real git operations, mocked network
  in
  # Test actual git behavior with mocked network
```

### E2E Tests: No Mocking
```nix
# ✅ GOOD: Full system validation
test-complete-workflow =
  pkgs.runCommand "test-full" { } ''
    # Real git, real network, real file system
    git clone https://github.com/example/repo.git
  '';
```

## Test Organization Rules

### File Placement
- `tests/unit/*-test.nix` - Individual module tests
- `tests/integration/*-test.nix` - Multi-module interaction tests
- `tests/e2e/*-test.nix` - Complete system tests
- `tests/lib/*.nix` - Test utilities and helpers

### Naming Conventions
- Unit: `{module}-test.nix` (e.g., `git-test.nix`)
- Integration: `{feature}-integration-test.nix` (e.g., `home-manager-integration-test.nix`)
- E2E: `{scenario}-e2e-test.nix` (e.g., `development-workflow-e2e-test.nix`)

### Test Structure
```nix
# Standard test structure
{
  pkgs,
  lib,
  # Use parameterized test config
  testConfig ? { username = "testuser"; },
}:

let
  # Test setup
  moduleUnderTest = import ../../path/to/module.nix { inherit lib; };

  # Test cases
  testCase1 = assertTest "test-name-1" condition1;
  testCase2 = assertTest "test-name-2" condition2;

in
# Test aggregation
pkgs.runCommand "test-results" { } ''
  echo "Running ${moduleUnderTest.name} tests..."
  echo "✅ testCase1: PASS"
  echo "✅ testCase2: PASS"
  touch $out
''
```

## Success Metrics

### Unit Test Success
- All tests run in < 30 seconds total
- 100% code coverage for business logic
- Zero external dependencies
- All edge cases covered

### Integration Test Success
- Tests run in < 5 minutes total
- Real dependency behavior validated
- Cross-module interactions verified
- No integration regressions

### E2E Test Success
- Core scenarios complete in < 3 minutes
- Real user workflows validated
- System functionality verified
- Zero false positives

## Migration Strategy

1. **Phase 1**: Document current test locations and responsibilities
2. **Phase 2**: Reorganize tests according to boundaries
3. **Phase 3**: Add missing test coverage
4. **Phase 4**: Optimize performance and remove duplication

Each phase should maintain 100% test pass rate - no functionality should be lost during reorganization.
