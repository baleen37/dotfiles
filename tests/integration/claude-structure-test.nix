# Claude Code Structure Integration Test
#
# Unified Nix-based test for Claude Code configuration structure.
# Replaces bash-based symlink tests with pure Nix assertions.
# Validates source structure (CI-safe, no runtime symlink checks).
#
# NOTE: Updated 2025-01-09 - Commands, agents, hooks, and skills directories
# migrated to claude-plugins repository.
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

  # Path to Claude configuration directory
  claudeDir = ../../users/shared/.config/claude;

  # Required files
  requiredFiles = [
    "CLAUDE.md"
    "settings.json"
    ".gitignore"
  ];

  # Required directories (migrated to claude-plugins repository)
  requiredDirs = [ ];

  # Individual file existence tests
  fileTests = builtins.map (fileName:
    helpers.assertTest "file-exists-${fileName}" (
      builtins.pathExists (claudeDir + "/${fileName}")
    ) "Required file ${fileName} should exist in ${claudeDir}"
  ) requiredFiles;

  # Individual directory existence tests
  dirTests = builtins.map (dirName:
    helpers.assertTest "dir-exists-${dirName}" (
      builtins.pathExists (claudeDir + "/${dirName}")
    ) "Required directory ${dirName} should exist in ${claudeDir}"
  ) requiredDirs;

in
helpers.testSuite "claude-structure" (
  # Configuration directory exists
  [
    (helpers.assertTest "claude-dir-exists" (
      builtins.pathExists claudeDir
    ) "Claude configuration directory should exist at ${claudeDir}")
  ] ++
  # All required files exist
  fileTests ++
  # All required directories exist
  dirTests
)
