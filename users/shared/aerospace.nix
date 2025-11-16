# users/shared/aerospace.nix
# AeroSpace tiling window manager configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/aerospace

{ pkgs, ... }:

{
  # Install AeroSpace package
  home.packages = with pkgs; [ aerospace ];

  # Symlink AeroSpace configuration
  # Pattern: XDG-compliant location (destination: ~/.config/aerospace/aerospace.toml)
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".config/aerospace/aerospace.toml" = {
    source = ./.config/aerospace.toml;
    force = true;
  };
}
