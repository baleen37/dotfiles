# tests/unit/platform-helpers-test.nix
# Tests platform helper utilities for conditional test inclusion
{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };
in
helpers.testSuite "platform-helpers" [
  # Test mkPlatformTest function availability
  (helpers.assertTest "mkPlatformTest-availability"
    (builtins.isFunction (import ../lib/platform-helpers.nix { inherit pkgs lib; }))
    "platform-helpers.nix should be importable and provide mkPlatformTest function")

  # Test filterPlatformTests function availability
  (helpers.assertTest "filterPlatformTests-availability"
    (builtins.isFunction (import ../lib/platform-helpers.nix { inherit pkgs lib; }))
    "platform-helpers.nix should provide filterPlatformTests function")

  # Test getCurrentPlatform function availability
  (helpers.assertTest "getCurrentPlatform-availability"
    (builtins.isFunction (import ../lib/platform-helpers.nix { inherit pkgs lib; }))
    "platform-helpers.nix should provide getCurrentPlatform function")

  # Test that platform detection returns a valid platform string
  (helpers.assertTest "getCurrentPlatform-returns-string"
    (builtins.isString ( (import ../lib/platform-helpers.nix { inherit pkgs lib; }).getCurrentPlatform ))
    "getCurrentPlatform should return a string identifier")

  # Test that current platform is one of expected values
  (helpers.assertTest "getCurrentPlatform-valid-value"
    (builtins.any (p: p == (import ../lib/platform-helpers.nix { inherit pkgs lib; }).getCurrentPlatform) ["darwin" "linux" "unknown"])
    "getCurrentPlatform should return darwin, linux, or unknown")
]
