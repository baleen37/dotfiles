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
      hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
    };
  });
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
    enable = false;  # Temporarily disabled to avoid tap conflicts
    casks = pkgs.callPackage ./casks.nix { };
    onActivation = {
      autoUpdate = false;
      upgrade = false;
    };
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
        packages = (pkgs.callPackage ./packages.nix { }) ++ [ karabiner-elements-v14 ];
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

      # Smart Claude config files management with user modification preservation
      home.activation.copyClaudeFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        import ../shared/lib/claude-activation.nix { inherit config lib self; }
      );
    };
  };

  # Dock configuration moved to hosts/darwin/default.nix
  # See hosts/darwin/default.nix for dock settings

  # Karabiner-Elements Nix Apps 연동
  system.activationScripts.karabinerNixApps = {
    text = ''
      # Nix Apps 디렉토리에 Karabiner-Elements 심볼릭 링크 생성
      mkdir -p "/Applications/Nix Apps"
      rm -f "/Applications/Nix Apps/Karabiner-Elements.app"
      ln -sf "${karabiner-elements-v14}/Applications/Karabiner-Elements.app" "/Applications/Nix Apps/Karabiner-Elements.app"

      # Launch Services 호환성을 위한 메인 Applications 링크
      rm -f "/Applications/Karabiner-Elements.app"
      ln -sf "/Applications/Nix Apps/Karabiner-Elements.app" "/Applications/Karabiner-Elements.app"
    '';
  };

}
