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

  # statusline.sh: executable script (read-only symlink)
  home.file.".claude/statusline.sh" = {
    source = ./.config/claude/statusline.sh;
    executable = true;
  };

  # settings.json: writable copy (always overwritten on rebuild)
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ~/.claude
    run cp ${./.config/claude/settings.json} ~/.claude/settings.json
  '';

  # Claude Code plugins: automatic installation via home-manager activation
  home.activation.claudePlugins = lib.hm.dag.entryAfter [ "claudeSettings" ] ''
    # Claude Code 플러그인 자동 설치
    # 빌드할 때마다 실행되며, 이미 설치된 경우 자동으로 건너뜁니다

    CLAUDE_BIN="$(command -v claude)"
    if [ -z "$CLAUDE_BIN" ]; then
      echo "Claude Code not found, skipping plugin installation"
      exit 0
    fi

    echo "Installing Claude Code plugins..."

    # 1. Superpowers marketplace 추가
    echo "Adding superpowers marketplace..."
    $CLAUDE_BIN plugin marketplace add obra/superpowers-marketplace 2>/dev/null || echo "Superpowers marketplace already exists or failed to add"

    # 2. Superpowers 플러그인 설치
    echo "Installing superpowers plugin..."
    $CLAUDE_BIN plugin install superpowers@superpowers-marketplace 2>/dev/null || echo "Superpowers plugin already installed or failed to install"

    echo "Claude Code plugin installation completed"
  '';
}
