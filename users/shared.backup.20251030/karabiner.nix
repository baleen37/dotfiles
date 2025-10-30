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
  # Pattern: XDG-compliant (destination: ~/.config/karabiner/)
  # Karabiner expects configuration in ~/.config/karabiner/ following XDG standard
  home.file.".config/karabiner/karabiner.json" = {
    source = ./.config/karabiner/karabiner.json;
    force = true;
  };
}
