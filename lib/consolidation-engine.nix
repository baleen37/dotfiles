# Consolidation Engine for Test File Management
# Handles the logic for consolidating 133 test files into 35 organized groups

{ pkgs, lib }:

let
  templateEngine = import ./template-engine.nix { inherit pkgs lib; };
in

rec {
  # Generate a single consolidated test file
  generateConsolidatedTestFile = categoryName: categoryData: pkgs.writeText "${categoryName}.nix" ''
    # ${categoryData.description}
    # Consolidated test file for category: ${categoryName}
    # Original files count: ${toString (lib.length categoryData.files)}
    
    { pkgs, lib, ... }:
    
    let
      testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
      
      # Import all original test logic
      runOriginalTests = pkgs.writeScript "run-${categoryName}-tests" ''
        #!/bin/bash
        set -e
        
        echo "Running consolidated tests for: ${categoryData.description}"
        echo "Testing ${toString (lib.length categoryData.files)} original test files..."
        
        # Track test results
        PASSED=0
        FAILED=0
        
        ${lib.concatStringsSep "\n        " (map (file: ''
          echo "Executing ${file}..."
          if nix-build --no-out-link "${file}" >/dev/null 2>&1; then
            echo "  ✓ ${file} PASSED"
            PASSED=$((PASSED+1))
          else
            echo "  ✗ ${file} FAILED"
            FAILED=$((FAILED+1))
          fi
        '') categoryData.files)}
        
        echo "Results for ${categoryName}:"
        echo "  Passed: $PASSED"
        echo "  Failed: $FAILED"
        echo "  Total:  ${toString (lib.length categoryData.files)}"
        
        if [ $FAILED -gt 0 ]; then
          echo "ERROR: Some tests failed in ${categoryName}"
          exit 1
        fi
        
        echo "All tests in ${categoryName} completed successfully"
      '';
    in
    
    pkgs.stdenv.mkDerivation {
      name = "${categoryName}-consolidated-test";
      
      nativeBuildInputs = [ pkgs.nix ];
      
      buildCommand = ''
        # Execute the consolidated test script
        ${runOriginalTests}
        
        # Create success marker
        touch $out
        echo "Consolidated test ${categoryName} completed successfully" > $out
      '';
      
      meta = {
        description = categoryData.description;
        originalFiles = categoryData.files;
        category = categoryName;
      };
    }
  '';
  
  # Generate all 35 consolidated test files
  generateAllConsolidatedTests = 
    lib.mapAttrs generateConsolidatedTestFile templateEngine.testCategories;
  
  # Create directory structure for consolidated tests
  createConsolidatedTestStructure = pkgs.runCommand "consolidated-tests" {} ''
    mkdir -p $out/tests-consolidated/{unit,integration,e2e,performance,lib}
    
    # Generate README for consolidated tests
    cat > $out/tests-consolidated/README.md << 'EOF'
    # Consolidated Test Suite
    
    This directory contains 35 consolidated test files that replace the original 133 test files.
    Each consolidated test maintains the same functionality as the original tests while providing
    better organization and faster execution.
    
    ## Test Categories
    
    ${lib.concatStringsSep "\n    " (lib.mapAttrsToList (name: data: 
      "- **${name}**: ${data.description} (${toString (lib.length data.files)} original files)"
    ) templateEngine.testCategories)}
    
    ## Usage
    
    Run all consolidated tests:
    ```bash
    nix-build tests-consolidated/
    ```
    
    Run specific category:
    ```bash
    nix-build tests-consolidated/01-core-system.nix
    ```
    EOF
    
    # Copy consolidated test files
    ${lib.concatStringsSep "\n    " (lib.mapAttrsToList (name: testFile: ''
      cp ${testFile} $out/tests-consolidated/${name}.nix
    '') generateAllConsolidatedTests)}
    
    # Create default.nix that runs all consolidated tests
    cat > $out/tests-consolidated/default.nix << 'EOF'
    { pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:
    
    let
      consolidatedTests = {
        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: _: 
          "${name} = import ./${name}.nix { inherit pkgs lib; };"
        ) templateEngine.testCategories)}
      };
    in
    
    pkgs.stdenv.mkDerivation {
      name = "all-consolidated-tests";
      
      buildCommand = ''
        echo "Running all 35 consolidated test categories..."
        
        # Run each consolidated test
        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: _: ''
          echo "Running ${name}..."
          nix-build --no-out-link ${name}.nix
        '') templateEngine.testCategories)}
        
        echo "All consolidated tests completed successfully!"
        touch $out
      '';
    }
    EOF
  '';
  
  # Validation function to ensure all original tests are covered
  validateConsolidation = 
    let
      allCategorizedFiles = lib.concatLists (lib.mapAttrsToList (name: data: data.files) templateEngine.testCategories);
      allExistingTests = import ./existing-tests.nix;
      uncategorizedTests = lib.filter (test: !(lib.elem test allCategorizedFiles)) allExistingTests;
      missingTests = lib.filter (test: !(lib.elem test allExistingTests)) allCategorizedFiles;
    in
    pkgs.writeText "consolidation-validation.json" (builtins.toJSON {
      totalOriginalTests = lib.length allExistingTests;
      totalCategorizedTests = lib.length allCategorizedFiles;
      consolidatedCategories = lib.length (lib.attrNames templateEngine.testCategories);
      uncategorizedTests = uncategorizedTests;
      missingTests = missingTests;
      isComplete = (uncategorizedTests == []) && (missingTests == []);
    });
}