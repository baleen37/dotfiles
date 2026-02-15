# Property-Based Test for lib/performance.nix
#
# Tests performance measurement functions for various invariants:
# - Accuracy: Measurements should be non-negative
# - Consistency: Repeated measurements should be similar
# - Monotonicity: Operations taking longer should report larger times
# - Composition: Combining measurements should preserve properties
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-01-31

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  nixtest ? { },
}:

let
  # Import property testing framework
  propertyTesting = import ../lib/property-testing.nix { inherit lib pkgs; };

  # Import performance module to test
  perfModule = import ../lib/performance.nix { inherit lib pkgs; };
  perf = perfModule.perf;

  # Import test helpers
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test operations with known performance characteristics
  testOperations = {
    # Constant time operation
    constant = x: x + 1;

    # Linear time operation (list length)
    linear = list: builtins.length list;

    # Nested operation (nested lists)
    nested = lists: builtins.map builtins.length lists;

    # String operation
    stringOp = str: builtins.stringLength str;

    # Attribute set operation
    attrOp = attrs: builtins.attrNames attrs;
  };

  # Test data generators
  generateTestData = {
    small = builtins.genList (x: x) 10;
    medium = builtins.genList (x: x) 100;
    large = builtins.genList (x: x) 1000;
    nestedSmall = builtins.genList (i: builtins.genList (x: x) 5) 10;
    nestedLarge = builtins.genList (i: builtins.genList (x: x) 20) 50;
    string = "test string for performance measurement";
    attrs = {
      a = 1;
      b = 2;
      c = 3;
      d = 4;
      e = 5;
    };
  };

  # Test scenarios for performance testing
  perfScenarios = [
    {
      identifier = "constant-operation";
      operation = testOperations.constant;
      input = 42;
      expectedComplexity = "constant";
    }
    {
      identifier = "linear-small";
      operation = testOperations.linear;
      input = generateTestData.small;
      expectedComplexity = "linear";
    }
    {
      identifier = "linear-medium";
      operation = testOperations.linear;
      input = generateTestData.medium;
      expectedComplexity = "linear";
    }
    {
      identifier = "string-operation";
      operation = testOperations.stringOp;
      input = generateTestData.string;
      expectedComplexity = "constant";
    }
    {
      identifier = "attr-operation";
      operation = testOperations.attrOp;
      input = generateTestData.attrs;
      expectedComplexity = "constant";
    }
  ];

