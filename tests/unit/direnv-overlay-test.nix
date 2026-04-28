{
  inputs,
  system,
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  overlays = import ../../lib/overlays.nix { inherit inputs; };
  overlaidPkgs = import inputs.nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };
in
helpers.assertTest "direnv-checks-disabled-on-darwin"
  (if overlaidPkgs.stdenv.isDarwin then overlaidPkgs.direnv.drvAttrs.doCheck == false else true)
  "direnv checks should be disabled on Darwin because upstream shell tests hang during system builds"
