# tests/integration/git-test.nix
# Git configuration extraction tests
# Tests that git config is properly extracted from modules/ to users/shared/git.nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  nixtest ? { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

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

in
helpers.testSuite "git" [
  # Test that git.nix can be imported and is usable (behavioral)
  (helpers.assertTest "git-config-usable" gitConfigUsable "git.nix should be importable and usable")

  # Test that git is enabled
  (helpers.assertTest "git-enabled" gitEnabled "git should be enabled")

  # Test that user settings exist
  (helpers.assertTest "user-settings-exist" hasUserSettings "git user settings should exist")

  # Test that LFS is enabled
  (helpers.assertTest "lfs-enabled" lfsEnabled "git LFS should be enabled")

  # Test that ignores exist
  (helpers.assertTest "ignores-exist" hasIgnores "git ignores should exist")

  # Test that default branch is main
  (helpers.assertTest "default-branch-main" hasMainBranch "git default branch should be main")

  # Test that pull rebase is enabled
  (helpers.assertTest "pull-rebase-enabled" pullRebaseEnabled "git pull rebase should be enabled")
]
