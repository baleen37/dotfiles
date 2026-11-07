# macOS input source and launcher keyboard shortcuts.

{
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.darwin.keyboard-input.enable = lib.mkEnableOption "keyboard-input";

  options.modules.darwin.keyboard-input.reserveCommandSpace =
    lib.mkEnableOption "reserve Cmd+Space for Raycast";

  config = lib.mkIf (isDarwin && config.modules.darwin.keyboard-input.enable) {
    home.activation.keyboardInputSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{
          enabled = 1;
          value = {
              type = standard;
              parameters = (32, 49, 262144);
          };
      }'

      ${lib.optionalString config.modules.darwin.keyboard-input.reserveCommandSpace ''
        # Reserve Cmd+Space for Raycast; merge only Spotlight's shortcut entry.
        run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict>
            <key>enabled</key><false/>
            <key>value</key><dict>
                <key>type</key><string>standard</string>
                <key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array>
            </dict>
        </dict>'
      ''}
      # SystemUIServer alone does not reload the active symbolic hotkeys.
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      if /usr/bin/pgrep -x SystemUIServer > /dev/null 2>&1; then
        run /usr/bin/killall SystemUIServer > /dev/null 2>&1 || true
      fi
    '';
  };
}
