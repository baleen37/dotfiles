{ user, config, pkgs, ... }:

let
  userHome = "${config.users.users.${user}.home}";
  xdg_configHome = "${config.users.users.${user}.home}/.config";
  xdg_dataHome = "${config.users.users.${user}.home}/.local/share";
  xdg_stateHome = "${config.users.users.${user}.home}/.local/state";
in
{


  "${userHome}/.hammerspoon" = {
    source = ./config/hammerspoon;
    recursive = true;
  };


  "${xdg_configHome}/karabiner" = {
    source = ./config/karabiner;
    recursive = true;
  };

  "${userHome}/Library/Preferences/com.lwouis.alt-tab-macos.plist" = {
    source = ./config/alt-tab/com.lwouis.alt-tab-macos.plist;
  };

  "${userHome}/Library/Preferences/com.runningwithcrayons.Alfred.plist" = {
    source = ./config/alfred/com.runningwithcrayons.Alfred.plist;
  };

}
