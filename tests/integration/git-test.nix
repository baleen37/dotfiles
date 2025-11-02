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

  # Behavioral test: try to import and use git config
  gitConfigFile = ../../users/shared/git.nix;
  gitConfigResult = builtins.tryEval (
    import gitConfigFile {
      inherit pkgs lib;
      config = { };
    }
  );

  # Test if git config can be imported and is usable
  gitConfig = if gitConfigResult.success then gitConfigResult.value else { };
  gitConfigUsable = gitConfigResult.success;

  # Test if git is enabled (behavioral)
  gitEnabled = gitConfigUsable && gitConfig.programs.git.enable;

  # Test if user settings exist (behavioral)
  hasUserSettings = gitConfigUsable && builtins.hasAttr "user" gitConfig.programs.git.settings;

  # Test if LFS is enabled (behavioral)
  lfsEnabled = gitConfigUsable && gitConfig.programs.git.lfs.enable;

  # Test if ignores exist (behavioral)
  hasIgnores = gitConfigUsable && builtins.hasAttr "ignores" gitConfig.programs.git;

  # Test if default branch is main (behavioral)
  hasMainBranch = gitConfigUsable && gitConfig.programs.git.settings.init.defaultBranch == "main";

  # Test if pull rebase is enabled (behavioral)
  pullRebaseEnabled = gitConfigUsable && gitConfig.programs.git.settings.pull.rebase;

  # Test suite using NixTest framework
  testSuite = {
    name = "git-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that git.nix can be imported and is usable (behavioral)
      git-config-usable = nixtest.test "git-config-usable" (assertTrue gitConfigUsable);

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

  # Test that git.nix can be imported and is usable
  echo "Test 1: git.nix file is importable..."
  ${
    if gitConfigUsable then
      ''echo "✅ PASS: git.nix is importable and usable"''
    else
      ''echo "❌ FAIL: git.nix is not importable or not usable"; exit 1''
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
