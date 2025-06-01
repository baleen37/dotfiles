{ config, pkgs, ... }:

{
  imports = [
    ./gh.nix
    ./git.nix
  ];
}
