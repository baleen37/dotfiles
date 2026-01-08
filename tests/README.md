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

### Test Helpers Overview

The testing framework provides multiple helper libraries organized by purpose:

- **test-helpers.nix**: Core assertion helpers, property testing, configuration validation
- **git-test-helpers.nix**: Git-specific testing helpers (aliases, settings, LFS, safety)
- **darwin-test-helpers.nix**: macOS/Darwin optimization levels and system settings
- **constants.nix**: Centralized test constants (67 constants for performance, validation, tools)
- **conventions.nix**: Testing standards and patterns (see [Test Conventions](#test-conventions))
- **assertions.nix**: Enhanced assertion utilities with detailed error messages
- **platform-helpers.nix**: Platform-aware test filtering for cross-platform support

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

**`assertConfigIntegrity`**
```nix
assertConfigIntegrity "test-name" configPath expectedFiles
```
Validates configuration file integrity - checks that all expected files exist and have content.

**Example**:
```nix
helpers.assertConfigIntegrity "vim-config" vimConfig [
  ".vimrc"
  ".vim/plugins.vim"
]
```

---

**`assertAttrsEqual`**
```nix
assertAttrsEqual "test-name" expected actual "message"
```
Deep equality comparison for attribute sets with detailed mismatch reporting.

**Example**:
```nix
helpers.assertAttrsEqual "git-settings" expectedSettings actualSettings "Git settings should match"
```

---

**`assertContainsGeneric`**
```nix
assertContainsGeneric "test-name" needle haystack "message"
```
Generic membership test for lists, attribute sets, or strings.

**Example**:
```nix
# Check if item is in a list
helpers.assertContainsGeneric "has-package" "vim" packages "vim should be in packages"

# Check if key exists in attribute set
helpers.assertContainsGeneric "has-attr" "programs" config "config should have programs"

# Check if substring exists in string
helpers.assertContainsGeneric "has-substring" "@", email "email should contain @"
```

---

### Plugin and Configuration Helpers

**`assertPluginPresent`**
```nix
assertPluginPresent "test-name" plugins expectedPlugins options
```
Test plugin/package presence in a list or attribute set with exact or regex matching.

**Parameters**:
- `name`: Test name for reporting
- `plugins`: List of plugins or attribute set of plugin configurations
- `expectedPlugins`: List of plugin names (exact strings) or regex patterns
- `options`: Optional attributes (default: `{ matchType = "exact"; allowExtra = true; }`)

**Example**:
```nix
# Exact match
helpers.assertPluginPresent "vim-plugins" vimPlugins [
  "vim-airline"
  "nerdtree"
]

# Regex match
helpers.assertPluginPresent "npm-packages" npmPackages [
  "eslint-.*"
  "prettier-.*"
] { matchType = "regex"; }
```

---

**`assertConfigPattern`**
```nix
assertConfigPattern "test-name" configFiles expectedPatterns
```
Test configuration file pattern matching using regex or substring search.

**Parameters**:
- `name`: Test name for reporting
- `configFiles`: Attribute set mapping file paths to their content (strings)
- `expectedPatterns`: Attribute set with substring strings, regex patterns, or lists

**Example**:
```nix
# Substring match
helpers.assertConfigPattern "vimrc" {
  ".vimrc" = vimrcContent;
} {
  ".vimrc" = "set number";
}

# Regex match
helpers.assertConfigPattern "gitconfig" {
  ".gitconfig" = gitContent;
} {
  ".gitconfig" = {
    regex = "\\[user\\]\\s*\\n.*name = Jiho";
  };
}

# Multiple patterns
helpers.assertConfigPattern "zshrc" {
  ".zshrc" = zshContent;
} {
  ".zshrc" = {
    patterns = [
      "export PATH"
      { regex = "fzf.*setup" }
    ];
  };
}
```

---

**`assertHomeFileConfigured`**
```nix
assertHomeFileConfigured "test-name" homeConfig expectedFiles
```
Test Home Manager file configuration in `home.file` or `home.xdg.configFile`.

**Parameters**:
- `name`: Test name for reporting
- `homeConfig`: The Home Manager configuration attribute set
- `expectedFiles`: Attribute set with file paths and optional settings (force, recursive, executable, text)

**Example**:
```nix
# Basic file presence check
helpers.assertHomeFileConfigured "vim-config" homeConfig {
  ".vimrc".path = ".vimrc";
  ".config/nvim/init.vim" = null;
}

# Check file options
helpers.assertHomeFileConfigured "scripts" homeConfig {
  "bin/myscript.sh" = {
    executable = true;
    force = true;
  };
  "bin/readonly.sh" = {
    executable = false;
  };
}

# Check file content
helpers.assertHomeFileConfigured "config-content" homeConfig {
  ".config/app/config.conf" = {
    text = "setting=value";
  };
}
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

### Git Helpers Library (tests/lib/git-test-helpers.nix)

The Git Helpers library provides specialized functions for comprehensive Git configuration testing. Import with:

```nix
gitHelpers = import ../lib/git-test-helpers.nix {
  inherit pkgs lib;
  testHelpers = helpers;
};
```

#### Git User Information

**`assertGitUserInfo`**
```nix
assertGitUserInfo "test-name" gitSettings userInfo
```
Validate Git user information against `lib/user-info.nix` (single source of truth).

**Example**:
```nix
gitHelpers.assertGitUserInfo "git-user-info" gitSettings userInfo
```

---

**`assertGitUserInfoValues`**
```nix
assertGitUserInfoValues "test-name" gitSettings expectedName expectedEmail
```
Validate Git user info with specific expected values.

**Example**:
```nix
gitHelpers.assertGitUserInfoValues "git-user" gitSettings "Jiho Lee" "baleen37@gmail.com"
```

#### Git LFS Configuration

**`assertGitLFS`**
```nix
assertGitLFS "test-name" gitConfig expectedEnabled
```
Validate Git LFS configuration state.

**Example**:
```nix
gitHelpers.assertGitLFS "git-lfs" gitConfig true
```

#### Bulk Git Assertions

**`assertGitAliasesBulk`**
```nix
assertGitAliasesBulk "test-name" aliasSettings expectedAliases
```
Bulk assertion helper for Git aliases with individual test reporting.

**Example**:
```nix
gitHelpers.assertGitAliasesBulk "git-aliases" gitSettings.alias {
  st = "status";
  co = "checkout";
  br = "branch";
  ci = "commit";
}
```

---

**`assertGitSettingsBulk`**
```nix
assertGitSettingsBulk "test-name" gitSettings expectedSettings
```
Bulk assertion helper for Git settings (supports nested keys).

**Example**:
```nix
gitHelpers.assertGitSettingsBulk "git-core" gitSettings.core {
  editor = "vim";
  autocrlf = "input";
  excludesFile = "~/.gitignore_global";
}
```

---

**`assertGitIgnorePatternsBulk`**
```nix
assertGitIgnorePatternsBulk "test-name" actualPatterns expectedPatterns
```
Bulk assertion helper for Git ignore patterns.

**Example**:
```nix
gitHelpers.assertGitIgnorePatternsBulk "gitignore" gitIgnores [
  "*.swp"
  "*.swo"
  ".DS_Store"
  "node_modules/"
]
```

#### Comprehensive Git Configuration

**`assertGitConfigComplete`**
```nix
assertGitConfigComplete "test-name" gitConfig userInfo expectedAliases expectedIgnores options
```
Complete Git configuration validation with all aspects:
- Git enabled
- User info matches `lib/user-info.nix`
- Git LFS enabled
- Core settings (editor, autocrlf, excludesFile)
- Init settings (defaultBranch)
- Pull settings (rebase)
- Rebase settings (autoStash)
- Git aliases
- Git ignore patterns

**Parameters**:
- `name`: Test suite name
- `gitConfig`: Full git configuration attribute set
- `userInfo`: User info from `lib/user-info.nix`
- `expectedAliases`: Attribute set of expected Git aliases
- `expectedIgnores`: List of expected gitignore patterns
- `options`: Optional configuration (default: all checks enabled)

**Example**:
```nix
gitHelpers.assertGitConfigComplete "git-config" gitConfig userInfo {
  st = "status";
  co = "checkout";
  br = "branch";
  ci = "commit";
  unstage = "reset HEAD --";
  last = "log -1 HEAD";
} [
  "*.swp"
  "*.swo"
  ".DS_Store"
  "node_modules/"
  ".env.local"
] {
  checkUserInfo = true;
  checkLFS = true;
  checkAliases = true;
  checkIgnores = true;
}
```

#### Git Safety Validation

**`assertGitAliasSafety`**
```nix
assertGitAliasSafety "test-name" aliasSettings options
```
Validate Git alias safety - checks for dangerous commands and essential aliases.

**Default dangerous patterns**: `rm -rf`, `sudo `, `chmod 777`, `chown `, `format`, `fdisk`

**Default required aliases**: `st`, `ci`

**Example**:
```nix
gitHelpers.assertGitAliasSafety "git-alias-safety" gitSettings.alias {
  requiredAliases = [ "st" "ci" "co" ];
  dangerousPatterns = [ "rm -rf" "sudo " "format " ];
}
```

---

**`assertGitIgnoreSafety`**
```nix
assertGitIgnoreSafety "test-name" ignorePatterns
```
Validate Git ignore pattern safety - checks for path traversal attacks.

**Example**:
```nix
gitHelpers.assertGitIgnoreSafety "gitignore-safety" gitIgnores
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

**Example**:
```nix
helpers.assertTrackpadSetting "clicking" "Clicking" true darwinConfig
```

---

### Darwin Helpers Library (tests/lib/darwin-test-helpers.nix)

The Darwin Helpers library provides comprehensive macOS system settings testing with semantic optimization levels. Import with:

```nix
darwinHelpers = import ../lib/darwin-test-helpers.nix {
  inherit pkgs lib;
  helpers = helpers;
  constants = testConstants;
};
```

#### Darwin Optimization Levels

The library provides three optimization levels for progressive macOS performance tuning:

**Level 1: Core System Optimizations**
- Disables UI animations (40-60% faster UI responsiveness)
- Optimizes input processing
- Settings: window animations, resize time, scroll animations, auto-capitalization, spell correction, smart quotes/dashes, press-and-hold

**`assertDarwinOptimizationsLevel1`**
```nix
assertDarwinOptimizationsLevel1 darwinConfig
```

**Example**:
```nix
darwinHelpers.assertDarwinOptimizationsLevel1 darwinConfig
```

---

**Level 2: Memory Management and Battery Efficiency**
- Enables app termination for 20-30% battery life extension
- Disables iCloud auto-save

**`assertDarwinOptimizationsLevel2`**
```nix
assertDarwinOptimizationsLevel2 darwinConfig
```

---

**Level 3: Advanced UI Reduction Optimizations**
- Disables navigation gestures
- Optimizes font smoothing
- Compacts save dialogs

**`assertDarwinOptimizationsLevel3`**
```nix
assertDarwinOptimizationsLevel3 darwinConfig
```

---

**All Optimization Levels Combined**

**`assertDarwinOptimizationsAll`**
```nix
assertDarwinOptimizationsAll darwinConfig
```
Run all three optimization level tests.

---

#### Comprehensive macOS Optimization Test Suite

**`assertDarwinFullOptimizationSuite`**
```nix
assertDarwinFullOptimizationSuite darwinConfig
```
Complete macOS optimization test suite including:
- All optimization levels (1, 2, 3)
- Login window optimizations
- Dock optimizations
- Finder optimizations
- Trackpad optimizations

**Example**:
```nix
darwinHelpers.assertDarwinFullOptimizationSuite darwinConfig
```

#### Individual macOS Component Tests

**Login Window Optimizations**
```nix
assertLoginWindowOptimizations darwinConfig
```
Tests login window settings for faster boot and streamlined login.

---

**Dock Optimizations**
```nix
assertDockOptimizations darwinConfig
```
Tests standard dock optimizations: autohide, instant delay, fast animation, optimized tile size.

---

**Finder Optimizations**
```nix
assertFinderOptimizations darwinConfig
```
Tests finder optimizations: show hidden files, disable extension warning, folders first, path bar, status bar.

---

**Trackpad Optimizations**
```nix
assertTrackpadOptimizations darwinConfig
```
Tests trackpad optimizations: tap-to-click, right-click, three-finger drag.

#### Darwin Configuration Tests

**`assertDarwinFullConfigSuite`**
```nix
assertDarwinFullConfigSuite expectedUser darwinConfig
```
Complete Darwin configuration test suite including:
- All optimizations
- Spaces settings (no span displays)
- Homebrew configuration (enabled, casks, brews, global settings)
- System configuration (primary user, documentation disabled)
- App cleanup script

**Example**:
```nix
darwinHelpers.assertDarwinFullConfigSuite "baleen" darwinConfig
```

#### Individual Setting Tests

**Space Settings**
```nix
assertSpacesNoSpanDisplays darwinConfig
```

**Homebrew Configuration**
```nix
assertHomebrewEnabled darwinConfig
assertHomebrewCasksConfigured darwinConfig
assertHomebrewBrewsConfigured darwinConfig
assertHomebrewGlobalSettings darwinConfig
```

**System Configuration**
```nix
assertSystemPrimaryUser "expectedUser" darwinConfig
assertDocumentationDisabled darwinConfig
assertCleanupScriptConfigured darwinConfig
```

#### Bulk Setting Helpers

**NSGlobalDomain Settings**
```nix
assertNSGlobalDefs [ ["key1" val1] ["key2" val2] ] darwinConfig
```
Test multiple NSGlobalDomain settings at once.

---

**Dock Settings**
```nix
assertDockSettings [ ["name1" "key1" val1] ["name2" "key2" val2] ] darwinConfig
```
Test multiple dock settings at once.

---

**Finder Settings**
```nix
assertFinderSettings [ ["name1" "key1" val1] ["name2" "key2" val2] ] darwinConfig
```
Test multiple finder settings at once.

---

**Trackpad Settings**
```nix
assertTrackpadSettings [ ["name1" "key1" val1] ["name2" "key2" val2] ] darwinConfig
```
Test multiple trackpad settings at once.

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

**`multiParamPropertyTest`**
```nix
multiParamPropertyTest "test-name" propertyFunction testValueSets
```
Test multi-parameter properties across all combinations of test values.

**Example**:
```nix
helpers.multiParamPropertyTest "string-concat"
  (a: b: a + b == b + a)
  [
    ["hello" "world"]
    ["foo" "bar"]
    ["a" "b" "c"]
  ]
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

**`generateUserTests`**
```nix
generateUserTests testFunction users
```
Generate multiple test configurations for different users.

**Example**:
```nix
helpers.generateUserTests
  (user: helpers.assertTest "user-${user}" true "User test")
  ["alice" "bob" "charlie"]
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

## Test Constants (tests/lib/constants.nix)

Centralized test constants eliminate magic numbers and provide documented rationale for test values. Import with:

```nix
testConstants = import ../lib/constants.nix { inherit pkgs lib; };
```

### Darwin Performance Constants

**Window and Dock Animation Timing**
```nix
darwinWindowResizeTime = 0.1;           # 100ms - fastest perceivable resize
darwinDockAutohideDelay = 0.0;          # 0.0 - instant dock appearance
darwinDockAutohideTimeModifier = 0.15;  # 150ms - fast/smooth animation
darwinExposeAnimationDuration = 0.2;    # 200ms - quick Mission Control
darwinDockTileSize = 48;                # 48px - balance visibility/space
darwinFontSmoothing = 1;                # 1 = reduced for sharpness
```

**Keyboard and Trackpad Speed**
```nix
darwinKeyRepeat = 1;                   # 1 (~16ms) - fastest repeat
darwinInitialKeyRepeat = 10;           # 10 (~167ms) - fast initial delay
darwinTrackpadScaling = 3.0;           # 3.0 - maximum cursor speed
darwinScrollwheelScaling = 1.0;        # 1.0 - maximum scroll speed
```

**Hotkey Modifiers**
```nix
darwinHotkeySpaceKeyCode = 49;         # kVK_Space from HIToolbox
darwinHotkeyCmdModifier = 1048576;     # cmdKey (256 * 4096)
darwinHotkeyShiftModifier = 131072;    # shiftKey (256 * 512)
darwinHotkeyCtrlModifier = 262144;     # controlKey (256 * 1024)
```

### Tool-Specific Constants

**Starship Prompt**
```nix
starshipCommandTimeout = 1000;         # 1s - balance responsiveness
starshipScanTimeout = 30;              # 30s - prevent hangs on large dirs
starshipCmdDurationMinTime = 3000;     # 3s - only show slow commands
starshipDirectoryTruncationLength = 3; # 3 segments - compact but informative
```

**Tmux**
```nix
tmuxHistoryLimit = 50000;              # 50K lines - searchable history
tmuxDisplayTime = 2000;                # 2s - message duration
tmuxRepeatTime = 500;                  # 500ms - repeat command timeout
```

**Vim**
```nix
vimHistory = 1000;                     # 1000 entries - command history
```

**Zsh/Fzf**
```nix
fzfPreviewLineRange = 500;             # 500 lines - preview context
fzfTreeHeadLimit = 200;                # 200 lines - tree structure
zshHistorySize = 10000;                # 10K entries - shell history
```

### Performance Test Constants

**Timeout Thresholds**
```nix
perfFastTimeout = 100;                 # 100ms - instant operations
perfMediumTimeout = 500;               # 500ms - quick operations
perfSlowTimeout = 1000;                # 1000ms - data processing
perfVerySlowTimeout = 5000;            # 5000ms - heavy computations
```

**Memory Allocations**
```nix
perfSmallMemory = 1 * 1024 * 1024;     # 1 MB - minimal allocation
perfMediumMemory = 10 * 1024 * 1024;   # 10 MB - typical operations
perfLargeMemory = 50 * 1024 * 1024;    # 50 MB - stress testing
```

**Regression Thresholds**
```nix
perfRegressionThresholdSmall = 0.3;    # 30% - small configs
perfRegressionThresholdMedium = 0.6;   # 60% - medium configs
perfRegressionThresholdLarge = 0.9;    # 90% - large configs
```

**Test Data Sizes**
```nix
perfTestSmallSize = 1000;              # 1K items
perfTestMediumSize = 5000;             # 5K items
perfTestLargeSize = 10000;             # 10K items
```

### String Length Validation

**Git Limits**
```nix
gitMaxCommandLength = 200;             # 200 chars - max alias length
gitMaxPatternLength = 200;             # 200 chars - max gitignore pattern
gitMaxNameLength = 100;                # 100 chars - practical name limit
gitMaxEmailLength = 254;               # 254 chars - RFC 5321 max
gitMaxEntryCount = 100;                # 100 entries - collection limit
```

**User Property Limits**
```nix
minFullNameLength = 2;                 # 2 chars - minimum name (e.g., "Al")
maxFullNameLength = 100;               # 100 chars - display limit
minEmailLength = 5;                    # 5 chars - min valid email
maxEmailLength = 254;                  # 254 chars - RFC 5321 max
```

### VM and System Test Constants

```nix
vmMemorySize = 2048;                   # 2 GB - minimum for development
vmDiskSize = 4096;                     # 4 GB - sufficient for testing
shellHistoryLimit = 5000;              # 5K entries - test sessions
```

### Content Validation

```nix
minContentLength = 100;                # 100 chars - meaningful content
tmuxMinConfigLength = 500;             # 500 chars - substantial config
tmuxMaxConfigReadLength = 1000;        # 1K chars - validation limit
```

### Mac App Store Constants

```nix
masAppMagnet = 441258766;              # Magnet app ID
masAppWireGuard = 1451685025;          # WireGuard app ID
masAppKakaoTalk = 869223134;           # KakaoTalk app ID
```

### Trend Analysis Constants

```nix
trendBaseDuration = 1000;              # 1000ms - baseline duration
trendBaseMemory = 50000000;            # 50 MB - baseline memory
trendDurationIncrement = 50;           # 50ms - duration increment
trendMemoryIncrement = 1000000;        # 1 MB - memory increment
trendSlowBaselineDuration = 2500;      # 2500ms - slow baseline
trendSlowBaselineMemory = 80000000;    # 80 MB - memory-intensive baseline
trendImprovedBaselineDuration = 950;   # 950ms - optimized baseline
```

### Other Constants

```nix
gpgDefaultCacheTtl = 1800;             # 1800s (30 min) - GPG cache
expectedMemorySize = 8192;             # 8192 - memory test value
expectedTestResult = 285;              # 285 - sum of squares 0-9
expectedTestCount = 10;                # 10 - iteration count
```

## Test Conventions (tests/lib/conventions.nix)

The conventions library defines standard patterns for writing consistent, maintainable tests. Import with:

```nix
conventions = import ../lib/conventions.nix { inherit pkgs lib; };
```

### Standard Test Structure

All test files must use one of these two standard structures:

**Pattern 1: Platform-filtered test (recommended)**
```nix
{
  platforms = ["any"];  # or ["darwin"] or ["linux"] or ["darwin" "linux"]
  value = helpers.testSuite "test-name" [
    (helpers.assertTest "test-1" condition "message")
    (helpers.assertTest "test-2" condition "message")
  ];
}
```

**Pattern 2: Direct test suite (platform-agnostic)**
```nix
helpers.testSuite "test-name" [
  (helpers.assertTest "test-1" condition "message")
  (helpers.assertTest "test-2" condition "message")
]
```

### Standard Helper Import Pattern

Always use the variable name "helpers":
```nix
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
# test structure here
```

### Standard Test File Header

All test files must start with:
```nix
# Single-line description of what is being tested
#
# Optional: More detailed description
{ inputs, system, pkgs, lib, self, nixtest ? {}, ... }:
```

### Naming Conventions

**Test file names**: `tests/unit/<feature>-test.nix` or `tests/integration/<feature>-test.nix`

**Test suite names**: Lowercase with hyphens (`"git-configuration"`, `"vim-settings"`)

**Individual test names**: Lowercase with hyphens, format: `<feature>-<aspect>-<expectation>`

**Helper function names**: camelCase (`hasPluginByName`, `mkConfigTest`), test creators start with "mk"

### Standard Assertion Patterns

```nix
# Basic assertion
(helpers.assertTest "test-name" condition "failure message")

# Assertion with details
(helpers.assertTestWithDetails "test-name" expected actual "message")

# File existence
(helpers.assertFileExists "test-name" derivation "path/to/file")

# Attribute existence
(helpers.assertHasAttr "test-name" "attrName" attributeSet)

# String contains
(helpers.assertContains "test-name" "needle" "haystack")

# Multiple related settings (bulk assertion)
(helpers.assertSettings "group-name" settings {
  key1 = expectedValue1;
  key2 = expectedValue2;
})
```

### Anti-Patterns to Avoid

```nix
# DON'T: Use direct pkgs.runCommand for tests
pkgs.runCommand "test-name" { } "echo 'pass'; touch $out"

# INSTEAD: Use helpers.testSuite
helpers.testSuite "test-name" [
  (helpers.assertTest "test-1" true "should pass")
]
```

```nix
# DON'T: Use variable names other than "helpers"
let h = import ../lib/test-helpers.nix { inherit pkgs lib; };

# INSTEAD: Always use "helpers"
let helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
```

```nix
# DON'T: Mix test styles in the same file
{ platforms = ["any"]; value = ... }
helpers.testSuite "other" [...]

# INSTEAD: Be consistent
{ platforms = ["any"]; value = helpers.testSuite "feature" [...]; }
```

### Example: Standard Test File

```nix
# Feature Configuration Test
#
# Tests the feature configuration in users/shared/feature.nix
# Verifies that settings are properly configured.
{ inputs, system, pkgs, lib, self, nixtest ? {}, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  featureConfig = import ../../users/shared/feature.nix {
    inherit pkgs lib;
    config = { };
  };

in
{
  platforms = ["any"];
  value = helpers.testSuite "feature" [
    (helpers.assertTest "feature-enabled" (
      featureConfig.programs.feature.enable == true
    ) "Feature should be enabled")

    (helpers.assertTest "feature-has-settings" (
      featureConfig.programs.feature ? settings
    ) "Feature should have settings configured")
  ];
}
```

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
- **tests/lib/test-helpers.nix**: Main test helpers framework (core assertions, property testing, configuration validation)
- **tests/lib/git-test-helpers.nix**: Git-specific testing helpers (aliases, settings, LFS, safety)
- **tests/lib/darwin-test-helpers.nix**: macOS/Darwin optimization levels and system settings
- **tests/lib/constants.nix**: Centralized test constants (67 constants for performance, validation, tools)
- **tests/lib/conventions.nix**: Testing standards and patterns
- **tests/lib/assertions.nix**: Enhanced assertion utilities with detailed error messages
- **tests/lib/platform-helpers.nix**: Platform-aware test filtering for cross-platform support
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
- **tests/integration/git-helpers-test.nix**: Git helpers library examples
- **tests/integration/darwin-optimizations-test.nix**: Darwin optimization level examples
