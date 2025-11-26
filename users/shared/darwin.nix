# macOS Configuration
#
# Optimized macOS setup with:
# - Performance optimizations (UI, input, memory)
# - Developer-friendly interface (Dock, Finder, Trackpad)
# - Homebrew integration for GUI apps
# - Automated app cleanup (6-8GB storage saved)
# - Korean keyboard support with cmd+shift+space

{
  pkgs,
  lib,
  config,
  currentSystemUser,
  ...
}:

let
  # macOS-specific packages
  darwin-packages = with pkgs; [
    dockutil
  ];

  # Homebrew Cask definitions (GUI applications)
  homebrew-casks = [
    # Development Tools
    "datagrip" # Database IDE from JetBrains
    "ghostty" # GPU-accelerated terminal emulator
    "intellij-idea"
    "utm" # Virtual machine manager for macOS

    # Communication Tools
    "discord"
    "notion"
    "slack"
    "telegram"
    "zoom"
    "obsidian"

    # Utility Tools
    "alt-tab"
    "claude"
    "karabiner-elements" # Key remapping and modification tool
    "orbstack" # Docker and Linux VM management
    "rectangle" # Simple window management tool
    "tailscale-app" # VPN mesh network with GUI
    "teleport-connect" # Teleport GUI client for secure infrastructure access

    # Entertainment Tools
    "vlc"

    # Study Tools
    "anki"

    # Productivity Tools
    "alfred"

    # Password Management
    "1password"
    "1password-cli"

    # Browsers
    "google-chrome"
    "brave-browser"
    "firefox"

    "hammerspoon"
  ];
