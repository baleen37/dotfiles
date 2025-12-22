# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager
# AGENTS.md symlinked from Claude Code's CLAUDE.md

{
  pkgs,
  lib,
  ...
}:

{
  # AGENTS.md: Symlink to CLAUDE.md for shared AI assistant instructions
  home.file.".config/opencode/AGENTS.md" = {
    source = ./.config/claude/CLAUDE.md;
    force = true;
  };
}
