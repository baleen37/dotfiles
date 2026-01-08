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
helpers.testSuite "git-configuration" [
  # Test git is enabled
  (helpers.assertTest "git-enabled" (
    gitConfig.programs.git.enable == true
  ) "Git should be enabled")

  # Test user info from lib/user-info.nix
  (helpers.assertTest "git-user-name-from-user-info" (
    gitSettings.user.name == userInfo.name
  ) "Git user name should match lib/user-info.nix")

  (helpers.assertTest "git-user-email-from-user-info" (
    gitSettings.user.email == userInfo.email
  ) "Git user email should match lib/user-info.nix")

  # Test user info values
  (helpers.assertTest "git-user-name-value" (
    gitSettings.user.name == "Jiho Lee"
  ) "Git user name should be 'Jiho Lee'")

  (helpers.assertTest "git-user-email-value" (
    gitSettings.user.email == "baleen37@gmail.com"
  ) "Git user email should be 'baleen37@gmail.com'")

  # Test Git LFS
  (helpers.assertTest "git-lfs-enabled" (
    gitConfig.programs.git.lfs.enable == true
  ) "Git LFS should be enabled")

  # Test git settings using bulk assertion helper
  (helpers.assertSettings "git-init" gitSettings.init {
    defaultBranch = "main";
  })

  (helpers.assertSettings "git-core" gitSettings.core {
    editor = "vim";
    autocrlf = "input";
    excludesFile = "~/.gitignore_global";
  })

  (helpers.assertSettings "git-pull" gitSettings.pull {
    rebase = true;
  })

  (helpers.assertSettings "git-rebase" gitSettings.rebase {
    autoStash = true;
  })

  # Test that git aliases exist
  (helpers.assertTest "git-has-aliases" (
    gitSettings.alias != null && builtins.length (builtins.attrNames gitSettings.alias) > 0
  ) "Git should have aliases configured")

  # Test git aliases using bulk assertion helper
  (helpers.assertAliases gitSettings.alias {
    st = "status";
    co = "checkout";
    br = "branch";
    ci = "commit";
    df = "diff";
    lg = "log --graph --oneline --decorate --all";
  })

  # Test gitignore patterns using bulk assertion helper
  (helpers.assertPatterns "gitignore" gitIgnores [
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
  ])
]
