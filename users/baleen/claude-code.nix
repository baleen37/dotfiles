# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.claude

{ ... }:

{
  # Pattern: Custom location (destination: ~/.claude/)
  # Claude Code requires configuration in ~/.claude/ (non-XDG custom location)
  # Source organized in .config/ for consistency, symlinked to custom location
  # Files are read-only symlinks to /nix/store (managed by Home Manager)
  home.file.".claude" = {
    source = ./.config/claude;
    recursive = true;
    force = true;
  };
}
