# Disabled Tests

This directory contains tests that are temporarily disabled for various reasons:

## Reasons for Disabling Tests

1. **Performance Issues**: Tests that are too slow for regular test runs
2. **Platform Incompatibility**: Tests that don't work on certain platforms
3. **Dependency Issues**: Tests with missing or incompatible dependencies
4. **Maintenance**: Tests that need refactoring or updating
5. **Flaky Tests**: Tests with intermittent failures

## Adding Disabled Tests

To temporarily disable a test:

1. Move the test file to this directory
2. Add a comment at the top explaining why it's disabled
3. Include the date it was disabled
4. Optionally add an issue number tracking the re-enabling

## Example Disabled Test Header

```nix
# DISABLED: Performance issue - too slow for regular runs
# Date: 2025-01-09
# Issue: #123
# Reason: This test takes 5+ minutes to run and should be optimized
#         before re-enabling. Move back to unit/ or integration/ when fixed.
```

## Re-enabling Tests

When a disabled test is fixed:

1. Move it back to the appropriate directory (unit/, integration/, etc.)
2. Remove the DISABLED header
3. Update the test discovery if needed
4. Run the test suite to ensure it passes

## Current Disabled Tests

Currently there are no disabled tests in this directory.

Tests are automatically excluded from discovery by the test framework
(see tests/default.nix - the disabled/ directory is explicitly excluded).
