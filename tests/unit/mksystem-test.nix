# tests/unit/mksystem-test.nix
# evantravers-style system factory tests
# Tests the lib/mksystem.nix system factory function
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test helpers from evantravers refactor
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import mksystem function for testing
  mkSystem = import ../../lib/mksystem.nix { inherit inputs; };

  # Mock inputs for testing
  mockInputs = {
    nixpkgs = { inherit lib; };
    darwin = {
      lib = {
        darwinSystem = _: { config = { }; };
      };
    };
    home-manager = {
      lib = {
        homeManagerConfiguration = _: { };
      };
    };
  };

  # Test with minimal config
  testSystem = mkSystem "test-machine" {
    inherit system;
    user = "testuser";
    darwin = (lib.hasSuffix "-darwin" system);
  };

  # Test suite using NixTest framework
  testSuite = {
    name = "mksystem-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test 1: Returns valid configuration
      mksystem-returns-config = nixtest.test "mksystem returns config" (
        builtins.hasAttr "config" testSystem
      );

      # Test 2: Special args passed correctly
      mksystem-special-args = nixtest.test "mksystem special args" (
        builtins.hasAttr "currentSystemName" testSystem.config._module.args
      );

      # Test 3: User set correctly
      mksystem-user = nixtest.test "mksystem user" (
        testSystem.config._module.args.currentSystemUser == "testuser"
      );

      # Test 4: Platform detection
      mksystem-platform = nixtest.test "mksystem platform" (
        testSystem.config._module.args.isDarwin == (lib.hasSuffix "-darwin" system)
      );

      # Test 5: System attribute present
      mksystem-system = nixtest.test "mksystem system" (
        testSystem ? system && testSystem.system == system
      );

      # Test 6: Special args consistency
      mksystem-special-args-consistency = nixtest.test "mksystem special args consistency" (
        testSystem.specialArgs.currentSystemName == "test-machine"
        && testSystem.specialArgs.currentSystemUser == "testuser"
      );
    };
  };

in
testSuite
