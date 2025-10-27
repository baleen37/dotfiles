# users/shared/claude-code.nix
# Claude Code configuration using symlinks
# Simplified from activation script to mkOutOfStoreSymlink

{ config, self, ... }:

{
  # Link Claude configuration directory using out-of-store symlink
  # Automatically detects dotfiles location from flake root (self.outPath)
  # Supports multiple users (baleen, jito, etc.) via shared directory
  xdg.configFile."claude" = {
    source = config.lib.file.mkOutOfStoreSymlink "${self.outPath}/users/shared/.config/claude";
    recursive = true;
    force = true;
  };
}
