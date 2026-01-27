# Git Configuration Integration Test
#
# Tests the Git configuration in users/shared/git.nix
# Verifies user info from lib/user-info.nix, Git LFS, rebase settings, and gitignore patterns.
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
  gitHelpers = import ../lib/git-test-helpers.nix {
    inherit pkgs lib;
    testHelpers = helpers;
  };

  # Import user info from lib/user-info.nix
  userInfo = import ../../lib/user-info.nix;

  # Import git configuration
  gitConfig = import ../../users/shared/git.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract git settings
  gitSettings = gitConfig.programs.git.settings;
  gitIgnores = gitConfig.programs.git.ignores;

in
gitHelpers.assertGitConfigComplete "git-configuration" gitConfig userInfo {
  st = "status";
  co = "checkout";
  br = "branch";
  ci = "commit";
  df = "diff";
  lg = "log --graph --oneline --decorate --all";
} [
  ".local/"
  "*.swp"
  "*.swo"
  "*~"
  ".vscode/"
  ".idea/"
  ".DS_Store"
  "Thumbs.db"
  "desktop.ini"
  ".direnv/"
  "result"
  "result-*"
  "node_modules/"
  ".env.local"
  ".env.*.local"
  ".serena/"
  "*.tmp"
  "*.log"
  ".cache/"
  "dist/"
  "build/"
  "target/"
  "issues/"
  "specs/"
  "plans/"
] {
  checkUserInfo = true;
  checkLFS = true;
  checkAliases = true;
  checkIgnores = true;
}
