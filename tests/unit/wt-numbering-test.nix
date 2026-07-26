# tests/unit/wt-numbering-test.nix
# Verify wt _sanitize_branch prefixes worktree directories with today's YYMMDD
# date instead of a monotonically increasing numeric counter.
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
  value = helpers.testSuite "wt-date-prefix" [
    (helpers.assertTest "wt-uses-yymmdd-date-prefix" (lib.hasInfix "date +%y%m%d" wtScript)
      "wt _sanitize_branch should prefix worktree directories with today's YYMMDD date"
    )

    (helpers.assertTest "wt-builds-date-title-worktree-path"
      (lib.hasInfix ''"''${repo_root}/.worktrees/''${date_prefix}-''${1//\//-}"'' wtScript)
      "wt _sanitize_branch should build .worktrees/YYMMDD-title paths"
    )

    (helpers.assertTest "wt-does-not-scan-numeric-prefixes" (
      !(lib.hasInfix "grep -oE '^[0-9]+'" wtScript)
    ) "wt _sanitize_branch should not scan existing numeric prefixes")
  ];
}
