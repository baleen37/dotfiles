# tests/unit/wt-hook-consistency-test.nix
# The Claude Code WorktreeCreate hook runs under bash and cannot call the zsh
# `wt` function, so the path rule is necessarily written twice. Pin both copies
# to the same rule here — they drifted apart once already (the hook was still
# on the old 00000- numbering after wt moved to YYMMDD-).
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
    (helpers.assertTest "hook-uses-worktrees-dir" (lib.hasInfix ".worktrees" hookScript)
      "hook should place worktrees under .worktrees/"
    )

    (helpers.assertTest "hook-uses-date-prefix" (lib.hasInfix "date +%y%m%d" hookScript)
      "hook should use the same YYMMDD prefix as wt"
    )

    (helpers.assertTest "wt-uses-date-prefix" (lib.hasInfix "date +%y%m%d" wtScript)
      "wt should use a YYMMDD prefix (the rule the hook mirrors)"
    )

    (helpers.assertTest "hook-drops-numeric-prefix" (
      !(lib.hasInfix "%05d" hookScript)
    ) "hook should not use the old zero-padded numeric prefix")

    (helpers.assertTest "hook-resolves-main-root" (lib.hasInfix "worktree list" hookScript)
      "hook should resolve the main worktree root so it never nests worktrees"
    )

    (helpers.assertTest "hook-has-shebang" (lib.hasPrefix "#!" hookScript)
      "hook script should have a shebang"
    )
  ];
}
