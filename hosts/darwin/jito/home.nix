{ config, pkgs, ... }:
{
  imports = [
    ../../../common/modules/user-env/cli/wezterm
    ../../../common/modules/user-env/cli/git
    ../../../common/modules/user-env/cli/tmux
    ../../../common/modules/user-env/cli/nvim
    ../../../common/modules/user-env/cli/act
    ../../../common/modules/user-env/cli/ssh
    ../../../common/modules/user-env/cli/1password
    ../../../common/modules/user-env/cli/zsh
    ../../../common/modules/user-env/gui/homerow
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
