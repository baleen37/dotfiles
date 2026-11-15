{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.chrome;
in
{
  options.modules.packages.chrome.enable = lib.mkEnableOption "Google Chrome";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.google-chrome ];
  };
}
