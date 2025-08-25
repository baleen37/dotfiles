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
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1179648</integer></array><key>type</key><string>standard</string></dict></dict>'
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '<dict><key>enabled</key><false/></dict>'

    echo "✅ Keyboard input settings configured"
    echo "📝 Changes will take effect after logout/login"
  '';

  # User-level app installation helper - 확장된 GUI 앱 링크 시스템
  appInstallHelper = pkgs.writeShellScriptBin "install-user-apps" ''
    #!/usr/bin/env bash

    echo "🔗 Installing Nix GUI applications to ~/Applications..."

    # Create user Applications directory if it doesn't exist
    mkdir -p "$HOME/Applications"

    # Helper function to link an app
    link_nix_app() {
      local app_name="$1"
      local nix_path="$2"

      if [ -d "$nix_path" ]; then
        echo "  🔗 Linking $app_name..."
        rm -f "$HOME/Applications/$app_name"
        ln -sf "$nix_path" "$HOME/Applications/$app_name"

        # Try to create alias in main /Applications if possible (non-root)
        if [ -w "/Applications" ]; then
          rm -f "/Applications/$app_name"
          ln -sf "$HOME/Applications/$app_name" "/Applications/$app_name"
          echo "     ✅ $app_name → ~/Applications + /Applications"
        else
          echo "     ✅ $app_name → ~/Applications"
        fi
      else
        echo "     ⚠️  $app_name not found at $nix_path"
      fi
    }

    # Link available GUI applications from Nix packages
    # 키보드 및 입력 도구
    link_nix_app "Karabiner-Elements.app" "${karabiner-elements-v14}/Applications/Karabiner-Elements.app"

    # 터미널 앱
    link_nix_app "WezTerm.app" "${pkgs.wezterm}/Applications/WezTerm.app"

    # 보안 및 패스워드 관리
    link_nix_app "KeePassXC.app" "${pkgs.keepassxc}/Applications/KeePassXC.app"

    # 파일 동기화 (GUI가 있는 경우에만)
    if [ -d "${pkgs.syncthing}/Applications" ]; then
      for app in "${pkgs.syncthing}/Applications"/*.app; do
        if [ -d "$app" ]; then
          link_nix_app "$(basename "$app")" "$app"
        fi
      done
    fi

    # 개발 도구 (GUI가 있는 경우)
    link_nix_app "Docker Desktop.app" "${pkgs.docker-desktop}/Applications/Docker Desktop.app" 2>/dev/null || echo "     ⚠️  Docker Desktop은 Homebrew Cask에서 설치됨"

    echo ""
    echo "✅ Nix app linking complete!"
    echo ""
    echo "📱 앱 실행 방법:"
    echo "   • Spotlight 검색: 앱 이름으로 직접 검색"
    echo "   • Finder: ~/Applications 폴더"
    echo "   • 터미널: open ~/Applications"
    echo ""
    echo "📝 참고사항:"
    if [ ! -w "/Applications" ]; then
      echo "   • /Applications 쓰기 권한 없음 (정상)"
      echo "   • 앱들은 ~/Applications에서 정상 작동"
      echo "   • Spotlight에서 검색 가능"
    else
      echo "   • /Applications에도 링크 생성됨"
    fi
    echo ""
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
