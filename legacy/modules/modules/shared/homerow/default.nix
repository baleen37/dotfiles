{ config, lib, pkgs, ... }:

with lib;
let
  inherit (lib) types;
  cfg = config.services.homerow;
in
{
  options.services.homerow = {
    enable = mkEnableOption "Homerow background service";
    package = mkOption {
      type = types.nullOr types.package;
      default = if pkgs ? homerow then pkgs.homerow else null;
      description = "Homerow package to use";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = [ cfg.package ];
    # LaunchAgent 설정이 필요하다면 여기에 추가
  };
}
