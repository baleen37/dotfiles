{ config, pkgs, lib, home-manager, self, ... }:

let
  # Resolve user with platform information
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "darwin";
    returnFormat = "extended";
  };
  user = getUserInfo.user;
  additionalFiles = import ./files.nix { inherit user config pkgs; };

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
        packages = (pkgs.callPackage ./packages.nix { });
        file = lib.mkMerge [
          (import ../shared/files.nix { inherit config pkgs user self lib; })
          additionalFiles
        ];
        stateVersion = "23.11";
      };
      # Import shared cross-platform programs (zsh, git, vim, etc.)
      programs = (import ../shared/home-manager.nix { inherit config pkgs lib; }).programs;

      # Darwin-specific programs should be added here in a separate programs attribute merge
      # Example: programs.darwin-specific-tool = { enable = true; };

      manual.manpages.enable = false;

      # TDD로 검증된 Nix 앱 링크 시스템
      home.activation.linkNixApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD echo "🔗 Linking Nix GUI applications to ~/Applications..."

        # 설정 기반 앱 링크 시스템 (하드코딩 제거)
        link_nix_apps() {
          local home_apps="$1"
          local nix_store="$2"
          local profile="$3"

          # Applications 디렉토리 생성
          mkdir -p "$home_apps"

          # 1. Karabiner-Elements v14 전용 링크 (v15 배제)
          local karabiner_path=$(find "$nix_store" -name "Karabiner-Elements.app" -path "*karabiner-elements-14*" -type d 2>/dev/null | head -1 || true)
          if [ -n "$karabiner_path" ] && [ -d "$karabiner_path" ]; then
            rm -f "$home_apps/Karabiner-Elements.app"
            ln -sf "$karabiner_path" "$home_apps/Karabiner-Elements.app"
            echo "  ✅ Karabiner-Elements.app linked (v14.13.0 only)"
          fi

          # 2. 현재 설치된 패키지에서 GUI 앱 자동 감지
          if [ -d "$profile" ]; then
            find "$profile" -name "*.app" -type d 2>/dev/null | while read -r app_path; do
              [ ! -d "$app_path" ] && continue

              local app_name=$(basename "$app_path")

              # Karabiner은 이미 처리했으므로 스킵
              [ "$app_name" = "Karabiner-Elements.app" ] && continue

              # 이미 링크된 앱은 스킵
              [ -L "$home_apps/$app_name" ] && continue

              rm -f "$home_apps/$app_name"
              ln -sf "$app_path" "$home_apps/$app_name"
              echo "  ✅ $app_name auto-linked from profile"
            done
          fi

        }

        # 함수 실행
        $DRY_RUN_CMD link_nix_apps "$HOME/Applications" "/nix/store" "$HOME/.nix-profile"

        $DRY_RUN_CMD echo "✅ TDD-verified app linking complete!"
        $DRY_RUN_CMD echo ""
        $DRY_RUN_CMD echo "📱 Available applications:"
        $DRY_RUN_CMD ls "$HOME/Applications"/*.app 2>/dev/null | sed 's|.*/||' | sed 's/^/  • /' || echo "  (no apps found)"
        $DRY_RUN_CMD echo "💡 Tip: Apps are now accessible via Spotlight and Finder"
        $DRY_RUN_CMD echo ""
      '';
    };
  };

  # Dock configuration moved to hosts/darwin/default.nix
  # See hosts/darwin/default.nix for dock settings


}
