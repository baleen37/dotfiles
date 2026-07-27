# tests/unit/wt-subcommands-test.nix
# Verify wt subcommands: wt ls (list worktrees) and wt rm (remove worktree
# paired with background nix store gc).
# Removing a worktree alone leaves nix-direnv gc-roots in
# /nix/var/nix/gcroots/per-user/ pointing at the deleted .direnv/;
# only a subsequent GC run cleans them up and reclaims store space.
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
  value = helpers.testSuite "wt-subcommands" [
    (helpers.assertTest "wt-help-subcommand" (lib.hasInfix "help | -h | --help)" wtScript)
      "wt should accept a bare `help` word alongside -h/--help"
    )

    (helpers.assertTest "wt-ls-subcommand" (lib.hasInfix "ls)" wtScript)
      "wt should handle an ls subcommand"
    )
    (helpers.assertTest "wt-ls-scans-machine-wide-gcroots"
      (lib.hasInfix "/nix/var/nix/gcroots/auto" wtScript)
      "wt ls should list worktrees machine-wide via nix-direnv gc-roots, not just the current repo"
    )
    (helpers.assertTest "wt-rm-subcommand" (lib.hasInfix "rm)" wtScript)
      "wt should handle an rm subcommand"
    )
    (helpers.assertTest "wt-rm-removes-worktree" (lib.hasInfix "git worktree remove" wtScript)
      "wt rm should remove the worktree via git worktree remove"
    )
    (helpers.assertTest "wt-rm-runs-gc-in-background" (lib.hasInfix "(nix store gc" wtScript)
      "wt rm should run nix store gc in a detached background subshell"
    )
    (helpers.assertTest "wt-create-runs-gc-in-background"
      (builtins.length (lib.splitString "(nix store gc" wtScript) >= 4)
      "wt create path should also trigger background nix store gc (three call sites: rm + prune + create)"
    )
    (helpers.assertTest "wt-rm-avoids-collect-garbage-d" (
      !(lib.hasInfix "nix-collect-garbage -d" wtScript)
    ) "wt rm should not use nix-collect-garbage -d (deletes system generations, breaks rollback)")
  ];
}
