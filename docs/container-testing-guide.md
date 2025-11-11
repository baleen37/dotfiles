# Container Testing Guide

## Overview

This guide explains how container testing works in this NixOS dotfiles project and how it handles user management across different environments.

## Problem Solved

### Issue: Dynamic User Resolution in CI

Previously, container tests used `builtins.getEnv "USER"` which caused issues in CI environments:

- **CI Environment**: `USER=ci` → Creates user named "ci" in containers
- **Local Environment**: `USER=john` → Creates user named "john" in containers
- **Root Environment**: `USER=root` → Falls back to "baleen"

This inconsistency made tests unreliable across different environments.

### Solution: Environment-Independent Testing

Container tests now use static test users while maintaining the dynamic user resolution for actual system configurations.

## Implementation Details

### Test User Strategy

1. **CI Environment**: Uses static `testuser` for all container tests
2. **Local Development**: Can optionally override with `TEST_USER` environment variable
3. **System Configuration**: Still uses dynamic user resolution for actual deployments

### Test Utilities

The `tests/lib/test-utils.nix` file provides helper functions:

```nix
{
  # Environment detection
  isCI = builtins.getEnv "GITHUB_ACTIONS" == "true";

  # Static test users
  testUsers = {
    main = "testuser";
    secondary = "testuser2";
    service = "testservice";
  };

  # Environment-aware user selection
  testUserName = if isCI then testUsers.main else (envUser or testUsers.main);
}
```

### Container Test Structure

All container tests follow this pattern:

```nix
# tests/containers/example-test.nix
{ pkgs, lib, inputs, self }:

let
  testUtils = import ../lib/test-utils.nix { inherit pkgs lib; };
  userName = testUtils.testUserName;
in {
  name = "example-test";

  nodes.machine = {
    # Static test user - no environment dependency
    users.users.${userName} = testUtils.mkTestUser { };

    # Test configuration...
  };

  testScript = ''
    # Test implementation using static userName
    machine.succeed(f"test -d /home/{userName}")
  '';
}
```

## Running Tests

### CI Environment (Automatic)

```bash
# CI automatically sets environment variables
export USER=ci
export TEST_USER=testuser
make test
```

### Local Development

```bash
# Use default test user
export USER=$(whoami)
make test

# Or override test user for debugging
export USER=$(whoami)
export TEST_USER=mydebuguser
make test

# Test with specific user configuration
export USER=jito
export TEST_USER=jito
make test
```

### CI Workflow

The GitHub Actions workflow (`.github/workflows/ci.yml`) ensures consistent testing:

1. **Fast Container Tests** (2-5 seconds): Basic container validation
2. **Full Test Suite**: Comprehensive testing including integration tests
3. **Cross-Platform**: Tests run on Darwin, Linux x64, and Linux ARM

## Benefits

### Environment Independence

- ✅ **Same results everywhere**: Tests produce identical results across CI and local
- ✅ **No user conflicts**: Container tests don't interfere with system users
- ✅ **Debugging friendly**: Can override test user for local debugging

### CI Reliability

- ✅ **Consistent state**: Each test run starts with the same user configuration
- ✅ **No race conditions**: Static users prevent dynamic user creation conflicts
- ✅ **Predictable paths**: Home directories are always at `/home/testuser`

### Maintained Flexibility

- ✅ **Dynamic system configs**: Actual system configurations still use dynamic user resolution
- ✅ **Multi-user support**: Real deployments continue to support multiple users (baleen, jito, etc.)
- ✅ **Local development**: Developers can test with their actual user configuration

## Best Practices

### Writing New Container Tests

1. **Always use test utilities**: Import and use `test-utils.nix`
2. **Static test users**: Never use `builtins.getEnv "USER"` in container tests
3. **Consistent naming**: Use provided `testUsers` constants when possible
4. **Environment-aware**: Tests should work identically in CI and locally

### Test Script Patterns

```python
# Use f-strings with static userName
machine.succeed(f"test -f /home/{userName}/.config")

# Include success indicators
print("✅ Configuration test passed")

# Test specific functionality, not just existence
machine.succeed(f"su - {userName} -c 'git --version'")
```

### CI Environment Variables

- `USER`: System user (for CI operations, `ci` in GitHub Actions)
- `TEST_USER`: Container test user (defaults to `testuser`)
- `GITHUB_ACTIONS`: CI detection flag (set to `true` in GitHub Actions)

## Migration Guide

### Before (Problematic)

```nix
let
  user = builtins.getEnv "USER";  # ❌ Environment-dependent
in {
  users.users.${user} = { ... };  # ❌ Creates different users
}
```

### After (Fixed)

```nix
let
  testUtils = import ../lib/test-utils.nix { inherit pkgs lib; };
  userName = testUtils.testUserName;  # ✅ Environment-independent
in {
  users.users.${userName} = testUtils.mkTestUser { };  # ✅ Consistent
}
```

## Troubleshooting

### Common Issues

1. **"user already exists" errors**: Ensure all container tests use static users
2. **Inconsistent test results**: Check for lingering `builtins.getEnv "USER"` usage
3. **Path not found errors**: Verify test scripts use the correct `userName` variable

### Debug Commands

```bash
# Check which users are being created
export USER=$(whoami)
export TEST_USER=debuguser
nix build '.#checks.x86_64-linux.basic' --show-trace

# Test locally with CI-like environment
export GITHUB_ACTIONS=true
export USER=ci
export TEST_USER=testuser
make test
```

### Log Analysis

Container test logs show user creation and configuration:

```
[INFO] Creating user: testuser
[INFO] Home directory: /home/testuser
✅ User configuration test passed
```

## Future Enhancements

### Potential Improvements

1. **Multiple test users**: Test user interactions and permissions
2. **Service users**: Test system service configurations
3. **User switching**: Test user context switching in containers
4. **Permission testing**: Verify sudo and group membership functionality

### Contributing

When adding new container tests:

1. Follow the established patterns in `tests/containers/`
2. Use the test utilities from `tests/lib/test-utils.nix`
3. Ensure tests pass both locally and in CI
4. Update this documentation if adding new testing patterns
