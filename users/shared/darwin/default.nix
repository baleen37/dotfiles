# macOS Configuration
#
# Optimized macOS setup with:
# - Performance optimizations (UI, input, memory)
# - Developer-friendly interface (Dock, Finder, Trackpad)
# - Homebrew integration for GUI apps (homebrew.nix)
# - Automated app cleanup and keyboard config (scripts.nix)
# - Korean keyboard support with cmd+shift+space

{
  pkgs,
  currentSystemUser,
  ...
}:

let
  # macOS-specific packages
  darwin-packages = with pkgs; [
    dockutil
  ];
in
{
  imports = [
    ./homebrew.nix
    ./scripts.nix
  ];

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

      # Keyboard Speed (macOS GUI 제한을 초과하는 최고속 설정)
      KeyRepeat = 1; # 키 반복 속도 (1-120, 낮을수록 빠름, GUI 최소값: 2)
      InitialKeyRepeat = 10; # 초기 반복 지연 (10-120, 낮을수록 빠름, GUI 최소값: 15)

      # Trackpad Speed (최대 속도 설정)
      "com.apple.trackpad.scaling" = 3.0; # 커서 이동 속도 (0.0-3.0, 최대값)

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

    # Custom User Preferences (스크롤 속도는 여기서만 설정 가능)
    CustomUserPreferences = {
      "NSGlobalDomain" = {
        "com.apple.scrollwheel.scaling" = 1.0; # 스크롤 속도 (최대값, -1은 가속 비활성화)
        "com.apple.trackpad.forceClick" = true; # Enable one-finger force click lookup
      };

      "com.apple.AppleMultitouchTrackpad" = {
        ForceSuppressed = 0; # Enable force click
        TrackpadThreeFingerTapGesture = 0; # Disable three-finger lookup
      };

      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        TrackpadThreeFingerTapGesture = 0; # Disable three-finger lookup
      };
    };
  };

  # ===== Authentication Configuration =====
  system.defaults.loginwindow = {
    SHOWFULLNAME = false; # Compact login prompt
    DisableConsoleAccess = false; # Maintain console access

    # Auto login on boot so the GUI session comes up unattended.
    #
    # macOS unlocks the login keychain as part of a GUI login. Without one, a
    # headless reboot leaves the keychain locked and every incoming SSH session
    # hits the unlock prompt in zsh/keychain-unlock.nix. Auto login restores the
    # normal unlock path instead of stashing the keychain password anywhere.
    #
    # nix-darwin only writes this plist key; it never touches /etc/kcpassword,
    # which is what actually makes auto login happen. That file holds the login
    # password, so it cannot live in this repo -- create it once with:
    #
    #   sudo sysadminctl -autologin set -userName <user>   # prompts for password
    #
    # Omit -password so the password is never in shell history. Verify with
    # `sysadminctl -autologin status`. Without that file this setting is inert
    # (the machine still shows the login window).
    #
    # Caveat: the GUI login only unlocks the keychain when the account password
    # and the login keychain password match. They diverge if the account
    # password was changed in a way that left the old keychain behind (macOS
    # renames it to login_renamed_N.keychain-db). Re-sync with
    # `security set-keychain-password ~/Library/Keychains/login.keychain-db`.
    autoLoginUser = currentSystemUser;
  };

  # ===== System Integration Configuration =====

  # Package Management Configuration
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix Integration
  nix = {
    enable = false; # Required for Determinate compatibility and to prevent conflicts
  };

  # Shell Environment Configuration
  programs.zsh.enable = true;

  # Keyboard Configuration
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system = {
    primaryUser = currentSystemUser; # Dynamic user resolution for multi-environment support
    checks.verifyNixPath = false; # Disable NIX_PATH verification for cleaner builds
    stateVersion = 5; # Updated to current nix-darwin version for compatibility
  };

  # Package Installation
  environment.systemPackages = darwin-packages;

  # Build Performance Optimization
  documentation.enable = false;
}
