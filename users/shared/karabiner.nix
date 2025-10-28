# Karabiner-Elements configuration
# Manages keyboard customization settings via Home Manager
#
# Installation: Homebrew Cask (users/shared/darwin.nix)
# Configuration: Managed here via Home Manager
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/karabiner/karabiner.json".source = ./config/karabiner/karabiner.json;
}
