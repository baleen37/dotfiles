# Raycast Script Command and Extension configuration

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.raycast;
in
{
  options.modules.programs.raycast.enable = lib.mkEnableOption "Raycast Script Commands" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/raycast/script-commands" = {
      source = ./.config/raycast/script-commands;
      recursive = true;
      force = true;
    };

  };
}
