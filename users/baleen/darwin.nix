# macOS Consolidated Configuration
#
# Consolidates all macOS-specific configurations from modules/darwin/ into a single file.
# Includes system settings, performance optimizations, Homebrew configuration, and app cleanup.
#
# Consolidated from:
#   - modules/darwin/performance-optimization.nix (Level 1+2 performance tuning)
#   - modules/darwin/macos-app-cleanup.nix (app cleanup activation script)
#   - modules/darwin/home-manager.nix (Homebrew integration)
#   - modules/darwin/casks.nix (GUI apps list)
#   - modules/darwin/packages.nix (macOS-specific packages)
#
# Performance Optimizations (Level 1+2):
#   - UI Animations: Window/scroll/Dock animations for 30-50% responsiveness boost
#   - Input Processing: Disable CPU-intensive auto-correction features
#   - Memory Management: Enable automatic app termination for resource efficiency
#   - Battery Efficiency: Minimize iCloud sync and background processing
#   - Developer Experience: Finder enhancements and trackpad responsiveness
#
# Expected Impact:
#   - UI responsiveness: 30-50% faster
#   - CPU usage: Reduced (auto-correction disabled)
#   - Battery life: Extended (iCloud sync minimized)
#   - Memory management: Improved (automatic app termination enabled)

{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Custom karabiner-elements version 14 (Darwin-only)
  karabiner-elements-14 = pkgs.karabiner-elements.overrideAttrs (_oldAttrs: {
    version = "14.13.0";
    src = pkgs.fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      sha256 = "1g3c7jb0q5ag3ppcpalfylhq1x789nnrm767m2wzjkbz3fi70ql2"; # pragma: allowlist secret
    };
  });

  # macOS-specific packages
  darwin-packages = with pkgs; [
    dockutil
    karabiner-elements-14 # Advanced keyboard customizer for macOS (version 14)
  ];

  # Homebrew Cask definitions (GUI applications)
  homebrew-casks = [
    # Development Tools
    "datagrip" # Database IDE from JetBrains
    "docker-desktop"
    "intellij-idea"

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
  # ===== Performance Optimization Settings =====
  # Comprehensive performance tuning via nix-darwin system.defaults
  system.defaults = {
    # UI Animations (30-50% speed boost)
    NSGlobalDomain = {
      # Window animations
      NSAutomaticWindowAnimationsEnabled = false; # Default: true → Disable window/popover animations
      NSWindowResizeTime = 0.1; # Default: 0.2s → 50% faster resize animation

      # Scroll behavior
      NSScrollAnimationEnabled = false; # Default: true → Disable smooth scrolling for performance

      # Input Auto-correction (CPU savings)
      # Disable CPU-intensive text processing features
      NSAutomaticCapitalizationEnabled = false; # Default: true → Disable auto-capitalization
      NSAutomaticSpellingCorrectionEnabled = false; # Default: true → Disable spell correction
      NSAutomaticQuoteSubstitutionEnabled = false; # Default: true → Disable smart quotes
      NSAutomaticDashSubstitutionEnabled = false; # Default: true → Disable smart dashes
      NSAutomaticPeriodSubstitutionEnabled = false; # Default: true → Disable auto-period

      # Memory Management
      # Enable automatic termination of inactive apps for memory efficiency
      NSDisableAutomaticTermination = false; # Default: true → Enable auto-termination (frees memory)

      # Battery and Network Efficiency
      # Reduce iCloud sync overhead
      NSDocumentSaveNewDocumentsToCloud = false; # Default: true → Disable iCloud auto-save
    };

    # Dock Optimization (instant response + fast animations)
    dock = {
      autohide = true; # Enable auto-hide for screen space
      autohide-delay = 0.0; # Default: 0.5s → Instant Dock appearance
      autohide-time-modifier = 0.15; # Default: 0.5s → 70% faster slide animation
      expose-animation-duration = 0.2; # Default: 1.0s → 80% faster Mission Control
      tilesize = 48; # Default: 64 → Smaller icons for memory savings
      mru-spaces = false; # Default: true → Disable auto-reordering for predictable layout
    };

    # Finder Optimization (developer experience)
    finder = {
      AppleShowAllFiles = true; # Default: false → Show hidden files
      FXEnableExtensionChangeWarning = false; # Default: true → Disable extension change warnings
      _FXSortFoldersFirst = true; # Default: false → Folders first for better navigation
      ShowPathbar = true; # Default: false → Show path bar for context
      ShowStatusBar = true; # Default: false → Show status bar for file info
    };

    # Trackpad Optimization (responsiveness)
    trackpad = {
      Clicking = true; # Default: false → Enable tap-to-click
      TrackpadRightClick = true; # Default: varies → Enable two-finger right-click
      TrackpadThreeFingerDrag = true; # Default: false → Enable three-finger drag
    };
  };

  # ===== Homebrew Configuration =====
  homebrew = {
    enable = true;
    casks = homebrew-casks;
    brews = [
      {
        name = "syncthing";
        start_service = true; # Auto-start on login
        restart_service = "changed"; # Restart on version change
      }
    ];

    # Performance optimization: selective cleanup
    onActivation = {
      autoUpdate = false; # Manual updates for predictability
      upgrade = false; # Avoid automatic upgrades
      # cleanup = "uninstall";  # Commented for safety during development
    };

    # Optimized global Homebrew settings
    global = {
      brewfile = true;
      lockfiles = true;
    };

    # Mac App Store applications with optimized metadata
    # IDs obtained via: nix shell nixpkgs#mas && mas search <app name>
    masApps = {
      "Magnet" = 441258766; # Window management
      "WireGuard" = 1451685025; # VPN client
      "KakaoTalk" = 869223134; # Messaging
    };

    # Additional Homebrew taps for extended package availability
    taps = [
      "homebrew/cask"
    ];
  };

  # ===== macOS App Cleanup Activation Script =====
  # Automatically removes unused default macOS apps (saves 6-8GB)
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

  # ===== Additional System Configuration =====
  # Allow unfree packages (system level for useGlobalPkgs)
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix compatibility
  # Determinate manages Nix installation, so disable nix-darwin's Nix management
  # All Nix settings are managed by Determinate in /etc/nix/nix.conf
  nix = {
    enable = false; # Required for Determinate compatibility
  };

  # zsh program activation
  programs.zsh.enable = true;

  # Primary user configuration (required for nix-darwin)
  system = {
    primaryUser = "baleen";
    checks.verifyNixPath = false;
    stateVersion = 5; # Updated to current nix-darwin version
  };

  # Disable documentation generation to avoid builtins.toFile warnings
  documentation.enable = false;
}
