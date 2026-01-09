# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager
# Configuration files shared with Claude Code
#
# NOTE: commands are now managed via external plugin:
# https://github.com/baleen37/claude-plugins

{
  pkgs,
  lib,
  ...
}:

{
  # AGENTS.md: Symlink to CLAUDE.md for shared AI assistant instructions
  home.file.".config/opencode/AGENTS.md" = {
    source = ./.config/opencode/AGENTS.md;
    force = true;
  };
}
