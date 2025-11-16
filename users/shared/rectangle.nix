# users/shared/rectangle.nix
# Rectangle window manager configuration managed via Home Manager

{
  pkgs,
  lib,
  ...
}:

{
  # Rectangle Configuration via home.file
  # Creates read-only symlinks to /nix/store for version control

  home.file."Library/Preferences/com.knollsoft.Rectangle.plist" = {
    text = ''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>allowAnyShortcut</key>
  <integer>1</integer>
  <key>alternateDefaultShortcuts</key>
  <integer>1</integer>
  <key>bottomHalf</key>
  <dict>
    <key>keyCode</key>
    <integer>125</integer>
    <key>modifierFlags</key>
    <integer>1572864</integer>
  </dict>
  <key>leftHalf</key>
  <dict>
    <key>keyCode</key>
    <integer>123</integer>
    <key>modifierFlags</key>
    <integer>1572864</integer>
  </dict>
  <key>rightHalf</key>
  <dict>
    <key>keyCode</key>
    <integer>124</integer>
    <key>modifierFlags</key>
    <integer>1572864</integer>
  </dict>
  <key>topHalf</key>
  <dict>
    <key>keyCode</key>
    <integer>126</integer>
    <key>modifierFlags</key>
    <integer>1572864</integer>
  </dict>
  <key>subsequentExecutionMode</key>
  <integer>1</integer>
  <key>SUEnableAutomaticChecks</key>
  <false/>
</dict>
</plist>
    '';
    force = true;
  };
}
