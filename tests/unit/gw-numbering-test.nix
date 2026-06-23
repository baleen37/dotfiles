# tests/unit/gw-numbering-test.nix
# Verify gw _sanitize_branch prefixes worktree directories with today's YYMMDD
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

  gwScript = import ../../users/shared/programs/zsh/gw.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "gw-date-prefix" [
    (helpers.assertTest "gw-uses-yymmdd-date-prefix" (lib.hasInfix "date +%y%m%d" gwScript)
      "gw _sanitize_branch should prefix worktree directories with today's YYMMDD date"
    )

    (helpers.assertTest "gw-builds-date-title-worktree-path"
      (lib.hasInfix ''"''${repo_root}/.worktrees/''${date_prefix}-''${1//\//-}"'' gwScript)
      "gw _sanitize_branch should build .worktrees/YYMMDD-title paths"
    )

    (helpers.assertTest "gw-does-not-scan-numeric-prefixes" (
      !(lib.hasInfix "grep -oE '^[0-9]+'" gwScript)
    ) "gw _sanitize_branch should not scan existing numeric prefixes")
  ];
}
