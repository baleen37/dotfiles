# tests/unit/wt-hook-consistency-test.nix
# The Claude Code WorktreeCreate hook runs under bash and cannot call the zsh
# `wt` function, so the path rule is necessarily written twice. Pin both copies
# to the same rule here.
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
  hookScript = builtins.readFile ../../users/shared/programs/.config/claude/setup-worktree.sh;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "wt-hook-consistency" [
    (helpers.assertTest "hook-uses-repository-worktrees-dir"
      (lib.hasInfix "$REPO_ROOT/.worktrees/" hookScript)
      "hook should place worktrees under <repo>/.worktrees/"
    )

    (helpers.assertTest "wt-uses-repository-worktrees-dir" (lib.hasInfix ".worktrees/" wtScript)
      "wt should use the same repository-local worktree root as the hook"
    )

    (helpers.assertTest "hook-resolves-main-root" (lib.hasInfix "worktree list" hookScript)
      "hook should resolve the main worktree root so it never nests worktrees"
    )

    (helpers.assertTest "hook-has-shebang" (lib.hasPrefix "#!" hookScript)
      "hook script should have a shebang"
    )
  ];
}
