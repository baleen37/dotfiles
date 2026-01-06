# tests/unit/lib-performance-baselines-test.nix
# Unit tests for lib/performance-baselines.nix baseline configuration
# Tests performance thresholds and system-specific baselines

{
  inputs,
  system,
  pkgs,
  lib,
  self,
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  baselines = import ../../lib/performance-baselines.nix { inherit lib pkgs; };

in
{
  # Test 1: Baseline exports exist
  exports-exist = testHelpers.assertTest "baselines-exports-exist" (
    builtins.hasAttr "systemBaselines" baselines
    && builtins.hasAttr "operationBaselines" baselines
    && builtins.hasAttr "regressionThresholds" baselines
    && builtins.hasAttr "monitoringConfig" baselines
  ) "Baseline exports should exist";

  # Test 2: systemBaselines contains expected systems
  system-baselines-has-systems = testHelpers.assertTest "baselines-system-baselines-has-systems" (
    builtins.hasAttr "aarch64-darwin" baselines.systemBaselines
    && builtins.hasAttr "x86_64-linux" baselines.systemBaselines
    && builtins.hasAttr "aarch64-linux" baselines.systemBaselines
  ) "systemBaselines should contain aarch64-darwin, x86_64-linux, and aarch64-linux";

  # Test 3: aarch64-darwin baseline has expected structure
  aarch64-darwin-baseline-structure = testHelpers.assertTest "baselines-aarch64-darwin-structure" (
    let
      baseline = baselines.systemBaselines."aarch64-darwin";
    in
    builtins.hasAttr "build" baseline
    && builtins.hasAttr "memory" baseline
    && builtins.hasAttr "test" baseline
  ) "aarch64-darwin baseline should have build, memory, and test sections";

  # Test 4: aarch64-darwin build thresholds are positive
  aarch64-darwin-build-thresholds-positive = testHelpers.assertTest "baselines-aarch64-darwin-build-positive" (
    let
      build = baselines.systemBaselines."aarch64-darwin".build;
    in
    build.maxEvaluationTimeMs > 0
    && build.maxFlakeLoadTimeMs > 0
    && build.maxDerivationTimeMs > 0
  ) "aarch64-darwin build thresholds should be positive";

  # Test 5: aarch64-darwin memory thresholds are positive
  aarch64-darwin-memory-thresholds-positive = testHelpers.assertTest "baselines-aarch64-darwin-memory-positive" (
    let
      memory = baselines.systemBaselines."aarch64-darwin".memory;
    in
    memory.maxConfigMemoryMb > 0
    && memory.maxEvaluationMemoryMb > 0
    && memory.maxBuildMemoryMb > 0
  ) "aarch64-darwin memory thresholds should be positive";

  # Test 6: aarch64-darwin test thresholds are positive
  aarch64-darwin-test-thresholds-positive = testHelpers.assertTest "baselines-aarch64-darwin-test-positive" (
    let
      test = baselines.systemBaselines."aarch64-darwin".test;
    in
    test.maxUnitTestTimeMs > 0
    && test.maxIntegrationTestTimeMs > 0
    && test.maxVmTestTimeMs > 0
  ) "aarch64-darwin test thresholds should be positive";

  # Test 7: x86_64-linux baseline has expected structure
  x86_64-linux-baseline-structure = testHelpers.assertTest "baselines-x86_64-linux-structure" (
    let
      baseline = baselines.systemBaselines."x86_64-linux";
    in
    builtins.hasAttr "build" baseline
    && builtins.hasAttr "memory" baseline
    && builtins.hasAttr "test" baseline
  ) "x86_64-linux baseline should have build, memory, and test sections";

  # Test 8: operationBaselines contains expected operations
  operation-baselines-has-operations = testHelpers.assertTest "baselines-operation-baselines-has-operations" (
    builtins.hasAttr "config-load" baselines.operationBaselines
    && builtins.hasAttr "module-eval" baselines.operationBaselines
    && builtins.hasAttr "build-operation" baselines.operationBaselines
    && builtins.hasAttr "test-execution" baselines.operationBaselines
  ) "operationBaselines should contain config-load, module-eval, build-operation, and test-execution";

  # Test 9: config-load operation baseline has expected sizes
  config-load-has-sizes = testHelpers.assertTest "baselines-config-load-has-sizes" (
    let
      configLoad = baselines.operationBaselines."config-load";
    in
    builtins.hasAttr "small" configLoad
    && builtins.hasAttr "medium" configLoad
    && builtins.hasAttr "large" configLoad
  ) "config-load operation should have small, medium, and large sizes";

  # Test 10: regressionThresholds has expected structure
  regression-thresholds-structure = testHelpers.assertTest "baselines-regression-thresholds-structure" (
    let
      thresholds = baselines.regressionThresholds;
    in
    builtins.hasAttr "timeRegressionFactor" thresholds
    && builtins.hasAttr "memoryRegressionFactor" thresholds
    && builtins.hasAttr "criticalTimeRegression" thresholds
    && builtins.hasAttr "criticalMemoryRegression" thresholds
  ) "regressionThresholds should have time and memory regression factors";

  # Test 11: regressionThresholds values are reasonable
  regression-thresholds-reasonable = testHelpers.assertTest "baselines-regression-thresholds-reasonable" (
    let
      thresholds = baselines.regressionThresholds;
    in
    thresholds.timeRegressionFactor >= 1.0
    && thresholds.memoryRegressionFactor >= 1.0
    && thresholds.criticalTimeRegression >= thresholds.timeRegressionFactor
    && thresholds.criticalMemoryRegression >= thresholds.memoryRegressionFactor
  ) "regressionThresholds should have reasonable values (critical >= warning)";

  # Test 12: monitoringConfig has expected structure
  monitoring-config-structure = testHelpers.assertTest "baselines-monitoring-config-structure" (
    let
      config = baselines.monitoringConfig;
    in
    builtins.hasAttr "enabled" config
    && builtins.hasAttr "sampleInterval" config
    && builtins.hasAttr "maxSamples" config
    && builtins.hasAttr "alerts" config
    && builtins.hasAttr "reports" config
  ) "monitoringConfig should have enabled, sampleInterval, maxSamples, alerts, and reports";

  # Test 13: monitoringConfig alerts has thresholds
  monitoring-config-alerts-thresholds = testHelpers.assertTest "baselines-monitoring-config-alerts-thresholds" (
    let
      alerts = baselines.monitoringConfig.alerts;
    in
    builtins.hasAttr "thresholds" alerts
    && builtins.hasAttr "enabled" alerts
  ) "monitoringConfig alerts should have thresholds and enabled";

  # Test 14: getCurrentBaseline function exists
  get-current-baseline-exists = testHelpers.assertTest "baselines-get-current-baseline-exists" (
    builtins.hasAttr "getCurrentBaseline" baselines
    && builtins.isFunction baselines.getCurrentBaseline
  ) "getCurrentBaseline function should exist";

  # Test 15: getCurrentBaseline returns expected baseline for known system
  get-current-baseline-returns-baseline = testHelpers.assertTest "baselines-get-current-baseline-returns" (
    let
      baseline = baselines.getCurrentBaseline "aarch64-darwin";
    in
    builtins.hasAttr "build" baseline
    && builtins.hasAttr "memory" baseline
    && builtins.hasAttr "test" baseline
  ) "getCurrentBaseline should return proper baseline structure for known system";

  # Test 16: getCurrentBaseline falls back to x86_64-linux for unknown system
  get-current-baseline-fallback = testHelpers.assertTest "baselines-get-current-baseline-fallback" (
    let
      baseline = baselines.getCurrentBaseline "unknown-system";
    in
    builtins.hasAttr "build" baseline
    && builtins.hasAttr "memory" baseline
    && builtins.hasAttr "test" baseline
  ) "getCurrentBaseline should fallback to x86_64-linux for unknown system";

  # Test 17: createBaselineMeasurements function exists
  create-baseline-measurements-exists = testHelpers.assertTest "baselines-create-baseline-measurements-exists" (
    builtins.hasAttr "createBaselineMeasurements" baselines
    && builtins.isFunction baselines.createBaselineMeasurements
  ) "createBaselineMeasurements function should exist";

  # Test 18: createBaselineMeasurements returns expected structure
  create-baseline-measurements-returns = testHelpers.assertTest "baselines-create-baseline-measurements-returns" (
    let
      measurements = baselines.createBaselineMeasurements "aarch64-darwin";
    in
    builtins.hasAttr "buildBaselines" measurements
    && builtins.hasAttr "testBaselines" measurements
    && builtins.hasAttr "memoryBaselines" measurements
  ) "createBaselineMeasurements should return build, test, and memory baselines";

  # Test 19: Legacy exports exist for backward compatibility
  legacy-exports-exist = testHelpers.assertTest "baselines-legacy-exports-exist" (
    builtins.hasAttr "createBaseline" baselines
    && builtins.hasAttr "checkBaseline" baselines
    && builtins.hasAttr "analyzeTrend" baselines
    && builtins.hasAttr "summary" baselines
    && builtins.hasAttr "formatResults" baselines
  ) "Legacy exports should exist for backward compatibility";

  # Test 20: Performance testing helpers exist
  testing-helpers-exist = testHelpers.assertTest "baselines-testing-helpers-exist" (
    builtins.hasAttr "mkPerfTest" baselines
    && builtins.hasAttr "mkBenchmarkSuite" baselines
  ) "Performance testing helpers should exist";
}
