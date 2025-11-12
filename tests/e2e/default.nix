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

  # Import individual e2e test suites
  buildSwitchTests = import ./build-switch-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  userWorkflowTests = import ./user-workflow-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  # Import VM-based build-switch tests
  buildSwitchVMTests = import ./build-switch-vm-test.nix {
    inherit lib pkgs system;
  };

  # Import Claude hooks tests
  claudeHooksTests = import ./claude-hooks-test.nix {
    inherit lib pkgs;
  };

  # Import NixOS VM tests
  nixosVmTests = import ./nixos-vm-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  # Import VM analysis tests (cross-platform compatible)
  vmAnalysisTests = import ./vm-analysis-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

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

in
{
  # Individual test suites
  inherit
    buildSwitchTests
    userWorkflowTests
    claudeHooksTests
    nixosVmTests
    vmAnalysisTests
    comprehensiveValidationTests
    freshMachineSetupTests
    environmentReplicationTests
    realProjectWorkflowTests
    ;

  # VM-based build-switch tests (실제 동작 검증)
  build-switch-vm-dry = buildSwitchVMTests.dryRunTest;
  build-switch-vm-full = buildSwitchVMTests.vmTest;
  build-switch-vm-all = buildSwitchVMTests.all;

  # Real-world scenario test runners
  fresh-machine-setup = freshMachineSetupTests;
  environment-replication = environmentReplicationTests;
  real-project-workflow = realProjectWorkflowTests;

  # Real-world scenarios only (individual VM tests)
  real-world-only = {
    "fresh-machine-setup" = freshMachineSetupTests;
    "environment-replication" = environmentReplicationTests;
    "real-project-workflow" = realProjectWorkflowTests;
  };

  # VM-only test suite for focused VM testing
  vm-only = nixosVmTests.all;

  # VM analysis test suite for cross-platform validation
  vm-analysis-only = vmAnalysisTests.all;

  # Comprehensive validation test suite
  comprehensive-only = comprehensiveValidationTests.all;
}
