{ user, config, ... }:

let
  userHome = "${config.users.users.${user}.home}";
  xdg_configHome = "${config.users.users.${user}.home}/.config";
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

}
