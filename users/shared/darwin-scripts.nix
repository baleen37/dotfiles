# macOS Activation Scripts
#
# System activation scripts for:
# - Keyboard input source configuration (cmd+shift+space for Korean/English)
# - Automated cleanup of unused default macOS applications

{ ... }:

{
  # Keyboard Input Source Configuration Script
  # Configures cmd+shift+space for Korean/English input source switching
  system.activationScripts.configureKeyboard = {
    text = ''
      echo "Configuring keyboard input sources..." >&2

      sleep 2

      # Note: KeyRepeat and InitialKeyRepeat are now managed in system.defaults.NSGlobalDomain

      # cmd+shift+space for input source switching (hotkey 60)
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{
          enabled = 1;
          value = {
              type = standard;
              parameters = (49, 1048576, 131072);  # space(49), cmd, shift
          };
      }'

      # control+space as backup hotkey (61)
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{
          enabled = 1;
          value = {
              type = standard;
              parameters = (49, 262144, 0, 0);        # space, control
          };
      }'

      # Enable language indicator for visual feedback
      /usr/bin/defaults write kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled -bool true

      # Restart system services to apply changes
      if pgrep -x "SystemUIServer" > /dev/null; then
          killall SystemUIServer 2>/dev/null || true
      fi
      if pgrep -x "ControlCenter" > /dev/null; then
          killall ControlCenter 2>/dev/null || true
      fi

      echo "Keyboard configuration complete!" >&2
    '';
  };

  # macOS App Cleanup Activation Script
  # Automated storage optimization through removal of unused default macOS applications
  # Saves 6-8GB of storage space and reduces system resource consumption
  system.activationScripts.cleanupMacOSApps = {
    text = ''
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "Removing unused macOS default apps..." >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

      # 제거할 앱 목록
      apps=(
        "GarageBand.app"
        "iMovie.app"
        "TV.app"
        "Podcasts.app"
        "News.app"
        "Stocks.app"
        "Freeform.app"
      )

      removed_count=0
      skipped_count=0

      for app in "''${apps[@]}"; do
        app_path="/Applications/$app"

        if [ -e "$app_path" ]; then
          echo "  Removing: $app" >&2

          # sudo 없이 제거 시도 (사용자 설치 앱)
          if rm -rf "$app_path" 2>/dev/null; then
            removed_count=$((removed_count + 1))
          else
            # sudo로 재시도 (시스템 앱)
            if sudo rm -rf "$app_path" 2>/dev/null; then
              removed_count=$((removed_count + 1))
            else
              echo "     Failed to remove (SIP protected): $app" >&2
              skipped_count=$((skipped_count + 1))
            fi
          fi
        else
          echo "  ✓  Already removed: $app" >&2
        fi
      done

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "Cleanup complete!" >&2
      echo "   - Removed: $removed_count apps" >&2
      echo "   - Skipped: $skipped_count apps (protected)" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    '';
  };
}
