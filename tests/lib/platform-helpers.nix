# tests/lib/platform-helpers.nix
# Platform-aware test utilities for conditional test inclusion
#
# STANDARD PATTERN FOR PLATFORM-SPECIFIC TESTS:
#
# All platform-specific tests should use the `platforms` attribute pattern:
#
#   {
#     platforms = ["darwin"];  # or ["linux"] or ["darwin" "linux"]
#     value = yourTestDerivation;
#   }
#
# This is the PREFERRED approach because:
# 1. Declarative - platform requirements are explicit in the test metadata
# 2. Composable - supports multiple platforms: ["darwin" "linux"]
# 3. Test Discovery Integration - works with automatic test filtering in tests/default.nix
# 4. Consistent - matches the pattern used in darwin-test.nix and darwin-only-test.nix
#
# DEPRECATED: Do NOT use helpers.runIfPlatform() in new tests.
# The runIfPlatform function is kept for backward compatibility but should not be used.
#
# Example test file:
#   # tests/unit/my-darwin-test.nix
#   { inputs, system, pkgs, lib, self, ... }:
#   let
#     helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
#   in
#   {
#     platforms = ["darwin"];
#     value = helpers.testSuite "my-darwin-test" [
#       (helpers.assertTest "test-name" true "Test description")
#     ];
#   }
#
# Tests without a `platforms` attribute run on all platforms.

{ pkgs, lib }:

let
  # Check if current platform matches a given platform
  # Helper for conditional test execution
  isCurrentPlatform = platform:
    if platform == "any" then true
    else if platform == "darwin" then pkgs.stdenv.hostPlatform.isDarwin
    else if platform == "linux" then pkgs.stdenv.hostPlatform.isLinux
    else if platform == "unknown" then (!pkgs.stdenv.hostPlatform.isDarwin && !pkgs.stdenv.hostPlatform.isLinux)
    else false;

  # Get current platform identifier
  # Returns standardized platform string for current system
  getCurrentPlatform =
    if pkgs.stdenv.hostPlatform.isDarwin then "darwin"
    else if pkgs.stdenv.hostPlatform.isLinux then "linux"
    else "unknown";

in
{
  # Platform-aware test inclusion
  # Creates a conditional test that only runs on the specified platform
  # Parameters: platform (string), test (derivation)
  mkPlatformTest = platform: test:
    if isCurrentPlatform platform then
      test
    else
      # Create a placeholder test that reports platform skip
      pkgs.runCommand "test-skipped-${platform}" { } ''
        echo "⏭️  Skipped (${platform}-only test on different platform)"
        echo "Current platform: ${getCurrentPlatform}"
        touch $out
      '';

  # Platform-specific test filtering
  # Filters tests based on platform requirements in test attributes
  # Tests can have a `platforms` attribute with list of supported platforms
  filterPlatformTests = tests:
    lib.filterAttrs (name: test:
      if builtins.hasAttr "platforms" test then
        builtins.any isCurrentPlatform test.platforms
      else
        # If no platforms attribute, include test for all platforms
        true
    ) tests;

  # Export helper functions
  inherit isCurrentPlatform getCurrentPlatform;

  # Create a platform-aware test suite
  # Automatically filters tests based on platform requirements
  mkPlatformTestSuite = name: tests:
    let
      filterPlatformTests = tests:
        lib.filterAttrs (name: test:
          if builtins.hasAttr "platforms" test then
            builtins.any isCurrentPlatform test.platforms
          else
            # If no platforms attribute, include test for all platforms
            true
        ) tests;
      filteredTests = filterPlatformTests tests;
      testList = lib.attrValues filteredTests;
    in
    if builtins.length testList > 0 then
      pkgs.runCommand "test-suite-${name}" { } ''
        echo "🧪 Running platform-aware test suite: ${name}"
        echo "🌍 Platform: ${getCurrentPlatform}"
        echo "📊 Tests: ${toString (builtins.length testList)} (filtered from ${toString (builtins.length (lib.attrValues tests))})"
        echo ""

        # Run each test
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "🔍 Running test: ${test.name or "unnamed"}"
          if cat ${test}; then
            echo "  ✅ PASS"
          else
            echo "  ❌ FAIL"
            exit 1
          fi
          echo ""
        '') testList}

        echo "✅ Test suite ${name}: All tests passed"
        touch $out
      ''
    else
      # No tests for current platform
      pkgs.runCommand "test-suite-${name}-empty" { } ''
        echo "⏭️  Test suite ${name}: No tests for current platform (${getCurrentPlatform})"
        touch $out
      '';
}
