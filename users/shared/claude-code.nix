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

  # settings.json: initial copy only (writable after first setup)
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f ~/.claude/settings.json ]; then
      run mkdir -p ~/.claude
      run cp ${./.config/claude/settings.json} ~/.claude/settings.json
      run chmod 644 ~/.claude/settings.json
    fi
  '';
}
