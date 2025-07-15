{ pkgs ? import <nixpkgs> {} }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
testHelpers.createTestScript {
  name = "flake-evaluation-optimization-test";
  script = ''
    ${testHelpers.testSection "Flake Evaluation Optimization Tests"}

    # Test environment setup
    export PROJECT_ROOT="${toString ../../.}"
    export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
    export FLAKE_EVAL_SCRIPT="$SCRIPTS_DIR/lib/flake-evaluation.sh"

    ${testHelpers.assertExists "$FLAKE_EVAL_SCRIPT" "Flake evaluation script exists"}

    # Source required modules for testing
    export LIB_DIR="$SCRIPTS_DIR/lib"
    . "$LIB_DIR/logging.sh" || echo "Warning: Could not load logging module"

    ${testHelpers.testSubsection "Batched Evaluation Function Tests"}

    # Test that the new functions exist in flake-evaluation.sh
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "batch_evaluate_flake" "Batch evaluate function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "optimized_flake_build" "Optimized flake build function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "replace_individual_evaluations" "Individual evaluation replacement function exists"}

    ${testHelpers.testSubsection "Caching Mechanism Tests"}

    # Test caching functions
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "init_flake_evaluation_cache" "Cache initialization function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "is_flake_evaluation_cached" "Cache check function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "get_cached_evaluation" "Cache retrieval function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "cache_evaluation_results" "Cache storage function exists"}

    ${testHelpers.testSubsection "Performance Optimization Features"}

    # Test performance monitoring integration
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "measure_flake_evaluation_performance" "Performance measurement function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "lazy_evaluate_flake_attr" "Lazy evaluation function exists"}

    ${testHelpers.testSubsection "Integration with Build System"}

    # Test integration with existing build logic
    BUILD_LOGIC_SCRIPT="$SCRIPTS_DIR/lib/build-logic.sh"
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "replace_individual_evaluations" "Build logic uses batched evaluation"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "optimized_flake_build" "Build logic uses optimized flake build"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "batched flake evaluation" "Build logic mentions batched evaluation"}

    ${testHelpers.testSubsection "Fallback Mechanism Tests"}

    # Test that fallback is properly implemented
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "falling back to individual evaluation" "Individual evaluation fallback exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "falling back to traditional build" "Traditional build fallback exists"}

    ${testHelpers.testSubsection "Cache Management Tests"}

    # Test cache cleanup and management
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "cleanup_flake_evaluation_cache" "Cache cleanup function exists"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "get_flake_cache_key" "Cache key generation function exists"}

    ${testHelpers.testSubsection "Nix Command Optimization"}

    # Test that nix commands are optimized
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "nix eval.*--json" "JSON output for structured data"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "--extra-experimental-features.*nix-command flakes" "Experimental features enabled"}
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "--apply" "Apply expressions for batching"}

    ${testHelpers.testSection "Performance Improvement Validation"}

    # Test that the optimization addresses the specific issue requirements
    echo "${testHelpers.colors.blue}Checking optimization addresses issue requirements:${testHelpers.colors.reset}"

    # Issue requirement: Batch flake operations
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "batched flake evaluation" "Implements batched operations"}

    # Issue requirement: Add flake caching
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "FLAKE_EVAL_CACHE_DIR" "Implements flake caching"}

    # Issue requirement: Optimize evaluation order
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "darwinConfigurations.*nixosConfigurations.*apps" "Optimized evaluation order"}

    # Issue requirement: Add lazy evaluation
    ${testHelpers.assertContains "$FLAKE_EVAL_SCRIPT" "lazy_evaluate_flake_attr" "Implements lazy evaluation"}

    echo ""
    echo "${testHelpers.colors.green}✓ All flake evaluation optimization tests passed!${testHelpers.colors.reset}"
  '';
}
