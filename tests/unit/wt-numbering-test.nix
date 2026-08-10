# tests/unit/wt-numbering-test.nix
# Verify wt _sanitize_branch places worktrees in the repository-local .worktrees root.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  wtScript = import ../../users/shared/programs/zsh/wt.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "wt-worktree-path" [
    (helpers.assertTest "wt-builds-repository-worktree-path" (
      lib.hasInfix ".worktrees/" wtScript
      && lib.hasInfix "repo_root" wtScript
      && lib.hasInfix "1//\\//-" wtScript
    ) "wt _sanitize_branch should build <repo>/.worktrees/<branch> paths")

    (helpers.assertTest "wt-resolves-main-repository-root"
      (lib.hasInfix "git worktree list --porcelain" wtScript)
      "wt should use the main repository root in the worktree path"
    )
  ];
}
