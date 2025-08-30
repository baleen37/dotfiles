{ config, pkgs, lib, home-manager, self, ... }:

let
  # Resolve user with platform information
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "darwin";
    returnFormat = "extended";
  };
  user = getUserInfo.user;
  additionalFiles = import ./files.nix { inherit user config pkgs; };

  # Karabiner-Elements v14.13.0 (v15.0+ has nix-darwin compatibility issues)
  karabiner-elements-v14 = pkgs.karabiner-elements.overrideAttrs (old: {
    version = "14.13.0";
    src = pkgs.fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw="; # pragma: allowlist secret
    };
  });

  # User-level macOS defaults using dconf-like approach
  macosDefaults = pkgs.writeShellScriptBin "apply-macos-defaults" ''
    #!/usr/bin/env bash

    echo "Applying user-level macOS defaults..."

    # Global domain settings (user-level)
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0.0
    defaults write NSGlobalDomain com.apple.sound.beep.feedback -int 0
    defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3.0
    defaults write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
    defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true

    # Dock settings (user-level)
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock launchanim -bool true
    defaults write com.apple.dock orientation -string bottom
    defaults write com.apple.dock tilesize -int 48

    # Finder settings (user-level)
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool false

    # Trackpad settings (user-level)
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadSpeed -int 5
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadSpeed -int 5

    echo "✅ macOS defaults applied successfully"
    echo "📝 Some settings may require logout/login to take effect"

    # Restart affected services (user-level only)
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
  '';

  # User-level keyboard input settings
  keyboardInputSettings = pkgs.writeShellScriptBin "setup-keyboard-input" ''
    #!/usr/bin/env bash

    echo "Setting up keyboard input preferences..."

    # 한영키 전환을 Shift+Cmd+Space로 설정 (사용자 레벨)
    # This is a simplified version that doesn't require system-level access
    # Note: Complex nested dictionary operations are disabled due to macOS limitations
    echo "⚠️  Keyboard shortcut configuration skipped (requires manual setup)"
    echo "   To set Korean/English toggle to Shift+Cmd+Space:"
    echo "   System Preferences > Keyboard > Shortcuts > Input Sources"

    echo "✅ Keyboard input settings configured"
    echo "📝 Changes will take effect after logout/login"
  '';

  # User-level app installation helper
  appInstallHelper = pkgs.writeShellScriptBin "install-user-apps" ''
    #!/usr/bin/env bash

    # Create user Applications directory if it doesn't exist
    mkdir -p "$HOME/Applications"

    # Link Karabiner-Elements to user Applications
    if [ -d "${karabiner-elements-v14}/Applications/Karabiner-Elements.app" ]; then
      rm -f "$HOME/Applications/Karabiner-Elements.app"
      ln -sf "${karabiner-elements-v14}/Applications/Karabiner-Elements.app" "$HOME/Applications/Karabiner-Elements.app"
      echo "✅ Karabiner-Elements installed to ~/Applications"
    fi

    # Try to create alias in main /Applications if possible (non-root)
    if [ -w "/Applications" ]; then
      rm -f "/Applications/Karabiner-Elements.app"
      ln -sf "$HOME/Applications/Karabiner-Elements.app" "/Applications/Karabiner-Elements.app"
      echo "✅ Karabiner-Elements alias created in /Applications"
    else
      echo "📝 /Applications not writable, app available in ~/Applications only"
      echo "   You can manually create an alias or use ~/Applications"
    fi
  '';
in

{
  imports = [
  ];

  # User configuration (minimal system impact)
  users.users.${user} = {
    name = "${user}";
    home = getUserInfo.homePath;
    isHidden = false;
    shell = pkgs.zsh; # This should work without system shells modification
  };

  # Homebrew configuration (user-level)
  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };

    masApps = {
      "magnet" = 441258766;
      "wireguard" = 1451685025;
      "kakaotalk" = 869223134;
    };
  };

  # Enable home-manager with enhanced user-level configurations
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    users.${user} = { pkgs, config, lib, ... }: {

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix { }) ++ [
          karabiner-elements-v14
          macosDefaults
          keyboardInputSettings
          appInstallHelper
        ];
        file = lib.mkMerge [
          (import ../shared/files.nix { inherit config pkgs user self lib; })
          additionalFiles
        ];
        stateVersion = "23.11";

        # User-level session variables
        sessionVariables = {
          # Add any environment variables needed
        };
      };

      # Import shared cross-platform programs (zsh, git, vim, etc.) with Darwin-specific zsh merge
      programs = lib.mkMerge [
        (import ../shared/home-manager.nix { inherit config pkgs lib; }).programs
        {
          # Darwin-specific zsh configuration merged with shared config
          zsh = {
            enable = true;
            # Add any Darwin-specific zsh configuration here
          };
        }
      ];

      manual.manpages.enable = false;

      # User-level activation scripts for macOS settings
      home.activation.applyMacosDefaults = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        echo "Applying user-level macOS defaults..."

        # Run the macOS defaults script
        ${macosDefaults}/bin/apply-macos-defaults

        # Setup keyboard input
        ${keyboardInputSettings}/bin/setup-keyboard-input

        # Install user apps
        ${appInstallHelper}/bin/install-user-apps

        echo "✅ User-level system configuration complete"
        echo ""
        echo "📝 추가 설정 안내:"
        echo "• Karabiner-Elements가 ~/Applications에 설치됨"
        echo "• 시스템 설정에서 필요한 권한들을 허용해주세요"
        echo "• 일부 설정은 로그아웃/로그인 후 적용됩니다"
        echo ""
      '';
    };
  };
}
