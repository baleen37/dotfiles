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

  # Behavioral tests: can we read the source files?
  claudeConfigDir = ../../users/shared/.config/claude;

  # Test helpers
  hasFileConfig = fileAttr: builtins.hasAttr fileAttr homeFiles;

  hasForceEnabled = fileAttr:
    if hasFileConfig fileAttr then
      homeFiles.${fileAttr}.force or false
    else
      false;

  isRecursive = fileAttr:
    if hasFileConfig fileAttr then
      homeFiles.${fileAttr}.recursive or false
    else
      false;

  isExecutable = fileAttr:
    if hasFileConfig fileAttr then
      homeFiles.${fileAttr}.executable or false
    else
      false;

  hasActivation = name: builtins.hasAttr name (claudeCodeConfig.home.activation or { });

  # Data-driven test helpers
  # Test that a file is configured in home.file
  assertFileConfigured = fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName fileAttr}-configured" (hasFileConfig fileAttr)
      "${fileAttr} should be configured in home.file";

  # Test that a file has force enabled
  assertFileForceEnabled = fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName fileAttr}-force-enabled" (hasForceEnabled fileAttr)
      "${fileAttr} should have force=true to overwrite existing files";

  # Test that a directory is recursive
  assertDirRecursive = fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName fileAttr}-recursive" (isRecursive fileAttr)
      "${fileAttr} should be recursive to copy all contents";

  # Test that a directory is readable and has files
  assertDirReadableAndHasFiles = name: sourcePath:
    let
      dirReadable = builtins.tryEval (builtins.readDir sourcePath);
    in
    [
      (helpers.assertTest "${name}-dir-readable" dirReadable.success
        "${name} source directory should be readable")
      (helpers.assertTest "${name}-dir-has-files"
        (dirReadable.success && builtins.length (builtins.attrNames dirReadable.value) > 0)
        "${name} source directory should contain files")
    ];

  # Test that a file is readable and has content
  assertFileReadableAndHasContent = name: sourcePath:
    let
      fileReadable = builtins.tryEval (builtins.readFile sourcePath);
    in
    [
      (helpers.assertTest "${name}-readable" fileReadable.success
        "${name} source file should be readable")
      (helpers.assertTest "${name}-has-content"
        (fileReadable.success && builtins.stringLength fileReadable.value > 0)
        "${name} source file should have content")
    ];

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

in
helpers.testSuite "claude-code" (
  # Configuration tests for directories
  (builtins.map assertFileConfigured directories) ++
  # Configuration tests for files
  (builtins.map assertFileConfigured files) ++
  # Activation script test for settings.json
  [
    (helpers.assertTest "settings-activation-exists" (hasActivation "claudeSettings")
      "Activation script for settings.json should exist")
  ] ++
  # Force enabled tests for directories
  (builtins.map assertFileForceEnabled directories) ++
  # Force enabled tests for files
  (builtins.map assertFileForceEnabled files) ++
  # Recursive tests for directories
  (builtins.map assertDirRecursive directories) ++
  # Executable test for statusline.sh
  [
    (helpers.assertTest "statusline-executable" (isExecutable ".claude/statusline.sh")
      "statusline.sh should be marked as executable")
  ] ++
  # Behavioral tests for directories (readable and has files)
  (assertDirReadableAndHasFiles "commands" sourcePaths.commands) ++
  (assertDirReadableAndHasFiles "agents" sourcePaths.agents) ++
  (assertDirReadableAndHasFiles "skills" sourcePaths.skills) ++
  (assertDirReadableAndHasFiles "hooks" sourcePaths.hooks) ++
  # Behavioral tests for files (readable and has content)
  (assertFileReadableAndHasContent "statusline" sourcePaths.statusline) ++
  (assertFileReadableAndHasContent "claude-md" sourcePaths.claudeMd) ++
  (assertFileReadableAndHasContent "settings" sourcePaths.settings) ++
  # Configuration integrity tests
  [
    (helpers.assertTest "home-file-exists" (homeFiles != null)
      "home.file should exist in claude-code configuration")
    (helpers.assertTest "home-activation-exists" (claudeCodeConfig.home.activation != null)
      "home.activation should exist in claude-code configuration")
  ]
)
