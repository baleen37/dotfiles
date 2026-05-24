{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.databases;
in
{
  options.myHome.packages.databases.enable = lib.mkEnableOption "database tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      postgresql
      sqlite
    ];
  };
}
