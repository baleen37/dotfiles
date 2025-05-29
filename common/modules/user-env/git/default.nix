{ config, pkgs, ... }:

{
  imports = [
    ./gh.nix
    ./git.nix
  ];

  home.packages = with pkgs; [
  ];
}
