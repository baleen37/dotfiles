{ config, pkgs, ... }:
{
  imports = [
    ../../../modules/shared/wezterm
    ../../../modules/shared/git
    ../../../modules/shared/tmux
    ../../../modules/shared/nvim
    ../../../modules/shared/act
    ../../../modules/shared/ssh
    ../../../modules/shared/1password
    ../../../modules/shared/zsh
    ../../../modules/shared/raycast
    ../../../modules/shared/homerow
    ../../../modules/shared/obsidian
    ../../../modules/darwin/hammerspoon
    ../../../modules/darwin/karabiner-elements
    ../../../modules/shared/syncthing
    ../../../modules/shared/vscode
    ../../../modules/darwin/application-activation.nix
  ];

  home.username = "baleen";
  home.homeDirectory = "/Users/baleen";
  home.packages = with pkgs; [
    git
    fzf
    google-chrome
    brave
  ];
  home.file.".gitconfig".source = ../../../.gitconfig;
  home.file.".aliases".source = ../../../.aliases;
  home.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
}
