# tests/unit/lib-performance-test.nix
# Unit tests for lib/performance.nix core functions
# Tests time measurement, memory estimation, and regression detection

{
  inputs,
  system,
  pkgs,
  lib,
  self,
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  perf = import ../../lib/performance.nix { inherit lib pkgs; };

in
{
  # Test 1: Time measurement functions
  time-measurement = testHelpers.assertTest "time-measurement-functions-exist" (
    builtins.hasAttr "time" perf.perf
    && builtins.hasAttr "now" perf.perf.time
    && builtins.hasAttr "measure" perf.perf.time
  ) "Time measurement functions not found";

  # Test 2: Memory estimation functions exist
  memory-functions-exist = testHelpers.assertTest "memory-functions-exist" (
    builtins.hasAttr "memory" perf.perf
    && builtins.hasAttr "estimateSize" perf.perf.memory
    && builtins.hasAttr "monitor" perf.perf.memory
  ) "Memory functions not found";

  # Test 3: Build performance functions exist
  build-functions-exist = testHelpers.assertTest "build-functions-exist" (
    builtins.hasAttr "build" perf.perf
    && builtins.hasAttr "measureEval" perf.perf.build
    && builtins.hasAttr "measureConfigComplexity" perf.perf.build
  ) "Build performance functions not found";

  # Test 4: Memory estimation for string
  memory-estimate-string = testHelpers.assertTestWithDetails "memory-estimate-string"
    (perf.perf.memory.estimateSize "hello")
    5
    "String memory estimation should return string length";

  # Test 5: Memory estimation for empty string
  memory-estimate-empty-string = testHelpers.assertTestWithDetails "memory-estimate-empty-string"
    (perf.perf.memory.estimateSize "")
    0
    "Empty string should have 0 size";

  # Test 6: Memory estimation for list
  memory-estimate-list = testHelpers.assertTest "memory-estimate-list"
    (perf.perf.memory.estimateSize [1 2 3] > 0)
    "List memory estimation should be positive";

  # Test 7: Memory estimation for attrset
  memory-estimate-attrset = testHelpers.assertTest "memory-estimate-attrset"
    (perf.perf.memory.estimateSize { a = 1; b = 2; } > 0)
    "Attrset memory estimation should be positive";

  # Test 8: Memory estimation for nested structures
  memory-estimate-nested = testHelpers.assertTest "memory-estimate-nested"
    (perf.perf.memory.estimateSize { list = [1 2 3]; nested = { a = "test"; }; } > 0)
    "Nested structure memory estimation should be positive";

  # Test 9: Legacy exports are available
  legacy-exports = testHelpers.assertTest "legacy-exports-available"
    (builtins.hasAttr "measure" perf
    && builtins.hasAttr "estimateSize" perf
    && builtins.hasAttr "createBaseline" perf
    && builtins.hasAttr "checkBaseline" perf
    && builtins.hasAttr "analyzeTrend" perf)
    "Legacy exports should be available for backward compatibility";

  # Test 10: Regression functions exist
  regression-functions-exist = testHelpers.assertTest "regression-functions-exist" (
    builtins.hasAttr "regression" perf.perf
    && builtins.hasAttr "createBaseline" perf.perf.regression
    && builtins.hasAttr "checkBaseline" perf.perf.regression
    && builtins.hasAttr "analyzeTrend" perf.perf.regression
  ) "Regression functions not found";

  # Test 11: Report functions exist
  report-functions-exist = testHelpers.assertTest "report-functions-exist" (
    builtins.hasAttr "report" perf.perf
    && builtins.hasAttr "summary" perf.perf.report
    && builtins.hasAttr "formatResults" perf.perf.report
  ) "Report functions not found";

  # Test 12: Testing helpers exist
  testing-functions-exist = testHelpers.assertTest "testing-functions-exist" (
    builtins.hasAttr "testing" perf.perf
    && builtins.hasAttr "mkPerfTest" perf.perf.testing
    && builtins.hasAttr "mkBenchmarkSuite" perf.perf.testing
  ) "Testing helpers not found";

  # Test 13: Resource monitoring functions exist
  resources-functions-exist = testHelpers.assertTest "resources-functions-exist" (
    builtins.hasAttr "resources" perf.perf
    && builtins.hasAttr "profile" perf.perf.resources
    && builtins.hasAttr "compare" perf.perf.resources
  ) "Resource monitoring functions not found";

  # Test 14: Baseline creation works
  baseline-creation = testHelpers.assertTest "baseline-creation"
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
  baseline-check-pass = testHelpers.assertTest "baseline-check-pass"
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
  baseline-check-fail = testHelpers.assertTest "baseline-check-fail-time"
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
  trend-analysis-stable = testHelpers.assertTest "trend-analysis-stable"
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
  trend-analysis-improving = testHelpers.assertTest "trend-analysis-improving"
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
  trend-analysis-degrading = testHelpers.assertTest "trend-analysis-degrading"
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
  summary-generation = testHelpers.assertTest "summary-generation"
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
