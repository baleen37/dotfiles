# ============================================================================
# DISABLED TEST - lib-performance-functions-test.nix
# ============================================================================
#
# WHAT THIS TESTS:
#   Core unit tests for lib/performance.nix functions. Tests cover:
#   - Time measurement: perf.time.now, perf.time.measure
#   - Memory estimation: perf.memory.estimateSize for strings, lists, attrsets,
#     nested structures
#   - Build performance: perf.build.measureEval, perf.build.measureConfigComplexity
#   - Regression detection: perf.perf.regression.createBaseline, checkBaseline,
#     analyzeTrend (stable/improving/degrading)
#   - Report generation: perf.perf.report.summary with statistics
#   - Testing helpers: perf.perf.testing.mkPerfTest, mkBenchmarkSuite
#   - Resource monitoring: perf.perf.resources.profile, compare
#   - Legacy exports: Backward compatibility layer
#
# WHY DISABLED:
#   This is the foundational performance testing suite that validates core
#   functionality. It's disabled likely due to:
#   1. Core performance.nix framework may still be in experimental state
#   2. Some functions may rely on features not available in pure Nix evaluation
#   3. Memory estimation may be approximate and not testable reliably
#   4. Time measurement functions may have implementation issues
#   5. The entire performance monitoring system may be undergoing refactoring
#
# WHAT WOULD NEED TO BE FIXED TO RE-ENABLE:
#   1. Complete and stabilize the core performance.nix API
#   2. Ensure all functions work correctly in pure Nix evaluation context
#   3. Fix any implementation issues with time/memory measurement
#   4. Add proper error handling for edge cases
#   5. Verify regression detection algorithms are correct
#   6. Test thoroughly across different Nix versions and platforms
#   7. Rename file from .nix.disabled to .nix to re-enable
#
# WHEN DISABLED:
#   Date unknown (file was already disabled when this documentation was added)
#   Documentation added: 2026-01-08
#
# TOTAL TESTS: 20 tests covering core performance functionality
# ============================================================================

# tests/unit/lib-performance-test.nix
# Unit tests for lib/performance.nix core functions
# Tests time measurement, memory estimation, and regression detection

{
  inputs,
  system,
  nixtest ? { },
  pkgs,
  lib,
  self,
}:

let
  helpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  perf = import ../../lib/performance.nix { inherit lib pkgs; };

