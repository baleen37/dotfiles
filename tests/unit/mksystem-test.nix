# tests/unit/mksystem-test.nix
{ inputs, system }:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # This will fail - mksystem.nix doesn't exist yet
  mkSystem = import ../../lib/mksystem.nix { inherit inputs; };

  # Test with minimal config
  testSystem = mkSystem "test-machine" {
    inherit system;
    user = "testuser";
    darwin = (lib.hasSuffix "-darwin" system);
  };

in
helpers.testSuite "mksystem" [
  # Test 1: Returns valid configuration
  (helpers.assertTest "mksystem-returns-config" (
    testSystem ? config
  ) "mkSystem should return a config attribute")

  # Test 2: Special args passed correctly
  (helpers.assertTest "mksystem-special-args" (
    testSystem.config._module.args ? currentSystemName
  ) "Special args should include currentSystemName")

  # Test 3: User set correctly
  (helpers.assertTest "mksystem-user" (
    testSystem.config._module.args.currentSystemUser == "testuser"
  ) "User should be testuser")

  # Test 4: Platform detection
  (helpers.assertTest "mksystem-platform" (
    testSystem.config._module.args.isDarwin == (lib.hasSuffix "-darwin" system)
  ) "Platform detection should match system")
]
