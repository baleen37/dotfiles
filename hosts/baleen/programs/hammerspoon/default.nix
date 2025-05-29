{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.hammerspoon = {
    enable = true;

    config = {
      HSUploadCrashData = 0;
      MJConfigFile = "${config.xdg.configHome}/hammerspoon/init.lua";
    };
  };

  xdg.configFile = {
    "hammerspoon" = {
      source = lib.cleanSource ./files;
      recursive = true;
    };
  };
}
