# tests/unit/gw-numbering-test.nix
# Verify gw _sanitize_branch numbers worktrees by scanning the max existing
# numeric prefix in .worktrees, not by counting `git worktree list` entries.
# Counting collides after a middle worktree is deleted.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  gwScript = import ../../users/shared/programs/zsh/gw.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "gw-numbering" [
    (helpers.assertTest "gw-scans-worktrees-dir-for-max-num"
      (lib.hasInfix ''ls "''${repo_root}/.worktrees"'' gwScript)
      "gw _sanitize_branch should list .worktrees to find the max number"
    )

    (helpers.assertTest "gw-extracts-numeric-prefix" (lib.hasInfix "grep -oE '^[0-9]+'" gwScript)
      "gw _sanitize_branch should extract the leading numeric prefix from directory names"
    )

    (helpers.assertTest "gw-does-not-count-worktree-list" (
      !(lib.hasInfix "git worktree list | tail -n +2 | wc -l" gwScript)
    ) "gw _sanitize_branch should not number by `git worktree list` count (collides after deletion)")
  ];
}
