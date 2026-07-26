# tests/unit/wt-sanitization-test.nix
# Verify wt _handle_ref_conflict does not use grep -E with branch variable
# interpolation, which would allow regex injection from branch names
# containing metacharacters (+, ., *, etc.)
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
  value = helpers.testSuite "wt-sanitization" [
    (helpers.assertTest "wt-no-regex-branch-matching" (
      !(lib.hasInfix "grep -E" wtScript && lib.hasInfix "$branch/" wtScript)
    ) "wt _handle_ref_conflict should not use grep -E with branch variable (regex injection risk)")
  ];
}
