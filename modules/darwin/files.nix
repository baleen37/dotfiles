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

  # WezTerm configuration (restored from iTerm2)
  "${xdg_configHome}/wezterm/wezterm.lua" = {
    source = ./config/wezterm/wezterm.lua;
  };

  # Keep iTerm2 config commented for backup
  # "${userHome}/Library/Application Support/iTerm2/DynamicProfiles/DynamicProfiles.json" = {
  #   source = ./config/iterm2/DynamicProfiles.json;
  # };

}
