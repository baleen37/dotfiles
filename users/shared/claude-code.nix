# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Configuration files only - package managed in home-manager.nix

{
  pkgs,
  lib,
  ...
}:

{

  # Configuration files: read-only symlinks to /nix/store (version controlled)
  home.file.".claude/commands" = {
    source = ./.config/claude/commands;
    recursive = true;
    force = true;
  };

  home.file.".claude/agents" = {
    source = ./.config/claude/agents;
    recursive = true;
    force = true;
  };

  home.file.".claude/skills" = {
    source = ./.config/claude/skills;
    recursive = true;
    force = true;
  };

  home.file.".claude/hooks" = {
    source = ./.config/claude/hooks;
    recursive = true;
    force = true;
  };

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
