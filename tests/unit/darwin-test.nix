# Darwin Configuration Test
#
# Tests the consolidated Darwin configuration in users/baleen/darwin.nix
# Verifies that system settings, Homebrew config, and performance optimizations are properly defined.
{ inputs, system }:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  darwinConfig = import ../../users/baleen/darwin.nix {
    inherit pkgs lib;
    config = { };
  };

in
helpers.testSuite "darwin" [
  # Test system settings exist
  (helpers.assertTest "darwin-has-system-settings" (
    darwinConfig ? system
  ) "Darwin config should have system settings")

  # Test Homebrew config exists
  (helpers.assertTest "darwin-has-homebrew" (
    darwinConfig ? homebrew
  ) "Darwin config should have Homebrew configuration")

  # Test performance optimization settings
  (helpers.assertTest "darwin-has-performance-optimizations" (
    darwinConfig.system.defaults ? NSGlobalDomain
  ) "Darwin config should have NSGlobalDomain performance settings")

  # Test dock optimization settings
  (helpers.assertTest "darwin-has-dock-optimizations" (
    darwinConfig.system.defaults ? dock
  ) "Darwin config should have dock optimization settings")

  # Test app cleanup activation script
  (helpers.assertTest "darwin-has-app-cleanup" (
    darwinConfig.system.activationScripts ? cleanupMacOSApps
  ) "Darwin config should have macOS app cleanup activation script")
]
