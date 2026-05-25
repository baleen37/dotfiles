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
    # Share the same instruction file used by Claude via symlink.
  home.file.".codex/AGENTS.md" = {
    source = ./.config/claude/CLAUDE.md;
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
