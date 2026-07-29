# tests/unit/wt-numbering-test.nix
# Verify wt _sanitize_branch places worktrees in the shared home worktree root.
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
    (helpers.assertTest "wt-builds-shared-worktree-path" (
      lib.hasInfix "worktrees/" wtScript
      && lib.hasInfix "repo_name" wtScript
      && lib.hasInfix "1//\\//-" wtScript
    ) "wt _sanitize_branch should build ~/worktrees/<repo>/<branch> paths")

    (helpers.assertTest "wt-derives-repo-name" (lib.hasInfix "basename \"$repo_root\"" wtScript)
      "wt should use the main repository directory name in the worktree path"
    )
  ];
}