in
{
  # ===== Core System Configuration =====
  system.defaults = {
    # Global system preferences and performance optimizations
    NSGlobalDomain = {
      # UI Performance
      NSAutomaticWindowAnimationsEnabled = false; # Disable window animations
      NSWindowResizeTime = 0.1; # Faster window resizing
      NSScrollAnimationEnabled = false; # Disable smooth scrolling

      # Input Optimization
      NSAutomaticCapitalizationEnabled = false; # Disable auto-capitalization
      NSAutomaticSpellingCorrectionEnabled = false; # Disable spell correction
      NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quotes
      NSAutomaticDashSubstitutionEnabled = false; # Disable smart dashes
      NSAutomaticPeriodSubstitutionEnabled = false; # Disable auto-period
      ApplePressAndHoldEnabled = false; # Faster key repeat

      # Memory & Battery
      NSDisableAutomaticTermination = false; # Enable app auto-termination
      NSDocumentSaveNewDocumentsToCloud = false; # Disable iCloud auto-save

      # Advanced Optimizations
      "AppleEnableMouseSwipeNavigateWithScrolls" = false; # Disable swipe navigation
      "AppleEnableSwipeNavigateWithScrolls" = false; # Disable Chrome swipe navigation
      "AppleFontSmoothing" = 1; # Reduced font smoothing
      "NSNavPanelExpandedStateForSaveMode" = false; # Compact save dialogs
      "NSNavPanelExpandedStateForSaveMode2" = false; # Compact save dialogs
    };

    # User Interface - Dock
    dock = {
      autohide = true; # Auto-hide dock
      autohide-delay = 0.0; # Instant appearance
      autohide-time-modifier = 0.15; # Faster animation
      expose-animation-duration = 0.2; # Quick Mission Control
      tilesize = 48; # Smaller icons
      mru-spaces = false; # Predictable layout
    };

    # User Interface - Finder
    finder = {
      AppleShowAllFiles = true; # Show hidden files
      FXEnableExtensionChangeWarning = false; # No extension warnings
      _FXSortFoldersFirst = true; # Folders first
      ShowPathbar = true; # Show path navigation
      ShowStatusBar = true; # Show file information
    };

    # User Interface - Trackpad
    trackpad = {
      Clicking = true; # Enable tap-to-click
      TrackpadRightClick = true; # Enable two-finger right-click
      TrackpadThreeFingerDrag = true; # Enable three-finger drag
    };

    # System Management - Spaces
    spaces = {
      spans-displays = false; # Better performance
    };
  };

  # ===== Authentication Configuration =====
  system.defaults.loginwindow = {
    SHOWFULLNAME = false; # Compact login prompt
    DisableConsoleAccess = false; # Maintain console access
  };

  # ===== Homebrew Configuration =====
  # Optimized Homebrew setup for development workflow with performance considerations
  homebrew = {
    enable = true;
    casks = homebrew-casks;

    # Development Services Configuration
    brews = [ ];

    # Performance Optimization: Selective Cleanup Strategy
    # Prevents unexpected interruptions during development while maintaining system hygiene
    onActivation = {
      autoUpdate = false; # Manual updates for predictability and control
      upgrade = false; # Avoid automatic upgrades during system rebuilds
      # cleanup = "uninstall";  # Commented for safety during development - enable when needed
    };

    # Optimized Global Homebrew Settings
    # Enhances package management efficiency and dependency tracking
    global = {
      brewfile = true; # Enable Brewfile support for reproducible setups
      lockfiles = true; # Use lockfiles for consistent dependency resolution
    };

    # Mac App Store Applications (Optimized Metadata)
    # Carefully selected apps for development productivity and system management
    # IDs obtained via: nix shell nixpkgs#mas && mas search <app name>
    masApps = {
      "WireGuard" = 1451685025; # Lightweight, secure VPN client
      "KakaoTalk" = 869223134; # Communication platform (if needed)
    };

    # Extended Package Repository Access
    # Additional Homebrew taps for specialized packages and development tools
    # Note: homebrew/cask is now built into Homebrew by default (since 2023)
    taps = [ ];
  };

  # ===== Keyboard Input Source Configuration Script =====
  # Configures cmd+shift+space for Korean/English input source switching
  system.activationScripts.configureKeyboard = {
    text = ''
      echo "⌨️  Configuring keyboard input sources..." >&2

      sleep 2

      # Optimize key repeat for Korean typing (no keyboard navigation)
      /usr/bin/defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
      /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 2
      /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 25

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

      echo "✅ Keyboard configuration complete!" >&2
    '';
  };

  # ===== macOS App Cleanup Activation Script =====
  # Automated storage optimization through removal of unused default macOS applications
  # Saves 6-8GB of storage space and reduces system resource consumption
  system.activationScripts.cleanupMacOSApps = {
    text = ''
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "🧹 Removing unused macOS default apps..." >&2
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
          echo "  🗑️  Removing: $app" >&2

          # sudo 없이 제거 시도 (사용자 설치 앱)
          if rm -rf "$app_path" 2>/dev/null; then
            removed_count=$((removed_count + 1))
          else
            # sudo로 재시도 (시스템 앱)
            if sudo rm -rf "$app_path" 2>/dev/null; then
              removed_count=$((removed_count + 1))
            else
              echo "     ⚠️  Failed to remove (SIP protected): $app" >&2
              skipped_count=$((skipped_count + 1))
            fi
          fi
        else
          echo "  ✓  Already removed: $app" >&2
        fi
      done

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "✨ Cleanup complete!" >&2
      echo "   - Removed: $removed_count apps" >&2
      echo "   - Skipped: $skipped_count apps (protected)" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    '';
  };

  # ===== System Integration Configuration =====
  # Core system settings and compatibility configurations

  # Package Management Configuration
  # Allow unfree packages (system level for useGlobalPkgs)
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix Integration
  # Compatibility layer for Determinate Nix installation
  # Determinate manages Nix installation independently, so disable nix-darwin's Nix management
  # All Nix settings are centrally managed by Determinate in /etc/nix/nix.conf
  nix = {
    enable = false; # Required for Determinate compatibility and to prevent conflicts
  };

  # Shell Environment Configuration
  # Enable zsh as the system shell for consistency with user configuration
  programs.zsh.enable = true;

  # Keyboard Configuration
  # System-level keyboard remapping for modifier keys
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # User and System Management
  # Primary user configuration for nix-darwin system management
  # Username is dynamically resolved from flake.nix for multi-user support
  # Root user management is now handled by system defaults, home-manager is disabled

  system = {
    primaryUser = currentSystemUser; # Dynamic user resolution for multi-environment support
    checks.verifyNixPath = false; # Disable NIX_PATH verification for cleaner builds
    stateVersion = 5; # Updated to current nix-darwin version for compatibility
  };

  # Package Installation
  # Install macOS-specific packages
  environment.systemPackages = darwin-packages;


  # Build Performance Optimization
  # Disable documentation generation to avoid builtins.toFile warnings and improve build speed
  documentation.enable = false;
}
