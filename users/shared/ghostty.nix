# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{ pkgs, ... }:

{
  # Install Ghostty package
  # Platform-specific: ghostty-bin (macOS binary) or ghostty (NixOS source build)
  # macOS: Use official binary (ghostty-bin) for better integration
  # NixOS: Use source build (ghostty) as binary is macOS-only
  home.packages = with pkgs; [
    (if pkgs.stdenv.isDarwin then ghostty-bin else ghostty)
  ];

  # Symlink Ghostty configuration
  # Pattern: XDG-compliant location (destination: ~/.config/ghostty/)
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".config/ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
    force = true;
  };
}
