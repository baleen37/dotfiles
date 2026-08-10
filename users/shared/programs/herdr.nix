{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.herdr;
in
{
  options.modules.programs.herdr.enable = lib.mkEnableOption "Herdr terminal workspace manager";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    xdg.configFile."herdr/config.toml".text = ''
      onboarding = false

      [update]
      channel = "stable"
      version_check = false

      [keys]
      prefix = "ctrl+a"
      detach = "prefix+d"
      split_vertical = "prefix+|"
      split_horizontal = "prefix+minus"
    '';
  };
}
