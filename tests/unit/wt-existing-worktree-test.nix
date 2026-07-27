# tests/unit/wt-existing-worktree-test.nix
# Verify wt handles the "branch already used by another worktree" case by
# parsing the existing path out of git's error message and cd-ing there.
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
  value = helpers.testSuite "wt-existing-worktree" [
    (helpers.assertTest "wt-defines-existing-worktree-handler"
      (lib.hasInfix "_handle_existing_worktree" wtScript)
      "wt should define _handle_existing_worktree helper"
    )

    (helpers.assertTest "wt-parses-existing-worktree-path"
      (lib.hasInfix "already used by worktree at" wtScript)
      "wt should parse 'already used by worktree at <path>' from git error output"
    )

    (helpers.assertTest "wt-warns-on-existing-worktree"
      (lib.hasInfix "is already checked out at" wtScript)
      "wt should print a warning when the branch is already checked out elsewhere"
    )

    (helpers.assertTest "wt-cds-into-existing-worktree"
      (lib.hasInfix ''cd "$existing_worktree"'' wtScript)
      "wt should cd into the existing worktree instead of failing"
    )
  ];
}
