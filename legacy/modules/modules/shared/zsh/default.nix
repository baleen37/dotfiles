{ config, pkgs, lib, ... }:

{
  programs.zsh.enable = true;
  home.file.".zshrc".source = ./.zshrc;

  # fzf integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
