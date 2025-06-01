{ config, pkgs, ... }:
{
  imports = [
    ../../../common/modules/shared/wezterm
    ../../../common/modules/shared/git
    ../../../common/modules/shared/tmux
    ../../../common/modules/shared/nvim
    ../../../common/modules/shared/act
    ../../../common/modules/shared/ssh
    ../../../common/modules/shared/1password
    ../../../common/modules/shared/zsh
    ../../../common/modules/shared/raycast
    ../../../common/modules/shared/homerow
    ../../../common/modules/shared/obsidian
    ../../../common/modules/darwin/hammerspoon
    ../../../common/modules/darwin/karabiner-elements
    ../../../common/modules/shared/syncthing
    ../../../common/modules/shared/vscode
    ../../../common/modules/darwin/application-activation.nix
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
