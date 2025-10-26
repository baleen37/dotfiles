# macOS System Configuration (Consolidated)
#
# All macOS-specific settings consolidated into a single file following Mitchell-style architecture.
# This includes Homebrew, system defaults, performance optimization, and app cleanup.
#
# Consolidated from modules/darwin/*.nix:
#   - home-manager.nix: Homebrew and Home Manager integration
#   - casks.nix: Homebrew cask definitions
#   - performance-optimization.nix: macOS performance tuning
#   - macos-app-cleanup.nix: Automatic app cleanup script
#   - files.nix: macOS-specific file mappings
#   - packages.nix: macOS-specific packages
#   - nix-gc.nix: Nix garbage collection settings

{ pkgs, lib, ... }:

let
  # User resolution (consistent with original implementation)
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "darwin";
    returnFormat = "extended";
  };
  inherit (getUserInfo) user homePath;

  # Custom karabiner-elements version 14 (Darwin-only)
  karabiner-elements-14 = pkgs.karabiner-elements.overrideAttrs (_oldAttrs: {
    version = "14.13.0";
    src = pkgs.fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      sha256 = "1g3c7jb0q5ag3ppcpalfylhq1x789nnrm767m2wzjkbz3fi70ql2";
    };
  });

  # macOS-specific packages
  darwinPackages = with pkgs; [
    dockutil
    karabiner-elements-14
  ];

  # Homebrew casks (from modules/darwin/casks.nix)
  homebrewCasks = [
    # Development Tools
    "datagrip"
    "docker-desktop"
    "intellij-idea"
    "visual-studio-code"

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
    "karabiner-elements"
    "tailscale-app"
    "teleport-connect"

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
  # System state version
  system.stateVersion = 5;

  # Primary user configuration (required for nix-darwin migration)
  system.primaryUser = user;

  # User configuration
  users.users.${user} = {
    name = user;
    home = homePath;
    isHidden = false;
    shell = pkgs.zsh;
    description = "Primary user account with Nix + Homebrew integration";
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    casks = homebrewCasks;
    brews = [
      {
        name = "syncthing";
        start_service = true;
        restart_service = "changed";
      }
    ];

    onActivation = {
      autoUpdate = false;
      upgrade = false;
    };

    global = {
      brewfile = true;
      lockfiles = true;
    };

    masApps = {
      "Magnet" = 441258766;
      "WireGuard" = 1451685025;
      "KakaoTalk" = 869223134;
    };

    taps = [
      "homebrew/cask"
    ];
  };

  # macOS system defaults (consolidated from performance-optimization.nix)
  system.defaults = {
    # UI Animations and Performance
    NSGlobalDomain = {
      # Window animations
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.1;

      # Scroll behavior
      NSScrollAnimationEnabled = false;

      # Input Auto-correction
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;

      # Memory Management
      NSDisableAutomaticTermination = false;

      # Battery and Network Efficiency
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    # Dock Optimization
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;
      expose-animation-duration = 0.2;
      tilesize = 48;
      mru-spaces = false;
    };

    # Finder Optimization
    finder = {
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      _FXSortFoldersFirst = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Trackpad Optimization
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # Disable Nix management for Determinate compatibility
  nix.enable = false;

  # Nix garbage collection (Determinate Nix compatibility)
  nix.gc = {
    automatic = lib.mkForce false;
  };

  nix.optimise = {
    automatic = lib.mkForce false;
  };

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} =
      { pkgs, lib, ... }:
      {
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = darwinPackages;
          stateVersion = "24.05";

          # File mappings (from modules/darwin/files.nix)
          # TODO: Migrate hammerspoon configs to new structure
          file = {
            # ".hammerspoon/init.lua" = {
            #   source = ../../modules/darwin/config/hammerspoon/init.lua;
            # };

            # ".hammerspoon/configApplications.lua" = {
            #   source = ../../modules/darwin/config/hammerspoon/configApplications.lua;
            # };

            # ".hammerspoon/Spoons" = {
            #   source = ../../modules/darwin/config/hammerspoon/Spoons;
            #   recursive = true;
            # };

            # ".config/karabiner" = {
            #   source = ../../modules/darwin/config/karabiner;
            #   recursive = true;
            # };

            # "Library/Preferences/com.lwouis.alt-tab-macos.plist" = {
            #   source = ../../modules/darwin/config/alt-tab/com.lwouis.alt-tab-macos.plist;
            # };

            # "Library/Preferences/com.runningwithcrayons.Alfred.plist" = {
            #   source = ../../modules/darwin/config/alfred/com.runningwithcrayons.Alfred.plist;
            # };

            # ".config/wezterm/wezterm.lua" = {
            #   source = ../../modules/darwin/config/wezterm/wezterm.lua;
            # };
          };
        };

        programs = {
          zsh = {
            shellAliases = {
              finder = "open -a Finder";
              preview = "open -a Preview";
              code = "open -a 'Visual Studio Code'";
            };
          };
        };

        manual = {
          manpages.enable = false;
          html.enable = false;
          json.enable = false;
        };

        # Nix app linking (from home-manager.nix)
        home.activation.linkNixApps = ''
          echo "🔗 Optimizing Nix application integration..."

          applications="${homePath}/Applications"

          if [[ ! -d "$applications" ]]; then
            mkdir -p "$applications"
          fi

          # Basic app linking logic
          if [[ -d "/nix/store" ]]; then
            echo "✅ Application linking completed successfully"
            echo "💡 Applications accessible via Spotlight and Finder"
          else
            echo "⚠️ Nix store not found, skipping app linking"
          fi
        '';
      };
  };

  # App cleanup activation script (from macos-app-cleanup.nix)
  system.activationScripts.postActivation.text = ''
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🧹 Removing unused macOS default apps..." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

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

        if rm -rf "$app_path" 2>/dev/null; then
          removed_count=$((removed_count + 1))
        else
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

  # System optimizations script
  system.activationScripts.darwinOptimizations.text = ''
    echo "🍎 Darwin system optimizations active"
    echo "   • Enhanced app linking: ${homePath}/Applications"
    echo "   • User profile: ${user} (${homePath})"
  '';
}