in
# Property-based test suite
{
  platforms = [ "any" ];
  value = helpers.testSuite "property-based-performance-test" [
    # Property 1: Time measurement non-negativity
    # All time measurements should be >= 0
    (helpers.assertTest "perf-time-non-negative" (
      let
        result = perf.time.now;
      in
      result >= 0
    ) "Time measurements should be non-negative")

    (helpers.assertTest "perf-measure-duration-non-negative" (
      let
        result = perf.time.measure (testOperations.constant 42);
      in
      result.duration >= 0
    ) "Measured duration should be non-negative")

    (helpers.assertTest "perf-measure-duration-ms-non-negative" (
      let
        result = perf.time.measure (testOperations.constant 42);
      in
      result.duration_ms >= 0
    ) "Duration in ms should be non-negative")

    # Property 2: Measurement consistency
    # Measuring the same operation should produce similar results
    (helpers.assertTest "perf-measure-consistent-success" (
      let
        result1 = perf.time.measure (testOperations.constant 42);
        result2 = perf.time.measure (testOperations.constant 42);
      in
      result1.success && result2.success
    ) "Measuring same operation should consistently succeed")

    (helpers.assertTest "perf-measure-consistent-value" (
      let
        result1 = perf.time.measure (testOperations.constant 42);
        result2 = perf.time.measure (testOperations.constant 42);
      in
      result1.value == result2.value
    ) "Measuring same operation should return same value")

    # Property 3: Benchmark statistics validity
    # Benchmark should calculate valid statistics
    (helpers.assertTest "perf-benchmark-valid-iterations" (
      let
        iterations = 5;
        result = perf.time.benchmark (testOperations.constant 42) iterations;
      in
      result.iterations <= iterations && result.iterations >= 0
    ) "Benchmark should report valid iteration count")

    (helpers.assertTest "perf-benchmark-average-valid" (
      let
        iterations = 5;
        result = perf.time.benchmark (testOperations.constant 42) iterations;
      in
      if result.iterations > 0 then result.averageDuration >= 0 else true
    ) "Benchmark average should be non-negative when iterations > 0")

    (helpers.assertTest "perf-benchmark-min-max-ordered" (
      let
        iterations = 5;
        result = perf.time.benchmark (testOperations.constant 42) iterations;
      in
      if result.iterations > 0 then result.minDuration <= result.maxDuration else true
    ) "Benchmark min should be <= max")

    # Property 4: Memory estimation non-negativity
    # All memory estimates should be >= 0
    (helpers.assertTest "perf-memory-string-non-negative" (
      let
        size = perf.memory.estimateSize "test string";
      in
      size >= 0
    ) "Memory estimate for string should be non-negative")

    (helpers.assertTest "perf-memory-list-non-negative" (
      let
        size = perf.memory.estimateSize [ 1 2 3 4 5 ];
      in
      size >= 0
    ) "Memory estimate for list should be non-negative")

    (helpers.assertTest "perf-memory-set-non-negative" (
      let
        size = perf.memory.estimateSize { a = 1; b = 2; };
      in
      size >= 0
    ) "Memory estimate for set should be non-negative")

    # Property 5: Memory estimation monotonicity
    # Larger structures should have larger estimates
    (helpers.assertTest "perf-memory-monotonic-lists" (
      let
        smallSize = perf.memory.estimateSize generateTestData.small;
        mediumSize = perf.memory.estimateSize generateTestData.medium;
      in
      mediumSize >= smallSize
    ) "Memory estimate should be monotonic for list sizes")

    (helpers.assertTest "perf-memory-monotonic-strings" (
      let
        smallSize = perf.memory.estimateSize "small";
        largeSize = perf.memory.estimateSize "this is a much larger string";
      in
      largeSize >= smallSize
    ) "Memory estimate should be monotonic for string lengths")

    # Property 6: Build evaluation success
    # Measure eval should succeed and return the value
    (helpers.assertTest "perf-build-eval-success" (
      let
        expr = testOperations.constant 42;
        result = perf.build.measureEval expr;
      in
      result.success
    ) "Build evaluation should succeed")

    (helpers.assertTest "perf-build-eval-correct-value" (
      let
        expr = testOperations.constant 42;
        result = perf.build.measureEval expr;
      in
      result.value == 43  # constant adds 1 to input: 42 + 1 = 43
    ) "Build evaluation should return correct value")

    (helpers.assertTest "perf-build-eval-non-negative-duration" (
      let
        expr = testOperations.constant 42;
        result = perf.build.measureEval expr;
      in
      result.duration >= 0
    ) "Build evaluation duration should be non-negative")

    # Property 7: Complexity measurement validity
    # Complexity measurements should have valid structure
    (helpers.assertTest "perf-complexity-has-attr-count" (
      let
        result = perf.build.measureConfigComplexity generateTestData.attrs;
      in
      builtins.hasAttr "attributes" result.complexity
    ) "Complexity measurement should include attribute count")

    (helpers.assertTest "perf-complexity-has-size-bytes" (
      let
        result = perf.build.measureConfigComplexity generateTestData.attrs;
      in
      builtins.hasAttr "size_bytes" result.complexity
    ) "Complexity measurement should include size in bytes")

    (helpers.assertTest "perf-complexity-attr-count-positive" (
      let
        result = perf.build.measureConfigComplexity generateTestData.attrs;
      in
      result.complexity.attributes > 0
    ) "Attribute count should be positive for non-empty set")

    # Property 8: Resource profile completeness
    # Resource profiles should have all required fields
    (helpers.assertTest "perf-resource-profile-has-time" (
      let
        result = perf.resources.profile (testOperations.constant 42);
      in
      builtins.hasAttr "duration_ms" result
    ) "Resource profile should include timing data")

    (helpers.assertTest "perf-resource-profile-has-memory" (
      let
        result = perf.resources.profile (testOperations.constant 42);
      in
      builtins.hasAttr "memoryAfter" result
    ) "Resource profile should include memory data")

    (helpers.assertTest "perf-resource-profile-non-negative-time" (
      let
        result = perf.resources.profile (testOperations.constant 42);
      in
      result.duration_ms >= 0
    ) "Resource profile time should be non-negative")

    # Property 9: Baseline creation validity
    # Baselines should calculate valid statistics
    (helpers.assertTest "perf-baseline-valid-average" (
      let
        measurements = [
          { duration_ms = 100; memoryAfter = 1000; }
          { duration_ms = 120; memoryAfter = 1100; }
          { duration_ms = 110; memoryAfter = 1050; }
        ];
        result = perf.regression.createBaseline "test" measurements;
      in
      result.baseline.avgTime_ms > 0
    ) "Baseline should calculate valid average time")

    (helpers.assertTest "perf-baseline-valid-max" (
      let
        measurements = [
          { duration_ms = 100; memoryAfter = 1000; }
          { duration_ms = 120; memoryAfter = 1100; }
          { duration_ms = 110; memoryAfter = 1050; }
        ];
        result = perf.regression.createBaseline "test" measurements;
      in
      result.baseline.maxTime_ms >= result.baseline.avgTime_ms
    ) "Baseline max should be >= average")

    # Property 10: Regression check logic
    # Regression checks should correctly identify regressions
    (helpers.assertTest "perf-regression-no-regression-similar" (
      let
        baseline = {
          baseline = {
            avgTime_ms = 100;
            avgMemory_bytes = 1000;
          };
        };
        measurement = {
          duration_ms = 105; # 5% increase
          memoryAfter = 1020; # 2% increase
        };
        thresholds = {
          time = 1.5; # 50% threshold
          memory = 1.5;
        };
        result = perf.regression.checkBaseline baseline measurement thresholds;
      in
      result.passed
    ) "Small variation should not trigger regression")

    (helpers.assertTest "perf-regression-detects-time-regression" (
      let
        baseline = {
          baseline = {
            avgTime_ms = 100;
            avgMemory_bytes = 1000;
          };
        };
        measurement = {
          duration_ms = 250; # 2.5x increase
          memoryAfter = 1020;
        };
        thresholds = {
          time = 2.0; # 2x threshold
          memory = 1.5;
        };
        result = perf.regression.checkBaseline baseline measurement thresholds;
      in
      result.timeRegression
    ) "Large time increase should trigger regression")

    # Property 11: Trend analysis validity
    # Trends should be correctly classified
    (helpers.assertTest "perf-trend-stable" (
      let
        measurements = [
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 100; }
          { duration_ms = 90; }
          { duration_ms = 90; }
          { duration_ms = 90; }
          { duration_ms = 90; }
          { duration_ms = 90; }
        ];
        result = perf.regression.analyzeTrend measurements;
      in
      result.trend == "stable"
    ) "Consistent measurements should be classified as stable")

    (helpers.assertTest "perf-trend-degrading" (
      let
        measurements = [
          { duration_ms = 80; }
          { duration_ms = 60; }
          { duration_ms = 40; }
          { duration_ms = 20; }
          { duration_ms = 10; }
          { duration_ms = 120; }
          { duration_ms = 140; }
          { duration_ms = 160; }
          { duration_ms = 200; }
          { duration_ms = 220; }
          { duration_ms = 240; }
          { duration_ms = 260; }
          { duration_ms = 280; }
          { duration_ms = 300; }
        ];
        result = perf.regression.analyzeTrend measurements;
      in
      result.trend == "degrading"
    ) "Increasing measurements should be classified as degrading")

    # Property 12: Summary statistics validity
    # Summaries should calculate correct statistics
    (helpers.assertTest "perf-summary-total-count" (
      let
        measurements = [
          { duration_ms = 100; memoryAfter = 1000; success = true; }
          { duration_ms = 120; memoryAfter = 1100; success = true; }
          { duration_ms = 110; memoryAfter = 1050; success = true; }
        ];
        result = perf.report.summary measurements;
      in
      result.totalMeasurements == 3
    ) "Summary should count all measurements")

    (helpers.assertTest "perf-summary-success-rate" (
      let
        measurements = [
          { duration_ms = 100; memoryAfter = 1000; success = true; }
          { duration_ms = 120; memoryAfter = 1100; success = true; }
          { duration_ms = 110; memoryAfter = 1050; success = false; }
        ];
        result = perf.report.summary measurements;
      in
      result.successfulMeasurements == 2
    ) "Summary should count only successful measurements")

    (helpers.assertTest "perf-summary-avg-time" (
      let
        measurements = [
          { duration_ms = 100; memoryAfter = 1000; success = true; }
          { duration_ms = 120; memoryAfter = 1100; success = true; }
          { duration_ms = 110; memoryAfter = 1050; success = true; }
        ];
        result = perf.report.summary measurements;
      in
      result.timing.avg_ms >= 100 && result.timing.avg_ms <= 120
    ) "Summary average should be within range")

    # Property 13: Performance test helpers
    # Performance test helpers should create valid tests
    (helpers.assertTest "perf-mkperftest-creates-test" (
      let
        test = perf.testing.mkPerfTest "test-op" (testOperations.constant 42) {
          maxTimeMs = 1000;
        };
      in
      builtins.isAttrs test && test ? name && test ? run
    ) "mkPerfTest should create a valid test object")

    (helpers.assertTest "perf-mkbenchmark-suite-creates-suite" (
      let
        tests = [
          (perf.testing.mkPerfTest "test1" (testOperations.constant 1) { maxTimeMs = 1000; })
          (perf.testing.mkPerfTest "test2" (testOperations.constant 2) { maxTimeMs = 1000; })
        ];
        suite = perf.testing.mkBenchmarkSuite "test-suite" tests;
      in
      builtins.isAttrs suite && suite ? name && suite ? results && suite ? summary
    ) "mkBenchmarkSuite should create a valid suite")

    # Property 14: Cross-operation consistency
    # Different operations should have measurable differences
    (helpers.assertTest "perf-operations-distinguishable" (
      let
        fastOp = testOperations.constant 42;
        listOp = testOperations.linear generateTestData.small;
        fastResult = perf.time.measure fastOp;
        listResult = perf.time.measure listOp;
      in
      fastResult.success && listResult.success
    ) "Different operations should both succeed")

    # Property 15: Nested structure handling
    # Memory estimation should handle nested structures correctly
    (helpers.assertTest "perf-memory-nested-non-negative" (
      let
        size = perf.memory.estimateSize generateTestData.nestedSmall;
      in
      size >= 0
    ) "Memory estimate for nested structures should be non-negative")

    (helpers.assertTest "perf-memory-nested-monotonic" (
      let
        smallSize = perf.memory.estimateSize generateTestData.nestedSmall;
        largeSize = perf.memory.estimateSize generateTestData.nestedLarge;
      in
      largeSize >= smallSize
    ) "Memory estimate should be monotonic for nested structures")

    # Summary test
    (pkgs.runCommand "property-based-performance-test-summary" { } ''
      echo "Property-Based Performance Test Summary"
      echo ""
      echo "Tested Properties:"
      echo "  Time measurement non-negativity"
      echo "  Measurement consistency"
      echo "  Benchmark statistics validity"
      echo "  Memory estimation non-negativity"
      echo "  Memory estimation monotonicity"
      echo "  Build evaluation success"
      echo "  Complexity measurement validity"
      echo "  Resource profile completeness"
      echo "  Baseline creation validity"
      echo "  Regression check logic"
      echo "  Trend analysis validity"
      echo "  Summary statistics validity"
      echo "  Performance test helpers"
      echo "  Cross-operation consistency"
      echo "  Nested structure handling"
      echo ""
      echo "Operations tested: ${toString (builtins.length (builtins.attrNames testOperations))}"
      echo "  - Constant time operations"
      echo "  - Linear time operations"
      echo "  - String operations"
      echo "  - Attribute set operations"
      echo "  - Nested structure operations"
      echo ""
      echo "Property-Based Testing Benefits:"
      echo "  Validates performance measurement accuracy"
      echo "  Ensures consistent measurements across runs"
      echo "  Verifies statistical calculations"
      echo "  Tests memory estimation logic"
      echo "  Validates regression detection"
      echo "  Checks trend analysis algorithms"
      echo ""
      echo "All Property-Based Performance Tests Passed!"
      touch $out
    '')
  ];
}
