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

    # FZF_DEFAULT_OPTS carries a `--preview 'bat ... {}'` for file pickers, and
    # {} here is a worktree row rather than a filename, so the pane has to be
    # turned off explicitly rather than merely left unset.
    (helpers.assertTest "wt-picker-disables-preview" (lib.hasInfix "--no-preview" wtScript)
      "wt picker should pass --no-preview to override the global FZF_DEFAULT_OPTS preview"
    )

    (helpers.assertTest "wt-picker-sets-no-preview-command" (
      !(lib.hasInfix "--preview=" wtScript) && !(lib.hasInfix "--preview '" wtScript)
    ) "wt picker should not define a preview command of its own")

    (helpers.assertTest "wt-picker-shows-relative-paths" (lib.hasInfix ''-v root="$root"'' wtScript)
      "wt picker should shorten paths against the main root so rows stay readable"
    )

    (helpers.assertTest "wt-picker-hides-absolute-path-column" (lib.hasInfix "--with-nth=1" wtScript)
      "wt picker should hide the trailing absolute-path field it uses for the cd"
    )

    (helpers.assertTest "wt-picker-sorts-by-recency" (lib.hasInfix "-k3,3nr" wtScript)
      "wt picker should list the most recently committed worktrees first"
    )

    # Directory mtime keeps moving from build output and direnv long after the
    # work stops, so it reports "recent" for worktrees nobody has touched.
    (helpers.assertTest "wt-picker-ages-by-commit-date" (lib.hasInfix "%(committerdate:unix)" wtScript)
      "wt picker should age rows by last commit date rather than directory mtime"
    )

    (helpers.assertTest "wt-picker-reads-all-branch-dates-at-once"
      (lib.hasInfix "git for-each-ref" wtScript)
      "wt picker should batch branch dates into one for-each-ref, not a git call per worktree"
    )

    (helpers.assertTest "wt-new-subcommand" (lib.hasInfix "new)" wtScript)
      "wt new should create a randomly named worktree"
    )

    (helpers.assertTest "wt-bare-does-not-create" (lib.hasInfix "if [[ $# -eq 0 ]]" wtScript)
      "bare wt should branch on zero arguments to reach the picker"
    )
  ];
}
