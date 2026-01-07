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

  # Test helper to check if gitignore pattern exists
  hasGitignorePattern = pattern:
    builtins.any (p: p == pattern) gitIgnores;

in
helpers.testSuite "git-configuration" [
  # Test git is enabled
  (helpers.assertTest "git-enabled" (
    gitConfig.programs.git.enable == true
  ) "Git should be enabled")

  # Test user name is imported from lib/user-info.nix
  (helpers.assertTest "git-user-name-from-user-info" (
    gitSettings.user.name == userInfo.name
  ) "Git user name should match lib/user-info.nix")

  # Test user email is imported from lib/user-info.nix
  (helpers.assertTest "git-user-email-from-user-info" (
    gitSettings.user.email == userInfo.email
  ) "Git user email should match lib/user-info.nix")

  # Test user name is "Jiho Lee"
  (helpers.assertTest "git-user-name-value" (
    gitSettings.user.name == "Jiho Lee"
  ) "Git user name should be 'Jiho Lee'")

  # Test user email is correct
  (helpers.assertTest "git-user-email-value" (
    gitSettings.user.email == "baleen37@gmail.com"
  ) "Git user email should be 'baleen37@gmail.com'")

  # Test Git LFS is enabled
  (helpers.assertTest "git-lfs-enabled" (
    gitConfig.programs.git.lfs.enable == true
  ) "Git LFS should be enabled")

  # Test default branch is "main"
  (helpers.assertTest "git-default-branch" (
    gitSettings.init.defaultBranch == "main"
  ) "Git default branch should be 'main'")

  # Test core editor is vim
  (helpers.assertTest "git-core-editor" (
    gitSettings.core.editor == "vim"
  ) "Git core editor should be 'vim'")

  # Test core autocrlf is "input"
  (helpers.assertTest "git-core-autocrlf" (
    gitSettings.core.autocrlf == "input"
  ) "Git core autocrlf should be 'input'")

  # Test core excludesFile is set
  (helpers.assertTest "git-core-excludes-file" (
    gitSettings.core.excludesFile == "~/.gitignore_global"
  ) "Git core excludesFile should be '~/.gitignore_global'")

  # Test pull rebase is enabled
  (helpers.assertTest "git-pull-rebase" (
    gitSettings.pull.rebase == true
  ) "Git pull rebase should be enabled")

  # Test rebase autoStash is enabled
  (helpers.assertTest "git-rebase-auto-stash" (
    gitSettings.rebase.autoStash == true
  ) "Git rebase autoStash should be enabled")

  # Test git aliases exist
  (helpers.assertTest "git-has-aliases" (
    gitSettings.alias != null && builtins.length (builtins.attrNames gitSettings.alias) > 0
  ) "Git should have aliases configured")

  # Test git alias 'st' exists
  (helpers.assertTest "git-alias-st" (
    gitSettings.alias.st == "status"
  ) "Git should have 'st' alias for 'status'")

  # Test git alias 'co' exists
  (helpers.assertTest "git-alias-co" (
    gitSettings.alias.co == "checkout"
  ) "Git should have 'co' alias for 'checkout'")

  # Test git alias 'br' exists
  (helpers.assertTest "git-alias-br" (
    gitSettings.alias.br == "branch"
  ) "Git should have 'br' alias for 'branch'")

  # Test git alias 'ci' exists
  (helpers.assertTest "git-alias-ci" (
    gitSettings.alias.ci == "commit"
  ) "Git should have 'ci' alias for 'commit'")

  # Test git alias 'df' exists
  (helpers.assertTest "git-alias-df" (
    gitSettings.alias.df == "diff"
  ) "Git should have 'df' alias for 'diff'")

  # Test git alias 'lg' exists
  (helpers.assertTest "git-alias-lg" (
    gitSettings.alias.lg == "log --graph --oneline --decorate --all"
  ) "Git should have 'lg' alias for 'log --graph --oneline --decorate --all'")

  # Test gitignore has .local/ pattern
  (helpers.assertTest "gitignore-has-local" (
    hasGitignorePattern ".local/"
  ) "Gitignore should include '.local/'")

  # Test gitignore has *.swp pattern
  (helpers.assertTest "gitignore-has-swp" (
    hasGitignorePattern "*.swp"
  ) "Gitignore should include '*.swp'")

  # Test gitignore has *.swo pattern
  (helpers.assertTest "gitignore-has-swo" (
    hasGitignorePattern "*.swo"
  ) "Gitignore should include '*.swo'")

  # Test gitignore has *~ pattern
  (helpers.assertTest "gitignore-has-tilde" (
    hasGitignorePattern "*~"
  ) "Gitignore should include '*~'")

  # Test gitignore has .vscode/ pattern
  (helpers.assertTest "gitignore-has-vscode" (
    hasGitignorePattern ".vscode/"
  ) "Gitignore should include '.vscode/'")

  # Test gitignore has .idea/ pattern
  (helpers.assertTest "gitignore-has-idea" (
    hasGitignorePattern ".idea/"
  ) "Gitignore should include '.idea/'")

  # Test gitignore has .DS_Store pattern
  (helpers.assertTest "gitignore-has-ds-store" (
    hasGitignorePattern ".DS_Store"
  ) "Gitignore should include '.DS_Store'")

  # Test gitignore has Thumbs.db pattern
  (helpers.assertTest "gitignore-has-thumbs-db" (
    hasGitignorePattern "Thumbs.db"
  ) "Gitignore should include 'Thumbs.db'")

  # Test gitignore has desktop.ini pattern
  (helpers.assertTest "gitignore-has-desktop-ini" (
    hasGitignorePattern "desktop.ini"
  ) "Gitignore should include 'desktop.ini'")

  # Test gitignore has .direnv/ pattern
  (helpers.assertTest "gitignore-has-direnv" (
    hasGitignorePattern ".direnv/"
  ) "Gitignore should include '.direnv/'")

  # Test gitignore has result pattern
  (helpers.assertTest "gitignore-has-result" (
    hasGitignorePattern "result"
  ) "Gitignore should include 'result'")

  # Test gitignore has result-* pattern
  (helpers.assertTest "gitignore-has-result-wildcard" (
    hasGitignorePattern "result-*"
  ) "Gitignore should include 'result-*'")

  # Test gitignore has node_modules/ pattern
  (helpers.assertTest "gitignore-has-node-modules" (
    hasGitignorePattern "node_modules/"
  ) "Gitignore should include 'node_modules/'")

  # Test gitignore has .env.local pattern
  (helpers.assertTest "gitignore-has-env-local" (
    hasGitignorePattern ".env.local"
  ) "Gitignore should include '.env.local'")

  # Test gitignore has .env.*.local pattern
  (helpers.assertTest "gitignore-has-env-wildcard-local" (
    hasGitignorePattern ".env.*.local"
  ) "Gitignore should include '.env.*.local'")

  # Test gitignore has .serena/ pattern
  (helpers.assertTest "gitignore-has-serena" (
    hasGitignorePattern ".serena/"
  ) "Gitignore should include '.serena/'")

  # Test gitignore has *.tmp pattern
  (helpers.assertTest "gitignore-has-tmp" (
    hasGitignorePattern "*.tmp"
  ) "Gitignore should include '*.tmp'")

  # Test gitignore has *.log pattern
  (helpers.assertTest "gitignore-has-log" (
    hasGitignorePattern "*.log"
  ) "Gitignore should include '*.log'")

  # Test gitignore has .cache/ pattern
  (helpers.assertTest "gitignore-has-cache" (
    hasGitignorePattern ".cache/"
  ) "Gitignore should include '.cache/'")

  # Test gitignore has dist/ pattern
  (helpers.assertTest "gitignore-has-dist" (
    hasGitignorePattern "dist/"
  ) "Gitignore should include 'dist/'")

  # Test gitignore has build/ pattern
  (helpers.assertTest "gitignore-has-build" (
    hasGitignorePattern "build/"
  ) "Gitignore should include 'build/'")

  # Test gitignore has target/ pattern
  (helpers.assertTest "gitignore-has-target" (
    hasGitignorePattern "target/"
  ) "Gitignore should include 'target/'")

  # Test gitignore has issues/ pattern
  (helpers.assertTest "gitignore-has-issues" (
    hasGitignorePattern "issues/"
  ) "Gitignore should include 'issues/'")

  # Test gitignore has specs/ pattern
  (helpers.assertTest "gitignore-has-specs" (
    hasGitignorePattern "specs/"
  ) "Gitignore should include 'specs/'")

  # Test gitignore has plans/ pattern
  (helpers.assertTest "gitignore-has-plans" (
    hasGitignorePattern "plans/"
  ) "Gitignore should include 'plans/'")
]
