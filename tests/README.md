# Testing Documentation

Comprehensive testing framework for Nix flakes-based dotfiles with TDD methodology, automatic test discovery, and cross-platform support.

## Overview

This testing framework provides:

- **Multiple Test Types**: Unit, integration, container, and end-to-end tests
- **Auto-Discovery**: Automatic test discovery using `*-test.nix` naming pattern
- **Platform Filtering**: Run tests only on relevant platforms (Darwin/Linux)
- **Rich Helpers**: Comprehensive test helpers for common patterns
- **TDD Support**: Test-driven development workflow integration
- **Fast Feedback**: Unit tests run in 2-5 seconds, container tests in CI

## Test Types

### Unit Tests
Fast, isolated tests for individual functions and modules.

**Location**: `tests/unit/*-test.nix`

**Purpose**: Test pure functions, data transformations, and configuration logic.

**Example**:
```nix
# tests/unit/lib-user-info-test.nix
{
  inputs, system, pkgs, lib, self,
}:
let
  testHelpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  userInfo = import ../../lib/user-info.nix;
in
{
  name-is-non-empty = testHelpers.assertTest "user-info-name-is-non-empty" (
    builtins.typeOf userInfo.name == "string"
    && builtins.stringLength userInfo.name > 0
  ) "userInfo.name should be a non-empty string";
}
```

### Integration Tests
Tests that verify multiple components work together.

**Location**: `tests/integration/*-test.nix`

**Purpose**: Test module interactions, configuration generation, and tool integration.

**Example**:
```nix
# tests/integration/git-configuration-test.nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  gitConfig = import ../../users/shared/git.nix {
    inherit pkgs lib;
    config = { };
  };
in
helpers.testSuite "git-configuration" [
  (helpers.assertTest "git-enabled" (
    gitConfig.programs.git.enable == true
  ) "Git should be enabled")
]
```

### Container Tests
NixOS container tests for system-level validation.

**Location**: `tests/containers/*.nix`

**Purpose**: Test system configuration, services, and packages in isolated containers.

**Platform**: Linux only (via `pkgs.testers.nixosTest`).

**Example**:
```nix
# tests/containers/basic-system.nix
{ pkgs, lib, ... }:
{
  name = "basic-system-test";

  nodes.machine = {
    system.stateVersion = "24.11";
    users.users.testuser = {
      isNormalUser = true;
      home = "/home/testuser";
    };
    environment.systemPackages = with pkgs; [ git vim ];
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("which git")
    machine.succeed("which vim")
    print("✅ Basic system test passed")
  '';
}
```

### End-to-End Tests
Heavy VM tests for complete system validation.

**Location**: `tests/e2e/*-test.nix`

**Purpose**: Full system bootstrap, cross-platform builds, multi-user scenarios.

**Usage**: Manual invocation only (excluded from auto-discovery).

```bash
nix eval '.#checks.aarch64-darwin.e2e-test-name' --impure
```

## Test Structure

### Directory Layout

```
tests/
├── lib/
│   ├── test-helpers.nix      # Main test helpers framework
│   ├── assertions.nix         # Assertion utilities with detailed errors
│   └── platform-helpers.nix   # Platform-aware test filtering
├── unit/                      # Fast unit tests (auto-discovered)
│   └── *-test.nix
├── integration/               # Integration tests (auto-discovered)
│   └── *-test.nix
├── containers/                # Container tests (manual)
│   ├── smoke-test.nix
│   ├── basic-system.nix
│   ├── services.nix
│   └── packages.nix
├── e2e/                      # End-to-end tests (manual)
│   └── *-test.nix
└── default.nix               # Test orchestration and discovery
```

### Naming Conventions

**Test Files**: Must end with `-test.nix` for auto-discovery

**Helper Files**: Must NOT end with `-test.nix` (excluded from discovery)

**Excluded Patterns**:
- `default.nix`
- `nixtest-template.nix`
- Files in `lib/` directory

### Platform Filtering

Tests can specify platform requirements using the `platforms` attribute:

```nix
{
  platforms = ["darwin"];  # Only runs on macOS
  value = helpers.assertTest "darwin-specific" true "Test message";
}
```

**Supported Platforms**:
- `"darwin"` - macOS only
- `"linux"` - Linux only
- `["darwin" "linux"]` - Both platforms
- No `platforms` attribute - All platforms

## Test Helpers

### Core Helpers (tests/lib/test-helpers.nix)

#### Basic Assertions

