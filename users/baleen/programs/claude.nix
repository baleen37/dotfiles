# Claude Code configuration
#
# Simplified Mitchell-style configuration for Claude Code IDE
#
# Features:
#   - Claude Code package installation
#   - Basic configuration setup
#   - Session-start hook for skills context injection
#
# Supported platforms: macOS (Darwin), Linux
# Packages: claude-code-nix
#
# VERSION: 1.1.0 (Added session-start hook)
# LAST UPDATED: 2025-10-26

{ pkgs, ... }:

{
  # Add Claude Code package
  home.packages = [
    pkgs.claude-code-nix
  ];

  # Basic Claude configuration (user-level)
  home.file.".claude/settings.json".text = ''
    {
      "theme": "dark",
      "autoSave": true,
      "fontSize": 14
    }
  '';

  # Project-level settings for dotfiles project
  home.file.".claude/projects/-Users-baleen-dotfiles--worktrees-mitchell-refactor/settings.json".text =
    ''
      {
        "$schema": "https://json.schemastore.org/claude-code-settings.json",
        "hooks": {
          "SessionStart": [
            {
              "hooks": [
                {
                  "type": "command",
                  "command": "bash ~/.claude/hooks/session-start"
                }
              ]
            }
          ],
          "PreToolUse": [
            {
              "matcher": "Bash",
              "hooks": [
                {
                  "type": "command",
                  "command": "claude-hooks git-commit-validator"
                }
              ]
            }
          ],
          "PostToolUse": [
            {
              "matcher": "Bash",
              "hooks": [
                {
                  "type": "command",
                  "command": "claude-hooks message-cleaner"
                }
              ]
            }
          ]
        }
      }
    '';

  home.file.".claude/CLAUDE.md".text = ''
    # Claude Configuration

    You are Claude Code, an experienced software engineer helping with dotfiles management.

    ## Guidelines
    - Follow YAGNI principle
    - Prefer simple solutions over complex ones
    - Use Mitchell-style organization when possible
    - Always verify builds work after changes
  '';

  # Session-start hook for skills context injection
  home.file.".claude/hooks/session-start" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # SessionStart hook for dotfiles project

      cat > /dev/null  # discard stdin

      set -euo pipefail

      # Determine hook directory and plugin root
      SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]:-$0}")" && pwd)"
      PLUGIN_ROOT="$(cd "''${SCRIPT_DIR}/.." && pwd)"

      # Read using-skills content
      using_skills_content=$(cat "''${PLUGIN_ROOT}/skills/using-skills/SKILL.md" 2>&1 || echo "Error reading using-skills skill")

      # Output plain text to stdout (gets added to Claude's context)
      cat <<CONTEXT
      <EXTREMELY_IMPORTANT>
      You are working in the dotfiles project.

      **The content below is from skills/using-skills/SKILL.md - your introduction to using skills:**

      ''${using_skills_content}
      </EXTREMELY_IMPORTANT>
      CONTEXT

      exit 0
    '';
  };
}
