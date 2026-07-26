# tests/unit/gw-subcommands-test.nix
# Verify gw subcommands: gw ls (list worktrees) and gw rm (remove worktree
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

  gwScript = import ../../users/shared/programs/zsh/gw.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "gw-subcommands" [
    (helpers.assertTest "gw-ls-subcommand" (lib.hasInfix "ls)" gwScript)
      "gw should handle an ls subcommand"
    )
    (helpers.assertTest "gw-ls-scans-machine-wide-gcroots"
      (lib.hasInfix "/nix/var/nix/gcroots/auto" gwScript)
      "gw ls should list worktrees machine-wide via nix-direnv gc-roots, not just the current repo"
    )
    (helpers.assertTest "gw-rm-subcommand" (lib.hasInfix "rm)" gwScript)
      "gw should handle an rm subcommand"
    )
    (helpers.assertTest "gw-rm-removes-worktree" (lib.hasInfix "git worktree remove" gwScript)
      "gw rm should remove the worktree via git worktree remove"
    )
    (helpers.assertTest "gw-rm-runs-gc-in-background" (lib.hasInfix "(nix store gc" gwScript)
      "gw rm should run nix store gc in a detached background subshell"
    )
    (helpers.assertTest "gw-create-runs-gc-in-background" (
      builtins.length (lib.splitString "(nix store gc" gwScript) >= 3
    ) "gw create path should also trigger background nix store gc (two call sites: create + rm)")
    (helpers.assertTest "gw-rm-avoids-collect-garbage-d" (
      !(lib.hasInfix "nix-collect-garbage -d" gwScript)
    ) "gw rm should not use nix-collect-garbage -d (deletes system generations, breaks rollback)")
  ];
}
