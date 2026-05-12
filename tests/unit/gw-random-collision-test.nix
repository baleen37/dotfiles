# tests/unit/gw-random-collision-test.nix
# Verify gw retries random branch name generation when the generated name
# collides with an existing branch, and that _create_worktree returns git's
# combined output on stdout (so $(...) capture works for error parsing).
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
  value = helpers.testSuite "gw-random-collision" [
    (helpers.assertTest "gw-retries-on-random-collision"
      (lib.hasInfix ''for _attempt in'' gwScript
        && lib.hasInfix ''git rev-parse --verify "$branch_name"'' gwScript)
      "gw should retry random branch name generation if it collides with an existing branch")

    (helpers.assertTest "gw-create-worktree-emits-on-stdout"
      (!(lib.hasInfix ''echo "$error_output" >&2'' gwScript))
      "gw _create_worktree should not redirect git output to stderr; caller captures via \$(...)")

    (helpers.assertTest "gw-create-worktree-uses-2to1-redirect"
      (lib.hasInfix ''git worktree add "$worktree_dir" "$branch" 2>&1'' gwScript)
      "gw _create_worktree should merge stderr into stdout so error output is capturable")
  ];
}
