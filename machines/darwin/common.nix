# machines/darwin/common.nix
{
  pkgs,
  lib,
  currentSystemName,
  currentSystemUser,
  ...
}:

{
  # Minimal system-level settings
  environment.systemPackages = with pkgs; [
    home-manager
    # `make switch` runs `nh clean all` after every switch.
    nh
  ];

  # Enable essential programs
  programs.zsh = {
    enable = true;
    # Home Manager's .zshrc runs compinit and sets the prompt; doing both here
    # too ran compinit twice and loaded a prompt theme that is then replaced.
    enableGlobalCompInit = false;
    promptInit = "";
  };

  security.sudo.extraConfig = lib.mkIf (currentSystemName == "kakaostyle-jito") ''
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/nh ^clean all --keep 3$
  '';

  # Touch ID for sudo. Non-interactive shells (Claude Code, scripts) cannot
  # answer a password prompt at all; Touch ID gives them a path that works.
  # `reattach` keeps it working inside tmux sessions.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # System state version
  system.stateVersion = 5;
}
