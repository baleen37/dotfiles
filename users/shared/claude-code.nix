# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager

{ config, lib, ... }:

{
  # Commands/Skills: read-only symlinks to /nix/store (version controlled)
  home.file.".claude/commands" = {
    source = ./.config/claude/commands;
    recursive = true;
  };

  home.file.".claude/skills" = {
    source = ./.config/claude/skills;
    recursive = true;
  };

  # settings.json: writable copy (always overwritten on rebuild)
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ~/.claude
    run cp ${./.config/claude/settings.json} ~/.claude/settings.json
  '';
}
