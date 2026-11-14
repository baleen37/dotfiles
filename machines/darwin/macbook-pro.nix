{
  config,
  lib,
  currentSystemName,
  currentSystemUser,
  ...
}:
{
  imports = [
    ./common.nix
    ../../users/shared/darwin/system
  ];

  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  # switch.sh uses a filtered snapshot for local hosts and untracked modules.
  security.sudo.extraConfig = ''
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake (\.|path:(/private)?/tmp/dotfiles-source\.[A-Za-z0-9]+/source)\#${lib.escapeRegex currentSystemName}$
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/nh ^clean all --keep 3$
  '';

  homebrew.casks =
    import ../../lib/filter-darwin-casks.nix
      {
        inherit lib;
        modules = config.home-manager.users.${currentSystemUser}.modules;
      }
      [
        # Development Tools
        "herdr-app" # Herdr desktop app for terminals and coding agents
        "visual-studio-code" # Code editor (not via nix: store-path launches stamp com.apple.macl and block GC)

        # Fonts
        "font-jetbrains-mono" # JetBrains Mono font for terminal

        # Communication Tools
        "notion"
        "slack"
        "obsidian"

        # Utility Tools
        "claude"
        "karabiner-elements" # Key remapping and modification tool
        "Sanyam-G/switch/switch" # Keyboard-driven window switcher
        "orbstack" # Docker and Linux VM management
        "rustdesk" # Remote desktop
        "tailscale-app" # VPN mesh network with GUI

        # Productivity Tools
        "raycast"

        # Password Management

        # Browsers
        "google-chrome"
        "brave-browser"

        "hammerspoon"
      ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "KakaoTalk" = 869223134; # Communication platform (if needed)
  };
  homebrew.taps = [
    # switch window switcher. Homebrew 6 ignores casks from an untrusted tap.
    {
      name = "Sanyam-G/switch";
      trusted = true;
    }
  ];

  home-manager.users.${currentSystemUser} = {
    imports = [ ../../users/shared/development.nix ];
    modules.programs.hammerspoon.enable = true;
    modules.programs.karabiner.enable = true;
    modules.programs.rustdesk.enable = true;
    modules.programs.tailscale.enable = true;
    modules.programs.syncthing.enable = true;
    modules.darwin.keyboard-input.enable = true;
    modules.darwin.keyboard-input.reserveCommandSpace = builtins.any (
      c: c.name == "raycast"
    ) config.homebrew.casks;
    modules.darwin.vscode.enable = true;
  };
}