**`assertTest`**
```nix
assertTest "test-name" condition "failure message"
```
Basic assertion with pass/fail reporting.

**Example**:
```nix
helpers.assertTest "git-enabled" (
  gitConfig.programs.git.enable == true
) "Git should be enabled"
```

---

**`assertTestWithDetails`**
```nix
assertTestWithDetails "test-name" expected actual "message"
```
Enhanced assertion with expected/actual value comparison.

**Example**:
```nix
helpers.assertTestWithDetails "user-name" "Jiho Lee" userInfo.name "User name should match"
```

---

**`assertFileExists`**
```nix
assertFileExists "test-name" derivation "path/in/derivation"
```
Validates file exists and is readable in a derivation.

**Example**:
```nix
helpers.assertFileExists "gitconfig-exists" homeConfig ".gitconfig"
```

---

**`assertHasAttr`**
```nix
assertHasAttr "test-name" "attr-name" attrset
```
Checks for attribute existence in a set.

**Example**:
```nix
helpers.assertHasAttr "has-git" "git" config.programs
```

---

**`assertContains`**
```nix
assertContains "test-name" "needle" "haystack"
```
String substring check.

**Example**:
```nix
helpers.assertContains "email-has-at" "@" userEmail
```

---

**`assertBuilds`**
```nix
assertBuilds "test-name" derivation
```
Validates a derivation builds successfully.

**Example**:
```nix
helpers.assertBuilds "vim-builds" pkgs.vim
```

---

### Bulk Assertion Helpers

**`assertSettings`**
```nix
assertSettings "group-name" actualSettings expectedSettings
```
Test multiple key-value pairs in nested attribute sets.

**Example**:
```nix
helpers.assertSettings "git-core" gitSettings.core {
  editor = "vim";
  autocrlf = "input";
  excludesFile = "~/.gitignore_global";
}
```

---

**`assertPatterns`**
```nix
assertPatterns "list-name" actualList expectedPatterns
```
Test that a list contains all expected patterns.

**Example**:
```nix
helpers.assertPatterns "gitignore" gitIgnores [
  "*.swp"
  "*.swo"
  ".DS_Store"
]
```

---

**`assertAliases`**
```nix
assertAliases aliasSettings expectedAliases
```
Test git alias configuration.

**Example**:
```nix
helpers.assertAliases gitSettings.alias {
  st = "status";
  co = "checkout";
  br = "branch";
}
```

---

### Git-Specific Helpers

**`assertGitUserInfo`**
```nix
assertGitUserInfo "test-name" gitConfig expectedName expectedEmail
```
Validate git user name and email.

**Example**:
```nix
helpers.assertGitUserInfo "git-user" gitConfig "Jiho Lee" "baleen37@gmail.com"
```

---

**`assertGitSettings`**
```nix
assertGitSettings "test-name" gitConfig expectedSettings
```
Validate git settings (supports nested keys like "init.defaultBranch").

**Example**:
```nix
helpers.assertGitSettings "git-settings" gitConfig {
  lfs.enable = true;
  init.defaultBranch = "main";
}
```

---

**`assertGitAliases`**
```nix
assertGitAliases "test-name" gitConfig expectedAliases
```
Validate git aliases with detailed error reporting.

**Example**:
```nix
helpers.assertGitAliases "git-aliases" gitConfig {
  st = "status";
  co = "checkout";
}
```

---

**`assertGitIgnorePatterns`**
```nix
assertGitIgnorePatterns "test-name" gitConfig expectedPatterns
```
Validate gitignore patterns.

**Example**:
```nix
helpers.assertGitIgnorePatterns "gitignore" gitConfig [
  "*.swp"
  ".DS_Store"
]
```

---

### macOS-Specific Helpers

**`assertNSGlobalDef`**
```nix
assertNSGlobalDef "test-name" "key" expectedValue darwinConfig
```
Test NSGlobalDomain default setting.

**Example**:
```nix
helpers.assertNSGlobalDef "window-animations" "NSAutomaticWindowAnimationsEnabled" false darwinConfig
```

---

**`assertDockSetting`**
```nix
assertDockSetting "test-name" "key" expectedValue darwinConfig
```
Test dock setting.

**Example**:
```nix
helpers.assertDockSetting "autohide" "autohide" true darwinConfig
```

---

**`assertFinderSetting`**
```nix
assertFinderSetting "test-name" "key" expectedValue darwinConfig
```
Test Finder setting.

