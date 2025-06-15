# API Reference

This document provides a comprehensive reference for all Nix functions and modules available in the dotfiles repository.

## Table of Contents

- [Core Libraries](#core-libraries)
  - [get-user.nix](#get-usernix)
  - [platform-apps.nix](#platform-appsnix)
  - [test-apps.nix](#test-appsnix)
  - [test-utils.nix](#test-utilsnix)
- [Module Libraries](#module-libraries)
  - [claude-config-policy.nix](#claude-config-policynix)
  - [conditional-file-copy.nix](#conditional-file-copynix)
  - [file-change-detector.nix](#file-change-detectornix)

## Core Libraries

### get-user.nix

**Purpose**: Dynamically retrieves the current user from environment variables.

**Location**: `/lib/get-user.nix`

**Usage**:
```nix
let
  getUser = import ./lib/get-user.nix { };
  user = getUser;
in
  # user will contain the value of $USER environment variable
```

**Notes**:
- Requires `--impure` flag when running Nix commands
- Falls back to "nixos" if USER environment variable is not set

### platform-apps.nix

**Purpose**: Provides platform-specific application builders for Darwin and Linux systems.

**Location**: `/lib/platform-apps.nix`

**Functions**:

#### `mkApp`
Creates a generic app wrapper for platform-specific scripts.

**Parameters**:
- `scriptName`: Name of the script to wrap
- `system`: Target system (e.g., "aarch64-darwin", "x86_64-linux")

**Returns**: Nix app attribute set

#### `mkSetupDevApp`
Creates the setup-dev app with fallback handling.

**Parameters**:
- `system`: Target system

**Returns**: Nix app attribute set for setup-dev

#### `mkLinuxCoreApps`
Builds the core set of apps for Linux systems.

**Parameters**:
- `system`: Linux system identifier

**Returns**: Attribute set of Linux apps including:
- apply, build, build-switch
- copy-keys, create-keys, check-keys
- install, setup-dev

#### `mkDarwinCoreApps`
Builds the core set of apps for Darwin systems.

**Parameters**:
- `system`: Darwin system identifier

**Returns**: Attribute set of Darwin apps including:
- apply, build, build-switch
- copy-keys, create-keys, check-keys
- rollback, setup-dev

### test-apps.nix

**Purpose**: Manages test application definitions and categories.

**Location**: `/lib/test-apps.nix`

**Exports**:

#### `testCategories`
Attribute set containing all test categories and their tests:
- `unit`: 17 unit tests
- `integration`: 11 integration tests
- `e2e`: 9 end-to-end tests
- `perf`: 2 performance tests

#### `mkLinuxTestApps`
Creates test apps for Linux systems.

**Parameters**:
- `system`: Linux system identifier

**Returns**: Base test apps (test, test-smoke, test-list)

#### `mkDarwinTestApps`
Creates test apps for Darwin systems.

**Parameters**:
- `system`: Darwin system identifier

**Returns**: All test apps including category-specific runners

### test-utils.nix

**Purpose**: Provides test utilities for discovery and reporting.

**Location**: `/lib/test-utils.nix`

**Functions**:

#### `mkTestReporter`
Creates a test report formatter.

**Parameters**:
- `name`: Report name
- `tests`: List of test names
- `results`: Test results string

**Returns**: Script that generates formatted test report

#### `mkTestDiscovery`
Creates a test discovery script.

**Parameters**:
- `flake`: Flake reference
- `system`: Target system

**Returns**: Script that discovers all available tests

#### `mkEnhancedTestRunner`
Creates an enhanced test runner with error handling.

**Parameters**:
- `name`: Runner name
- `tests`: List of tests to run

**Returns**: Script that runs tests with progress reporting

## Module Libraries

### claude-config-policy.nix

**Purpose**: Implements the Claude configuration preservation policy.

**Location**: `/modules/shared/lib/claude-config-policy.nix`

**Functions**:

#### `getExpectedHashes`
Returns expected SHA256 hashes for dotfiles versions of Claude config files.

**Returns**: Attribute set with file hashes

#### `getFilePriority`
Determines preservation priority for a given file.

**Parameters**:
- `file`: File name

**Returns**: Priority string ("high", "medium", "low")

#### `shouldPreserveFile`
Determines if a file should be preserved based on policy.

**Parameters**:
- `file`: File name
- `userHash`: SHA256 hash of user's file
- `expectedHash`: Expected hash from dotfiles

**Returns**: Boolean

### conditional-file-copy.nix

**Purpose**: Provides conditional file copying with preservation logic.

**Location**: `/modules/shared/lib/conditional-file-copy.nix`

**Functions**:

#### `mkConditionalCopy`
Creates a conditional file copy operation.

**Parameters**:
- `targetPath`: Destination path
- `sourceDir`: Source directory
- `files`: List of files to copy
- `forceOverwrite`: Boolean to force overwrite

**Returns**: Derivation that performs conditional copy

#### `mkClaudeConfigCopy`
Specialized copy function for Claude configuration.

**Parameters**:
- `sourceDir`: Claude config source directory
- `forceOverwrite`: Boolean to force overwrite

**Returns**: Home Manager configuration attribute set

### file-change-detector.nix

**Purpose**: Detects file changes using SHA256 hashing.

**Location**: `/modules/shared/lib/file-change-detector.nix`

**Functions**:

#### `fileHash`
Computes SHA256 hash of a file.

**Parameters**:
- `file`: File path

**Returns**: SHA256 hash string or empty if file doesn't exist

#### `hasFileChanged`
Checks if a file has been modified.

**Parameters**:
- `file`: File path
- `expectedHash`: Expected SHA256 hash

**Returns**: Boolean indicating if file changed

#### `detectChanges`
Detects changes across multiple files.

**Parameters**:
- `files`: Attribute set of file paths and expected hashes

**Returns**: Attribute set with change detection results

## Usage Examples

### Example 1: Using platform-apps in flake.nix
```nix
let
  platformApps = import ./lib/platform-apps.nix { inherit nixpkgs self; };
in
{
  apps = {
    aarch64-darwin = platformApps.mkDarwinCoreApps "aarch64-darwin";
    x86_64-linux = platformApps.mkLinuxCoreApps "x86_64-linux";
  };
}
```

### Example 2: Using test categories
```nix
let
  testApps = import ./lib/test-apps.nix { inherit nixpkgs self; };
  unitTests = testApps.testCategories.unit;
in
{
  # Use unitTests list for custom test runner
  customRunner = mkTestRunner { tests = unitTests; };
}
```

### Example 3: Conditional file copy with preservation
```nix
let
  copyLib = import ./lib/conditional-file-copy.nix { inherit pkgs lib; };
in
{
  home.file = copyLib.mkClaudeConfigCopy {
    sourceDir = ./config/claude;
    forceOverwrite = false;
  };
}
```

## Best Practices

1. **Always use `--impure` flag** when functions depend on environment variables
2. **Check file existence** before operations in conditional copy functions
3. **Use appropriate test categories** when adding new tests
4. **Follow the preservation policy** for user configuration files
5. **Document new functions** with clear parameter and return descriptions

## Contributing

When adding new library functions:

1. Place them in the appropriate directory (`/lib` for core, module-specific `lib/` for modules)
2. Follow the existing naming conventions
3. Add comprehensive documentation in this file
4. Include usage examples
5. Add tests for new functionality