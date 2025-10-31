# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{ pkgs, ... }:

{
  # Install Ghostty package
  home.packages = with pkgs; [ ghostty ];

  # Symlink Ghostty configuration
  # Pattern: XDG-compliant location (destination: ~/.config/ghostty/)
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".config/ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
    force = true;
  };
}
