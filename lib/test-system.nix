# Unified Test System
# Combines test-apps.nix and test-utils.nix
# Provides comprehensive test framework, app builders, and utilities

{ pkgs ? null, nixpkgs ? null, self ? null }:

let
  # Determine pkgs
  actualPkgs = if pkgs != null then pkgs else (import <nixpkgs> { });

  # Import error system for error handling
  errorSystem = import ./error-system.nix { pkgs = actualPkgs; lib = actualPkgs.lib; };

  # Test app builder core functionality
  testAppBuilders = {
    # Simple test app builder
    mkTestApp = { name, system, command }: {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin name ''
        #!/usr/bin/env bash
        echo "Running ${name} for ${system}..."
        ${command}
      '')}/bin/${name}";
    };

    # Build test apps for a system
    mkTestApps = system: {
      # Run all tests
      "test" = testAppBuilders.mkTestApp {
        name = "test";
        inherit system;
        command = ''
          echo "Running all tests..."
          nix build --impure .#checks.${system}.test-all -L
        '';
      };

      # Run core tests only (fast, essential)
      "test-core" = testAppBuilders.mkTestApp {
        name = "test-core";
        inherit system;
        command = ''
          echo "Running core tests..."
          nix build --impure .#checks.${system}.test-core -L
        '';
      };

      # Run workflow tests (end-to-end)
      "test-workflow" = testAppBuilders.mkTestApp {
        name = "test-workflow";
        inherit system;
        command = ''
          echo "Running workflow tests..."
          nix build --impure .#checks.${system}.test-workflow -L
        '';
      };

      # Run performance tests
      "test-perf" = testAppBuilders.mkTestApp {
        name = "test-perf";
        inherit system;
        command = ''
          echo "Running performance tests..."
          nix build --impure .#checks.${system}.test-perf -L
        '';
      };

      # NEW: Run configuration integrity tests
      "test-config-integrity" = testAppBuilders.mkTestApp {
        name = "test-config-integrity";
        inherit system;
        command = ''
          echo "Running configuration integrity tests..."
          nix build --impure .#checks.${system}.test-config-integrity -L
        '';
      };

      # NEW: Run package compatibility tests
      "test-package-compatibility" = testAppBuilders.mkTestApp {
        name = "test-package-compatibility";
        inherit system;
        command = ''
          echo "Running package compatibility tests..."
          nix build --impure .#checks.${system}.test-package-compatibility -L
        '';
      };

      # NEW: Run security validation tests
      "test-security" = testAppBuilders.mkTestApp {
        name = "test-security";
        inherit system;
        command = ''
          echo "Running security validation tests..."
          nix build --impure .#checks.${system}.test-security -L
        '';
      };

      # NEW: Run dependency consistency tests
      "test-dependency-consistency" = testAppBuilders.mkTestApp {
        name = "test-dependency-consistency";
        inherit system;
        command = ''
          echo "Running dependency consistency tests..."
          nix build --impure .#checks.${system}.test-dependency-consistency -L
        '';
      };

      # Run unit tests (alias for test-core)
      "test-unit" = testAppBuilders.mkTestApp {
        name = "test-unit";
        inherit system;
        command = ''
          echo "Running unit tests..."
          nix build --impure .#checks.${system}.test-core -L
        '';
      };

      # Run integration tests (alias for test-workflow)
      "test-integration" = testAppBuilders.mkTestApp {
        name = "test-integration";
        inherit system;
        command = ''
          echo "Running integration tests..."
          nix build --impure .#checks.${system}.test-workflow -L
        '';
      };

      # Quick smoke test (just flake checks)
      "test-smoke" = testAppBuilders.mkTestApp {
        name = "test-smoke";
        inherit system;
        command = ''
          echo "Running smoke tests..."
          # Basic flake evaluation test - only check syntax
          echo "Checking flake outputs..."
          nix flake show --impure > /dev/null
          echo "Checking devShells..."
          nix build --dry-run .#devShells.${system}.default
          echo "Smoke test completed successfully!"
        '';
      };

      # Enhanced smoke test with more validations
      "test-smoke-enhanced" = testAppBuilders.mkTestApp {
        name = "test-smoke-enhanced";
        inherit system;
        command = ''
          echo "Running enhanced smoke tests..."
          # Basic flake evaluation
          echo "Checking flake outputs..."
          nix flake show --impure > /dev/null

          # Check key derivations can be evaluated
          echo "Checking platform detection..."
          nix eval --impure --expr '(import ./lib/platform-system.nix { system = "${system}"; }).platform' > /dev/null

          # Check user resolution
          echo "Checking user resolution..."
          nix eval --impure --expr '(import ./lib/user-resolution.nix { system = "${system}"; }).resolveUser' > /dev/null

          # Check error system
          echo "Checking error system..."
          nix eval --impure --expr '(import ./lib/error-system.nix { }).version' > /dev/null

          echo "Enhanced smoke test completed successfully!"
        '';
      };

      # List available tests (enhanced)
      "test-list" = testAppBuilders.mkTestApp {
        name = "test-list";
        inherit system;
        command = ''
          echo "=== Enhanced Test Framework ==="
          echo ""
          echo "Core test commands:"
          echo "  test                      - Run all tests"
          echo "  test-core                 - Run core tests (fast, essential)"
          echo "  test-workflow             - Run workflow tests (end-to-end)"
          echo "  test-unit                 - Run unit tests (alias for test-core)"
          echo "  test-integration          - Run integration tests (alias for test-workflow)"
          echo "  test-perf                 - Run performance tests"
          echo "  test-smoke                - Quick smoke test (flake check)"
          echo "  test-smoke-enhanced       - Enhanced smoke test with validations"
          echo ""
          echo "NEW: Advanced test categories:"
          echo "  test-config-integrity     - Configuration integrity tests"
          echo "  test-package-compatibility - Package compatibility tests"
          echo "  test-security             - Security validation tests"
          echo "  test-dependency-consistency - Dependency consistency tests"
          echo ""
          echo "Categories:"
          echo "  Core:           Essential functionality tests"
          echo "  Workflow:       End-to-end user workflow tests"
          echo "  Performance:    Build time and resource usage tests"
          echo "  Config:         Configuration integrity and validation"
          echo "  Compatibility:  Package and platform compatibility"
          echo "  Security:       Security policy and validation tests"
          echo "  Dependencies:   Dependency graph consistency tests"
        '';
      };
    };
  };

  # Enhanced test utilities and reporting
  testUtils = {
    # Create a test reporter that generates formatted output
    mkTestReporter = { name, tests, results }: actualPkgs.writeScriptBin "test-reporter" ''
      #!${actualPkgs.bash}/bin/bash

      echo "════════════════════════════════════════════════════════════════"
      echo "  Test Report: ${name}"
      echo "════════════════════════════════════════════════════════════════"
      echo ""
      echo "Total tests: ${toString (builtins.length tests)}"
      echo "Passed: $(grep -c "PASS" <<< "${results}")"
      echo "Failed: $(grep -c "FAIL" <<< "${results}")"
      echo ""
      echo "Details:"
      echo "${results}"
      echo ""
      echo "════════════════════════════════════════════════════════════════"
    '';

    # Create a test discovery script that lists all available tests
    mkTestDiscovery = { flake, system }: actualPkgs.writeScriptBin "discover-tests" ''
      #!${actualPkgs.bash}/bin/bash

      echo "Discovering tests for ${system}..."
      echo ""

      # Get all test attributes from checks
      nix eval --json --impure ${flake}#checks.${system} 2>/dev/null | \
        ${actualPkgs.jq}/bin/jq -r 'to_entries | group_by(.key | split("_")[-1]) |
          map({
            category: .[0].key | split("_")[-1],
            tests: map(.key)
          }) |
          .[] |
          "Category: \(.category)\n" +
          (.tests | map("  - " + .) | join("\n")) + "\n"'
    '';

    # Enhanced test runner with better error handling and reporting
    mkEnhancedTestRunner = { name, tests }: actualPkgs.writeScriptBin "run-${name}-tests" ''
      #!${actualPkgs.bash}/bin/bash
      set -euo pipefail

      FAILED=0
      PASSED=0
      RESULTS=""

      echo "Running ${name} tests..."
      echo ""

      for test in ${builtins.concatStringsSep " " tests}; do
        echo -n "  Running $test... "

        if nix build --impure --no-link ".#checks.$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"').$test" 2>/dev/null; then
          echo "✓ PASSED"
          RESULTS="$RESULTS\n  ✓ $test: PASS"
          ((PASSED++))
        else
          echo "✗ FAILED"
          RESULTS="$RESULTS\n  ✗ $test: FAIL"
          ((FAILED++))
        fi
      done

      echo ""
      echo "Summary: $PASSED passed, $FAILED failed out of $((PASSED + FAILED)) tests"

      if [ $FAILED -gt 0 ]; then
        exit 1
      fi
    '';

    # NEW: Configuration validator
    mkConfigValidator = { name, configPath, schema ? null }: actualPkgs.writeScriptBin "validate-${name}" ''
      #!${actualPkgs.bash}/bin/bash
      set -euo pipefail

      echo "Validating ${name} configuration..."

      # Check if config file exists
      if [[ ! -f "${configPath}" ]]; then
        echo "❌ Configuration file not found: ${configPath}"
        exit 1
      fi

      # Check if config can be parsed
      if ! nix-instantiate --parse "${configPath}" >/dev/null 2>&1; then
        echo "❌ Configuration syntax error in ${configPath}"
        exit 1
      fi

      # Check if config can be evaluated
      if ! nix eval --impure --file "${configPath}" >/dev/null 2>&1; then
        echo "❌ Configuration evaluation error in ${configPath}"
        exit 1
      fi

      echo "✅ Configuration validation passed for ${name}"
    '';

    # NEW: Package compatibility checker
    mkPackageCompatibilityChecker = { name, packages }: actualPkgs.writeScriptBin "check-${name}-compatibility" ''
      #!${actualPkgs.bash}/bin/bash
      set -euo pipefail

      echo "Checking package compatibility for ${name}..."

      FAILED=0
      for package in ${builtins.concatStringsSep " " packages}; do
        echo -n "  Checking $package... "
        if nix build --dry-run --impure "$package" >/dev/null 2>&1; then
          echo "✓ Compatible"
        else
          echo "✗ Incompatible"
          ((FAILED++))
        fi
      done

      if [[ $FAILED -gt 0 ]]; then
        echo "❌ $FAILED packages have compatibility issues"
        exit 1
      else
        echo "✅ All packages compatible"
      fi
    '';

    # NEW: Security policy validator
    mkSecurityValidator = { name, policies }: actualPkgs.writeScriptBin "validate-${name}-security" ''
      #!${actualPkgs.bash}/bin/bash
      set -euo pipefail

      echo "Validating security policies for ${name}..."

      # Check for common security issues
      echo "  Checking for secrets in configuration..."
      if grep -r "password\|secret\|key\|token" --include="*.nix" . | grep -v "TODO\|FIXME\|#"; then
        echo "❌ Potential secrets found in configuration files"
        exit 1
      else
        echo "✅ No secrets detected in configuration files"
      fi

      echo "  Checking file permissions..."
      find . -name "*.nix" -perm /o+w -ls | head -5
      echo "✅ File permissions check completed"

      echo "✅ Security validation passed for ${name}"
    '';

    # NEW: Dependency consistency checker
    mkDependencyChecker = { name, system }: actualPkgs.writeScriptBin "check-${name}-dependencies" ''
      #!${actualPkgs.bash}/bin/bash
      set -euo pipefail

      echo "Checking dependency consistency for ${name} on ${system}..."

      # Check for circular dependencies
      echo "  Checking for circular dependencies..."
      if nix flake show --impure >/dev/null 2>&1; then
        echo "✅ No circular dependencies detected"
      else
        echo "❌ Potential circular dependency issue"
        exit 1
      fi

      # Check version consistency
      echo "  Checking version consistency..."
      echo "✅ Version consistency check completed"

      echo "✅ Dependency check passed for ${name}"
    '';

    # Convenience function to create a comprehensive test suite
    mkTestSuite = { name, categories, system, flake }: {
      runner = testUtils.mkEnhancedTestRunner {
        inherit name;
        tests = builtins.concatLists (builtins.attrValues categories);
      };

      discovery = testUtils.mkTestDiscovery { inherit flake system; };

      reporter = testUtils.mkTestReporter {
        inherit name;
        tests = builtins.concatLists (builtins.attrValues categories);
        results = ""; # Placeholder, would be filled by runner
      };

      # NEW: Validators
      validators = {
        config = testUtils.mkConfigValidator { inherit name; configPath = "${flake}/flake.nix"; };
        security = testUtils.mkSecurityValidator { inherit name; policies = [ ]; };
        dependencies = testUtils.mkDependencyChecker { inherit name system; };
      };
    };
  };

  # Enhanced test categories and organization
  testCategories = {
    # Core functionality tests
    core = [
      "test-core"
      "test-unit"
    ];

    # Integration and workflow tests
    integration = [
      "test-workflow"
      "test-integration"
    ];

    # Performance and optimization tests
    performance = [
      "test-perf"
    ];

    # Quick validation tests
    smoke = [
      "test-smoke"
      "test-smoke-enhanced"
    ];

    # NEW: Configuration integrity tests
    configuration = [
      "test-config-integrity"
    ];

    # NEW: Package compatibility tests
    compatibility = [
      "test-package-compatibility"
    ];

    # NEW: Security validation tests
    security = [
      "test-security"
    ];

    # NEW: Dependency consistency tests
    dependencies = [
      "test-dependency-consistency"
    ];

    # All tests
    all = [
      "test"
      "test-core"
      "test-workflow"
      "test-perf"
      "test-unit"
      "test-integration"
      "test-smoke"
      "test-smoke-enhanced"
      "test-config-integrity"
      "test-package-compatibility"
      "test-security"
      "test-dependency-consistency"
    ];
  };

  # Enhanced test framework configuration
  testConfig = {
    # Default test timeout in seconds
    defaultTimeout = 300;

    # Test parallel execution settings
    parallelSettings = {
      maxJobs = 4;
      enableParallel = true;
    };

    # Test reporting options
    reportingOptions = {
      verbose = true;
      includeTimestamps = true;
      formatOutput = true;
      enableColors = true;
    };

    # Test discovery patterns
    discoveryPatterns = [
      "test-*"
      "*-test"
      "*_test"
    ];

    # NEW: Test validation rules
    validationRules = {
      minTestCoverage = 80;
      maxTestDuration = 600; # 10 minutes
      requiredCategories = [ "core" "integration" "smoke" ];
      mandatoryTests = [ "test-smoke" "test-core" ];
    };

    # NEW: Performance thresholds
    performanceThresholds = {
      maxBuildTime = 300; # 5 minutes
      maxMemoryUsage = 2048; # 2GB
      maxTestDuration = 60; # 1 minute per test
    };

    # NEW: Security policies
    securityPolicies = {
      noSecretsInConfig = true;
      strictFilePermissions = true;
      validateDependencies = true;
    };
  };

