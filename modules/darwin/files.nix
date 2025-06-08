{ user, config, pkgs, ... }:

let
  userHome = "${config.users.users.${user}.home}";
  xdg_configHome = "${config.users.users.${user}.home}/.config";
  xdg_dataHome   = "${config.users.users.${user}.home}/.local/share";
  xdg_stateHome  = "${config.users.users.${user}.home}/.local/state"; in
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
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      	<key>holdShortcut</key>
      	<string>⌥⇥</string>
      	<key>holdShortcut2</key>
      	<string>⌥`</string>
      	<key>nextWindowShortcut</key>
      	<string>⌥⇥</string>
      	<key>nextWindowShortcut2</key>
      	<string>⌥`</string>
      	<key>previousWindowShortcut</key>
      	<string>⌥⇧⇥</string>
      	<key>previousWindowShortcut2</key>
      	<string>⌥⇧`</string>
      </dict>
      </plist>
    '';
  };

}
