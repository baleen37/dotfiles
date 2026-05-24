{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.nix-tools;
in
{
  options.myHome.packages.nix-tools.enable = lib.mkEnableOption "Nix tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nixfmt
      statix
      deadnix
    ];
  };
}
