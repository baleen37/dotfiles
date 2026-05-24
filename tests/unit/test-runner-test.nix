# tests/unit/test-runner-test.nix
# Tests test runner functionality with filtering and performance monitoring

{
  pkgs,
  lib,
  ...
}:

let
  runner = import ../lib/test-runner.nix { inherit pkgs lib; };
  inherit (runner) mkTestSuite;

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
  testRunnerBasic = mkTestSuite "mock-suite" mockTests { };
  testRunnerFiltered = mkTestSuite "filtered-suite" mockTests { filter = "pass"; };
}
