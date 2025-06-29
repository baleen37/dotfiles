{ pkgs, flake ? null }:
let
  # Core tests - Essential functionality that must always work
  coreTests = {
    # Basic functionality and structure
    flake_structure = import ./unit/flake-structure-test.nix { inherit pkgs flake; lib = pkgs.lib; src = ../.; };
    module_imports = import ./unit/module-imports-unit.nix { inherit pkgs flake; src = ../.; };
    configuration_validation = import ./unit/configuration-validation-unit.nix { inherit pkgs flake; src = ../.; };

    # Critical functionality
    user_resolution = import ./unit/user-resolution-test.nix { inherit pkgs flake; src = ../.; };
    error_handling = import ./unit/error-handling-test.nix { inherit pkgs flake; src = ../.; };
    platform_detection = import ./unit/platform-detection-test.nix { inherit pkgs flake; src = ../.; };

    # Core features
    claude_config = import ./unit/claude-config-test.nix { inherit pkgs flake; src = ../.; };
    auto_update = import ./unit/auto-update-test.nix { inherit pkgs flake; src = ../.; };
    build_switch = import ./unit/build-switch-improved-unit.nix { inherit pkgs flake; src = ../.; };

    # Essential integrations
    package_availability = import ./integration/package-availability-integration.nix { inherit pkgs flake; src = ../.; };
    module_dependency = import ./integration/module-dependency-integration.nix { inherit pkgs flake; src = ../.; };
    cross_platform = import ./integration/cross-platform-integration.nix { inherit pkgs flake; src = ../.; };
  };

  # Workflow tests - End-to-end user workflows
  workflowTests = {
    # Core workflows
    system_build = import ./e2e/system-build-e2e.nix { inherit pkgs flake; src = ../.; };
    system_deployment = import ./e2e/system-deployment-e2e.nix { inherit pkgs flake; src = ../.; };
    complete_workflow = import ./e2e/complete-workflow-e2e.nix { inherit pkgs flake; src = ../.; };

    # Feature workflows
    claude_config_workflow = import ./e2e/claude-config-workflow-e2e.nix { inherit pkgs flake; src = ../.; };
    build_switch_workflow = import ./e2e/build-switch-improved-e2e.nix { inherit pkgs flake; src = ../.; };
  };

  # Performance tests - Build time and resource usage
  performanceTests = {
    build_time = import ./performance/build-time-perf.nix { inherit pkgs flake; src = ../.; };
    resource_usage = import ./performance/resource-usage-perf.nix { inherit pkgs flake; src = ../.; };
  };

  # Combine all tests
  allTests = coreTests // workflowTests // performanceTests;

  # Test metadata for reporting
  testMetadata = {
    categories = {
      core = builtins.length (builtins.attrNames coreTests);
      workflow = builtins.length (builtins.attrNames workflowTests);
      performance = builtins.length (builtins.attrNames performanceTests);
    };
    total = builtins.length (builtins.attrNames allTests);
  };

  # Framework status report
  frameworkStatus = pkgs.runCommand "test-framework-status" { } ''
    echo "=== Test Framework Status (Simplified) ==="
    echo "Core tests: ${toString testMetadata.categories.core}"
    echo "Workflow tests: ${toString testMetadata.categories.workflow}"
    echo "Performance tests: ${toString testMetadata.categories.performance}"
    echo "Total tests: ${toString testMetadata.total}"
    echo ""
    echo "Framework successfully loaded!"
    touch $out
  '';

in
allTests // {
  # Include framework status as a test
  framework_status = frameworkStatus;
}