**Example**:
```nix
helpers.assertFinderSetting "show-hidden" "AppleShowAllFiles" true darwinConfig
```

---

**`assertTrackpadSetting`**
```nix
assertTrackpadSetting "test-name" "key" expectedValue darwinConfig
```
Test trackpad setting.

---

### Test Suite Helpers

**`testSuite`**
```nix
testSuite "suite-name" [test1 test2 test3]
```
Aggregate multiple tests into a suite.

**Example**:
```nix
helpers.testSuite "git-configuration" [
  (helpers.assertTest "git-enabled" gitConfig.programs.git.enable == true)
  (helpers.assertSettings "git-core" gitSettings.core { editor = "vim"; })
]
```

---

### Property-Based Testing

**`propertyTest`**
```nix
propertyTest "test-name" propertyFunction testValues
```
Test a property across multiple test values.

**Example**:
```nix
helpers.propertyTest "commutative-addition"
  (x: x + 1 == 1 + x)
  [1 2 3 4 5 0 -1]
```

---

**`forAllCases`**
```nix
forAllCases "test-name" testCases propertyFunction
```
Helper pattern for property-based testing with named test cases.

**Example**:
```nix
helpers.forAllCases "user-identity-validation" testUsers validateUserIdentity
```

---

### Platform Helpers

**`runIfPlatform`**
```nix
runIfPlatform "darwin" test
```
Conditionally run test based on platform.

**Example**:
```nix
helpers.runIfPlatform "darwin" (
  helpers.assertTest "homebrew-check" true "Homebrew available"
)
```

---

### Utility Helpers

**`mkTest`**
```nix
mkTest "test-name" "bash test logic"
```
Create a test with custom bash logic.

**Example**:
```nix
helpers.mkTest "custom-check" ''
  if [ -f "/path/to/file" ]; then
    echo "File exists"
  else
    exit 1
  fi
''
```

---

**`runTestList`**
```nix
runTestList "test-name" [
  { name = "test1"; expected = true; actual = true; }
  { name = "test2"; expected = "hello"; actual = "hello"; }
]
```
Run a list of test cases with expected/actual comparison.

---

**`assertPerformance`**
```nix
assertPerformance "test-name" expectedBoundMs "command"
```
Performance test with execution time bound.

**Example**:
```nix
helpers.assertPerformance "fast-command" 1000 "echo 'test'"
```

---

### Configuration Helpers

**`createTestUserConfig`**
```nix
createTestUserConfig { home.packages = [pkgs.vim]; }
```
Create test user configuration with parameterized settings.

---

**`getUserHomeDir`** / **`getTestUserHome`**
```nix
getUserHomeDir "username"  # Returns "/Users/username" or "/home/username"
getTestUserHome            # Returns test user home directory
```
Platform-agnostic home directory resolution.

---

**`createModuleTestConfig`**
```nix
createModuleTestConfig moduleConfig
```
Create test configuration for modules requiring `currentSystemUser`.

---

## Writing Tests

### Standard Test Pattern

All test files should follow this structure:

```nix
# tests/unit/my-feature-test.nix
{
  inputs, system, pkgs, lib, self, nixtest ? {}
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  # Import the code under test
  myConfig = import ../../users/shared/my-feature.nix {
    inherit pkgs lib;
    config = { };
  };
in
helpers.testSuite "my-feature" [
  # Test cases here
  (helpers.assertTest "feature-enabled" (
    myConfig.enable == true
  ) "Feature should be enabled")
]
```

### Unit Test Pattern

For testing pure functions and data transformations:

```nix
{
  inputs, system, pkgs, lib, self,
}:
let
  testHelpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  myFunction = import ../../lib/my-function.nix;
in
{
  test-1 = testHelpers.assertTest "function-works" (
    myFunction 2 == 4
  ) "Function should double input";

  test-2 = testHelpers.assertTest "handles-zero" (
    myFunction 0 == 0
  ) "Function should handle zero";
}
```

### Integration Test Pattern

For testing module interactions:

```nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  config = import ../../users/shared/my-config.nix {
    inherit pkgs lib;
    config = { };
  };
in
helpers.testSuite "my-config-integration" [
  (helpers.assertTest "config-valid" (
    config ? programs && config ? services
  ) "Config should have programs and services")

  (helpers.assertSettings "program-settings" config.programs.myProgram {
    enable = true;
    setting = "value";
  })
]
```

### Property-Based Test Pattern

For testing invariants across multiple scenarios:

