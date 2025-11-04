# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager

{ config, lib, ... }:

{
  # Commands/Skills: read-only symlinks to /nix/store (version controlled)
  home.file.".claude/commands" = {
    source = ./.config/claude/commands;
    recursive = true;
    force = true;
  };

  home.file.".claude/skills" = {
    source = ./.config/claude/skills;
    recursive = true;
    force = true;
  };

  # statusline.sh: executable script (read-only symlink)
  home.file.".claude/statusline.sh" = {
    source = ./.config/claude/statusline.sh;
    executable = true;
    force = true;
  };

  # settings.json: writable copy (always overwritten on rebuild)
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ~/.claude
    run chmod +w ~/.claude/settings.json 2>/dev/null || true
    run cp ${./.config/claude/settings.json} ~/.claude/settings.json
  '';

  # Claude Code 플러그인 자동 설치
  # 빌드할 때마다 실행되며, 이미 설치된 경우 자동으로 건너뜁니다
  home.activation.claudePlugins = lib.hm.dag.entryAfter [ "claudeSettings" ] ''
    # Claude Code plugin auto-installation
    # Runs on every build, automatically skips if already installed

    # PATH setup for activation script environment (required in our environment)
    export PATH="/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

    CLAUDE_BIN="$(command -v claude || true)"
    if [ -z "$CLAUDE_BIN" ]; then
      noteEcho "Claude Code not found, skipping plugin installation"
      exit 0
    fi

    verboseEcho "Installing Claude Code plugins..."

    # Add marketplace (idempotent)
    noteEcho "Adding superpowers marketplace..."
    run $CLAUDE_BIN plugin marketplace add obra/superpowers-marketplace 2>/dev/null || warnEcho "Superpowers marketplace setup failed"

    # Install plugin (idempotent)
    run $CLAUDE_BIN plugin install superpowers@superpowers-marketplace 2>/dev/null || warnEcho "Superpowers plugin setup failed"

    noteEcho "Claude Code plugin installation completed"
  '';

}
