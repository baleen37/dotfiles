{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.fonts;
in
{
  options.myHome.packages.fonts.enable = lib.mkEnableOption "fonts" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      noto-fonts-cjk-sans
      cascadia-code
      d2coding
    ];
  };
}
