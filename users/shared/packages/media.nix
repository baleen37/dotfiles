{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.media;
in
{
  options.modules.packages.media.enable = lib.mkEnableOption "media tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg
    ];
  };
}
