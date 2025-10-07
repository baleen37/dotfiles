# Claude hooks binary builder
#
# Builds claude-hooks Go binary for Claude Code hook execution.
# Provides high-performance hook validation for git commits, PRs, and messages.
#
# Hooks implemented:
#   - git-commit-validator: PreToolUse validation for git commits
#   - gh-pr-validator: PreToolUse validation for GitHub PRs
#   - message-cleaner: PostToolUse message cleanup
#   - gh-pr-cleaner: PostToolUse PR description cleanup
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-10-07

{ pkgs }:

pkgs.buildGoModule {
  pname = "claude-hooks";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
  subPackages = [ "cmd/claude-hooks" ];

  meta = {
    description = "Claude Code hooks for git and GitHub operations";
    mainProgram = "claude-hooks";
  };
}
