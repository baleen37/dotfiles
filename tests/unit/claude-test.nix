# tests/unit/claude-test.nix
# Claude configuration integrity tests
# Tests that all Claude config files are preserved during migration
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test helpers from evantravers refactor
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

  # Path to Claude configuration
  claudeDir = ../../users/baleen/.config/claude;

  # Basic existence checks
  claudeDirExists = builtins.pathExists claudeDir;
  claudeMdExists = builtins.pathExists (claudeDir + "/CLAUDE.md");
  settingsJsonExists = builtins.pathExists (claudeDir + "/settings.json");
  skillsDirExists = builtins.pathExists (claudeDir + "/skills");
  agentsDirExists = builtins.pathExists (claudeDir + "/agents");
  commandsDirExists = builtins.pathExists (claudeDir + "/commands");
  hooksDirExists = builtins.pathExists (claudeDir + "/hooks");

  # Directory structure validation
  claudeDirContents = if claudeDirExists then builtins.readDir claudeDir else { };
  expectedDirs = [
    "skills"
    "agents"
    "commands"
    "hooks"
  ];
  hasExpectedDirs = lib.all (dir: builtins.hasAttr dir claudeDirContents) expectedDirs;

  # Test suite using NixTest framework
  testSuite = {
    name = "claude-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that Claude config directory exists
      claude-dir-exists = nixtest.test "claude-dir-exists" (assertTrue claudeDirExists);

      # Test that CLAUDE.md exists
      claude-md-exists = nixtest.test "claude-md-exists" (assertTrue claudeMdExists);

      # Test that settings.json exists
      settings-json-exists = nixtest.test "settings-json-exists" (assertTrue settingsJsonExists);

      # Test that all expected subdirectories exist
      expected-dirs-exist = nixtest.test "expected-dirs-exist" (assertTrue hasExpectedDirs);

      # Test that skills directory exists
      skills-dir-exists = nixtest.test "skills-dir-exists" (assertTrue skillsDirExists);

      # Test that agents directory exists
      agents-dir-exists = nixtest.test "agents-dir-exists" (assertTrue agentsDirExists);

      # Test that commands directory exists
      commands-dir-exists = nixtest.test "commands-dir-exists" (assertTrue commandsDirExists);

      # Test that hooks directory exists
      hooks-dir-exists = nixtest.test "hooks-dir-exists" (assertTrue hooksDirExists);

      # Test that directory has expected structure (at least CLAUDE.md, settings.json, and 4 subdirs)
      directory-structure = nixtest.test "directory-structure" (
        assertTrue (
          claudeDirExists
          && claudeMdExists
          && settingsJsonExists
          && (builtins.length (lib.attrNames claudeDirContents) >= 5)
        )
      );
    };
  };

in
testSuite
