# tests/unit/gw-sanitization-test.nix
# Verify gw _handle_ref_conflict uses fixed-string grep to avoid regex injection
# from branch names containing metacharacters (+, ., *, etc.)
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
    (helpers.assertTest "gw-grep-uses-fixed-strings"
      (lib.hasInfix "grep -F" gwScript)
      "gw _handle_ref_conflict should use grep -F for literal branch matching")
  ];
}
