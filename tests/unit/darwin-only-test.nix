# tests/unit/darwin-only-test.nix
# Darwin-specific test to verify platform filtering works
{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
# Platform filtering - this test should only run on Darwin systems
{
  platforms = ["darwin"];
  value = helpers.testSuite "darwin-only-test" [
    # This test should only run on Darwin systems
    (helpers.assertTest "darwin-platform-check"
      pkgs.stdenv.hostPlatform.isDarwin
      "This test should only run on Darwin")

    # Test Darwin-specific functionality
    (helpers.assertTest "darwin-homebrew-works"
      pkgs.stdenv.hostPlatform.isDarwin
      "Darwin platform check should pass on Darwin systems")
  ];
}
