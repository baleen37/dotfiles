# tests/unit/wt-picker-test.nix
# Verify bare `wt` opens an fzf picker over the current repo's worktrees
# instead of creating one, and that `wt new` still creates a random one.
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
  value = helpers.testSuite "wt-picker" [
    (helpers.assertTest "wt-defines-picker" (lib.hasInfix "_pick_worktree" wtScript)
      "wt should define a _pick_worktree helper"
    )

    (helpers.assertTest "wt-picker-uses-fzf" (lib.hasInfix "fzf" wtScript) "wt picker should use fzf")

    (helpers.assertTest "wt-picker-lists-repo-worktrees" (lib.hasInfix "git worktree list" wtScript)
      "wt picker should enumerate the current repo's worktrees"
    )

    (helpers.assertTest "wt-picker-has-preview" (lib.hasInfix "--preview" wtScript)
      "wt picker should show a preview of each worktree"
    )

    (helpers.assertTest "wt-new-subcommand" (lib.hasInfix "new)" wtScript)
      "wt new should create a randomly named worktree"
    )

    (helpers.assertTest "wt-bare-does-not-create" (lib.hasInfix "if [[ $# -eq 0 ]]" wtScript)
      "bare wt should branch on zero arguments to reach the picker"
    )
  ];
}
