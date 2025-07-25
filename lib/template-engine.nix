# Template Engine for Test Consolidation
# Provides functionality to consolidate 133 test files into 35 organized groups

{ pkgs, lib }:

rec {
  # Test categorization mapping - 133 tests organized into 35 logical groups
  testCategories = {
    # Core System Tests (Group 1-5)
    "01-core-system" = {
      pattern = ["*system*" "*core*" "*flake*"];
      files = [
        "tests/unit/flake-structure-test.nix"
        "tests/unit/flake-config-module-unit.nix"
        "tests/unit/flake-integration-unit.nix"
        "tests/e2e/flake-evaluation-e2e-test.nix"
        "tests/integration/flake-evaluation-performance-test.nix"
        "tests/unit/flake-evaluation-optimization-test.nix"
        "tests/unit/system-configs-module-unit.nix"
      ];
      description = "Core system and flake configuration tests";
    };

    "02-build-switch" = {
      pattern = ["*build-switch*" "*build*switch*"];
      files = [
        "tests/unit/build-switch-unit.nix"
        "tests/e2e/build-switch-e2e.nix"
        "tests/integration/build-switch-workflow-integration-test.nix"
        "tests/unit/build-switch-claude-code-environment-test.nix"
        "tests/unit/build-switch-claude-code-environment-test-simple.nix"
        "tests/ci/build-switch-ci-test.nix"
        "tests/integration/build-switch-comprehensive-system-state-test.nix"
        "tests/integration/build-switch-rollback-integration.nix"
        "tests/integration/build-switch-system-state-integration.nix"
        "tests/integration/build-switch-offline-mode-test.nix"
        "tests/integration/build-switch-path-fallback-test.nix"
        "tests/regression/build-switch-combined-mode-hardcoded-paths-test.nix"
        "tests/regression/build-switch-error-handling-consistency-test.nix"
        "tests/regression/build-switch-path-resolution-test.nix"
        "tests/regression/build-switch-security-edge-case-test.nix"
      ];
      description = "Build and switch functionality tests";
    };

    "03-platform-detection" = {
      pattern = ["*platform*" "*darwin*" "*linux*"];
      files = [
        "tests/unit/platform-detection-test.nix"
        "tests/unit/platform-detection-test.nix.disabled"
        "tests/integration/cross-platform-integration.nix"
      ];
      description = "Platform detection and cross-platform tests";
    };

    "04-user-resolution" = {
      pattern = ["*user*" "*resolution*"];
      files = [
        "tests/unit/user-resolution-test.nix"
        "tests/unit/test-unified-user-resolution.nix"
        "tests/unit/unified-user-resolution-unit.nix"
        "tests/unit/user-resolution-unification-unit.nix"
        "tests/integration/test-user-path-consistency.nix"
      ];
      description = "User resolution and path consistency tests";
    };

    "05-error-handling" = {
      pattern = ["*error*" "*handling*"];
      files = [
        "tests/unit/error-handling-test.nix"
        "tests/unit/enhanced-error-messaging-test.nix"
        "tests/unit/enhanced-error-functionality-unit.nix"
      ];
      description = "Error handling and messaging tests";
    };

    # Configuration Tests (Group 6-10)
    "06-configuration" = {
      pattern = ["*config*" "*configuration*"];
      files = [
        "tests/unit/configuration-validation-unit.nix"
        "tests/unit/configuration-externalization-unit.nix"
      ];
      description = "Configuration validation and externalization tests";
    };

    "07-claude-config" = {
      pattern = ["*claude*config*"];
      files = [
        "tests/unit/claude-config-test.nix"
        "tests/unit/claude-config-test-final.nix"
        "tests/integration/claude-config-preservation-integration.nix"
        "tests/e2e/claude-config-workflow-e2e.nix"
      ];
      description = "Claude configuration management tests";
    };

    "08-keyboard-input" = {
      pattern = ["*keyboard*" "*input*"];
      files = [
        "tests/unit/keyboard-input-settings-test.nix"
        "tests/unit/keyboard-input-settings-nix-test.nix"
      ];
      description = "Keyboard input configuration tests";
    };

    "09-zsh-configuration" = {
      pattern = ["*zsh*"];
      files = [
        "tests/unit/zsh-configuration-test.nix"
        "tests/unit/zsh-configuration-green-test.nix"
        "tests/unit/zsh-integration-test.nix"
        "tests/unit/zsh-powerlevel10k-fix-test.nix"
      ];
      description = "ZSH shell configuration tests";
    };

    "10-app-links" = {
      pattern = ["*app*link*"];
      files = [
        "tests/unit/app-links-unit.nix"
        "tests/integration/app-links-integration.nix"
        "tests/e2e/app-links-e2e.nix"
      ];
      description = "Application links management tests";
    };

    # Build and Performance Tests (Group 11-15)
    "11-build-logic" = {
      pattern = ["*build*logic*"];
      files = [
        "tests/unit/build-logic-function-decomposition-unit.nix"
        "tests/unit/build-logic-unified-unit.nix"
        "tests/unit/build-script-build-logic-unit.nix"
      ];
      description = "Build logic and decomposition tests";
    };

    "12-build-parallelization" = {
      pattern = ["*parallel*" "*build*"];
      files = [
        "tests/unit/build-parallelization-unit.nix"
        "tests/integration/build-parallelization-integration.nix"
        "tests/performance/build-parallelization-perf.nix"
        "tests/performance/parallel-processing-perf.nix"
      ];
      description = "Build parallelization and performance tests";
    };

    "13-performance-monitoring" = {
      pattern = ["*performance*" "*perf*"];
      files = [
        "tests/unit/build-script-performance-unit.nix"
        "tests/unit/performance-dashboard-test.nix"
        "tests/unit/test-helpers-performance-test.nix"
        "tests/performance/build-switch-perf.nix"
        "tests/performance/build-switch-performance-regression-test.nix"
        "tests/performance/build-time-perf.nix"
        "tests/performance/resource-usage-perf.nix"
        "tests/integration/darwin-build-switch-performance-test.nix"
        "tests/unit/darwin-build-switch-optimization-test.nix"
      ];
      description = "Performance monitoring and optimization tests";
    };

    "14-cache-management" = {
      pattern = ["*cache*"];
      files = [
        "tests/unit/cache-management-unit.nix"
        "tests/unit/cache-optimization-strategy-test.nix"
        "tests/e2e/cache-optimization-e2e.nix"
        "tests/integration/nix-cachix-performance-integration.nix"
        "tests/e2e/nix-cachix-build-performance-e2e.nix"
        "tests/unit/nix-cachix-trusted-users-test.nix"
      ];
      description = "Cache management and optimization tests";
    };

    "15-network-handling" = {
      pattern = ["*network*"];
      files = [
        "tests/e2e/network-failure-recovery-e2e.nix"
      ];
      description = "Network failure recovery tests";
    };

    # Package and Module Tests (Group 16-20)
    "16-package-management" = {
      pattern = ["*package*"];
      files = [
        "tests/unit/package-utils-unit.nix"
        "tests/unit/package-import-pattern-unit.nix"
        "tests/integration/package-availability-integration.nix"
      ];
      description = "Package management and utilities tests";
    };

    "17-module-dependencies" = {
      pattern = ["*module*"];
      files = [
        "tests/unit/module-dependency-structure-unit.nix"
        "tests/unit/module-imports-unit.nix"
        "tests/integration/module-dependency-integration.nix"
      ];
      description = "Module dependency and import tests";
    };

    "18-homebrew-integration" = {
      pattern = ["*homebrew*" "*brew*"];
      files = [
        "tests/integration/build-switch-homebrew-integration.nix"
        "tests/integration/homebrew-nix-conflict-resolution.nix"
        "tests/integration/homebrew-rollback-scenarios.nix"
        "tests/unit/homebrew-ecosystem-comprehensive-unit.nix"
        "tests/unit/brew-karabiner-integration-unit.nix"
        "tests/brew-karabiner-test.sh"
        "tests/simple-karabiner-test.sh"
      ];
      description = "Homebrew ecosystem integration tests";
    };

    "19-cask-management" = {
      pattern = ["*cask*"];
      files = [
        "tests/unit/casks-management-unit.nix"
      ];
      description = "macOS cask management tests";
    };

    "20-iterm2-config" = {
      pattern = ["*iterm*"];
      files = [
        "tests/integration/iterm2-configuration-integration.nix"
      ];
      description = "iTerm2 configuration tests";
    };

    # Security and Permissions (Group 21-25)
    "21-security-ssh" = {
      pattern = ["*ssh*" "*security*"];
      files = [
        "tests/unit/ssh-key-security-test.nix"
      ];
      description = "SSH key security tests";
    };

    "22-sudo-management" = {
      pattern = ["*sudo*"];
      files = [
        "tests/unit/sudo-security-test.nix"
        "tests/unit/sudo-session-persistence-test.nix"
        "tests/unit/sudoers-script-test.nix"
        "tests/unit/build-script-sudo-management-unit.nix"
        "tests/integration/sudoers-workflow-integration-test.nix"
      ];
      description = "Sudo management and security tests";
    };

    "23-precommit-ci" = {
      pattern = ["*precommit*" "*ci*"];
      files = [
        "tests/unit/precommit-ci-consistency.nix"
      ];
      description = "Pre-commit and CI consistency tests";
    };

    # Utils and Libraries (Group 24-28)
    "24-common-utils" = {
      pattern = ["*utils*" "*common*"];
      files = [
        "tests/unit/common-utils-unit.nix"
      ];
      description = "Common utilities tests";
    };

    "25-lib-consolidation" = {
      pattern = ["*lib*"];
      files = [
        "tests/unit/lib-consolidation-unit.nix"
        "tests/unit/check-builders-module-unit.nix"
      ];
      description = "Library consolidation tests";
    };

    "26-file-operations" = {
      pattern = ["*file*"];
      files = [
        "tests/unit/conditional-file-copy-modularization-unit.nix"
        "tests/integration/file-generation-integration.nix"
      ];
      description = "File operations and generation tests";
    };

    "27-portable-paths" = {
      pattern = ["*portable*" "*path*"];
      files = [
        "tests/unit/portable-paths-test.nix"
      ];
      description = "Portable path handling tests";
    };

    "28-directory-structure" = {
      pattern = ["*directory*"];
      files = [
        "tests/unit/directory-structure-optimization-unit.nix"
      ];
      description = "Directory structure optimization tests";
    };

    # Advanced Features (Group 29-33)
    "29-auto-update" = {
      pattern = ["*auto*update*"];
      files = [
        "tests/unit/auto-update-test.nix"
        "tests/unit/bl-auto-update-commands-unit.nix"
        "tests/integration/auto-update-integration.nix"
        "tests/unit/notification-auto-recovery-test.nix"
      ];
      description = "Auto-update functionality tests";
    };

    "30-claude-cli" = {
      pattern = ["*claude*cli*"];
      files = [
        "tests/claude-cli-test-suite.nix"
        "tests/e2e/claude-cli-e2e-tests.nix"
        "tests/integration/claude-cli-integration-tests.nix"
        "tests/stress/claude-cli-stress-tests.nix"
        "tests/unit/claude-cli-commands-test.nix"
        "tests/unit/claude-cli-unit-tests.nix"
        "tests/unit/claude-commands-test.nix"
      ];
      description = "Claude CLI functionality tests";
    };

    "31-intellij-idea" = {
      pattern = ["*intellij*" "*idea*"];
      files = [
        "tests/unit/intellij-idea-background-execution-test.nix"
        "tests/unit/idea-alias-execution-test.nix"
      ];
      description = "IntelliJ IDEA integration tests";
    };

    "32-alternative-execution" = {
      pattern = ["*alternative*" "*execution*"];
      files = [
        "tests/unit/alternative-execution-paths-test.nix"
      ];
      description = "Alternative execution path tests";
    };

    "33-parallel-testing" = {
      pattern = ["*parallel*test*"];
      files = [
        "tests/unit/parallel-test-execution-unit.nix"
        "tests/unit/parallel-test-functionality-unit.nix"
      ];
      description = "Parallel test execution tests";
    };

    # System Integration and E2E (Group 34-35)
    "34-system-deployment" = {
      pattern = ["*system*deploy*" "*deploy*"];
      files = [
        "tests/e2e/system-deployment-e2e.nix"
        "tests/e2e/system-build-e2e.nix"
        "tests/integration/system-build-integration.nix"
      ];
      description = "System deployment and build tests";
    };

    "35-comprehensive-workflow" = {
      pattern = ["*complete*" "*comprehensive*" "*workflow*"];
      files = [
        "tests/e2e/complete-workflow-e2e.nix"
        "tests/e2e/build-switch-comprehensive-scenarios-e2e.nix"
        "tests/unit/apply-functional-integration-unit.nix"
        "tests/unit/apply-script-deduplication-unit.nix"
        "tests/unit/build-script-modularization-integration.nix"
        "tests/unit/apply-template-system-unit.nix"
        "tests/unit/build-script-logging-unit.nix"
        "tests/unit/documentation-completeness-unit.nix"
        "tests/unit/pre-validation-system-test.nix"
        "tests/unit/test-logging-availability.sh"
      ];
      description = "Comprehensive workflow and integration tests";
    };
  };

  # Generate consolidated test file for a category
  generateConsolidatedTest = categoryName: categoryData: ''
    # ${categoryData.description}
    # Consolidated test file for category: ${categoryName}

    { pkgs, lib, ... }:

    let
      testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

      # Import all original test modules for this category
      originalTests = {
        ${lib.concatStringsSep "\n        " (map (file:
          let fileName = lib.last (lib.splitString "/" file);
              testName = lib.removeSuffix ".nix" fileName;
          in "${testName} = import ../../${file} { inherit pkgs lib; };"
        ) categoryData.files)}
      };
    in

    pkgs.stdenv.mkDerivation {
      name = "${categoryName}-consolidated-test";

      buildCommand = '''
        echo "Running consolidated tests for: ${categoryData.description}"

        # Execute all original tests in this category
        ${lib.concatStringsSep "\n        " (map (file:
          let fileName = lib.last (lib.splitString "/" file);
              testName = lib.removeSuffix ".nix" fileName;
          in ''
            echo "Executing ${testName}..."
            if ! nix-build --no-out-link ../../${file}; then
              echo "ERROR: ${testName} failed"
              exit 1
            fi
          ''
        ) categoryData.files)}

        echo "All tests in ${categoryName} completed successfully"
        touch $out
      ''';
    }
  '';

  # Main function to generate all consolidated test files
  generateAllConsolidatedTests =
    lib.mapAttrs generateConsolidatedTest testCategories;

  # Utility function to get category for a test file
  getCategoryForTest = testFile:
    let
      matchingCategories = lib.filterAttrs (name: data:
        lib.any (file: file == testFile) data.files
      ) testCategories;
    in
    if matchingCategories == {} then null
    else lib.head (lib.attrNames matchingCategories);

  # Function to validate all 133 tests are categorized
  validateAllTestsCategorized =
    let
      allCategorizedFiles = lib.concatLists (lib.mapAttrsToList (name: data: data.files) testCategories);
      allExistingTests = import ./existing-tests.nix;
    in
    lib.all (test: lib.elem test allCategorizedFiles) allExistingTests;
}
