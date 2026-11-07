{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.security;
in
{
  options.modules.packages.security.enable = lib.mkEnableOption "security tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
    ];
  };
}
