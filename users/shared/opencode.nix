# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager
# Configuration files shared with Claude Code

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

  # Commands: Share Claude Code's commands
  home.file.".config/opencode/commands" = {
    source = ./.config/claude/commands;
    recursive = true;
    force = true;
  };
}
