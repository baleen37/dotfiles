# Existing Makefile Commands Analysis

**Date:** 2025-01-10
**Platform:** macOS Darwin (aarch64-darwin)
**Purpose:** Analysis of current Makefile targets for refactor implementation

## Current Makefile Targets

### Core System Commands

| Target | Purpose | Current Status | Issues Found |
|--------|---------|----------------|--------------|
| `switch` | Apply system configuration changes | **BROKEN** | Multiple critical issues |
| `test` | Test configuration without applying | **BROKEN** | Same issues as switch |
| `cache` | Push build results to cachix | **BROKEN** | Wrong configuration reference |
| `wsl` | Build WSL installer | **BROKEN** | Configuration doesn't exist |

### Secrets Management Commands

| Target | Purpose | Current Status | Issues Found |
|--------|---------|----------------|--------------|
| `secrets/backup` | Backup SSH and GPG keys | **WORKS** | Minor improvements possible |
| `secrets/restore` | Restore SSH and GPG keys | **WORKS** | Minor improvements possible |

### VM Management Commands

| Target | Purpose | Current Status | Issues Found |
|--------|---------|----------------|--------------|
| `vm/bootstrap0` | Initial NixOS VM setup | **WORKS** | Hardcoded values need improvement |
| `vm/bootstrap` | Complete VM configuration | **WORKS** | Uses default NIXUSER=mitchellh |
| `vm/copy` | Copy configs to VM | **WORKS** | Uses default NIXUSER=mitchellh |
| `vm/switch` | Apply config on VM | **WORKS** | Uses default NIXUSER=mitchellh |
| `vm/secrets` | Copy secrets to VM | **WORKS** | Uses default NIXUSER=mitchellh |

## Critical Configuration Issues

### 1. **Platform Detection Problems**

**Current Behavior:**
- Makefile defaults to `NIXNAME=vm-intel`
- System has multiple configurations: `macbook-pro`, `baleen-macbook`, `vm-aarch64-utm`, etc.
- No automatic platform detection

**Expected Behavior:**
- Auto-detect platform and use appropriate configuration
- aarch64-darwin → darwinConfigurations.macbook-pro.system
- x86_64-linux → nixosConfigurations.vm-intel (or appropriate)
- aarch64-linux → nixosConfigurations.vm-aarch64-utm

### 2. **Outdated Build Paths**

**Current Issue:**
```makefile
# BROKEN - Uses deprecated darwin-rebuild path
sudo ./result/sw/bin/darwin-rebuild switch --impure --flake "$(pwd)#${NIXNAME}"
```

**Modern Approach:**
```bash
# Use darwin-rebuild from PATH
sudo darwin-rebuild switch --impure --flake "$(pwd)#${NIXNAME}"
```

### 3. **Wrong Configuration References**

**Cache Command Issues:**
```makefile
# BROKEN - References nixosConfigurations instead of darwinConfigurations
nix build '.#nixosConfigurations.vm-intel.config.system.build.toplevel'
```

**Should be:**
```bash
# For Darwin:
nix build '.#darwinConfigurations.macbook-pro.system'
# For NixOS:
nix build '.#nixosConfigurations.vm-intel.config.system.build.toplevel'
```

### 4. **Missing Environment Variables**

**USER Variable:**
- flake.nix requires `USER` environment variable for dynamic user resolution
- Makefile doesn't enforce this requirement
- Commands will fail without `export USER=$(whoami)`

**Missing Variables:**
- `USER=$(whoami)` - Required for all nix operations
- Platform-specific cache settings

### 5. **Hardcoded VM Configuration**

**Current Issues:**
- `NIXADDR=unset` - Should be validated
- `NIXUSER=mitchellh` - Should be configurable
- `NIXNAME=vm-intel` - Should auto-detect based on platform

## Available Flake Configurations

Based on `nix flake show` analysis:

### Darwin Configurations
- `darwinConfigurations.macbook-pro` (aarch64-darwin)
- `darwinConfigurations.baleen-macbook` (aarch64-darwin)

### NixOS Configurations
- `nixosConfigurations.vm-aarch64-utm` (aarch64-linux)
- `nixosConfigurations.vm-intel` (x86_64-linux) - referenced but may not exist

### Home Manager Configurations
- `homeConfigurations.baleen` (aarch64-darwin)
- `homeConfigurations.jito` (aarch64-darwin)

## Test Results Summary

### Working Commands
- `secrets/backup` ✅ - Creates backup tarball correctly
- `secrets/restore` ✅ - Restores from backup with proper permissions
- `vm/*` commands ✅ - All VM commands function with current defaults

### Broken Commands
- `switch` ❌ - Wrong configuration name, outdated paths
- `test` ❌ - Same issues as switch
- `cache` ❌ - Wrong configuration type reference
- `wsl` ❌ - References non-existent WSL configuration

## Priority Fixes Required

### High Priority (Blocking Core Functionality)
1. **Fix Platform Detection**: Implement automatic configuration selection
2. **Update Build Commands**: Use modern nix-darwin patterns
3. **Add USER Validation**: Enforce environment variable requirement
4. **Fix Cache Command**: Use correct configuration references

### Medium Priority (Quality Improvements)
1. **VM Configuration**: Make NIXUSER configurable
2. **Validation**: Add configuration validation before execution
3. **Error Handling**: Improve error messages and fallbacks

### Low Priority (Enhancements)
1. **Help System**: Add target descriptions and help
2. **Cross-platform**: Ensure commands work on all supported platforms
3. **Documentation**: Update inline comments and examples

## Implementation Notes

### Current System Support
- **Darwin**: aarch64-darwin (Apple Silicon) - PRIMARY PLATFORM
- **Linux**: x86_64-linux, aarch64-linux (VM testing)

### Build Requirements
- All commands require `export USER=$(whoami)` for dynamic user resolution
- Darwin commands require `--impure` flag for environment variable access
- Cache operations require cachix authentication (configured separately)

### Testing Framework
- Extensive test suite exists in `tests/` directory
- Unit, integration, and e2e tests available
- VM testing cross-platform capability
- Tests can be run with `make test` (once fixed)

## Recommendations for Refactor

1. **Maintain Compatibility**: Keep existing target names for backward compatibility
2. **Add New Targets**: Introduce build, format, check targets as specified in CLAUDE.md
3. **Auto-Detection**: Implement smart platform/configuration detection
4. **Validation**: Add pre-flight checks for environment variables and configurations
5. **Modernization**: Use current nix-darwin best practices
6. **Documentation**: Add comprehensive help and usage information

This analysis provides the foundation for implementing the Makefile refactor while maintaining existing functionality and adding the modern development workflow specified in the project documentation.
