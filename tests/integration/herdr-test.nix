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
      ../../users/shared/programs/herdr.nix
      {
        modules.programs.herdr.enable = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };

  inherit (homeConfig) config;
  herdrConfig = config.xdg.configFile."herdr/config.toml".text;
  parsedConfig = builtins.fromTOML herdrConfig;
  herdrConfigFile = pkgs.writeText "herdr-config.toml" herdrConfig;
in
{
  herdr-package-installed =
    helpers.assertTest "herdr-package-installed" (builtins.elem pkgs.herdr config.home.packages)
      "Herdr should be installed through Home Manager";

  herdr-config-contains-tmux-bindings = helpers.assertTest "herdr-config-contains-tmux-bindings" (
    parsedConfig.keys == {
      prefix = "ctrl+a";
      detach = "prefix+d";
      split_vertical = "prefix+|";
      split_horizontal = "prefix+minus";
    }
  ) "Herdr should use the selected tmux-compatible bindings";

  herdr-config-does-not-set-worktree-root =
    helpers.assertTest "herdr-config-does-not-set-worktree-root" (!(parsedConfig ? worktrees))
      "Herdr config should not maintain a global worktree root";

  herdr-config-valid = pkgs.runCommand "herdr-config-valid" { } ''
    export HOME="$TMPDIR"
    export HERDR_CONFIG_PATH=${herdrConfigFile}
    ${pkgs.herdr}/bin/herdr config check
    touch "$out"
  '';
}
