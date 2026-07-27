# tests/unit/wt-random-collision-test.nix
# Verify wt retries random branch name generation when the generated name
# collides with an existing branch, and that _create_worktree returns git's
# combined output on stdout (so $(...) capture works for error parsing).
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
  value = helpers.testSuite "wt-random-collision" [
    (helpers.assertTest "wt-retries-on-random-collision" (
      lib.hasInfix "for _attempt in" wtScript
      && lib.hasInfix ''git rev-parse --verify "$branch_name"'' wtScript
    ) "wt should retry random branch name generation if it collides with an existing branch")

    (helpers.assertTest "wt-create-worktree-emits-on-stdout" (
      !(lib.hasInfix ''echo "$error_output" >&2'' wtScript)
    ) "wt _create_worktree should not redirect git output to stderr; caller captures via \$(...)")

    (helpers.assertTest "wt-create-worktree-uses-2to1-redirect"
      (lib.hasInfix ''git worktree add "$worktree_dir" "$branch" 2>&1'' wtScript)
      "wt _create_worktree should merge stderr into stdout so error output is capturable"
    )
  ];
}
