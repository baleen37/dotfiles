# users/baleen/claude-code.nix
# Claude Code configuration using symlinks
# Simplified from activation script to mkOutOfStoreSymlink

{ config, ... }:

{
  # Link Claude configuration directory using out-of-store symlink
  xdg.configFile."claude" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/users/baleen/.config/claude";
    recursive = true;
  };
}
