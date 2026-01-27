# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{ pkgs, ... }:

{
  # Install Ghostty package
  # Note: Using ghostty-bin (official binary) instead of ghostty (source build)
  # because ghostty source build doesn't support macOS in nixpkgs
  home.packages = with pkgs; lib.optional pkgs.stdenv.hostPlatform.isDarwin ghostty-bin;

  # Symlink Ghostty configuration
  # Pattern: XDG-compliant location (destination: ~/.config/ghostty/)
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".config/ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
    force = true;
  };
}
