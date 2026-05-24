{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.cloud;
in
{
  options.myHome.packages.cloud.enable = lib.mkEnableOption "cloud tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      act
      gh
      awscli2
    ];
  };
}
