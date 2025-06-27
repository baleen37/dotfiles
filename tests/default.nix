{ pkgs, flake ? null }:
let
  # Helper function to convert filename to valid Nix attribute name
  sanitizeName = name:
    let
      baseName = builtins.substring 0 ((builtins.stringLength name) - 4) name;
      # Replace hyphens with underscores for valid Nix attribute names
      sanitized = builtins.replaceStrings [ "-" ] [ "_" ] baseName;
    in
    sanitized;

  # Discover tests in a directory with a pattern
  discoverTests = dir: pattern:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        testFiles = builtins.filter
          (name:
            builtins.match pattern name != null
          )
          (builtins.attrNames entries);

        # Function to check if a test file needs lib parameter
        needsLib = file:
          let
            fileContent = builtins.readFile (dir + ("/" + file));
          in
          builtins.match ".*\\{ pkgs, lib,.*" fileContent != null;

      in
      builtins.listToAttrs (map
        (file: {
          name = sanitizeName file;
          value =
            if needsLib file then
              import (dir + ("/" + file)) { inherit pkgs flake; lib = pkgs.lib; src = ../.; }
            else
              import (dir + ("/" + file)) { inherit pkgs flake; src = ../.; };
        })
        testFiles)
    else { };

  # Current directory for legacy tests
  legacyDir = ./.;
  legacyEntries = builtins.readDir legacyDir;
  legacyFiles = builtins.filter
    (name:
      name != "default.nix" &&
      builtins.match ".*\\.nix" name != null &&
      # Only include files, not directories
      legacyEntries.${name} == "regular"
    )
    (builtins.attrNames legacyEntries);

  # Test categories with their patterns
  unitTests = discoverTests ./unit ".*-(unit|test)\\.nix";
  integrationTests = discoverTests ./integration ".*-integration\\.nix";
  e2eTests = discoverTests ./e2e ".*-e2e\\.nix";
  performanceTests = discoverTests ./performance ".*-perf\\.nix";

  # Refactor tests for configuration restructuring (disabled during consolidation)
  # refactorUnitTests = discoverTests ./refactor/unit ".*-unit\\.nix";
  # refactorIntegrationTests = discoverTests ./refactor/integration ".*-integration\\.nix";
  refactorUnitTests = {};
  refactorIntegrationTests = {};


  # Legacy tests (disabled during consolidation)
  # legacyTests = builtins.listToAttrs (map
  #   (file: {
  #     name = "legacy_" + (sanitizeName file);
  #     value = import (legacyDir + ("/" + file)) { inherit pkgs; };
  #   })
  #   legacyFiles);
  legacyTests = {};

  # Combine all tests with clear categorization
  allTests = unitTests // integrationTests // e2eTests // performanceTests;

  # Test metadata for reporting
  testMetadata = {
    categories = {
      unit = builtins.length (builtins.attrNames unitTests);
      integration = builtins.length (builtins.attrNames integrationTests);
      e2e = builtins.length (builtins.attrNames e2eTests);
      performance = builtins.length (builtins.attrNames performanceTests);
      refactor_unit = builtins.length (builtins.attrNames refactorUnitTests);
      refactor_integration = builtins.length (builtins.attrNames refactorIntegrationTests);
      legacy = builtins.length (builtins.attrNames legacyTests);
    };
    total = builtins.length (builtins.attrNames allTests);
  };

  # Add a special test that reports the framework status
  frameworkStatus = pkgs.runCommand "test-framework-status" { } ''
    echo "=== Test Framework Status ==="
    echo "Unit tests: ${toString testMetadata.categories.unit}"
    echo "Integration tests: ${toString testMetadata.categories.integration}"
    echo "E2E tests: ${toString testMetadata.categories.e2e}"
    echo "Performance tests: ${toString testMetadata.categories.performance}"
    echo "Refactor unit tests: ${toString testMetadata.categories.refactor_unit}"
    echo "Refactor integration tests: ${toString testMetadata.categories.refactor_integration}"
    echo "Legacy tests: ${toString testMetadata.categories.legacy}"
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
