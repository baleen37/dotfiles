# users/shared/hammerspoon.nix
# Hammerspoon configuration

{ ... }:

{
  # Pattern: Tool-specific home directory (destination: ~/.hammerspoon/)
  # Hammerspoon requires configuration in ~/.hammerspoon/ (non-XDG)
  # Source organized in .config/ for consistency, symlinked to custom location
  home.file.".hammerspoon" = {
    source = ./.config/hammerspoon;
    recursive = true;
    force = true;
  };
}
