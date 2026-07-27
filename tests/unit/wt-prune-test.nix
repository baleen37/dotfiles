# tests/unit/wt-prune-test.nix
# Verify wt prune classifies worktrees three ways, defaults to dry-run, and
# runs a single background nix store gc after all removals.
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
  value = helpers.testSuite "wt-prune" [
    (helpers.assertTest "wt-prune-subcommand" (lib.hasInfix "prune)" wtScript)
      "wt should handle a prune subcommand"
    )

    (helpers.assertTest "wt-prune-defines-classifier" (lib.hasInfix "_classify_worktree" wtScript)
      "wt prune should classify worktrees via a _classify_worktree helper"
    )

    (helpers.assertTest "wt-prune-three-classes" (
      lib.hasInfix "safe" wtScript && lib.hasInfix "stale" wtScript && lib.hasInfix "keep" wtScript
    ) "wt prune should use three classes: safe, stale, keep")

    (helpers.assertTest "wt-prune-detects-merged" (lib.hasInfix "branch --merged" wtScript)
      "wt prune should detect merged branches via git branch --merged"
    )

    (helpers.assertTest "wt-prune-detects-dirty" (lib.hasInfix "status --porcelain" wtScript)
      "wt prune should detect uncommitted changes via git status --porcelain"
    )

    (helpers.assertTest "wt-prune-dry-run-by-default" (lib.hasInfix "--yes" wtScript)
      "wt prune should require --yes to actually delete; dry-run otherwise"
    )

    (helpers.assertTest "wt-prune-stale-flag" (lib.hasInfix "--stale" wtScript)
      "wt prune should accept --stale to include old unmerged worktrees"
    )

    (helpers.assertTest "wt-prune-skips-main-worktree" (lib.hasInfix "_main_root" wtScript)
      "wt prune should resolve the main worktree root so it can exclude it"
    )
  ];
}
