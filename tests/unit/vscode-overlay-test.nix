{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  overlays = import ../../lib/overlays.nix { inherit inputs; };
  darwinPkgs = import inputs.nixpkgs {
    system = "aarch64-darwin";
    inherit overlays;
    config.allowUnfree = true;
  };
  postPatch = darwinPkgs.vscode.drvAttrs.postPatch;
  ripgrepPath = "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal";
  brokenRipgrepPath = "Contents/Resources/app/node_modules/@vscode/ripgrep-universal";
in
helpers.assertTest "vscode-darwin-ripgrep-path" (
  lib.hasInfix ripgrepPath postPatch && !lib.hasInfix brokenRipgrepPath postPatch
) "VS Code must patch ripgrep at its node_modules.asar.unpacked location on Darwin"
