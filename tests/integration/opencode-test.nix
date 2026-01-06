# OpenCode Configuration Integration Test
#
# Tests the OpenCode configuration in users/shared/opencode.nix
# Verifies AGENTS.md symlink, commands directory sharing, and force settings.
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

  # Import opencode configuration
  opencodeConfig = import ../../users/shared/opencode.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract home.file configuration
  homeFiles = opencodeConfig.home.file;

  # Test if AGENTS.md file is configured
  hasAgentsMd = builtins.hasAttr ".config/opencode/AGENTS.md" homeFiles;

  # Test if command directory is configured
  hasCommandDir = builtins.hasAttr ".config/opencode/command" homeFiles;

  # Test helper to check if file configuration has force=true
  hasForceEnabled = fileAttr:
    if builtins.hasAttr fileAttr homeFiles then
      homeFiles.${fileAttr}.force or false
    else
      false;

  # Test helper to check if file configuration is recursive
  isRecursive = fileAttr:
    if builtins.hasAttr fileAttr homeFiles then
      homeFiles.${fileAttr}.recursive or false
    else
      false;

  # Behavioral test: can we read the source files?
  opencodeConfigDir = ../../users/shared/.config/opencode;
  agentsMdSource = opencodeConfigDir + "/AGENTS.md";
  commandsSource = ../../users/shared/.config/claude/commands;

  agentsMdReadable = builtins.tryEval (builtins.readFile agentsMdSource);
  commandsDirReadable = builtins.tryEval (builtins.readDir commandsSource);

in
helpers.testSuite "opencode" [
  # Test that AGENTS.md is configured
  (helpers.assertTest "agents-md-configured" hasAgentsMd
    "AGENTS.md should be configured in home.file")

  # Test that command directory is configured
  (helpers.assertTest "command-dir-configured" hasCommandDir
    "Command directory should be configured in home.file")

  # Test that AGENTS.md has force enabled
  (helpers.assertTest "agents-md-force-enabled" (hasForceEnabled ".config/opencode/AGENTS.md")
    "AGENTS.md should have force=true to overwrite existing files")

  # Test that command directory has force enabled
  (helpers.assertTest "command-dir-force-enabled" (hasForceEnabled ".config/opencode/command")
    "Command directory should have force=true to overwrite existing files")

  # Test that command directory is recursive
  (helpers.assertTest "command-dir-recursive" (isRecursive ".config/opencode/command")
    "Command directory should be recursive to copy all commands")

  # Behavioral test: AGENTS.md source file is readable
  (helpers.assertTest "agents-md-source-readable" agentsMdReadable.success
    "AGENTS.md source file should be readable")

  # Behavioral test: AGENTS.md source file has content
  (helpers.assertTest "agents-md-source-has-content"
    (agentsMdReadable.success && builtins.stringLength agentsMdReadable.value > 0)
    "AGENTS.md source file should have content")

  # Behavioral test: commands directory is readable
  (helpers.assertTest "commands-dir-readable" commandsDirReadable.success
    "Commands source directory should be readable")

  # Behavioral test: commands directory has files
  (helpers.assertTest "commands-dir-has-files"
    (commandsDirReadable.success && builtins.length (builtins.attrNames commandsDirReadable.value) > 0)
    "Commands source directory should contain files")

  # Test that home.file configuration exists
  (helpers.assertTest "home-file-exists" (homeFiles != null)
    "home.file should exist in opencode configuration")
]
