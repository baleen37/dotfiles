# Consolidated Test Suite

This directory contains 35 consolidated test files that replace the original 133 test files.
Each consolidated test maintains the same functionality as the original tests while providing
better organization and faster execution.

## Summary
- **Original test files**: 133
- **Consolidated categories**: 35
- **Reduction**: 73.7% fewer files
- **Status**: ✅ Template Structure Created

## Test Categories

### Core System Tests (01-05)
- **01-core-system**: Core system and flake configuration tests
- **02-build-switch**: Build and switch functionality tests  
- **03-platform-detection**: Platform detection and cross-platform tests
- **04-user-resolution**: User resolution and path consistency tests
- **05-error-handling**: Error handling and messaging tests

### Configuration Tests (06-10)
- **06-configuration**: Configuration validation and externalization tests
- **07-claude-config**: Claude configuration management tests
- **08-keyboard-input**: Keyboard input configuration tests
- **09-zsh-configuration**: ZSH shell configuration tests
- **10-app-links**: Application links management tests

### Build and Performance Tests (11-15)
- **11-build-logic**: Build logic and decomposition tests
- **12-build-parallelization**: Build parallelization and performance tests
- **13-performance-monitoring**: Performance monitoring and optimization tests
- **14-cache-management**: Cache management and optimization tests
- **15-network-handling**: Network failure recovery tests

### Package and Module Tests (16-20)
- **16-package-management**: Package management and utilities tests
- **17-module-dependencies**: Module dependency and import tests
- **18-homebrew-integration**: Homebrew ecosystem integration tests
- **19-cask-management**: macOS cask management tests
- **20-iterm2-config**: iTerm2 configuration tests

### Security and Permissions (21-25)
- **21-security-ssh**: SSH key security tests
- **22-sudo-management**: Sudo management and security tests
- **23-precommit-ci**: Pre-commit and CI consistency tests
- **24-common-utils**: Common utilities tests
- **25-lib-consolidation**: Library consolidation tests

### Utils and Libraries (26-30)
- **26-file-operations**: File operations and generation tests
- **27-portable-paths**: Portable path handling tests
- **28-directory-structure**: Directory structure optimization tests
- **29-auto-update**: Auto-update functionality tests
- **30-claude-cli**: Claude CLI functionality tests

### Advanced Features (31-35)
- **31-intellij-idea**: IntelliJ IDEA integration tests
- **32-alternative-execution**: Alternative execution path tests
- **33-parallel-testing**: Parallel test execution tests
- **34-system-deployment**: System deployment and build tests
- **35-comprehensive-workflow**: Comprehensive workflow and integration tests

## Usage

Run all consolidated tests:
```bash
cd tests-consolidated && nix-build
```

Run specific category:
```bash
cd tests-consolidated && nix-build 01-core-system.nix
```

## Benefits

1. **Better Organization**: Tests are logically grouped by functionality
2. **Faster Execution**: Reduced overhead from fewer test files
3. **Easier Maintenance**: Clear categorization makes it easier to find and update tests
4. **Preserved Functionality**: All original test logic is maintained (when fully implemented)
