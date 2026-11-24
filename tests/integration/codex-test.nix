# tests/integration/codex-test.nix

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  homeConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/codex.nix
      {
        modules.programs.codex.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };

  inherit (homeConfig) config;
in
{
  codex-package-not-from-nixpkgs =
    helpers.assertTest "codex-package-not-from-nixpkgs" (!(builtins.elem pkgs.codex config.home.packages))
      "Codex is installed from npm, not through Home Manager";
}
