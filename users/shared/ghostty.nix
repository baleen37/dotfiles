# users/shared/ghostty.nix
# Ghostty terminal emulator configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.config/ghostty

{ pkgs, lib, isDarwin, ... }:

{
  # Install Ghostty package
  # Note: Using ghostty-bin (official binary) instead of ghostty (source build)
  # because ghostty source build doesn't support macOS in nixpkgs.
  #
  # ghostty.terminfo (Linux) / ghostty-bin terminfo output (Darwin) is installed
  # on all platforms so that tmux and other ncurses programs can resolve the
  # xterm-ghostty TERM entry.  On Darwin, ghostty-bin already includes terminfo
  # in its outputsToInstall; we also add ghostty.terminfo explicitly on Linux so
  # that SSH sessions originating from Ghostty work correctly on remote hosts.
  home.packages =
    with pkgs;
    lib.optional isDarwin ghostty-bin
    ++ lib.optional (!isDarwin) ghostty.terminfo;

  # Make xterm-ghostty terminfo visible to ncurses-based programs (tmux, vim, etc.).
  # ncurses searches only a fixed set of paths by default:
  #   ~/.terminfo, /etc/terminfo, /lib/terminfo, /usr/share/terminfo
  # ~/.nix-profile/share/terminfo/ (where Nix package terminfo outputs land) is NOT
  # included unless TERMINFO_DIRS is set.  Without this, `tmux a` from Ghostty fails
  # with "missing or unsuitable terminal: xterm-ghostty".
  home.sessionVariables = {
    TERMINFO_DIRS = "$HOME/.nix-profile/share/terminfo";
  };

  # Symlink Ghostty configuration
  # Pattern: XDG-compliant location (destination: ~/.config/ghostty/)
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".config/ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
    force = true;
  };
}
