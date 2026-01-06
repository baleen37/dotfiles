# tests/unit/lib-monitoring-test.nix
# Unit tests for lib/monitoring.nix monitoring system
# Tests storage, metrics, alerts, and reporting functionality

{
  inputs,
  system,
  pkgs,
  lib,
  self,
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  monitoring = import ../../lib/monitoring.nix { inherit lib pkgs; };

in
{
  # Test 1: Monitoring module structure exists
  monitoring-structure-exists = testHelpers.assertTest "monitoring-structure-exists" (
    builtins.hasAttr "monitoring" monitoring
    && builtins.hasAttr "storage" monitoring.monitoring
    && builtins.hasAttr "tests" monitoring.monitoring
    && builtins.hasAttr "metrics" monitoring.monitoring
    && builtins.hasAttr "alerts" monitoring.monitoring
    && builtins.hasAttr "reporting" monitoring.monitoring
    && builtins.hasAttr "integration" monitoring.monitoring
  ) "Monitoring should have storage, tests, metrics, alerts, reporting, and integration sections";

  # Test 2: Storage createStore creates store
  storage-create-store = testHelpers.assertTest "monitoring-storage-create-store" (
    let
      store = monitoring.monitoring.storage.createStore "/tmp/test-store";
    in
    builtins.hasAttr "path" store
    && builtins.hasAttr "data" store
    && builtins.hasAttr "metadata" store
    && store.path == "/tmp/test-store"
  ) "storage.createStore should create a store with path, data, and metadata";

  # Test 3: Storage createStore metadata structure
  storage-create-store-metadata = testHelpers.assertTest "monitoring-storage-create-store-metadata" (
    let
      store = monitoring.monitoring.storage.createStore "/tmp/test";
    in
    builtins.hasAttr "version" store.metadata
    && builtins.hasAttr "created" store.metadata
    && builtins.hasAttr "system" store.metadata
  ) "storage.createStore metadata should include version, created, and system";

  # Test 4: Storage addMeasurement adds measurement
  storage-add-measurement = testHelpers.assertTest "monitoring-storage-add-measurement" (
    let
      store = monitoring.monitoring.storage.createStore "/tmp/test";
      updatedStore = monitoring.monitoring.storage.addMeasurement
        store
        "test-category"
        { duration_ms = 100; memoryAfter = 1000; };
    in
    builtins.hasAttr "test-category" updatedStore.data
    && builtins.length updatedStore.data."test-category" == 1
  ) "storage.addMeasurement should add measurement to store";

  # Test 5: Storage addMeasurement updates metadata
  storage-add-measurement-metadata = testHelpers.assertTest "monitoring-storage-add-measurement-metadata" (
    let
      store = monitoring.monitoring.storage.createStore "/tmp/test";
      updatedStore = monitoring.monitoring.storage.addMeasurement
        store
        "test-category"
        { duration_ms = 100; };
    in
    builtins.hasAttr "lastUpdated" updatedStore.metadata
    && builtins.hasAttr "totalMeasurements" updatedStore.metadata
  ) "storage.addMeasurement should update store metadata";

  # Test 6: Storage queryMeasurements filters by time
  storage-query-measurements = testHelpers.assertTest "monitoring-storage-query-measurements" (
    let
      store = monitoring.monitoring.storage.createStore "/tmp/test";
      measurements = [
        { duration_ms = 100; }
        { duration_ms = 200; }
        { duration_ms = 300; }
      ];
      storeWithMeasurements = builtins.foldl (acc: m:
        monitoring.monitoring.storage.addMeasurement acc "test" m
      ) store measurements;
      queried = monitoring.monitoring.storage.queryMeasurements
        storeWithMeasurements
        "test"
        0
        999999999999999999;
    in
    builtins.length queried == 3
  ) "storage.queryMeasurements should return measurements within time range";

  # Test 7: Storage getLatest returns latest measurements
  storage-get-latest = testHelpers.assertTest "monitoring-storage-get-latest" (
    let
      store = monitoring.monitoring.storage.createStore "/tmp/test";
      measurements = [
        { duration_ms = 100; }
        { duration_ms = 200; }
        { duration_ms = 300; }
      ];
      storeWithMeasurements = builtins.foldl (acc: m:
        monitoring.monitoring.storage.addMeasurement acc "test" m
      ) store measurements;
      latest = monitoring.monitoring.storage.getLatest storeWithMeasurements "test" 2;
    in
    builtins.length latest == 2
  ) "storage.getLatest should return specified number of latest measurements";

  # Test 8: Tests trackExecution creates measurement
  tests-track-execution = testHelpers.assertTest "monitoring-tests-track-execution" (
    let
      measurement = monitoring.monitoring.tests.trackExecution
        "test-name"
        "unit"
        { duration = 100; memory = 1000; success = true; };
    in
    builtins.hasAttr "testName" measurement
    && builtins.hasAttr "testType" measurement
    && builtins.hasAttr "timestamp" measurement
    && builtins.hasAttr "system" measurement
    && builtins.hasAttr "duration_ms" measurement
    && builtins.hasAttr "memory_bytes" measurement
    && builtins.hasAttr "success" measurement
  ) "tests.trackExecution should create measurement with all required fields";

  # Test 9: Tests measureExecution returns profile
  tests-measure-execution = testHelpers.assertTest "monitoring-tests-measure-execution" (
    let
      result = monitoring.monitoring.tests.measureExecution
        "test-name"
        "unit"
        (builtins.deepSeq 42 42);
    in
    builtins.hasAttr "measurement" result
    && builtins.hasAttr "profile" result
  ) "tests.measureExecution should return measurement and profile";

  # Test 10: Tests analyzeTrends returns analysis
  tests-analyze-trends = testHelpers.assertTest "monitoring-tests-analyze-trends" (
    let
      measurements = [
        { duration_ms = 100; memory_bytes = 1000; success = true; }
        { duration_ms = 200; memory_bytes = 2000; success = true; }
        { duration_ms = 150; memory_bytes = 1500; success = true; }
      ];
      analysis = monitoring.monitoring.tests.analyzeTrends measurements;
    in
    builtins.hasAttr "summary" analysis
    && builtins.hasAttr "performance" analysis
    && builtins.hasAttr "reliability" analysis
    && builtins.hasAttr "alerts" analysis
  ) "tests.analyzeTrends should return summary, performance, reliability, and alerts";

  # Test 11: Tests analyzeTrends summary structure
  tests-analyze-trends-summary = testHelpers.assertTest "monitoring-tests-analyze-trends-summary" (
    let
      measurements = [
        { duration_ms = 100; memory_bytes = 1000; success = true; }
        { duration_ms = 200; memory_bytes = 2000; success = true; }
      ];
      analysis = monitoring.monitoring.tests.analyzeTrends measurements;
    in
    builtins.hasAttr "totalRuns" analysis.summary
    && builtins.hasAttr "successfulRuns" analysis.summary
    && builtins.hasAttr "successRate" analysis.summary
    && builtins.hasAttr "avgDuration_ms" analysis.summary
    && builtins.hasAttr "avgMemory_mb" analysis.summary
  ) "tests.analyzeTrends summary should include totalRuns, successfulRuns, successRate, avgDuration_ms, and avgMemory_mb";

  # Test 12: Metrics getCurrentSystemMetrics returns metrics
  metrics-get-current-system-metrics = testHelpers.assertTest "monitoring-metrics-get-current-system-metrics" (
    let
      metrics = monitoring.monitoring.metrics.getCurrentSystemMetrics;
    in
    builtins.hasAttr "timestamp" metrics
    && builtins.hasAttr "memory" metrics
    && builtins.hasAttr "cpu" metrics
    && builtins.hasAttr "disk" metrics
    && builtins.hasAttr "network" metrics
  ) "metrics.getCurrentSystemMetrics should return timestamp, memory, cpu, disk, and network";

  # Test 13: Metrics aggregateMetrics aggregates correctly
  metrics-aggregate-metrics = testHelpers.assertTest "monitoring-metrics-aggregate-metrics" (
    let
      measurements = [
        {
          system = { memory = 100; cpu = 50; disk = 1000; };
          profile = { duration_ms = 100; };
        }
        {
          system = { memory = 200; cpu = 60; disk = 2000; };
          profile = { duration_ms = 200; };
        }
      ];
      aggregated = monitoring.monitoring.metrics.aggregateMetrics measurements;
    in
    builtins.hasAttr "count" aggregated
    && builtins.hasAttr "memory" aggregated
    && builtins.hasAttr "cpu" aggregated
    && builtins.hasAttr "duration" aggregated
  ) "metrics.aggregateMetrics should aggregate measurements correctly";

  # Test 14: Alerts createAlert creates alert
  alerts-create-alert = testHelpers.assertTest "monitoring-alerts-create-alert" (
    let
      alert = monitoring.monitoring.alerts.createAlert
        "critical"
        "test-type"
        "Test message"
        100
        50;
    in
    builtins.hasAttr "id" alert
    && builtins.hasAttr "severity" alert
    && builtins.hasAttr "type" alert
    && builtins.hasAttr "message" alert
    && builtins.hasAttr "value" alert
    && builtins.hasAttr "threshold" alert
    && alert.severity == "critical"
    && alert.acknowledged == false
    && alert.resolved == false
  ) "alerts.createAlert should create alert with all required fields";

  # Test 15: Alerts generateSummary aggregates alerts
  alerts-generate-summary = testHelpers.assertTest "monitoring-alerts-generate-summary" (
    let
      alerts = [
        (monitoring.monitoring.alerts.createAlert "critical" "test1" "msg1" 1 1)
        (monitoring.monitoring.alerts.createAlert "warning" "test2" "msg2" 1 1)
        (monitoring.monitoring.alerts.createAlert "info" "test3" "msg3" 1 1)
      ];
      summary = monitoring.monitoring.alerts.generateSummary alerts;
    in
    builtins.hasAttr "total" summary
    && builtins.hasAttr "critical" summary
    && builtins.hasAttr "warning" summary
    && builtins.hasAttr "info" summary
    && builtins.hasAttr "status" summary
    && summary.total == 3
    && summary.critical == 1
    && summary.warning == 1
    && summary.info == 1
  ) "alerts.generateSummary should aggregate alerts by severity";

  # Test 16: Alerts status is calculated correctly
  alerts-generate-summary-status = testHelpers.assertTest "monitoring-alerts-generate-summary-status" (
    let
      criticalOnly = [
        (monitoring.monitoring.alerts.createAlert "critical" "test" "msg" 1 1)
      ];
      warningOnly = [
        (monitoring.monitoring.alerts.createAlert "warning" "test" "msg" 1 1)
      ];
      infoOnly = [
        (monitoring.monitoring.alerts.createAlert "info" "test" "msg" 1 1)
      ];
      criticalStatus = monitoring.monitoring.alerts.generateSummary criticalOnly;
      warningStatus = monitoring.monitoring.alerts.generateSummary warningOnly;
      infoStatus = monitoring.monitoring.alerts.generateSummary infoOnly;
    in
    criticalStatus.status == "critical"
    && warningStatus.status == "warning"
    && infoStatus.status == "healthy"
  ) "alerts.generateSummary status should be critical/warning/healthy based on alerts";

  # Test 17: Integration wrapTest wraps test
  integration-wrap-test = testHelpers.assertTest "monitoring-integration-wrap-test" (
    let
      result = monitoring.monitoring.integration.wrapTest
        "test-name"
        "unit"
        (builtins.deepSeq 42 42);
    in
    builtins.hasAttr "testResult" result
    && builtins.hasAttr "measurement" result
    && builtins.hasAttr "profile" result
  ) "integration.wrapTest should wrap test execution with monitoring";

  # Test 18: Integration ciConfig has expected structure
  integration-ci-config = testHelpers.assertTest "monitoring-integration-ci-config" (
    let
      config = monitoring.monitoring.integration.ciConfig;
    in
    builtins.hasAttr "enableMonitoring" config
    && builtins.hasAttr "formats" config
    && builtins.hasAttr "artifacts" config
    && builtins.hasAttr "thresholds" config
    && builtins.hasAttr "notifications" config
  ) "integration.ciConfig should have enableMonitoring, formats, artifacts, thresholds, and notifications";

  # Test 19: Integration ciConfig thresholds structure
  integration-ci-config-thresholds = testHelpers.assertTest "monitoring-integration-ci-config-thresholds" (
    let
      thresholds = monitoring.monitoring.integration.ciConfig.thresholds;
    in
    builtins.hasAttr "successRate" thresholds
    && builtins.hasAttr "duration" thresholds
    && builtins.hasAttr "memory" thresholds
  ) "integration.ciConfig thresholds should include successRate, duration, and memory";

  # Test 20: Reporting formatSummary returns string
  reporting-format-summary = testHelpers.assertTest "monitoring-reporting-format-summary" (
    let
      mockReport = {
        metadata = {
          system = "x86_64-linux";
          timestamp = "1234567890";
        };
        summary = {
          successRate = 1.0;
          timing = { avg_ms = 100; };
          memory = { avg_bytes = 1000000; };
        };
        monitoring = {
          health = { status = "healthy"; score = 100; };
          alerts = { total = 0; critical = 0; warning = 0; };
          measurements = { total = 10; };
          categories = [ "unit" "integration" ];
          systemMetrics = {
            unit = { duration = { avg = 50; }; };
            integration = { duration = { avg = 150; }; };
          };
        };
        analysis = {
          performanceClass = "optimal";
          recommendations = [ "All systems nominal" ];
        };
      };
      formatted = monitoring.monitoring.reporting.formatSummary mockReport;
    in
    builtins.typeOf formatted == "string"
    && builtins.stringLength formatted > 0
    && lib.hasInfix "Test Execution Monitoring Report" formatted
  ) "reporting.formatSummary should return formatted report string";
}
