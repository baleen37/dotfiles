# Integration Test Template
#
# This is a template for writing integration tests.
# Copy this file to tests/integration/<feature>-test.nix and modify.
#
# Integration tests should:
# - Test module interactions and configuration generation
# - Have medium execution time (10-30 seconds)
# - Validate real-world usage scenarios
# - Use patterns from tests/lib/patterns.nix for common cases
#
# Quick Start:
# 1. Copy this file: cp tests/integration/test-template.nix tests/integration/my-feature-test.nix
# 2. Edit the test configuration below
# 3. Run: make test-integration
# 4. Run specific test: nix build '.#checks.<platform>.integration-my-feature' --impure

{
  inputs,
  system,
  # Standard parameters
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  nixtest ? { },
  ...
}:

let
  # Import test helpers
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import additional helper libraries
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };

  # ===== TEST DATA SETUP =====
  # Define test configurations and fixtures

  # Example: Load Home Manager configuration
  # hmConfig = import ../../users/shared/home-manager.nix {
  #   inherit pkgs lib inputs;
  #   currentSystemUser = "testuser";
  #   config = {
  #     home = {
  #       homeDirectory = if pkgs.stdenv.isDarwin then "/Users/testuser" else "/home/testuser";
  #     };
  #   };
  # };

  # Example: Load specific tool configuration
  # toolConfig = import ../../users/shared/my-tool.nix {
  #   inherit pkgs lib;
  #   config = { };
  # };

in
{
  # ===== PLATFORM FILTERING =====
  # Specify which platforms this test should run on
  platforms = ["any"];

  # ===== TEST SUITE =====
  value = helpers.testSuite "my-integration-test" [
    # ===== CONFIGURATION STRUCTURE =====
    # Test that the configuration has expected structure

    # (assertions.assertConfigStructure "hm-valid" hmConfig [
    #   "home"
    #   "xdg"
    #   "programs"
    # ])

    # ===== USER CONFIGURATION =====
    # Test user-specific settings

    # (patterns.testUsername "default-user" hmConfig "testuser")
    # (patterns.testHomeDirectory "test-home" hmConfig "/Users/testuser")

    # ===== MODULE IMPORTS =====
    # Test that required modules are imported

    # (helpers.testSuite "module-imports" (
    #   builtins.attrValues (patterns.testModuleImports "tool-modules" hmConfig [
    #     "./git.nix"
    #     "./vim.nix"
    #     "./zsh.nix"
    #   ])
    # ))

    # ===== PACKAGE INSTALLATION =====
    # Test that packages are installed

    # (helpers.testSuite "package-installation" (
    #   builtins.attrValues (patterns.testPackagesInstalled "essential-tools" hmConfig [
    #     "git"
    #     "vim"
    #     "tmux"
    #   ])
    # ))

    # ===== PROGRAM ENABLEMENT =====
    # Test that programs are enabled

    # (patterns.testProgramEnabled "git-enabled" hmConfig "git" true)

    # ===== FILE CONFIGURATION =====
    # Test that files are configured

    # (helpers.testSuite "file-config" (
    #   builtins.attrValues (patterns.testHomeFileConfig "config-files" hmConfig {
    #     ".config/my-tool/config.conf" = true;
    #     ".config/my-tool/settings.json" = true;
    #   })
    # ))

    # ===== SETTINGS VALIDATION =====
    # Test configuration values

    # (helpers.assertSettings "tool-settings" toolConfig.settings {
    #   key1 = "value1";
    #   key2 = "value2";
    # })

    # ===== CROSS-MODULE INTEGRATION =====
    # Test interactions between multiple modules

    # (helpers.assertTest "modules-work-together" (
    #   hmConfig.programs.git.enable == true
    #   && hmConfig.programs.vim.enable == true
    #   && hmConfig.home.username == "testuser"
    # ) "Git, Vim, and user configuration should be consistent")

    # ===== DERIVATION BUILDING =====
    # Test that configurations build successfully

    # (helpers.assertTest "config-builds" (
    #   hmConfig ? home && hmConfig.home ? homeDirectory
    # ) "Configuration should be buildable")

    # ===== PLATFORM-SPECIFIC TESTS =====
    # Test platform-specific behavior

    # (helpers.assertTest "darwin-specific" (
    #   if pkgs.stdenv.isDarwin then
    #     hmConfig ? launchd
    #   else
    #     true  # Skip on non-Darwin platforms
    # ) "Darwin-specific features should be configured")

    # Add more integration tests below...
  ];
}
