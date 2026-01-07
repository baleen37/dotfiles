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

  # Priority 1: Critical system feature tests
  multiUserSupportTests = import ./multi-user-support-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  crossPlatformBuildTests = import ./cross-platform-build-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  systemFactoryValidationTests = import ./system-factory-validation-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  # Priority 2: Integration and workflow tests
  cacheConfigurationTests = import ./cache-configuration-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  toolIntegrationTests = import ./tool-integration-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  completeVmBootstrapTests = import ./complete-vm-bootstrap-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  # Priority 3: Operational and maintenance tests
  serviceManagementTests = import ./service-management-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  secretManagementTests = import ./secret-management-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  packageManagementTests = import ./package-management-test.nix {
    inherit
      lib
      pkgs
      system
      self
      ;
  };

  machineSpecificConfigTests = import ./machine-specific-config-test.nix {
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
    multiUserSupportTests
    crossPlatformBuildTests
    systemFactoryValidationTests
    cacheConfigurationTests
    toolIntegrationTests
    completeVmBootstrapTests
    serviceManagementTests
    secretManagementTests
    packageManagementTests
    machineSpecificConfigTests
    ;

  # Real-world scenario test runners
  fresh-machine-setup = freshMachineSetupTests;
  environment-replication = environmentReplicationTests;
  real-project-workflow = realProjectWorkflowTests;
  build-switch = buildSwitchTests;

  # Critical system feature test runners (Priority 1)
  multi-user-support = multiUserSupportTests;
  cross-platform-build = crossPlatformBuildTests;
  system-factory-validation = systemFactoryValidationTests;

  # Real-world scenarios only (individual VM tests)
  real-world-only = {
    "fresh-machine-setup" = freshMachineSetupTests;
    "environment-replication" = environmentReplicationTests;
    "real-project-workflow" = realProjectWorkflowTests;
    "build-switch" = buildSwitchTests;
  };

  # Critical system features only (Priority 1)
  critical-features-only = {
    "multi-user-support" = multiUserSupportTests;
    "cross-platform-build" = crossPlatformBuildTests;
    "system-factory-validation" = systemFactoryValidationTests;
  };

  # Integration and workflow tests (Priority 2)
  integration-tests = {
    "cache-configuration" = cacheConfigurationTests;
    "tool-integration" = toolIntegrationTests;
    "complete-vm-bootstrap" = completeVmBootstrapTests;
  };

  # Operational and maintenance tests (Priority 3)
  operational-tests = {
    "service-management" = serviceManagementTests;
    "secret-management" = secretManagementTests;
    "package-management" = packageManagementTests;
  };

  # Comprehensive validation test suite
  comprehensive-only = comprehensiveValidationTests.all;

  # All e2e tests combined
  all = {
    "fresh-machine-setup" = freshMachineSetupTests;
    "environment-replication" = environmentReplicationTests;
    "real-project-workflow" = realProjectWorkflowTests;
    "build-switch" = buildSwitchTests;
    "multi-user-support" = multiUserSupportTests;
    "cross-platform-build" = crossPlatformBuildTests;
    "system-factory-validation" = systemFactoryValidationTests;
    "cache-configuration" = cacheConfigurationTests;
    "tool-integration" = toolIntegrationTests;
    "complete-vm-bootstrap" = completeVmBootstrapTests;
    "service-management" = serviceManagementTests;
    "secret-management" = secretManagementTests;
    "package-management" = packageManagementTests;
    "machine-specific-config" = machineSpecificConfigTests;
  };
}
