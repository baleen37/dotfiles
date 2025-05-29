{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    karabiner-elements
  ];
  home.file.".config/karabiner/karabiner.json".source = ./files/karabiner.json;
}