in
{
  # Test 1: Time measurement functions
  time-measurement = helpers.assertTest "time-measurement-functions-exist" (
    builtins.hasAttr "time" perf.perf
    && builtins.hasAttr "now" perf.perf.time
    && builtins.hasAttr "measure" perf.perf.time
  ) "Time measurement functions not found";

  # Test 2: Memory estimation functions exist
  memory-functions-exist = helpers.assertTest "memory-functions-exist" (
    builtins.hasAttr "memory" perf.perf
    && builtins.hasAttr "estimateSize" perf.perf.memory
    && builtins.hasAttr "monitor" perf.perf.memory
  ) "Memory functions not found";

  # Test 3: Build performance functions exist
  build-functions-exist = helpers.assertTest "build-functions-exist" (
    builtins.hasAttr "build" perf.perf
    && builtins.hasAttr "measureEval" perf.perf.build
    && builtins.hasAttr "measureConfigComplexity" perf.perf.build
  ) "Build performance functions not found";

  # Test 4: Memory estimation for string
  memory-estimate-string = helpers.assertTestWithDetails "memory-estimate-string"
    (perf.perf.memory.estimateSize "hello")
    5
    "String memory estimation should return string length";

  # Test 5: Memory estimation for empty string
  memory-estimate-empty-string = helpers.assertTestWithDetails "memory-estimate-empty-string"
    (perf.perf.memory.estimateSize "")
    0
    "Empty string should have 0 size";

  # Test 6: Memory estimation for list
  memory-estimate-list = helpers.assertTest "memory-estimate-list"
    (perf.perf.memory.estimateSize [1 2 3] > 0)
    "List memory estimation should be positive";

  # Test 7: Memory estimation for attrset
  memory-estimate-attrset = helpers.assertTest "memory-estimate-attrset"
    (perf.perf.memory.estimateSize { a = 1; b = 2; } > 0)
    "Attrset memory estimation should be positive";

  # Test 8: Memory estimation for nested structures
  memory-estimate-nested = helpers.assertTest "memory-estimate-nested"
    (perf.perf.memory.estimateSize { list = [1 2 3]; nested = { a = "test"; }; } > 0)
    "Nested structure memory estimation should be positive";

  # Test 9: Legacy exports are available
  legacy-exports = helpers.assertTest "legacy-exports-available"
    (builtins.hasAttr "measure" perf
    && builtins.hasAttr "estimateSize" perf
    && builtins.hasAttr "createBaseline" perf
    && builtins.hasAttr "checkBaseline" perf
    && builtins.hasAttr "analyzeTrend" perf)
    "Legacy exports should be available for backward compatibility";

  # Test 10: Regression functions exist
  regression-functions-exist = helpers.assertTest "regression-functions-exist" (
    builtins.hasAttr "regression" perf.perf
    && builtins.hasAttr "createBaseline" perf.perf.regression
    && builtins.hasAttr "checkBaseline" perf.perf.regression
    && builtins.hasAttr "analyzeTrend" perf.perf.regression
  ) "Regression functions not found";

  # Test 11: Report functions exist
  report-functions-exist = helpers.assertTest "report-functions-exist" (
    builtins.hasAttr "report" perf.perf
    && builtins.hasAttr "summary" perf.perf.report
    && builtins.hasAttr "formatResults" perf.perf.report
  ) "Report functions not found";

  # Test 12: Testing helpers exist
  testing-functions-exist = helpers.assertTest "testing-functions-exist" (
    builtins.hasAttr "testing" perf.perf
    && builtins.hasAttr "mkPerfTest" perf.perf.testing
    && builtins.hasAttr "mkBenchmarkSuite" perf.perf.testing
  ) "Testing helpers not found";

  # Test 13: Resource monitoring functions exist
  resources-functions-exist = helpers.assertTest "resources-functions-exist" (
    builtins.hasAttr "resources" perf.perf
    && builtins.hasAttr "profile" perf.perf.resources
    && builtins.hasAttr "compare" perf.perf.resources
  ) "Resource monitoring functions not found";

  # Test 14: Baseline creation works
  baseline-creation = helpers.assertTest "baseline-creation"
    (let
      baseline = perf.perf.regression.createBaseline "test" [
        { duration_ms = 100; memoryAfter = 1000; }
        { duration_ms = 200; memoryAfter = 2000; }
      ];
    in
    builtins.hasAttr "baseline" baseline
    && builtins.hasAttr "name" baseline
    && baseline.name == "test"
    && baseline.baseline.avgTime_ms == 150
    && baseline.baseline.avgMemory_bytes == 1500)
    "Baseline creation should calculate averages correctly";

  # Test 15: Baseline check with passing thresholds
  baseline-check-pass = helpers.assertTest "baseline-check-pass"
    (let
      baseline = perf.perf.regression.createBaseline "test" [
        { duration_ms = 100; memoryAfter = 1000; }
      ];
      measurement = { duration_ms = 150; memoryAfter = 1200; success = true; };
      result = perf.perf.regression.checkBaseline baseline measurement {
        time = 2.0;
        memory = 1.5;
      };
    in
    result.passed == true)
    "Baseline check should pass when within thresholds";

  # Test 16: Baseline check with failing thresholds
  baseline-check-fail = helpers.assertTest "baseline-check-fail-time"
    (let
      baseline = perf.perf.regression.createBaseline "test" [
        { duration_ms = 100; memoryAfter = 1000; }
      ];
      measurement = { duration_ms = 250; memoryAfter = 1200; success = true; };
      result = perf.perf.regression.checkBaseline baseline measurement {
        time = 2.0;
        memory = 1.5;
      };
    in
    result.passed == false && result.timeRegression == true)
    "Baseline check should fail when exceeding time threshold";

  # Test 17: Trend analysis - stable trend
  trend-analysis-stable = helpers.assertTest "trend-analysis-stable"
    (let
      measurements = [
        { duration_ms = 100; success = true; }
        { duration_ms = 105; success = true; }
        { duration_ms = 98; success = true; }
        { duration_ms = 102; success = true; }
        { duration_ms = 99; success = true; }
      ];
      result = perf.perf.regression.analyzeTrend measurements;
    in
    result.trend == "stable")
    "Trend analysis should detect stable performance";

  # Test 18: Trend analysis - improving trend
  trend-analysis-improving = helpers.assertTest "trend-analysis-improving"
    (let
      measurements = [
        { duration_ms = 200; success = true; }
        { duration_ms = 180; success = true; }
        { duration_ms = 160; success = true; }
        { duration_ms = 140; success = true; }
        { duration_ms = 120; success = true; }
      ];
      result = perf.perf.regression.analyzeTrend measurements;
    in
    result.trend == "improving")
    "Trend analysis should detect improving performance";

  # Test 19: Trend analysis - degrading trend
  trend-analysis-degrading = helpers.assertTest "trend-analysis-degrading"
    (let
      measurements = [
        { duration_ms = 100; success = true; }
        { duration_ms = 120; success = true; }
        { duration_ms = 140; success = true; }
        { duration_ms = 160; success = true; }
        { duration_ms = 180; success = true; }
      ];
      result = perf.perf.regression.analyzeTrend measurements;
    in
    result.trend == "degrading")
    "Trend analysis should detect degrading performance";

  # Test 20: Summary generation
  summary-generation = helpers.assertTest "summary-generation"
    (let
      measurements = [
        { duration_ms = 100; memoryAfter = 1000; success = true; }
        { duration_ms = 200; memoryAfter = 2000; success = true; }
      ];
      result = perf.perf.report.summary measurements;
    in
    builtins.hasAttr "totalMeasurements" result
    && result.totalMeasurements == 2
    && result.successRate == 1.0
    && result.timing.avg_ms == 150
    && result.memory.avg_bytes == 1500)
    "Summary should calculate correct statistics";
}
