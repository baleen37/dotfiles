# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Configuration files only - package managed in home-manager.nix
#
# NOTE: commands, agents, skills, and hooks are now managed via external plugin:
# https://github.com/baleen37/claude-plugins
#
# These config files (CLAUDE.md, settings.json, statusline.sh, local.md) are
# copied as real, writable files rather than read-only store symlinks, because
# Claude Code mutates them at runtime (e.g. feedbackSurveyState, plugin toggles,
# /remember). The copy only runs when the file is absent, so local edits and
# runtime writes are preserved across rebuilds. To pull dotfiles updates into an
# existing file, delete it and re-run switch.

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
      for f in CLAUDE.md local.md settings.json statusline.sh; do
        if [ ! -f ~/.claude/"$f" ]; then
          run cp ${src}/"$f" ~/.claude/"$f"
          run chmod u+w ~/.claude/"$f"
        fi
      done
      run chmod +x ~/.claude/statusline.sh
    '';
  };
}
