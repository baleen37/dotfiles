{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.security;
in
{
  options.myHome.packages.security.enable = lib.mkEnableOption "security tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
    ];
  };
}
