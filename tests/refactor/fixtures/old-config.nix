# Test fixture: Old configuration example
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  system.stateVersion = "23.11";

  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
}
