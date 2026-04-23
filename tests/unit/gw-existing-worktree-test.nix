# tests/unit/gw-existing-worktree-test.nix
# Verify gw handles the "branch already used by another worktree" case by
# parsing the existing path out of git's error message and cd-ing there.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  gwScript = import ../../users/shared/zsh/gw.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "gw-existing-worktree" [
    (helpers.assertTest "gw-defines-existing-worktree-handler"
      (lib.hasInfix "_handle_existing_worktree" gwScript)
      "gw should define _handle_existing_worktree helper")

    (helpers.assertTest "gw-parses-existing-worktree-path"
      (lib.hasInfix "already used by worktree at" gwScript)
      "gw should parse 'already used by worktree at <path>' from git error output")

    (helpers.assertTest "gw-warns-on-existing-worktree"
      (lib.hasInfix "is already checked out at" gwScript)
      "gw should print a warning when the branch is already checked out elsewhere")

    (helpers.assertTest "gw-cds-into-existing-worktree"
      (lib.hasInfix ''cd "$existing_worktree"'' gwScript)
      "gw should cd into the existing worktree instead of failing")
  ];
}
