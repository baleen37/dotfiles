# tests/unit/test-runner-test.nix
# Tests test runner functionality with filtering and performance monitoring

{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };
  runner = import ../lib/test-runner.nix { inherit pkgs lib; };
  mkTestSuite = runner.mkTestSuite;

  mockTests = {
    "test-pass" = pkgs.runCommand "test-pass" { } ''
      echo "Mock test passing"
      touch $out
    '';
    "test-success" = pkgs.runCommand "test-success" { } ''
      echo "Mock test success"
      touch $out
    '';
  };
in
{
  testRunnerBasic = mkTestSuite "mock-suite" mockTests {};
  testRunnerFiltered = mkTestSuite "filtered-suite" mockTests { filter = "pass"; };
}
