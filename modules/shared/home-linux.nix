{ config, pkgs, ... }:
{
  home.username = "testuser";
  home.homeDirectory = "/home/testuser";
  home.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
}
