# tests/unit/test-runner-test.nix
# Tests test runner functionality with filtering and performance monitoring

{ inputs, system, pkgs, lib, self }:

let
  helpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };
  runner = import ../lib/test-runner.nix { inherit pkgs lib; };

  mockTests = {
    "test-pass" = helpers.assertTestWithDetails "mock-pass" true "Should pass" null null null null;
    "test-fail" = helpers.assertTestWithDetails "mock-fail" false "Should fail" null null null null;
  };
in
{
  testRunnerBasic = runner.mkTestSuite "mock-suite" mockTests;
  testRunnerFiltered = runner.mkTestSuite "filtered-suite" mockTests { filter = "pass"; };
}
