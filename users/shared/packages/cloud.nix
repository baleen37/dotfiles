{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.cloud;
in
{
  options.modules.packages.cloud.enable = lib.mkEnableOption "cloud tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      act
      gh
      awscli2
    ];
  };
}
