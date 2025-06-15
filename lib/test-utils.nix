# Test utilities and helpers
# Provides test discovery and reporting functionality

{ pkgs }:

let
  # Create a test reporter that generates formatted output
  mkTestReporter = { name, tests, results }: pkgs.writeScriptBin "test-reporter" ''
    #!${pkgs.bash}/bin/bash
    
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
  mkTestDiscovery = { flake, system }: pkgs.writeScriptBin "discover-tests" ''
    #!${pkgs.bash}/bin/bash
    
    echo "Discovering tests for ${system}..."
    echo ""
    
    # Get all test attributes from checks
    nix eval --json --impure ${flake}#checks.${system} 2>/dev/null | \
      ${pkgs.jq}/bin/jq -r 'to_entries | group_by(.key | split("_")[-1]) | 
        map({
          category: .[0].key | split("_")[-1],
          tests: map(.key)
        }) | 
        .[] | 
        "Category: \(.category)\n" + 
        (.tests | map("  - " + .) | join("\n")) + "\n"'
  '';

  # Enhanced test runner with better error handling and reporting
  mkEnhancedTestRunner = { name, tests }: pkgs.writeScriptBin "run-${name}-tests" ''
    #!${pkgs.bash}/bin/bash
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

in
{
  inherit mkTestReporter mkTestDiscovery mkEnhancedTestRunner;
  
  # Convenience function to create a comprehensive test suite
  mkTestSuite = { name, categories, system, flake }: {
    runner = mkEnhancedTestRunner {
      inherit name;
      tests = builtins.concatLists (builtins.attrValues categories);
    };
    
    discovery = mkTestDiscovery { inherit flake system; };
    
    reporter = mkTestReporter {
      inherit name;
      tests = builtins.concatLists (builtins.attrValues categories);
      results = ""; # Placeholder, would be filled by runner
    };
  };
}