```nix
{
  inputs, system, pkgs, lib, self, nixtest ? {}
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  testCases = [
    { name = "case1"; value = 1; }
    { name = "case2"; value = 2; }
    { name = "case3"; value = 3; }
  ];

  validateProperty = case: case.value > 0;
in
helpers.testSuite "property-test" [
  (helpers.forAllCases "my-property" testCases validateProperty)
]
```

### Platform-Specific Test Pattern

For tests that only run on specific platforms:

```nix
{
  inputs, system, pkgs, lib, self, nixtest ? {}
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  platforms = ["darwin"];
  value = helpers.assertTest "darwin-feature" (
    pkgs.stdenv.hostPlatform.isDarwin
  ) "This test only runs on Darwin";
}
```

### Best Practices

1. **Use Helper Functions**: Always prefer helper functions over raw derivations
2. **Descriptive Names**: Use clear, descriptive test names
3. **Specific Assertions**: Test one thing per assertion
4. **Bulk Helpers**: Use `assertSettings`, `assertPatterns` for multiple values
5. **Property Testing**: Use `forAllCases` for invariant validation
6. **Platform Filtering**: Use `platforms` attribute for platform-specific tests
7. **Test Data**: Use generated test data, not personal information
8. **Error Messages**: Include clear failure messages for debugging

### Common Patterns

**Testing Configuration Generation**:
```nix
(helpers.assertFileExists "config-file" configDerivation ".config/app/config.conf")
```

**Testing Package Installation**:
```nix
(helpers.assertTest "package-installed" (
  builtins.elem "mypackage" config.home.packages
) "Package should be in packages list")
```

**Testing Aliases**:
```nix
(helpers.assertAliases config.programs.git.aliases {
  st = "status";
  co = "checkout";
})
```

**Testing Platform-Specific Code**:
```nix
(helpers.runIfPlatform "darwin" (
  helpers.assertTest "homebrew-enabled" true "Homebrew available on Darwin"
))
```

## Running Tests

### Make Commands

**Quick Test** (Unit + Integration):
```bash
make test
```

**All Tests** (Unit + Integration + Container):
```bash
make test-all
```

**Integration Tests Only**:
```bash
make test-integration
```

### Nix Commands

**Run All Tests**:
```bash
export USER=$(whoami)
nix flake check --impure
```

**Run Specific Test**:
```bash
nix build '.#checks.aarch64-darwin.unit-lib-user-info' --impure
```

**Run Container Test** (Linux only):
```bash
nix build '.#checks.x86_64-linux.basic' --impure
```

### Platform-Specific Considerations

**macOS**:
- Container tests don't run (require Linux)
- `make test` runs validation mode (config check without execution)
- Full container tests run in CI

**Linux**:
- All tests run including container tests
- `make test` executes full test suite
- Faster feedback without validation mode

**CI**:
- Runs on macOS-15 (ARM) and Ubuntu (x64 + ARM64)
- Executes full container tests on Linux runners
- Uploads successful builds to Cachix

## Refactoring Guidelines

### When to Create New Helpers

Create a new helper when:

1. **Code Duplication**: Same pattern appears in 3+ tests
2. **Domain-Specific Logic**: Complex validation logic for specific domain (git, darwin, etc.)
3. **Cross-Cutting Concerns**: Platform filtering, user configuration, etc.
4. **Improved Error Messages**: Current helpers don't provide enough debugging info

### How to Reduce Duplication

**Before** (Duplicated):
```nix
(helpers.assertTest "git-editor" gitSettings.core.editor == "vim")
(helpers.assertTest "git-autocrlf" gitSettings.core.autocrlf == "input")
(helpers.assertTest "git-excludes" gitSettings.core.excludesFile == "~/.gitignore_global")
```

**After** (Using Helper):
```nix
(helpers.assertSettings "git-core" gitSettings.core {
  editor = "vim";
  autocrlf = "input";
  excludesFile = "~/.gitignore_global";
})
```

### Code Review Checklist

When reviewing test code:

- [ ] Uses appropriate helper functions
- [ ] Descriptive test names
- [ ] Clear failure messages
- [ ] Platform filtering if needed
- [ ] No hardcoded personal data
- [ ] Follows naming conventions (`*-test.nix`)
- [ ] Tests are discoverable (not in `lib/`)
- [ ] Uses `testSuite` for multiple related tests
- [ ] Property testing for invariants
- [ ] No test implementation in production code

### Creating New Helpers

**Step 1**: Identify the pattern

