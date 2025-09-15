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

      # Claude 설정 활성화 (공통 라이브러리 사용)
      home.activation.setupClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        import ../shared/claude.nix {
          inherit config lib self;
          platform = "darwin";
        }
      );

      # TDD로 검증된 Nix 앱 링크 시스템 (최적화됨)
      home.activation.linkNixApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🔗 Linking Nix GUI applications to ~/Applications..."

        # 최적화된 앱 링크 라이브러리 사용 (Context7 베스트 프랙티스)
        run source "${self}/lib/nix-app-linker.sh"
        run link_nix_apps "$HOME/Applications" "/nix/store" "$HOME/.nix-profile"

        run echo "✅ TDD-verified optimized app linking complete!"
        run echo ""
        run echo "📱 Available applications:"
        run ls "$HOME/Applications"/*.app 2>/dev/null | sed 's|.*/||' | sed 's/^/  • /' || echo "  (no apps found)"
        run echo "💡 Tip: Apps are now accessible via Spotlight and Finder"
        run echo ""
      '';
    };
  };

  # Dock configuration moved to hosts/darwin/default.nix
  # See hosts/darwin/default.nix for dock settings


}
