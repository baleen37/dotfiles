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
    (helpers.assertTest "hook-uses-shared-worktrees-dir" (lib.hasInfix "$HOME/worktrees" hookScript)
      "hook should place worktrees under ~/worktrees/"
    )

    (helpers.assertTest "hook-uses-repo-name" (lib.hasInfix "basename \"$REPO_ROOT\"" hookScript)
      "hook should include the repository name in the worktree path"
    )

    (helpers.assertTest "wt-uses-shared-worktrees-dir" (lib.hasInfix "\${HOME}/worktrees" wtScript)
      "wt should use the same shared worktree root as the hook"
    )

    (helpers.assertTest "hook-resolves-main-root" (lib.hasInfix "worktree list" hookScript)
      "hook should resolve the main worktree root so it never nests worktrees"
    )

    (helpers.assertTest "hook-has-shebang" (lib.hasPrefix "#!" hookScript)
      "hook script should have a shebang"
    )
  ];
}
