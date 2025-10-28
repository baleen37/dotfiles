# users/shared/hammerspoon.nix
# Hammerspoon configuration

{ ... }:

{
  # Hammerspoon configuration files
  home.file.".hammerspoon" = {
    source = ./.config/hammerspoon;
    recursive = true;
    force = true;
  };
}
