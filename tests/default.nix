{ pkgs, flake ? null }:
let
  # Core tests - Essential functionality that must always work (simplified)
  coreTests = {
    # Basic functionality and structure (only active tests)
    flake_structure = import ./unit/flake-structure-test.nix { inherit pkgs flake; lib = pkgs.lib; src = ../.; };
    configuration_validation = import ./unit/configuration-validation-unit.nix { inherit pkgs flake; src = ../.; };

    # Critical functionality (only active tests)
    user_resolution = import ./unit/user-resolution-test.nix { inherit pkgs flake; src = ../.; };
    unified_user_resolution = import ./unit/test-unified-user-resolution.nix { inherit pkgs; lib = pkgs.lib; };

    # Build system functionality
    build_parallelization_unit = import ./unit/build-parallelization-unit.nix { inherit pkgs; };
    build_switch_unit = import ./unit/build-switch-unit.nix { inherit pkgs flake; src = ../.; };
    sudo_security_test = import ./unit/sudo-security-test.nix { inherit pkgs; lib = pkgs.lib; src = ../.; };
    sudo_session_persistence_test = import ./unit/sudo-session-persistence-test.nix { inherit pkgs; };

    # Build script modularization tests (TDD)
    build_script_logging_unit = import ./unit/build-script-logging-unit.nix { inherit pkgs; };
    build_script_performance_unit = import ./unit/build-script-performance-unit.nix { inherit pkgs; };
    build_script_sudo_management_unit = import ./unit/build-script-sudo-management-unit.nix { inherit pkgs; };
    build_script_build_logic_unit = import ./unit/build-script-build-logic-unit.nix { inherit pkgs; };
    build_script_modularization_integration = import ./unit/build-script-modularization-integration.nix { inherit pkgs; };

    # Cache management tests (Issue #287)
    cache_management_unit = import ./unit/cache-management-unit.nix { inherit pkgs; };

    # Lib consolidation tests (TDD - Phase 1 Sprint 1.1)
    lib_consolidation_unit = import ./unit/lib-consolidation-unit.nix { inherit pkgs; lib = pkgs.lib; };

    # Apply script deduplication tests (TDD - Issue #301)
    apply_script_deduplication_unit = import ./unit/apply-script-deduplication-unit.nix { inherit pkgs; };
    apply_template_system_unit = import ./unit/apply-template-system-unit.nix { inherit pkgs; };
    apply_functional_integration_unit = import ./unit/apply-functional-integration-unit.nix { inherit pkgs; };

    # App links module tests
    app_links_unit = import ./unit/app-links-unit.nix { inherit pkgs flake; src = ../.; };

    # Pre-commit and CI consistency tests
    precommit_ci_consistency = import ./unit/precommit-ci-consistency.nix { inherit pkgs; };

    # Keyboard input settings tests (TDD)
    keyboard_input_settings_test = import ./unit/keyboard-input-settings-test.nix { inherit pkgs; lib = pkgs.lib; };
    keyboard_input_settings_nix_test = import ./unit/keyboard-input-settings-nix-test.nix { inherit pkgs; lib = pkgs.lib; };

    # Build-switch Claude Code environment tests (simplified)
    build_switch_claude_code_environment_test = import ./unit/build-switch-claude-code-environment-test-simple.nix { inherit pkgs; lib = pkgs.lib; src = ../.; };

    # Sudoers script tests
    sudoers_script_test = import ./unit/sudoers-script-test.nix { inherit pkgs; lib = pkgs.lib; };

    # Essential integrations (only active tests)
    user_path_consistency = import ./integration/test-user-path-consistency.nix { inherit pkgs; lib = pkgs.lib; };
    build_parallelization_integration = import ./integration/build-parallelization-integration.nix { inherit pkgs; };
    app_links_integration = import ./integration/app-links-integration.nix { inherit pkgs flake; src = ../.; };
  };

  # Workflow tests - End-to-end user workflows (simplified)
  workflowTests = {
    # Core workflows (keep essential E2E tests)
    system_build = import ./e2e/system-build-e2e.nix { inherit pkgs flake; src = ../.; };
    system_deployment = import ./e2e/system-deployment-e2e.nix { inherit pkgs flake; src = ../.; };
    complete_workflow = import ./e2e/complete-workflow-e2e.nix { inherit pkgs flake; src = ../.; };

    # Feature workflows (keep Claude config workflow)
    claude_config_workflow = import ./e2e/claude-config-workflow-e2e.nix { inherit pkgs flake; src = ../.; };
    build_switch_workflow = import ./e2e/build-switch-e2e.nix { inherit pkgs flake; src = ../.; };
    app_links_e2e = import ./e2e/app-links-e2e.nix { inherit pkgs flake; src = ../.; };

    # Cache optimization workflow (Issue #287)
    cache_optimization_e2e = import ./e2e/cache-optimization-e2e.nix { inherit pkgs flake; src = ../.; };

    # Build-switch workflow integration test
    build_switch_workflow_integration_test = import ./integration/build-switch-workflow-integration-test.nix { inherit pkgs; lib = pkgs.lib; src = ../.; };

    # Sudoers workflow integration test
    sudoers_workflow_integration_test = import ./integration/sudoers-workflow-integration-test.nix { inherit pkgs; lib = pkgs.lib; };
  };

  # Performance tests - Build time and resource usage
  performanceTests = {
    build_time = import ./performance/build-time-perf.nix { inherit pkgs flake; src = ../.; };
    resource_usage = import ./performance/resource-usage-perf.nix { inherit pkgs flake; src = ../.; };
    build_parallelization_perf = import ./performance/build-parallelization-perf.nix { inherit pkgs; };
    build_switch_perf = import ./performance/build-switch-perf.nix { inherit pkgs flake; src = ../.; };
    parallel_processing_perf = import ./performance/parallel-processing-perf.nix { inherit pkgs flake; src = ../.; };
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
