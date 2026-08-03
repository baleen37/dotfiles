{
  inputs,
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  overlays = import ../../lib/overlays.nix { inherit inputs; };
  overlayPkgs = import inputs.nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    inherit overlays;
    config.allowUnfree = true;
  };

  homeConfiguration = self.homeConfigurations.baleen;
in
helpers.testSuite "per-system-pkgs" [
  (helpers.assertTest "baleen-home-configuration-evaluates" (
    homeConfiguration ? activationPackage
  ) "homeConfigurations.baleen should evaluate an activation package")

  (helpers.assertTest "overlay-package-is-available" (
    overlayPkgs ? claude-code
  ) "per-system nixpkgs should include the claude-code overlay package")
]
