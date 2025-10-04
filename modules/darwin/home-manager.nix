# Darwin-Specific Home Manager Configuration (Optimized)
#
# macOS-specific Home Manager configuration with performance optimizations,
# Homebrew integration, and native app linking system.
#
# FEATURES:
#   - Optimized Homebrew cask management
#   - TDD-verified Nix app linking system
#   - Platform-specific user resolution
#   - Performance-enhanced file management
#
# VERSION: 2.0.0 (Phase 2 optimized)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, home-manager
, self
, ...
}:

let
  # Optimized user resolution with Darwin platform awareness
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "darwin";
    returnFormat = "extended";
  };
  user = getUserInfo.user;

  # Import platform-specific files with optimized loading
  additionalFiles = import ./files.nix { inherit user config pkgs; };

  # Import shared configuration for consistency
  sharedConfig = import ../shared/home-manager.nix { inherit config pkgs lib; };

  # Performance optimization: cache frequently used paths
  darwinPaths = {
    applications = "${getUserInfo.homePath}/Applications";
    library = "${getUserInfo.homePath}/Library";
    nixProfile = "${getUserInfo.homePath}/.nix-profile";
    nixStore = "/nix/store";
  };

in
{
  imports = [
  ];

  # Optimized user configuration with Darwin-specific settings
  users.users.${user} = {
    name = "${user}";
    home = getUserInfo.homePath;
    isHidden = false;
    shell = pkgs.zsh;
    description = "Primary user account with Nix + Homebrew integration";
  };

  # Optimized Homebrew configuration with performance settings
  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };

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
      "homebrew/cask-fonts"
      "homebrew/services"
    ];
  };

  # Enhanced Home Manager configuration with optimization
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true; # Performance: reduce evaluation overhead

    users.${user} =
      { pkgs
      , config
      , lib
      , ...
      }:
      {
        home = {
          enableNixpkgsReleaseCheck = false;

          # Optimized package management
          packages = (pkgs.callPackage ./packages.nix { });

          # Enhanced file management with optimized merging
          file = lib.mkMerge [
            (import ../shared/files.nix {
              inherit
                config
                pkgs
                user
                self
                lib
                ;
            })
            additionalFiles
          ];

          stateVersion = "23.11";
        };

        # Import optimized shared programs configuration
        programs = {
          # Darwin-specific program overrides and additions

          # Enhanced macOS terminal integration
          zsh = {
            shellAliases = {
              # macOS-specific aliases
              finder = "open -a Finder";
              preview = "open -a Preview";
              code = "open -a 'Visual Studio Code'";
            };
          };
        };

        # Performance optimization: disable man pages for faster builds
        manual.manpages.enable = false;

        # Enhanced Nix application linking with performance optimizations
        home.activation = {
          linkNixApps = ''
            echo "🔗 Optimizing Nix application integration..."

            # Performance: check if linking is needed
            if [[ ! -d "${darwinPaths.applications}" ]]; then
              mkdir -p "${darwinPaths.applications}"
            fi

            # Use optimized app linking library
            if [[ -f "${self}/lib/nix-app-linker.sh" ]]; then
              source "${self}/lib/nix-app-linker.sh"

              # Enhanced linking with error handling
              if link_nix_apps "${darwinPaths.applications}" "${darwinPaths.nixStore}" "${darwinPaths.nixProfile}"; then
                echo "✅ Application linking completed successfully"

                # Performance: only list if verbose mode
                if [[ "$${VERBOSE:-}" == "1" ]]; then
                  echo "📱 Available Nix applications:"
                  find "${darwinPaths.applications}" -name "*.app" -maxdepth 1 2>/dev/null | \
                    sed 's|.*/||; s/\.app$//; s/^/  • /' || echo "  (no apps found)"
                fi

                echo "💡 Applications accessible via Spotlight and Finder"
              else
                echo "⚠️ Application linking encountered issues (non-fatal)"
              fi
            else
              echo "⚠️ App linking library not found, skipping Nix app integration"
            fi
          '';

          # macOS-specific system optimizations
          optimizeDarwinSystem = ''
            echo "🍎 Applying macOS system optimizations..."

            # Optimize Finder performance
            defaults write com.apple.finder AppleShowAllFiles -bool false
            defaults write com.apple.finder ShowPathbar -bool true
            defaults write com.apple.finder ShowStatusBar -bool true

            # Optimize Dock performance
            defaults write com.apple.dock autohide-delay -float 0
            defaults write com.apple.dock autohide-time-modifier -float 0.5

            echo "✅ macOS optimizations applied"
          '';
        };

        # Enhanced services for macOS integration
        services = {
          # Add valid Darwin-specific Home Manager services here
        };
      };
  };

  # System-level configuration optimizations
  # Note: Dock configuration managed in hosts/darwin/default.nix for system-wide settings

  # Performance monitoring and optimization hints
  system.activationScripts.darwinOptimizations.text = ''
    echo "🍎 Darwin Home Manager optimizations active"
    echo "   • Enhanced app linking: ${darwinPaths.applications}"
    echo "   • Homebrew integration: $(brew --version 2>/dev/null | head -1 || echo 'not available')"
    echo "   • User profile: ${user} (${getUserInfo.homePath})"
  '';
}
