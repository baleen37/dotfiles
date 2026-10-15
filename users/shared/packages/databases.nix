{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.databases;
in
{
  options.modules.packages.databases.enable = lib.mkEnableOption "database tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      postgresql
      sqlite
    ];
  };
}
