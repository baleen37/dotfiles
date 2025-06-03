{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
  hammerspoonPkg = pkgs.callPackage ../../../modules/nix/packages/hammerspoon {};
  filesDir = ./files;

in
lib.mkIf isDarwin {
  home.packages = [ hammerspoonPkg ];

  xdg.configFile = {
    "hammerspoon" = {
      source = lib.cleanSource filesDir;
      recursive = true;
    };
  };

  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/Applications/Home Manager Apps/${hammerspoonPkg.sourceRoot}/Contents/MacOS/Hammerspoon"
      ];
      KeepAlive = true;
      ProcessType = "Interactive";
      StandardOutPath = "${config.xdg.cacheHome}/hammerspoon.log";
      StandardErrorPath = "${config.xdg.cacheHome}/hammerspoon.log";
    };
  };
}
