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

  # Import claude-code configuration
  claudeCodeConfig = import ../../users/shared/claude-code.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract home.file configuration
  homeFiles = claudeCodeConfig.home.file;

  # Test helper to check if file configuration exists
  hasFileConfig = fileAttr: builtins.hasAttr fileAttr homeFiles;

  # Test helper to check if file configuration has force=true
  hasForceEnabled = fileAttr:
    if hasFileConfig fileAttr then
      homeFiles.${fileAttr}.force or false
    else
      false;

  # Test helper to check if file configuration is recursive
  isRecursive = fileAttr:
    if hasFileConfig fileAttr then
      homeFiles.${fileAttr}.recursive or false
    else
      false;

  # Test helper to check if file is executable
  isExecutable = fileAttr:
    if hasFileConfig fileAttr then
      homeFiles.${fileAttr}.executable or false
    else
      false;

  # Test helper to check if activation script exists
  hasActivation = name: builtins.hasAttr name (claudeCodeConfig.home.activation or { });

  # Behavioral tests: can we read the source files?
  claudeConfigDir = ../../users/shared/.config/claude;
  commandsSource = claudeConfigDir + "/commands";
  agentsSource = claudeConfigDir + "/agents";
  skillsSource = claudeConfigDir + "/skills";
  hooksSource = claudeConfigDir + "/hooks";
  statuslineSource = claudeConfigDir + "/statusline.sh";
  claudeMdSource = claudeConfigDir + "/CLAUDE.md";
  settingsSource = claudeConfigDir + "/settings.json";

  commandsDirReadable = builtins.tryEval (builtins.readDir commandsSource);
  agentsDirReadable = builtins.tryEval (builtins.readDir agentsSource);
  skillsDirReadable = builtins.tryEval (builtins.readDir skillsSource);
  hooksDirReadable = builtins.tryEval (builtins.readDir hooksSource);
  statuslineReadable = builtins.tryEval (builtins.readFile statuslineSource);
  claudeMdReadable = builtins.tryEval (builtins.readFile claudeMdSource);
  settingsReadable = builtins.tryEval (builtins.readFile settingsSource);

