# Test applications module
# Provides test-related app definitions for both Darwin and Linux systems

{ nixpkgs, self }:

let
  # Common test app builder
  mkTestApp = { name, system, command ? name, extraTests ? [ ] }: {
    type = "app";
    program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin name ''
      #!/usr/bin/env bash
      echo "Running ${name} for ${system}..."
      ${if command == "test-all" then ''
        nix build --impure .#checks.${system}.test-all -L
      '' else if command == "smoke-test" then ''
        nix build --impure .#checks.${system}.smoke-test -L
      '' else ''
        # For specific test categories, run the corresponding tests
        ${nixpkgs.lib.concatStringsSep "\n" (map (test:
          "nix build --impure .#checks.${system}.${test} -L"
        ) extraTests)}
      ''}
    '')}/bin/${name}";
  };

  # Test categories with their corresponding test files
  testCategories = {
    unit = [
      "basic_functionality_unit"
      "bl_auto_update_commands_unit"
      "build_switch_improved_unit"
      "check_builders_module_unit"
      "common_utils_unit"
      "configuration_validation_unit"
      "enhanced_error_functionality_unit"
      "error_handling_test"
      "flake_config_module_unit"
      "flake_integration_unit"
      "input_validation_unit"
      "module_imports_unit"
      "parallel_test_execution_unit"
      "parallel_test_functionality_unit"
      "system_configs_module_unit"
      # These tests exist but don't follow the _unit naming convention
      "auto_update_test"
      "claude_commands_test"
      "claude_config_test"
      "flake_structure_test"
      "makefile_usability_test"
      "platform_detection_test"
      "ssh_key_security_test"
      "sudo_security_test"
      "user_resolution_test"
    ];
    integration = [
      "auto_update_integration"
      "bl_auto_update_workflow_integration"
      "build_switch_improved_integration"
      "claude_config_force_overwrite_integration"
      "claude_config_overwrite_integration"
      "claude_config_preservation_integration"
      "cross_platform_integration"
      "file_generation_integration"
      "module_dependency_integration"
      "network_dependencies_integration"
      "package_availability_integration"
      "recovery_mechanisms_integration"
      "system_build_integration"
    ];
    e2e = [
      "build_switch_auto_update_e2e"
      "build_switch_improved_e2e"
      "claude_config_force_overwrite_e2e"
      "claude_config_overwrite_e2e"
      "claude_config_workflow_e2e"
      "complete_workflow_e2e"
      "legacy_system_integration_e2e"
      "legacy_workflow_e2e"
      "system_build_e2e"
      "system_deployment_e2e"
    ];
    perf = [
      "build_time_perf"
      "resource_usage_perf"
    ];
  };

  # Build base test apps (common for all platforms)
  mkBaseTestApps = system: {
    "test" = mkTestApp {
      name = "test";
      inherit system;
      command = "test-all";
    };
    "test-smoke" = mkTestApp {
      name = "test-smoke";
      inherit system;
      command = "smoke-test";
    };
    "test-list" = {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "test-list" ''
        #!/usr/bin/env bash
        echo "Available test categories for ${system}:"
        echo ""
        echo "Unit tests (${toString (builtins.length testCategories.unit)} tests):"
        ${nixpkgs.lib.concatStringsSep "\n" (map (test: "echo \"  - ${test}\"") testCategories.unit)}
        echo ""
        echo "Integration tests (${toString (builtins.length testCategories.integration)} tests):"
        ${nixpkgs.lib.concatStringsSep "\n" (map (test: "echo \"  - ${test}\"") testCategories.integration)}
        echo ""
        echo "E2E tests (${toString (builtins.length testCategories.e2e)} tests):"
        ${nixpkgs.lib.concatStringsSep "\n" (map (test: "echo \"  - ${test}\"") testCategories.e2e)}
        echo ""
        echo "Performance tests (${toString (builtins.length testCategories.perf)} tests):"
        ${nixpkgs.lib.concatStringsSep "\n" (map (test: "echo \"  - ${test}\"") testCategories.perf)}
      '')}/bin/test-list";
    };
  };

  # Build extended test apps (Darwin only for now)
  mkExtendedTestApps = system: {
    "test-unit" = mkTestApp {
      name = "test-unit";
      inherit system;
      extraTests = testCategories.unit;
    };
    "test-integration" = mkTestApp {
      name = "test-integration";
      inherit system;
      extraTests = testCategories.integration;
    };
    "test-e2e" = mkTestApp {
      name = "test-e2e";
      inherit system;
      extraTests = testCategories.e2e;
    };
    "test-perf" = mkTestApp {
      name = "test-perf";
      inherit system;
      extraTests = testCategories.perf;
    };
  };
in
{
  # Export functions for use in flake.nix
  mkLinuxTestApps = system: mkBaseTestApps system // mkExtendedTestApps system;
  mkDarwinTestApps = system: mkBaseTestApps system // mkExtendedTestApps system;

  # Export test categories for potential reuse
  inherit testCategories;
}
