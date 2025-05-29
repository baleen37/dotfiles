{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.homerow;
in
{
  options.services.homerow = {
    enable = mkEnableOption "Homerow background service";
    package = mkOption {
      type = types.package;
      default = pkgs.homerow;
      description = "Homerow package to use";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.homerow = {
      description = "Homerow";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/Applications/Homerow.app/Contents/MacOS/Homerow";
        Restart = "always";
      };
    };
  };
}
