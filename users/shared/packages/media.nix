{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.media;
in
{
  options.myHome.packages.media.enable = lib.mkEnableOption "media tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg
    ];
  };
}
