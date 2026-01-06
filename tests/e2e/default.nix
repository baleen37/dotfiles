# E2E Tests Entry Point
#
# End-to-end 테스트 스위트의 진입점
# 모든 e2e 테스트를 통합하고 실행

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  self ? null,
}:

let
  # Note: E2E tests are individual VM tests, not nixtest suite
  # Each test is a complete NixOS VM test

  # Import comprehensive suite validation tests
  comprehensiveValidationTests = import ./comprehensive-suite-validation-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  # Import real-world scenario tests
  freshMachineSetupTests = import ./fresh-machine-setup-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  environmentReplicationTests = import ./environment-replication-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  realProjectWorkflowTests = import ./real-project-workflow-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  buildSwitchTests = import ./build-switch-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

in
{
  # Individual test suites
  inherit
    comprehensiveValidationTests
    freshMachineSetupTests
    environmentReplicationTests
    realProjectWorkflowTests
    buildSwitchTests
    ;

  # Real-world scenario test runners
  fresh-machine-setup = freshMachineSetupTests;
  environment-replication = environmentReplicationTests;
  real-project-workflow = realProjectWorkflowTests;
  build-switch = buildSwitchTests;

  # Real-world scenarios only (individual VM tests)
  real-world-only = {
    "fresh-machine-setup" = freshMachineSetupTests;
    "environment-replication" = environmentReplicationTests;
    "real-project-workflow" = realProjectWorkflowTests;
    "build-switch" = buildSwitchTests;
  };

  # Comprehensive validation test suite
  comprehensive-only = comprehensiveValidationTests;
}
