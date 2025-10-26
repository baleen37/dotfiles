# tests/unit/git-test.nix
# Git configuration extraction tests
# Tests that git config is properly extracted from modules/ to users/baleen/git.nix
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
  gitConfigFile = ../../users/baleen/git.nix;
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
  gitEnabled = gitConfigExists && gitConfig.programs.git.enable == true;

  # Test if user settings exist
  hasUserSettings = gitConfigExists && builtins.hasAttr "user" gitConfig.programs.git.settings;

  # Test if LFS is enabled
  lfsEnabled = gitConfigExists && gitConfig.programs.git.lfs.enable == true;

  # Test if ignores exist
  hasIgnores = gitConfigExists && builtins.hasAttr "ignores" gitConfig.programs.git;

  # Test if default branch is main
  hasMainBranch = gitConfigExists && gitConfig.programs.git.settings.init.defaultBranch == "main";

  # Test if pull rebase is enabled
  pullRebaseEnabled = gitConfigExists && gitConfig.programs.git.settings.pull.rebase == true;

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
testSuite