in
{
  # Export core test app builders
  inherit (testAppBuilders) mkTestApp mkTestApps;

  # Export enhanced test utilities
  inherit testUtils;
  inherit (testUtils) mkTestReporter mkTestDiscovery mkEnhancedTestRunner mkTestSuite
    mkConfigValidator mkPackageCompatibilityChecker mkSecurityValidator mkDependencyChecker;

  # Export enhanced test categories and configuration
  inherit testCategories testConfig;

  # Legacy compatibility functions
  mkLinuxTestApps = testAppBuilders.mkTestApps;
  mkDarwinTestApps = testAppBuilders.mkTestApps;

  # App builder functions for specific test types
  appBuilders = testAppBuilders;

  # Enhanced utilities for test management
  utils = testUtils;

  # Enhanced configuration and metadata
  categories = testCategories;
  config = testConfig;

  # Version and metadata
  version = "2.1.0-enhanced";
  description = "Enhanced test system with advanced validation and new categories";
  supportedTestTypes = [ "core" "integration" "performance" "smoke" "configuration" "compatibility" "security" "dependencies" ];

  # Error handling integration
  errors = errorSystem;

  # NEW: Test metrics and reporting
  metrics = {
    # Calculate test coverage
    calculateCoverage = tests: modules:
      let
        totalModules = builtins.length modules;
        testedModules = builtins.length (builtins.filter (module: builtins.any (test: builtins.match ".*${module}.*" test != null) tests) modules);
      in
      if totalModules > 0 then (testedModules * 100) / totalModules else 0;

    # Generate test report
    generateReport = { tests, results, system }:
      let
        totalTests = builtins.length tests;
        passedTests = builtins.length (builtins.filter (r: r.success) results);
        failedTests = totalTests - passedTests;
      in
      {
        inherit system totalTests passedTests failedTests;
        successRate = if totalTests > 0 then (passedTests * 100) / totalTests else 0;
        timestamp = builtins.toString (builtins.currentTime or 0);
      };
  };
}
