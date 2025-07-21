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

    # Build logic unification tests (TDD - Phase 1 Sprint 1.3)
    build_logic_unified_unit = import ./unit/build-logic-unified-unit.nix { inherit pkgs; lib = pkgs.lib; };

    # Conditional file copy modularization tests (TDD - Phase 2 Sprint 2.1)
    conditional_file_copy_modularization_unit = import ./unit/conditional-file-copy-modularization-unit.nix { inherit pkgs; lib = pkgs.lib; };

    # Platform detection tests (TDD - Phase 3 Sprint 3.1)
    platform_detection_test = import ./unit/platform-detection-test.nix { inherit pkgs; };

    # Claude configuration tests (TDD - Phase 3 Sprint 3.1)
    claude_config_test = import ./unit/claude-config-test.nix { inherit pkgs; };

    # Module imports tests (TDD - Phase 3 Sprint 3.1)
    module_imports_unit = import ./unit/module-imports-unit.nix { inherit pkgs flake; src = ../.; };

    # Error handling tests (TDD - Phase 3 Sprint 3.1)
    error_handling_test = import ./unit/error-handling-test.nix { inherit pkgs; src = ../.; };

    # Flake config module tests (TDD - Phase 3 Sprint 3.1 Medium Priority)
    flake_config_module_unit = import ./unit/flake-config-module-unit.nix { inherit pkgs flake; src = ../.; };

    # System configs module tests (TDD - Phase 3 Sprint 3.1 Medium Priority)
    system_configs_module_unit = import ./unit/system-configs-module-unit.nix { inherit pkgs flake; src = ../.; };

    # Common utils tests (TDD - Phase 3 Sprint 3.1 Medium Priority)
    common_utils_unit = import ./unit/common-utils-unit.nix { inherit pkgs flake; src = ../.; };

    # Auto-update tests (TDD - Phase 3 Sprint 3.1 Build System Tests)
    auto_update_test = import ./unit/auto-update-test.nix { inherit pkgs; src = ../.; };

    # BL auto-update commands tests (TDD - Phase 3 Sprint 3.1 Build System Tests)
    bl_auto_update_commands_unit = import ./unit/bl-auto-update-commands-unit.nix { inherit pkgs; src = ../.; };

    # Check builders module tests (TDD - Phase 3 Sprint 3.1 Build System Tests)
    check_builders_module_unit = import ./unit/check-builders-module-unit.nix { inherit pkgs flake; src = ../.; };

    # Flake integration tests (TDD - Phase 3 Sprint 3.1 Integration Tests)
    flake_integration_unit = import ./unit/flake-integration-unit.nix { inherit pkgs flake; src = ../.; };

    # Parallel test execution tests (TDD - Phase 3 Sprint 3.1 Integration Tests)
    parallel_test_execution_unit = import ./unit/parallel-test-execution-unit.nix { inherit pkgs flake; src = ../.; };

    # Enhanced error functionality tests (TDD - Phase 3 Sprint 3.1 Performance Tests)
    enhanced_error_functionality_unit = import ./unit/enhanced-error-functionality-unit.nix { inherit pkgs flake; src = ../.; };

    # Portable paths tests (TDD - Phase 3 Sprint 3.1 Performance Tests)
    portable_paths_test = import ./unit/portable-paths-test.nix { inherit pkgs flake; src = ../.; };

    # SSH key security tests (TDD - Phase 3 Sprint 3.1 Additional Tests)
    ssh_key_security_test = import ./unit/ssh-key-security-test.nix { inherit pkgs; lib = pkgs.lib; src = ../.; };

    # Package utils tests (TDD - Phase 3 Sprint 3.2 Coverage Expansion)
    package_utils_unit = import ./unit/package-utils-unit.nix { inherit pkgs flake; src = ../.; };

    # Claude commands tests (TDD - Phase 3 Sprint 3.2 Coverage Expansion)
    claude_commands_test = import ./unit/claude-commands-test.nix { inherit pkgs; src = ../.; };

    # Parallel test functionality tests (TDD - Phase 3 Sprint 3.2 Coverage Expansion)
    parallel_test_functionality_unit = import ./unit/parallel-test-functionality-unit.nix { inherit pkgs flake; src = ../.; };

    # Claude config test final (TDD - Phase 3 Sprint 3.2 Coverage Expansion - Final Test)
    claude_config_test_final = import ./unit/claude-config-test-final.nix { inherit pkgs; src = ../.; };

    # Directory structure optimization tests (TDD - Phase 4 Sprint 4.1)
    directory_structure_optimization_unit = import ./unit/directory-structure-optimization-unit.nix { inherit pkgs flake; src = ../.; };

    # Configuration externalization tests (TDD - Phase 4 Sprint 4.2)
    configuration_externalization_unit = import ./unit/configuration-externalization-unit.nix { inherit pkgs flake; src = ../.; };

    # Documentation completeness tests (TDD - Phase 4 Sprint 4.3)
    documentation_completeness_unit = import ./unit/documentation-completeness-unit.nix { inherit pkgs flake; src = ../.; };
    # Apply script deduplication tests (TDD - Issue #301)
    apply_script_deduplication_unit = import ./unit/apply-script-deduplication-unit.nix { inherit pkgs; };
    apply_template_system_unit = import ./unit/apply-template-system-unit.nix { inherit pkgs; };
    apply_functional_integration_unit = import ./unit/apply-functional-integration-unit.nix { inherit pkgs; };

    # Phase 4: Performance optimization and monitoring tests (TDD)
    cache_optimization_strategy_test = import ./unit/cache-optimization-strategy-test.nix { inherit pkgs; lib = pkgs.lib; };
    performance_dashboard_test = import ./unit/performance-dashboard-test.nix { inherit pkgs; lib = pkgs.lib; };
    notification_auto_recovery_test = import ./unit/notification-auto-recovery-test.nix { inherit pkgs; lib = pkgs.lib; };

    # App links module tests
    app_links_unit = import ./unit/app-links-unit.nix { inherit pkgs flake; src = ../.; };

    # Pre-commit and CI consistency tests
    precommit_ci_consistency = import ./unit/precommit-ci-consistency.nix { inherit pkgs; };

    # Phase 3: Enhanced validation and error handling tests (TDD)
    pre_validation_system_test = import ./unit/pre-validation-system-test.nix { inherit pkgs; lib = pkgs.lib; };
    alternative_execution_paths_test = import ./unit/alternative-execution-paths-test.nix { inherit pkgs; lib = pkgs.lib; };
    enhanced_error_messaging_test = import ./unit/enhanced-error-messaging-test.nix { inherit pkgs; lib = pkgs.lib; };

    # Keyboard input settings tests (TDD)
    keyboard_input_settings_test = import ./unit/keyboard-input-settings-test.nix { inherit pkgs; lib = pkgs.lib; };
    keyboard_input_settings_nix_test = import ./unit/keyboard-input-settings-nix-test.nix { inherit pkgs; lib = pkgs.lib; };

    # Build-switch Claude Code environment tests (simplified)
    build_switch_claude_code_environment_test = import ./unit/build-switch-claude-code-environment-test-simple.nix { inherit pkgs; lib = pkgs.lib; src = ../.; };

    # Build-switch CI tests
    build_switch_ci_test = import ./ci/build-switch-ci-test.nix { inherit pkgs; lib = pkgs.lib; src = ../.; };

    # Regression tests for build-switch path resolution (TDD Phase 1.1)
    build_switch_path_resolution_regression = import ./regression/build-switch-path-resolution-test.nix { inherit pkgs flake; src = ../.; };

    # Regression tests for combined mode hardcoded paths (TDD Phase 1.2)
    build_switch_combined_mode_hardcoded_paths_regression = import ./regression/build-switch-combined-mode-hardcoded-paths-test.nix { inherit pkgs flake; src = ../.; };

    # Regression tests for error handling consistency (TDD Phase 1.3)
    build_switch_error_handling_consistency_regression = import ./regression/build-switch-error-handling-consistency-test.nix { inherit pkgs flake; src = ../.; };

    # Phase 2.1: Enhanced system state and network resilience tests
    build_switch_offline_mode_integration = import ./integration/build-switch-offline-mode-test.nix { inherit pkgs flake; src = ../.; };
    build_switch_rollback_integration = import ./integration/build-switch-rollback-integration.nix { inherit pkgs flake; src = ../.; };

    # Phase 2.2: System state capture and recovery integration tests
    build_switch_system_state_integration = import ./integration/build-switch-system-state-integration.nix { inherit pkgs flake; src = ../.; };

    # Sudoers script tests
    sudoers_script_test = import ./unit/sudoers-script-test.nix { inherit pkgs; lib = pkgs.lib; };

    # Homebrew ecosystem tests (Phase 5 - Homebrew Integration)
    homebrew_ecosystem_comprehensive_unit = import ./unit/homebrew-ecosystem-comprehensive-unit.nix { inherit pkgs flake; src = ../.; };
    casks_management_unit = import ./unit/casks-management-unit.nix { inherit pkgs flake; src = ../.; };
    brew_karabiner_integration_unit = import ./unit/brew-karabiner-integration-unit.nix { inherit pkgs flake; src = ../.; };

    # Essential integrations (only active tests)
    user_path_consistency = import ./integration/test-user-path-consistency.nix { inherit pkgs; lib = pkgs.lib; };
    build_parallelization_integration = import ./integration/build-parallelization-integration.nix { inherit pkgs; };
    app_links_integration = import ./integration/app-links-integration.nix { inherit pkgs flake; src = ../.; };

    # Cross-platform integration tests (TDD - Phase 3 Sprint 3.1 Additional Tests)
    cross_platform_integration = import ./integration/cross-platform-integration.nix { inherit pkgs flake; src = ../.; };

    # Auto-update integration tests (TDD - Phase 3 Sprint 3.1 Additional Tests)
    auto_update_integration = import ./integration/auto-update-integration.nix { inherit pkgs flake; src = ../.; };

    # Package availability integration tests (TDD - Phase 3 Sprint 3.1 Additional Tests)
    package_availability_integration = import ./integration/package-availability-integration.nix { inherit pkgs flake; src = ../.; };

    # System build integration tests (TDD - Phase 3 Sprint 3.1 Additional Tests)
    system_build_integration = import ./integration/system-build-integration.nix { inherit pkgs flake; src = ../.; };

    # File generation integration tests (TDD - Phase 3 Sprint 3.1 Additional Tests)
    file_generation_integration = import ./integration/file-generation-integration.nix { inherit pkgs flake; src = ../.; };

    # Homebrew integration tests (Phase 5 - Homebrew Integration)
    homebrew_nix_conflict_resolution = import ./integration/homebrew-nix-conflict-resolution.nix { inherit pkgs flake; src = ../.; };
    build_switch_homebrew_integration = import ./integration/build-switch-homebrew-integration.nix { inherit pkgs flake; src = ../.; };
    homebrew_rollback_scenarios = import ./integration/homebrew-rollback-scenarios.nix { inherit pkgs flake; src = ../.; };
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

    # Phase 2.1: Network resilience end-to-end tests
    network_failure_recovery_e2e = import ./e2e/network-failure-recovery-e2e.nix { inherit pkgs flake; src = ../.; };

    # Phase 2.3: Comprehensive scenario end-to-end tests
    build_switch_comprehensive_scenarios_e2e = import ./e2e/build-switch-comprehensive-scenarios-e2e.nix { inherit pkgs flake; src = ../.; };

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
