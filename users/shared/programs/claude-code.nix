# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Configuration files only - package managed in home-manager.nix
#
# NOTE: commands, agents, skills, and hooks are now managed via external plugin:
# https://github.com/baleen37/claude-plugins
#
# CLAUDE.md is copied on every switch so its declarative guidance stays in sync.
# The remaining files are real, writable files rather than read-only store
# symlinks, because Claude Code mutates them at runtime (e.g.
# feedbackSurveyState and plugin toggles). They are only copied when absent so
# local edits and runtime writes are preserved across rebuilds.

{ config, lib, ... }:

let
  cfg = config.modules.programs.claude-code;
  src = ./.config/claude;
in
{
  options.modules.programs.claude-code.enable = lib.mkEnableOption "Claude Code configuration";

  config = lib.mkIf cfg.enable {
    home.activation.claudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ~/.claude
      run cp ${src}/CLAUDE.md ~/.claude/CLAUDE.md
      run chmod u+w ~/.claude/CLAUDE.md
      for f in local.md settings.json statusline.sh setup-worktree.sh; do
        if [ ! -f ~/.claude/"$f" ]; then
          run cp ${src}/"$f" ~/.claude/"$f"
          run chmod u+w ~/.claude/"$f"
        fi
      done
      run chmod +x ~/.claude/statusline.sh
      run chmod +x ~/.claude/setup-worktree.sh
    '';
  };
}
