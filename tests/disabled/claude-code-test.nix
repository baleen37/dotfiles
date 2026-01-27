# Claude Code Configuration Integration Test
#
# Tests the Claude Code configuration in users/shared/claude-code.nix
# Verifies commands, agents, skills, hooks symlinks, statusline.sh, CLAUDE.md, and settings.json.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  ...
} @ args:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  claudeHelpers = import (self + /tests/lib/claude-test-helpers.nix) { inherit pkgs lib helpers; };

  # Import claude-code configuration
  claudeCodeConfig = import ../../users/shared/claude-code.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract home.file configuration
  homeFiles = claudeCodeConfig.home.file;

  # Behavioral tests: can we read the source files?
  claudeConfigDir = ../../users/shared/.config/claude;

  # Define test data
  # Directories that should be configured, force-enabled, and recursive
  directories = [
    ".claude/commands"
    ".claude/agents"
    ".claude/skills"
    ".claude/hooks"
  ];

  # Files that should be configured and force-enabled
  files = [
    ".claude/statusline.sh"
    ".claude/CLAUDE.md"
  ];

  # Source paths for behavioral tests
  sourcePaths = {
    commands = claudeConfigDir + "/commands";
    agents = claudeConfigDir + "/agents";
    skills = claudeConfigDir + "/skills";
    hooks = claudeConfigDir + "/hooks";
    statusline = claudeConfigDir + "/statusline.sh";
    claudeMd = claudeConfigDir + "/CLAUDE.md";
    settings = claudeConfigDir + "/settings.json";
  };

  # Check if activation exists
  hasActivation = name: builtins.hasAttr name (claudeCodeConfig.home.activation or { });

in
helpers.testSuite "claude-code" (
  # Configuration tests for directories and files
  (claudeHelpers.assertClaudeFilesConfigured (directories ++ files) homeFiles) ++
  # Activation script test for settings.json
  [
    (claudeHelpers.assertClaudeActivationExists "settings-activation-exists"
      claudeCodeConfig.home.activation "claudeSettings")
  ] ++
  # Force enabled tests for directories and files
  (claudeHelpers.assertClaudeFilesForceEnabled (directories ++ files) homeFiles) ++
  # Recursive tests for directories
  (claudeHelpers.assertClaudeDirsRecursive directories homeFiles) ++
  # Executable test for statusline.sh
  [
    (claudeHelpers.assertClaudeFileExecutable "statusline-executable" homeFiles ".claude/statusline.sh")
  ] ++
  # Behavioral tests for directories (readable and has files)
  (claudeHelpers.assertClaudeDirReadableAndHasFiles "commands" sourcePaths.commands) ++
  (claudeHelpers.assertClaudeDirReadableAndHasFiles "agents" sourcePaths.agents) ++
  (claudeHelpers.assertClaudeDirReadableAndHasFiles "skills" sourcePaths.skills) ++
  (claudeHelpers.assertClaudeDirReadableAndHasFiles "hooks" sourcePaths.hooks) ++
  # Behavioral tests for files (readable and has content)
  (claudeHelpers.assertClaudeFileReadableAndHasContent "statusline" sourcePaths.statusline) ++
  (claudeHelpers.assertClaudeFileReadableAndHasContent "claude-md" sourcePaths.claudeMd) ++
  (claudeHelpers.assertClaudeFileReadableAndHasContent "settings" sourcePaths.settings) ++
  # Configuration integrity tests
  [
    (helpers.assertTest "home-file-exists" (homeFiles != null)
      "home.file should exist in claude-code configuration")
    (helpers.assertTest "home-activation-exists" (claudeCodeConfig.home.activation != null)
      "home.activation should exist in claude-code configuration")
  ]
)
