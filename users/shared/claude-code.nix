# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Symlinks config files from dotfiles to ~/.claude

{ ... }:

{
  # Claude Code configuration directory
  # Uses ~/.claude (Claude Code's default location)
  # Files are symlinked from /nix/store (managed by Home Manager)
  home.file.".claude" = {
    source = ./.config/claude;
    recursive = true;
    force = true;
  };
}
