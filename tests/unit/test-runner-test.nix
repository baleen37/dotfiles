# tests/unit/test-runner-test.nix
# Tests test runner functionality with filtering and performance monitoring

{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/assertions.nix { inherit pkgs lib; };
  runner = import ../lib/test-runner.nix { inherit pkgs lib; };
  mkTestSuite = runner.mkTestSuite;

  mockTests = {
    "test-pass" = pkgs.writeShellScript "test-pass" ''
      echo "Mock test passing"
      exit 0
    '';
    "test-success" = pkgs.writeShellScript "test-success" ''
      echo "Mock test success"
      exit 0
    '';
  };
in
{
  testRunnerBasic = mkTestSuite "mock-suite" mockTests {};
  testRunnerFiltered = mkTestSuite "filtered-suite" mockTests { filter = "pass"; };
}
