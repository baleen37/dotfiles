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

  # Basic Claude configuration
  home.file.".claude/settings.json".text = ''
    {
      "theme": "dark",
      "autoSave": true,
      "fontSize": 14
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

      set -euo pipefail

      # Determine hook directory and plugin root
      SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]:-$0}")" && pwd)"
      PLUGIN_ROOT="$(cd "''${SCRIPT_DIR}/.." && pwd)"

      # Read using-skills content
      using_skills_content=$(cat "''${PLUGIN_ROOT}/skills/using-skills/SKILL.md" 2>&1 || echo "Error reading using-skills skill")

      # Escape outputs for JSON
      using_skills_escaped=$(echo "$using_skills_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

      # Output context injection as JSON
      cat <<EOF
      {
        "hookSpecificOutput": {
          "hookEventName": "SessionStart",
          "additionalContext": "<EXTREMELY_IMPORTANT>\nYou are working in the dotfiles project.\n\n**The content below is from skills/using-skills/SKILL.md - your introduction to using skills:**\n\n''${using_skills_escaped}\n</EXTREMELY_IMPORTANT>"
        }
      }
      EOF

      exit 0
    '';
  };
}