```nix
# Pattern found in 3+ tests
(helpers.assertTest "setting1" config.setting1 == "value1")
(helpers.assertTest "setting2" config.setting2 == "value2")
(helpers.assertTest "setting3" config.setting3 == "value3")
```

**Step 2**: Create helper in `tests/lib/test-helpers.nix`

```nix
assertSettings =
  name: settings: expectedValues:
  let
    individualTests = builtins.map (
      key:
      let
        expectedValue = builtins.getAttr key expectedValues;
        actualValue = builtins.getAttr key settings;
        testName = "${name}-${key}";
      in
      assertTest testName (actualValue == expectedValue) "${name}.${key} should match"
    ) (builtins.attrNames expectedValues);

    summaryTest = pkgs.runCommand "${name}-settings-summary" { } ''
      echo "✅ Settings group '${name}': All tests passed"
      touch $out
    '';
  in
  testSuite "${name}-settings" (individualTests ++ [ summaryTest ]);
```

**Step 3**: Use the helper

```nix
(helpers.assertSettings "my-settings" config {
  setting1 = "value1";
  setting2 = "value2";
  setting3 = "value3";
})
```

**Step 4**: Update documentation (this file)

## Test Discovery

Tests are automatically discovered using the pattern in `tests/default.nix`:

```nix
discoverTests = dir: prefix:
  lib.pipe (builtins.readDir dir) [
    (lib.filterAttrs (
      name: type:
      (type == "regular" && lib.hasSuffix "-test.nix" name)
      || type == "directory"
    ))
    # Process files and directories recursively
  ];
```

**Discovery Rules**:
1. Files must end with `-test.nix`
2. Directories are searched recursively
3. Excludes: `default.nix`, `nixtest-template.nix`, `lib/` directory
4. Import failures create failing test derivations (not silent skips)

## CI/CD Integration

Tests run automatically in GitHub Actions (`.github/workflows/ci.yml`):

**Triggers**:
- Push to main branch
- Pull requests
- Manual workflow dispatch

**Platforms**:
- macOS-15 (ARM64)
- Ubuntu (x86_64)
- Ubuntu (ARM64)

**Required Environment Variables**:
```bash
export USER=${USER:-ci}
export TEST_USER=${TEST_USER:-testuser}
```

**Caching**:
- Cachix integration for successful builds
- Week-based cache rotation for Nix installations

## Troubleshooting

### Test Import Failures

**Error**: `❌ TEST IMPORT FAILED: test-name`

**Cause**: Cross-platform compatibility issue or missing dependency

**Solution**:
1. Check if test uses platform-specific code
2. Add `platforms` attribute to filter test
3. Ensure all imports are available on target platform

### Container Tests on macOS

**Error**: Container tests fail on macOS

**Expected**: Container tests require Linux

**Solution**:
- Use `make test` for validation mode on macOS
- Run container tests in CI or Linux VM
- Use `nix build` for specific container tests

### Pre-commit Hook Failures

**Error**: Tests fail during pre-commit

**Solution**:
```bash
# Run all hooks to see failures
pre-commit run --all-files

# Format Nix files
make format

# Run tests
make test
```

### Performance Issues

**Slow Tests**: Unit tests taking > 5 seconds

**Solutions**:
1. Use `assertTest` instead of `runTestList` for simple cases
2. Avoid heavy derivations in unit tests
3. Move slow tests to integration or e2e
4. Use `--no-build` for validation mode

## References

### Key Files

- **tests/default.nix**: Test orchestration and auto-discovery
- **tests/lib/test-helpers.nix**: Main test helpers framework
- **tests/lib/assertions.nix**: Enhanced assertion utilities
- **tests/lib/platform-helpers.nix**: Platform-aware filtering
- **Makefile**: Test commands and CI integration

### Related Documentation

- **CLAUDE.md**: Project overview and development guidelines
- **CONTRIBUTING.md**: Detailed contribution workflow
- **lib/mksystem.nix**: System factory pattern
- **flake.nix**: Configuration entry point

### Test Examples

- **tests/unit/lib-user-info-test.nix**: Basic unit test
- **tests/integration/git-configuration-test.nix**: Integration test with bulk helpers
- **tests/unit/property-based-git-config-test.nix**: Property-based testing
- **tests/unit/darwin-only-test.nix**: Platform-specific test
- **tests/containers/basic-system.nix**: Container test
- **tests/lib/test-helpers-test.nix**: Test helpers validation
