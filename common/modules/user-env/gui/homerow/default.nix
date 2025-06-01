{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
  homerowPkg = pkgs.callPackage ../../../../nix/packages/homerow {};

in
lib.mkIf isDarwin {
  assertions = [
    {
      assertion = true;
      message = "Nix homerow only supports darwin.";
    }
  ];

  home.packages = [ homerowPkg ];

  launchd.agents.homerow = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/Applications/Home Manager Apps/${homerowPkg.sourceRoot}/Contents/MacOS/Homerow"
      ];
      KeepAlive = true;
      ProcessType = "Interactive";
      StandardOutPath = "${config.xdg.cacheHome}/homerow.log";
      StandardErrorPath = "${config.xdg.cacheHome}/homerow.log";
    };
  };
}
