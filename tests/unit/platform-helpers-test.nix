# Platform Helpers Test
#
# Tests platform helper utilities for conditional test inclusion
# Verifies that platform detection and filtering functions work correctly.
{ inputs, system, pkgs, lib, self, nixtest ? {}, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import platform helpers once for testing
  platformHelpers = import ../lib/platform-helpers.nix { inherit pkgs lib; };
  currentPlatform = platformHelpers.getCurrentPlatform;
in
{
  platforms = ["any"];
  value = helpers.testSuite "platform-helpers" [
    # Test mkPlatformTest function availability
    (helpers.assertTest "mkPlatformTest-available" (
      builtins.isFunction platformHelpers.mkPlatformTest
    ) "mkPlatformTest should be available")

    # Test filterPlatformTests function availability
    (helpers.assertTest "filterPlatformTests-available" (
      builtins.isFunction platformHelpers.filterPlatformTests
    ) "filterPlatformTests should be available")

    # Test getCurrentPlatform value availability
    (helpers.assertTest "getCurrentPlatform-available" (
      builtins.isString currentPlatform
    ) "getCurrentPlatform should return a string")

    # Test platform detection returns valid value
    (helpers.assertTest "platform-detection-valid" (
      currentPlatform == "darwin" || currentPlatform == "linux" || currentPlatform == "unknown"
    ) "Platform detection should return a valid value")

    # Test isCurrentPlatform helper availability
    (helpers.assertTest "isCurrentPlatform-available" (
      builtins.isFunction platformHelpers.isCurrentPlatform
    ) "isCurrentPlatform should be available")

    # Test mkPlatformTestSuite helper availability
    (helpers.assertTest "mkPlatformTestSuite-available" (
      builtins.isFunction platformHelpers.mkPlatformTestSuite
    ) "mkPlatformTestSuite should be available")
  ];
}
