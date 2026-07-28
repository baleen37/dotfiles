# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.programs.ghostty;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options.modules.programs.ghostty.enable = lib.mkEnableOption "Ghostty terminal configuration";

  config = lib.mkIf cfg.enable {
    # Install Ghostty from the official macOS binary package. Ghostty is configured
    # to use the standard xterm-256color terminal type.
    home.packages =
      with pkgs;
      lib.optional isDarwin ghostty-bin;

    # Symlink Ghostty configuration
    # Pattern: XDG-compliant location (destination: ~/.config/ghostty/)
    # Files are read-only symlinks to /nix/store (managed by Home Manager)
    home.file.".config/ghostty" = {
      source = ./.config/ghostty;
      recursive = true;
      force = true;
    };
  };
}
