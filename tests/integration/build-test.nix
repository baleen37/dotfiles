# tests/integration/build-test.nix
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test data
  fullSystem = inputs.self.darwinConfigurations.macbook-pro;

in
# Use consistent helper pattern for platform-specific testing
helpers.runIfPlatform "darwin" (
  helpers.testSuite "integration-build" [
    # Test 1: Full system should have config attribute
    (helpers.assertTest "system-has-config"
      (fullSystem ? config)
      "Full system should have config attribute")

    # Test 2: Home Manager should be loaded in system config
    (helpers.assertTest "home-manager-loaded"
      (fullSystem.config ? home-manager)
      "Home Manager should be loaded in system config")

    # Test 3: System configuration should be buildable
    (helpers.assertTest "system-buildable"
      (fullSystem ? system)
      "System configuration should be buildable")
  ]
)
