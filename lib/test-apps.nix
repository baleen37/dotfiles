# Test applications module
# Provides test-related app definitions for both Darwin and Linux systems

{ nixpkgs, self }:

let
  # Common test app builder
  mkTestApp = { name, system, command ? name, extraTests ? [] }: {
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
      "error_handling_unit"
      "input_validation_unit"
      "module_imports_unit"
      "platform_detection_unit"
      "user_resolution_unit"
      "configuration_validation_unit"
      "claude_config_copy_unit"
      "claude_commands_copy_unit"
      "claude_config_copy_consistency_unit"
      "claude_config_force_overwrite_unit"
      "claude_file_copy_test"
      "claude_file_overwrite_unit"
      "claude_config_overwrite_prevention_test"
      "claude_config_preserve_user_changes_test"
      "claude_config_force_overwrite_feature_test"
      "auto_update_dotfiles_unit"
    ];
    integration = [
      "package_availability_integration"
      "module_dependency_integration"
      "file_generation_integration"
      "cross_platform_integration"
      "system_build_integration"
      "network_dependencies_integration"
      "claude_config_preservation_integration"
      "claude_config_overwrite_integration"
      "claude_config_force_overwrite_integration"
      "auto_update_integration"
      "recovery_mechanisms_integration"
    ];
    e2e = [
      "system_build_e2e"
      "system_deployment_e2e"
      "complete_workflow_e2e"
      "legacy_workflow_e2e"
      "legacy_system_integration_e2e"
      "claude_config_workflow_e2e"
      "claude_config_overwrite_e2e"
      "claude_config_force_overwrite_e2e"
      "build_switch_auto_update_e2e"
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
  mkLinuxTestApps = system: mkBaseTestApps system;
  mkDarwinTestApps = system: mkBaseTestApps system // mkExtendedTestApps system;
  
  # Export test categories for potential reuse
  inherit testCategories;
}