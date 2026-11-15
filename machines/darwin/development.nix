# Opt-in Mac development composition. common.nix stays minimal.
{
  config,
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

  # Apps with managed settings are derived from the corresponding feature flags.
  homebrew.casks = [
    "font-jetbrains-mono"
    "notion"
    "slack"
    "obsidian"
    "claude"
    "Sanyam-G/switch/switch"
    "orbstack"
    "raycast"
    "google-chrome"
    "brave-browser"
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
