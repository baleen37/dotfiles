# users/shared/codex.nix
# Codex configuration managed via Home Manager

{
  ...
}:

{
  # Share the same instruction file used by Claude via symlink.
  home.file.".codex/AGENTS.md" = {
    source = ./.config/claude/CLAUDE.md;
    force = true;
  };
}
