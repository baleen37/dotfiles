{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
  cfg = config.services.homerow;
in
{
  options.services.homerow = {
    enable = lib.mkEnableOption "homerow";
    package = lib.mkPackageOption pkgs "homerow" { };
    config = { };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> isDarwin;
          message = "Nix homerow only supports darwin.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];

      launchd.agents.homerow = {
        enable = true;
        config = {
          ProgramArguments = [
            "${config.home.homeDirectory}/Applications/Home Manager Apps/${cfg.package.sourceRoot}/Contents/MacOS/Homerow"
          ];
          KeepAlive = true;
          ProcessType = "Interactive";
          StandardOutPath = "${config.xdg.cacheHome}/homerow.log";
          StandardErrorPath = "${config.xdg.cacheHome}/homerow.log";
        };
      };
    })
  ];
}
