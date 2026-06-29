# users/shared/codex.nix
# Codex configuration managed via Home Manager

{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.codex;
in
{
  options.modules.programs.codex.enable = lib.mkEnableOption "Codex CLI configuration";

  config = lib.mkIf cfg.enable {
    # Share Claude's instruction file: AGENTS.md -> live ~/.claude/CLAUDE.md
    # (the writable copy managed by claude-code.nix), so both tools read the
    # same file and edits to either propagate. force overrides the symlink the
    # `me` plugin may install at runtime.
    home.file.".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/CLAUDE.md";
      force = true;
    };

    # Initial codex config copy (preserves local edits after first setup)
    home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f ~/.codex/config.toml ]; then
        run mkdir -p ~/.codex
        run cp ${./.config/codex/config.toml} ~/.codex/config.toml
        run chmod 644 ~/.codex/config.toml
      fi
    '';
  };
}
