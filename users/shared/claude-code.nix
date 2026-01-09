# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Configuration files only - package managed in home-manager.nix
#
# NOTE: commands, agents, skills, and hooks are now managed via external plugin:
# https://github.com/baleen37/claude-plugins

{
  pkgs,
  lib,
  ...
}:

{

  # Configuration files: read-only symlinks to /nix/store (version controlled)
  home.file.".claude/statusline.sh" = {
    source = ./.config/claude/statusline.sh;
    executable = true;
    force = true;
  };

  home.file.".claude/CLAUDE.md" = {
    source = ./.config/claude/CLAUDE.md;
    force = true;
  };

  # settings.json: writable copy (always overwritten on rebuild)
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ~/.claude
    run rm -f ~/.claude/settings.json
    run cp ${./.config/claude/settings.json} ~/.claude/settings.json
  '';
}
