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
  claudeDir = ../../users/shared/.config/claude;

  # Basic existence checks
  claudeDirExists = builtins.pathExists claudeDir;
  claudeMdExists = builtins.pathExists (claudeDir + "/CLAUDE.md");
  settingsJsonExists = builtins.pathExists (claudeDir + "/settings.json");
  commandsDirExists = builtins.pathExists (claudeDir + "/commands");
  skillsDirExists = builtins.pathExists (claudeDir + "/skills");

  # Directory structure validation
  claudeDirContents = if claudeDirExists then builtins.readDir claudeDir else { };
  expectedDirs = [
    "commands"
    "skills"
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

      # Test that commands directory exists
      commands-dir-exists = nixtest.test "commands-dir-exists" (assertTrue commandsDirExists);

      # Test that skills directory exists
      skills-dir-exists = nixtest.test "skills-dir-exists" (assertTrue skillsDirExists);

      # Test that directory has expected structure (CLAUDE.md, settings.json, and 2 subdirs)
      directory-structure = nixtest.test "directory-structure" (
        assertTrue (
          claudeDirExists && claudeMdExists && settingsJsonExists && commandsDirExists && skillsDirExists
        )
      );
    };
  };

in
# Convert test suite to executable derivation
pkgs.runCommand "claude-test-results" { } ''
  echo "Running Claude configuration tests..."

  # Test that Claude config directory exists
  echo "Test 1: Claude directory exists..."
  ${
    if claudeDirExists then
      ''echo "✅ PASS: Claude directory exists"''
    else
      ''echo "❌ FAIL: Claude directory not found"; exit 1''
  }

  # Test that CLAUDE.md exists
  echo "Test 2: CLAUDE.md exists..."
  ${
    if claudeMdExists then
      ''echo "✅ PASS: CLAUDE.md exists"''
    else
      ''echo "❌ FAIL: CLAUDE.md not found"; exit 1''
  }

  # Test that settings.json exists
  echo "Test 3: settings.json exists..."
  ${
    if settingsJsonExists then
      ''echo "✅ PASS: settings.json exists"''
    else
      ''echo "❌ FAIL: settings.json not found"; exit 1''
  }

  # Test that commands directory exists
  echo "Test 4: commands directory exists..."
  ${
    if commandsDirExists then
      ''echo "✅ PASS: commands directory exists"''
    else
      ''echo "❌ FAIL: commands directory not found"; exit 1''
  }

  # Test that skills directory exists
  echo "Test 5: skills directory exists..."
  ${
    if skillsDirExists then
      ''echo "✅ PASS: skills directory exists"''
    else
      ''echo "❌ FAIL: skills directory not found"; exit 1''
  }

  # Test that all expected subdirectories exist
  echo "Test 6: expected subdirectories exist..."
  ${
    if hasExpectedDirs then
      ''echo "✅ PASS: All expected subdirectories exist"''
    else
      ''echo "❌ FAIL: Missing expected subdirectories"; exit 1''
  }

  # Test that directory has expected structure
  echo "Test 7: directory structure integrity..."
  ${
    if
      claudeDirExists && claudeMdExists && settingsJsonExists && commandsDirExists && skillsDirExists
    then
      ''echo "✅ PASS: Directory structure is correct"''
    else
      ''echo "❌ FAIL: Directory structure is incomplete"; exit 1''
  }

  echo "✅ All Claude configuration tests passed!"
  echo "Configuration integrity verified - all expected files and directories are present"
  touch $out
''
