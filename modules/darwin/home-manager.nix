{ config, pkgs, lib, home-manager, self, ... }:

let
  # Resolve user with platform information
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "darwin";
    returnFormat = "extended";
  };
  user = getUserInfo.user;
  additionalFiles = import ./files.nix { inherit user config pkgs; };

  # User-level app installation helper - Nix GUI 앱 링크 시스템
  nixAppLinker = pkgs.writeShellScriptBin "link-nix-apps" ''
    #!/usr/bin/env bash

    echo "🔗 Linking Nix GUI applications to ~/Applications..."

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
    # 터미널 앱
    link_nix_app "WezTerm.app" "${pkgs.wezterm}/Applications/WezTerm.app"

    # 보안 및 패스워드 관리
    link_nix_app "KeePassXC.app" "${pkgs.keepassxc}/Applications/KeePassXC.app"

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

  # It me
  users.users.${user} = {
    name = "${user}";
    home = getUserInfo.homePath;
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    # onActivation.cleanup = "uninstall";

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
    masApps = {
      "magnet" = 441258766;
      "wireguard" = 1451685025;
      "kakaotalk" = 869223134;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    users.${user} = { pkgs, config, lib, ... }: {

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix { }) ++ [
          nixAppLinker # 앱 링크 도구 추가
        ];
        file = lib.mkMerge [
          (import ../shared/files.nix { inherit config pkgs lib; })
          additionalFiles
        ];
        stateVersion = "23.11";

        # User-level activation script for linking Nix GUI apps
        activation.linkNixApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          echo "🔗 Running Nix app linking activation..."
          ${nixAppLinker}/bin/link-nix-apps
        '';
      };
      # Import shared cross-platform programs (zsh, git, vim, etc.)
      programs = (import ../shared/home-manager.nix { inherit config pkgs lib; }).programs;

      # Darwin-specific programs should be added here in a separate programs attribute merge
      # Example: programs.darwin-specific-tool = { enable = true; };

      manual.manpages.enable = false;

    };
  };

  # Dock configuration moved to hosts/darwin/default.nix
  # See hosts/darwin/default.nix for dock settings


}