in
helpers.testSuite "claude-code" [
  # Test that commands directory is configured
  (helpers.assertTest "commands-dir-configured" (hasFileConfig ".claude/commands")
    "Commands directory should be configured in home.file")

  # Test that agents directory is configured
  (helpers.assertTest "agents-dir-configured" (hasFileConfig ".claude/agents")
    "Agents directory should be configured in home.file")

  # Test that skills directory is configured
  (helpers.assertTest "skills-dir-configured" (hasFileConfig ".claude/skills")
    "Skills directory should be configured in home.file")

  # Test that hooks directory is configured
  (helpers.assertTest "hooks-dir-configured" (hasFileConfig ".claude/hooks")
    "Hooks directory should be configured in home.file")

  # Test that statusline.sh is configured
  (helpers.assertTest "statusline-configured" (hasFileConfig ".claude/statusline.sh")
    "statusline.sh should be configured in home.file")

  # Test that CLAUDE.md is configured
  (helpers.assertTest "claude-md-configured" (hasFileConfig ".claude/CLAUDE.md")
    "CLAUDE.md should be configured in home.file")

  # Test that activation script for settings.json exists
  (helpers.assertTest "settings-activation-exists" (hasActivation "claudeSettings")
    "Activation script for settings.json should exist")

  # Test that commands directory has force enabled
  (helpers.assertTest "commands-force-enabled" (hasForceEnabled ".claude/commands")
    "Commands directory should have force=true to overwrite existing files")

  # Test that agents directory has force enabled
  (helpers.assertTest "agents-force-enabled" (hasForceEnabled ".claude/agents")
    "Agents directory should have force=true to overwrite existing files")

  # Test that skills directory has force enabled
  (helpers.assertTest "skills-force-enabled" (hasForceEnabled ".claude/skills")
    "Skills directory should have force=true to overwrite existing files")

  # Test that hooks directory has force enabled
  (helpers.assertTest "hooks-force-enabled" (hasForceEnabled ".claude/hooks")
    "Hooks directory should have force=true to overwrite existing files")

  # Test that statusline.sh has force enabled
  (helpers.assertTest "statusline-force-enabled" (hasForceEnabled ".claude/statusline.sh")
    "statusline.sh should have force=true to overwrite existing files")

  # Test that CLAUDE.md has force enabled
  (helpers.assertTest "claude-md-force-enabled" (hasForceEnabled ".claude/CLAUDE.md")
    "CLAUDE.md should have force=true to overwrite existing files")

  # Test that commands directory is recursive
  (helpers.assertTest "commands-recursive" (isRecursive ".claude/commands")
    "Commands directory should be recursive to copy all commands")

  # Test that agents directory is recursive
  (helpers.assertTest "agents-recursive" (isRecursive ".claude/agents")
    "Agents directory should be recursive to copy all agents")

  # Test that skills directory is recursive
  (helpers.assertTest "skills-recursive" (isRecursive ".claude/skills")
    "Skills directory should be recursive to copy all skills")

  # Test that hooks directory is recursive
  (helpers.assertTest "hooks-recursive" (isRecursive ".claude/hooks")
    "Hooks directory should be recursive to copy all hooks")

  # Test that statusline.sh is executable
  (helpers.assertTest "statusline-executable" (isExecutable ".claude/statusline.sh")
    "statusline.sh should be marked as executable")

  # Behavioral test: commands directory is readable
  (helpers.assertTest "commands-dir-readable" commandsDirReadable.success
    "Commands source directory should be readable")

  # Behavioral test: commands directory has files
  (helpers.assertTest "commands-dir-has-files"
    (commandsDirReadable.success && builtins.length (builtins.attrNames commandsDirReadable.value) > 0)
    "Commands source directory should contain files")

  # Behavioral test: agents directory is readable
  (helpers.assertTest "agents-dir-readable" agentsDirReadable.success
    "Agents source directory should be readable")

  # Behavioral test: agents directory has files
  (helpers.assertTest "agents-dir-has-files"
    (agentsDirReadable.success && builtins.length (builtins.attrNames agentsDirReadable.value) > 0)
    "Agents source directory should contain files")

  # Behavioral test: skills directory is readable
  (helpers.assertTest "skills-dir-readable" skillsDirReadable.success
    "Skills source directory should be readable")

  # Behavioral test: skills directory has files
  (helpers.assertTest "skills-dir-has-files"
    (skillsDirReadable.success && builtins.length (builtins.attrNames skillsDirReadable.value) > 0)
    "Skills source directory should contain files")

  # Behavioral test: hooks directory is readable
  (helpers.assertTest "hooks-dir-readable" hooksDirReadable.success
    "Hooks source directory should be readable")

  # Behavioral test: hooks directory has files
  (helpers.assertTest "hooks-dir-has-files"
    (hooksDirReadable.success && builtins.length (builtins.attrNames hooksDirReadable.value) > 0)
    "Hooks source directory should contain files")

  # Behavioral test: statusline.sh is readable
  (helpers.assertTest "statusline-readable" statuslineReadable.success
    "statusline.sh source file should be readable")

  # Behavioral test: statusline.sh has content
  (helpers.assertTest "statusline-has-content"
    (statuslineReadable.success && builtins.stringLength statuslineReadable.value > 0)
    "statusline.sh source file should have content")

  # Behavioral test: CLAUDE.md is readable
  (helpers.assertTest "claude-md-readable" claudeMdReadable.success
    "CLAUDE.md source file should be readable")

  # Behavioral test: CLAUDE.md has content
  (helpers.assertTest "claude-md-has-content"
    (claudeMdReadable.success && builtins.stringLength claudeMdReadable.value > 0)
    "CLAUDE.md source file should have content")

  # Behavioral test: settings.json is readable
  (helpers.assertTest "settings-readable" settingsReadable.success
    "settings.json source file should be readable")

  # Behavioral test: settings.json has content
  (helpers.assertTest "settings-has-content"
    (settingsReadable.success && builtins.stringLength settingsReadable.value > 0)
    "settings.json source file should have content")

  # Test that home.file configuration exists
  (helpers.assertTest "home-file-exists" (homeFiles != null)
    "home.file should exist in claude-code configuration")

  # Test that home.activation configuration exists
  (helpers.assertTest "home-activation-exists" (claudeCodeConfig.home.activation != null)
    "home.activation should exist in claude-code configuration")
]
