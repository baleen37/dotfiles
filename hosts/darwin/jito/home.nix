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
    ../../../modules/shared/homerow
  ];

  home.username = "jito";
  home.homeDirectory = "/Users/jito";
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
