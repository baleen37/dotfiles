{
  config,
  lib,
  currentSystemUser,
  ...
}:
{
  imports = [
    ./common.nix
    ../../users/shared/darwin
  ];

  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  homebrew.casks =
    lib.filter
      (
        name:
        if name == "hammerspoon" then
          config.home-manager.users.${currentSystemUser}.modules.programs.hammerspoon.enable
        else if name == "karabiner-elements" then
          config.home-manager.users.${currentSystemUser}.modules.programs.karabiner.enable
        else if name == "rustdesk" then
          config.home-manager.users.${currentSystemUser}.modules.programs.rustdesk.enable
        else if name == "herdr-app" then
          config.home-manager.users.${currentSystemUser}.modules.programs.herdr.enable
        else if name == "visual-studio-code" then
          config.home-manager.users.${currentSystemUser}.modules.darwin.vscode.enable
        else
          true
      )
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
    modules.programs.baleen-toolkit.enable = true;
    modules.programs.claude-code.enable = true;
    modules.programs.codex.enable = true;
    modules.programs.docker.enable = true;
    modules.programs.git.enable = true;
    modules.programs.hammerspoon.enable = true;
    modules.programs.herdr.enable = true;
    modules.programs.karabiner.enable = true;
    modules.programs.neovim.enable = true;
    modules.programs.powerlevel10k.enable = true;
    modules.programs.rustdesk.enable = true;
    modules.programs.ssh.enable = true;
    modules.programs.syncthing.enable = true;
    modules.programs.terraform.enable = true;
    modules.programs.tmux.enable = true;
    modules.programs.vim.enable = true;
    modules.programs.yarn.enable = true;
    modules.programs.zsh.enable = true;
    modules.packages.ai.enable = true;
    modules.packages.cloud.enable = true;
    modules.packages.core.enable = true;
    modules.packages.databases.enable = true;
    modules.packages.dev.enable = true;
    modules.packages.fonts.enable = true;
    modules.packages.media.enable = true;
    modules.packages.nix-tools.enable = true;
    modules.packages.security.enable = true;
    modules.packages.ssh.enable = true;
    modules.darwin.keyboard-input.enable = true;
    modules.darwin.keyboard-input.reserveCommandSpace = builtins.any (
      c: c.name == "raycast"
    ) config.homebrew.casks;
    modules.darwin.vscode.enable = true;
  };

  security.sudo.extraConfig = ''
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/nh ^clean all --keep 3$
  '';

}
