# tests/integration/build-test.nix
{ inputs, system }:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  lib = pkgs.lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Try to build the full system
  fullSystem =
    if pkgs.stdenv.isDarwin then
      inputs.self.darwinConfigurations.macbook-pro
    else
      throw "Not on Darwin";

in
helpers.testSuite "integration-build" [
  (helpers.assertTest "system-has-config" (fullSystem ? config) "Full system should have config")

  (helpers.assertTest "home-manager-loaded" (
    fullSystem.config ? home-manager
  ) "Home Manager should be loaded")
]
