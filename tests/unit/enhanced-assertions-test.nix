# tests/unit/enhanced-assertions-test.nix
{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };
in
{
  test-assertTestWithDetails-pass =
    helpers.assertTestWithDetails "simple-pass" true "Should pass";

  test-assertTestWithDetails-fail =
    helpers.assertTestWithDetails "simple-fail" false "Should fail";
}
