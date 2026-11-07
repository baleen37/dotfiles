{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.nix-tools;
in
{
  options.modules.packages.nix-tools.enable = lib.mkEnableOption "Nix tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nixfmt
      statix
      deadnix
    ];
  };
}
