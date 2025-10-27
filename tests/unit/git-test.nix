# tests/unit/git-test.nix
# Git configuration extraction tests
# Tests that git config is properly extracted from modules/ to users/shared/git.nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

  # Try to import git config (this will fail initially)
  gitConfigFile = ../../users/shared/git.nix;
  gitConfigExists = builtins.pathExists gitConfigFile;

  # Test if git config can be imported (will fail initially)
  gitConfig =
    if gitConfigExists then
      (import gitConfigFile {
        inherit pkgs lib;
        config = { };
      })
    else
      { };

  # Test if git is enabled
  gitEnabled = gitConfigExists && gitConfig.programs.git.enable;

  # Test if user settings exist
  hasUserSettings = gitConfigExists && builtins.hasAttr "user" gitConfig.programs.git.settings;

  # Test if LFS is enabled
  lfsEnabled = gitConfigExists && gitConfig.programs.git.lfs.enable;

  # Test if ignores exist
  hasIgnores = gitConfigExists && builtins.hasAttr "ignores" gitConfig.programs.git;

  # Test if default branch is main
  hasMainBranch = gitConfigExists && gitConfig.programs.git.settings.init.defaultBranch == "main";

  # Test if pull rebase is enabled
  pullRebaseEnabled = gitConfigExists && gitConfig.programs.git.settings.pull.rebase;

  # Test suite using NixTest framework
  testSuite = {
    name = "git-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that git.nix file exists (will fail initially)
      git-config-exists = nixtest.test "git-config-exists" (assertTrue gitConfigExists);

      # Test that git is enabled
      git-enabled = nixtest.test "git-enabled" (assertTrue gitEnabled);

      # Test that user settings exist
      user-settings-exist = nixtest.test "user-settings-exist" (assertTrue hasUserSettings);

      # Test that LFS is enabled
      lfs-enabled = nixtest.test "lfs-enabled" (assertTrue lfsEnabled);

      # Test that ignores exist
      ignores-exist = nixtest.test "ignores-exist" (assertTrue hasIgnores);

      # Test that default branch is main
      default-branch-main = nixtest.test "default-branch-main" (assertTrue hasMainBranch);

      # Test that pull rebase is enabled
      pull-rebase-enabled = nixtest.test "pull-rebase-enabled" (assertTrue pullRebaseEnabled);
    };
  };

in
# Convert test suite to executable derivation
pkgs.runCommand "git-test-results" { } ''
  echo "Running Git configuration tests..."

  # Test that git.nix file exists
  echo "Test 1: git.nix file exists..."
  ${
    if gitConfigExists then
      ''echo "✅ PASS: git.nix file exists"''
    else
      ''echo "❌ FAIL: git.nix file not found"; exit 1''
  }

  # Test that git is enabled
  echo "Test 2: git is enabled..."
  ${
    if gitEnabled then
      ''echo "✅ PASS: git is enabled"''
    else
      ''echo "❌ FAIL: git is not enabled"; exit 1''
  }

  # Test that user settings exist
  echo "Test 3: git user settings exist..."
  ${
    if hasUserSettings then
      ''echo "✅ PASS: git user settings exist"''
    else
      ''echo "❌ FAIL: git user settings missing"; exit 1''
  }

  # Test that LFS is enabled
  echo "Test 4: git LFS is enabled..."
  ${
    if lfsEnabled then
      ''echo "✅ PASS: git LFS is enabled"''
    else
      ''echo "❌ FAIL: git LFS is not enabled"; exit 1''
  }

  # Test that ignores exist
  echo "Test 5: git ignores exist..."
  ${
    if hasIgnores then
      ''echo "✅ PASS: git ignores exist"''
    else
      ''echo "❌ FAIL: git ignores missing"; exit 1''
  }

  # Test that default branch is main
  echo "Test 6: git default branch is main..."
  ${
    if hasMainBranch then
      ''echo "✅ PASS: git default branch is main"''
    else
      ''echo "❌ FAIL: git default branch is not main"; exit 1''
  }

  # Test that pull rebase is enabled
  echo "Test 7: git pull rebase is enabled..."
  ${
    if pullRebaseEnabled then
      ''echo "✅ PASS: git pull rebase is enabled"''
    else
      ''echo "❌ FAIL: git pull rebase is not enabled"; exit 1''
  }

  echo "✅ All Git configuration tests passed!"
  echo "Git configuration verified - all expected settings are present"
  touch $out
''
