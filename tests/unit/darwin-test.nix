# Darwin Configuration Test
#
# Tests the consolidated Darwin configuration in users/shared/darwin.nix
# Verifies that system settings, Homebrew config, and performance optimizations are properly defined.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  darwinHelpers = import ../lib/darwin-test-helpers.nix { inherit pkgs lib helpers; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  darwinConfig = import ../../users/shared/darwin.nix {
    inherit pkgs lib;
    config = mockConfig.mkEmptyConfig;
    currentSystemUser = "baleen"; # Test with default user
  };

in
# Platform filtering - this test should only run on Darwin systems
{
  platforms = ["darwin"];
  value = helpers.testSuite "darwin" [
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
  (darwinHelpers.assertCleanupScriptConfigured darwinConfig)
  ];
}
