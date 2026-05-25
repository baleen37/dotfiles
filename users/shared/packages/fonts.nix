{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.fonts;
in
{
  options.modules.packages.fonts.enable = lib.mkEnableOption "fonts";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      noto-fonts-cjk-sans
      cascadia-code
      d2coding
    ];
  };
}
