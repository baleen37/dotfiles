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
    extraSpecialArgs = { inherit inputs; };
    modules = [
      ../../users/shared/programs/herdr.nix
      {
        modules.programs.herdr.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };

  inherit (homeConfig) config;
  herdrSimPackage = inputs.herdr-sim.packages.${system}.default;
in
{
  # The app's herdr-sim mods run `herdr-sim` from PATH; without it the Changes
  # panel shows an error instead of PRs.
  herdr-sim-on-path =
    helpers.assertTest "herdr-sim-on-path" (builtins.elem herdrSimPackage config.home.packages)
      "herdr-sim should be installed for the Herdr app's mods";

  # Only the desktop app is used, so the terminal UI and its config stay out.
  herdr-tui-not-installed = helpers.assertTest "herdr-tui-not-installed" (
    !(builtins.elem pkgs.herdr config.home.packages) && !(config.xdg.configFile ? "herdr/config.toml")
  ) "the Herdr terminal UI and its config.toml should not be installed";
}
