# tests/unit/gw-sanitization-test.nix
# Verify gw _handle_ref_conflict does not use grep -E with branch variable
# interpolation, which would allow regex injection from branch names
# containing metacharacters (+, ., *, etc.)
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
  value = helpers.testSuite "gw-sanitization" [
    (helpers.assertTest "gw-no-regex-branch-matching"
      (!(lib.hasInfix "grep -E" gwScript && lib.hasInfix "$branch/" gwScript))
      "gw _handle_ref_conflict should not use grep -E with branch variable (regex injection risk)")
  ];
}
