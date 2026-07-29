# tests/integration/git-configuration-test.nix
#
# Covers users/shared/programs/git.nix.
#
# The single invariant worth the most here is that the identity written into
# every commit comes from lib/user-info.nix rather than being hardcoded — that is
# the whole reason user-info.nix exists. The rest are settings whose loss is
# silent: you only notice `pull.rebase` is gone after a merge commit appears.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };

  userInfo = import ../../lib/user-info.nix;

  # (lib.mkIf true {...}).content unwraps the module's conditional body.
  gitModule = import ../../users/shared/programs/git.nix {
    inherit pkgs lib;
    config = {
      modules.programs.git.enable = true;
    };
  };
  gitConfig = gitModule.config.content;

  gitSettings = gitConfig.programs.git.settings;
  gitIgnores = gitConfig.programs.git.ignores;

  expectedAliases = {
    st = "status";
    co = "checkout";
    br = "branch";
    ci = "commit";
    df = "diff";
    lg = "log --graph --oneline --decorate --all";
  };

  # Ignore patterns contain `*` and `/`, which are not legal in a store path
  # name, so test names are slugged.
  slug = lib.stringAsChars (c: if builtins.match "[a-zA-Z0-9]" c != null then c else "-");

  requiredIgnores = [
    "*.swp"
    "*.swo"
    ".DS_Store"
    ".direnv/"
    "result"
    "node_modules/"
  ];

in
helpers.testSuite "git-configuration" (
  [
    (assertions.assertAttrEquals "git-enabled" gitConfig.programs.git "enable" true null)
    (assertions.assertAttrEquals "git-lfs-enabled" gitConfig.programs.git.lfs "enable" true null)

    # The point of lib/user-info.nix: one place to change your identity.
    (helpers.assertTest "identity-comes-from-user-info" (
      gitSettings.user.name == userInfo.name && gitSettings.user.email == userInfo.email
    ) "programs.git user.name/user.email must come from lib/user-info.nix, not be hardcoded")

    (assertions.assertAttrEquals "git-core-editor" gitSettings.core "editor" "vim" null)
    # "input" keeps checkouts LF on both macOS and Linux.
    (assertions.assertAttrEquals "git-core-autocrlf" gitSettings.core "autocrlf" "input" null)
    (assertions.assertAttrEquals "git-default-branch" gitSettings.init "defaultBranch" "main" null)
    (assertions.assertAttrEquals "git-pull-rebase" gitSettings.pull "rebase" true null)
    (assertions.assertAttrEquals "git-rebase-autostash" gitSettings.rebase "autoStash" true null)
  ]
  ++ lib.mapAttrsToList (
    alias: command: assertions.assertAttrEquals "git-alias-${alias}" gitSettings.alias alias command null
  ) expectedAliases
  ++ map (
    pattern: assertions.assertListContains "gitignore-has-${slug pattern}" gitIgnores pattern null
  ) requiredIgnores
)
