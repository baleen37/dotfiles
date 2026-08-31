# macOS keyboard input source configuration.

{
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf isDarwin {
    home.activation.keyboardInputSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{
          enabled = 1;
          value = {
              type = standard;
              parameters = (32, 49, 262144);
          };
      }'

      if /usr/bin/pgrep -x SystemUIServer > /dev/null 2>&1; then
        run /usr/bin/killall SystemUIServer > /dev/null 2>&1 || true
      fi
    '';
  };
}
