{ config, pkgs, lib, home-manager, self, ... }:

let
  # Resolve user from USER env var
  getUser = import ../../lib/get-user.nix { };
  user = getUser;
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
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
      "1password" = 1333542190;
      "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          (import ../shared/files.nix { inherit config pkgs user self lib; })
          additionalFiles
        ];
        stateVersion = "23.11";
      };
      programs = lib.mkMerge [
        (import ../shared/home-manager.nix { inherit config pkgs lib; })
      ];

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
      
      # Force copy Claude config files instead of symlinks
      home.activation.copyClaudeFiles = lib.hm.dag.entryAfter ["linkGeneration"] ''
        $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.claude/commands"
        
        # Function to copy symlink to real file
        copy_if_symlink() {
          local file="$1"
          if [[ -L "$file" ]]; then
            local target=$(readlink "$file")
            if [[ -n "$target" && -f "$target" ]]; then
              $DRY_RUN_CMD rm "$file"
              $DRY_RUN_CMD cp "$target" "$file"
              $DRY_RUN_CMD chmod 644 "$file"
              echo "Copied $file from symlink"
            fi
          fi
        }
        
        # Remove any existing backup files that might cause conflicts
        $DRY_RUN_CMD rm -f "${config.home.homeDirectory}/.claude"/*.bak
        $DRY_RUN_CMD rm -f "${config.home.homeDirectory}/.claude/commands"/*.bak
        
        # Copy CLAUDE.md
        copy_if_symlink "${config.home.homeDirectory}/.claude/CLAUDE.md"
        
        # Copy settings.json
        copy_if_symlink "${config.home.homeDirectory}/.claude/settings.json"
        
        # Copy command files
        for file in "${config.home.homeDirectory}/.claude/commands"/*.md; do
          [[ -e "$file" ]] && copy_if_symlink "$file"
        done
      '';
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock = {
    enable = true;
    username = user;
    entries = [
    { path = "/Applications/Slack.app/"; }
    { path = "/System/Applications/Messages.app/"; }
    { path = "/System/Applications/Facetime.app/"; }
    { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
    { path = "/System/Applications/Music.app/"; }
    { path = "/System/Applications/News.app/"; }
    { path = "/System/Applications/Photos.app/"; }
    { path = "/System/Applications/Photo Booth.app/"; }
    { path = "/System/Applications/TV.app/"; }
    { path = "/System/Applications/Home.app/"; }
    { path = "/Applications/Karabiner-Elements.app/"; }
    { path = "/Applications/Raycast.app/"; }
    { path = "/Applications/Obsidian.app/"; }
    {
      path = "${config.users.users.${user}.home}/.local/share/";
      section = "others";
      options = "--sort name --view grid --display folder";
    }
    {
      path = "${config.users.users.${user}.home}/.local/share/downloads";
      section = "others";
      options = "--sort name --view grid --display stack";
    }
  ];
  };

}
