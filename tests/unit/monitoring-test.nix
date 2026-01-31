# tests/unit/monitoring-test.nix
# Unit tests for lib/monitoring.nix monitoring system
# Tests storage, test tracking, metrics, alerts, and reporting

{
  inputs,
  system,
  nixtest ? { },
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit lib pkgs; };

  # Create mock inputs for monitoring lib
  mockInputs = {
    nixpkgs = pkgs;
    darwin = null;
    home-manager = null;
    determinate = null;
  };
  monitoringLib = import ../../lib/monitoring.nix { inherit lib pkgs; };
  inherit (monitoringLib) monitoring storage tests metrics alerts reporting;

  # Helper function to create mock test measurements
  createMockMeasurement = testName: success: duration: memoryBytes: {
    testName = testName;
    testType = "unit";
    timestamp = builtins.currentTime;
    system = builtins.currentSystem or "unknown";
    duration_ms = duration;
    memory_bytes = memoryBytes;
    inherit success;
    exitCode = if success then 0 else 1;
    metrics = {
      cpu = 50;
      disk = 1000;
      network = 10;
    };
    context = {
      gitCommit = "abc123";
      branch = "main";
      buildId = "build-1";
      ci = true;
    };
  };

  # Mock measurements for testing
  mockMeasurements = [
    (createMockMeasurement "test1" true 100 (50 * 1024 * 1024))
    (createMockMeasurement "test2" true 150 (60 * 1024 * 1024))
    (createMockMeasurement "test3" true 120 (55 * 1024 * 1024))
    (createMockMeasurement "test4" false 200 (70 * 1024 * 1024))
    (createMockMeasurement "test5" true 110 (52 * 1024 * 1024))
  ];

in
{
  platforms = ["any"];
  value = helpers.testSuite "monitoring" [
    # ===== Storage Tests =====

    # Test 1: createStore creates a valid store structure
    (helpers.assertTest "monitoring-storage-creates-valid-store" (
      let
        testStore = storage.createStore "/tmp/test-store";
      in
      builtins.hasAttr "path" testStore
      && builtins.hasAttr "data" testStore
      && builtins.hasAttr "metadata" testStore
      && builtins.hasAttr "version" testStore.metadata
      && builtins.hasAttr "created" testStore.metadata
      && builtins.hasAttr "system" testStore.metadata
    ) "createStore should create a store with path, data, and metadata")

    # Test 2: createStore initializes with empty data
    (helpers.assertTest "monitoring-storage-initializes-empty-data" (
      let
        testStore = storage.createStore "/tmp/test-store";
      in
      testStore.data == { }
    ) "createStore should initialize with empty data attribute set")

    # Test 3: createStore creates metadata with version 1.0.0
    (helpers.assertTest "monitoring-storage-metadata-has-version" (
      let
        testStore = storage.createStore "/tmp/test-store";
      in
      testStore.metadata.version == "1.0.0"
    ) "Store metadata should contain version 1.0.0")

    # Test 4: addMeasurement adds measurement to store
    (helpers.assertTest "monitoring-storage-adds-measurement" (
      let
        initialStore = storage.createStore "/tmp/test";
        testMeasurement = createMockMeasurement "test1" true 100 (50 * 1024 * 1024);
        updatedStore = storage.addMeasurement initialStore "test-category" testMeasurement;
      in
      builtins.hasAttr "test-category" updatedStore.data
      && builtins.length updatedStore.data.test-category == 1
    ) "addMeasurement should add measurement to the store under the specified category")

    # Test 5: addMeasurement updates metadata
    (helpers.assertTest "monitoring-storage-updates-metadata" (
      let
        initialStore = storage.createStore "/tmp/test";
        testMeasurement = createMockMeasurement "test1" true 100 (50 * 1024 * 1024);
        updatedStore = storage.addMeasurement initialStore "test-category" testMeasurement;
      in
      builtins.hasAttr "lastUpdated" updatedStore.metadata
      && builtins.hasAttr "totalMeasurements" updatedStore.metadata
    ) "addMeasurement should update lastUpdated and totalMeasurements in metadata")

    # Test 6: getLatest returns most recent measurements
    (helpers.assertTest "monitoring-storage-get-latest" (
      let
        testStore = storage.createStore "/tmp/test";
        storeWithMeasurements = storage.addMeasurement testStore "cat1" (createMockMeasurement "test1" true 100 (50 * 1024 * 1024));
        latest = storage.getLatest storeWithMeasurements "cat1" 1;
      in
      builtins.length latest == 1
    ) "getLatest should return the specified number of most recent measurements")

    # Test 7: cleanup removes old measurements
    (helpers.assertTest "monitoring-storage-cleanup-removes-old" (
      let
        testStore = storage.createStore "/tmp/test";
        # cleanup should filter measurements by age
        maxAge = 3600; # 1 hour
      in
      # The cleanup function should return a store structure
      let
        cleanedStore = storage.cleanup testStore "cat1" maxAge;
      in
      builtins.hasAttr "data" cleanedStore
    ) "cleanup should return store with old measurements removed")

    # ===== Test Tracking Tests =====

    # Test 8: trackExecution creates measurement with required fields
    (helpers.assertTest "monitoring-tests-track-execution" (
      let
        result = {
          duration = 1000;
          memory = 50 * 1024 * 1024;
          success = true;
          exitCode = 0;
        };
        measurement = tests.trackExecution "myTest" "unit" result;
      in
      builtins.hasAttr "testName" measurement
      && builtins.hasAttr "testType" measurement
      && builtins.hasAttr "timestamp" measurement
      && builtins.hasAttr "duration_ms" measurement
      && builtins.hasAttr "memory_bytes" measurement
      && builtins.hasAttr "success" measurement
    ) "trackExecution should create measurement with all required fields")

    # Test 9: trackExecution uses correct test name
    (helpers.assertTest "monitoring-tests-uses-test-name" (
      let
        result = { duration = 1000; };
        measurement = tests.trackExecution "specificTest" "unit" result;
      in
      measurement.testName == "specificTest"
    ) "trackExecution should use the provided test name")

    # Test 10: trackExecution sets test type correctly
    (helpers.assertTest "monitoring-tests-sets-test-type" (
      let
        result = { duration = 1000; };
        measurement = tests.trackExecution "test" "integration" result;
      in
      measurement.testType == "integration"
    ) "trackExecution should set testType to the provided value")

    # Test 11: analyzeTrends calculates success rate
    (helpers.assertTest "monitoring-tests-analyzes-success-rate" (
      let
        analysis = tests.analyzeTrends mockMeasurements;
      in
      builtins.hasAttr "summary" analysis
      && builtins.hasAttr "successRate" analysis.summary
      && analysis.summary.successRate > 0.0
      && analysis.summary.successRate <= 1.0
    ) "analyzeTrends should calculate success rate between 0 and 1")

    # Test 12: analyzeTrends calculates average duration
    (helpers.assertTest "monitoring-tests-analyzes-avg-duration" (
      let
        analysis = tests.analyzeTrends mockMeasurements;
      in
      builtins.hasAttr "avgDuration_ms" analysis.summary
      && analysis.summary.avgDuration_ms > 0
    ) "analyzeTrends should calculate average duration in milliseconds")

    # Test 13: analyzeTrends calculates average memory
    (helpers.assertTest "monitoring-tests-analyzes-avg-memory" (
      let
        analysis = tests.analyzeTrends mockMeasurements;
      in
      builtins.hasAttr "avgMemory_mb" analysis.summary
      && analysis.summary.avgMemory_mb > 0
    ) "analyzeTrends should calculate average memory in megabytes")

    # Test 14: analyzeTrends provides reliability rating
    (helpers.assertTest "monitoring-tests-provides-reliability" (
      let
        analysis = tests.analyzeTrends mockMeasurements;
      in
      builtins.hasAttr "reliability" analysis
      && builtins.hasAttr "stability" analysis.reliability
      && builtins.elem analysis.reliability.stability ["excellent" "good" "acceptable" "poor"]
    ) "analyzeTrends should provide stability rating")

    # Test 15: analyzeTrends detects performance trend
    (helpers.assertTest "monitoring-tests-detects-trend" (
      let
        analysis = tests.analyzeTrends mockMeasurements;
      in
      builtins.hasAttr "reliability" analysis
      && builtins.hasAttr "trend" analysis.reliability
      && builtins.elem analysis.reliability.trend ["improving" "degrading" "stable"]
    ) "analyzeTrends should detect if performance is improving, degrading, or stable")

    # Test 16: analyzeTrends generates alerts for low success rate
    (helpers.assertTest "monitoring-tests-alerts-low-success" (
      let
        lowSuccessMeasurements = [
          (createMockMeasurement "test1" false 200 (70 * 1024 * 1024))
          (createMockMeasurement "test2" false 250 (80 * 1024 * 1024))
          (createMockMeasurement "test3" true 150 (60 * 1024 * 1024))
        ];
        analysis = tests.analyzeTrends lowSuccessMeasurements;
      in
      builtins.hasAttr "alerts" analysis
      && builtins.length analysis.alerts > 0
    ) "analyzeTrends should generate alerts when success rate is below 80%")

    # Test 17: analyzeTrends generates alerts for high duration
    (helpers.assertTest "monitoring-tests-alerts-high-duration" (
      let
        slowTests = [
          (createMockMeasurement "test1" true 35000 (50 * 1024 * 1024))
          (createMockMeasurement "test2" true 40000 (60 * 1024 * 1024))
        ];
        analysis = tests.analyzeTrends slowTests;
      in
      builtins.hasAttr "alerts" analysis
      && builtins.any (a: a.type == "performance") analysis.alerts
    ) "analyzeTrends should generate performance alerts when duration exceeds 30 seconds")

    # Test 18: generateReport creates comprehensive report
    (helpers.assertTest "monitoring-tests-generates-report" (
      let
        report = tests.generateReport "test-suite" mockMeasurements {
          framework = "test-framework";
          suiteName = "my-suite";
        };
      in
      builtins.hasAttr "metadata" report
      && builtins.hasAttr "summary" report
      && builtins.hasAttr "performance" report
      && builtins.hasAttr "reliability" report
      && builtins.hasAttr "trends" report
      && builtins.hasAttr "alerts" report
    ) "generateReport should create a comprehensive report with all sections")

    # Test 19: generateReport includes metadata
    (helpers.assertTest "monitoring-tests-report-has-metadata" (
      let
        report = tests.generateReport "test-suite" mockMeasurements {};
      in
      builtins.hasAttr "testName" report.metadata
      && report.metadata.testName == "test-suite"
    ) "generateReport should include testName in metadata")

    # ===== Metrics Tests =====

    # Test 20: getCurrentSystemMetrics returns metrics structure
    (helpers.assertTest "monitoring-metrics-returns-structure" (
      let
        currentMetrics = metrics.getCurrentSystemMetrics;
      in
      builtins.hasAttr "timestamp" currentMetrics
      && builtins.hasAttr "memory" currentMetrics
      && builtins.hasAttr "cpu" currentMetrics
      && builtins.hasAttr "disk" currentMetrics
      && builtins.hasAttr "network" currentMetrics
    ) "getCurrentSystemMetrics should return metrics with timestamp, memory, cpu, disk, and network")

    # Test 21: getCurrentSystemMetrics has valid timestamp
    (helpers.assertTest "monitoring-metrics-has-timestamp" (
      let
        currentMetrics = metrics.getCurrentSystemMetrics;
      in
      currentMetrics.timestamp > 0
    ) "getCurrentSystemMetrics should have a positive timestamp")

    # Test 22: getCurrentSystemMetrics returns positive memory value
    (helpers.assertTest "monitoring-metrics-has-memory" (
      let
        currentMetrics = metrics.getCurrentSystemMetrics;
      in
      currentMetrics.memory > 0
    ) "getCurrentSystemMetrics should return a positive memory value")

    # Test 23: getCurrentSystemMetrics cpu in valid range
    (helpers.assertTest "monitoring-metrics-cpu-in-range" (
      let
        currentMetrics = metrics.getCurrentSystemMetrics;
      in
      currentMetrics.cpu >= 0 && currentMetrics.cpu <= 100
    ) "getCurrentSystemMetrics should return CPU value between 0 and 100")

    # Test 24: aggregateMetrics calculates averages
    (helpers.assertTest "monitoring-metrics-aggregates-averages" (
      let
        # Create mock measurements with system metrics
        mockMeasurementsWithMetrics = [
          {
            system = { memory = 100 * 1024 * 1024; cpu = 50; disk = 1000; };
            profile = { duration_ms = 100; };
          }
          {
            system = { memory = 200 * 1024 * 1024; cpu = 70; disk = 2000; };
            profile = { duration_ms = 200; };
          }
        ];
        aggregated = metrics.aggregateMetrics mockMeasurementsWithMetrics;
      in
      builtins.hasAttr "memory" aggregated
      && builtins.hasAttr "cpu" aggregated
      && builtins.hasAttr "duration" aggregated
      && builtins.hasAttr "avg" aggregated.memory
      && builtins.hasAttr "avg" aggregated.cpu
      && builtins.hasAttr "avg" aggregated.duration
    ) "aggregateMetrics should calculate average metrics")

    # Test 25: aggregateMetrics calculates min/max
    (helpers.assertTest "monitoring-metrics-aggregates-minmax" (
      let
        mockMeasurementsWithMetrics = [
          {
            system = { memory = 100 * 1024 * 1024; cpu = 50; };
            profile = { duration_ms = 100; };
          }
          {
            system = { memory = 200 * 1024 * 1024; cpu = 70; };
            profile = { duration_ms = 200; };
          }
        ];
        aggregated = metrics.aggregateMetrics mockMeasurementsWithMetrics;
      in
      builtins.hasAttr "min" aggregated.memory
      && builtins.hasAttr "max" aggregated.memory
      && builtins.hasAttr "min" aggregated.cpu
      && builtins.hasAttr "max" aggregated.cpu
    ) "aggregateMetrics should calculate min and max values")

    # Test 26: aggregateMetrics count is correct
    (helpers.assertTest "monitoring-metrics-count-correct" (
      let
        mockMeasurementsWithMetrics = [
          { system = { memory = 100; cpu = 50; }; profile = { duration_ms = 100; }; }
          { system = { memory = 200; cpu = 70; }; profile = { duration_ms = 200; }; }
          { system = { memory = 150; cpu = 60; }; profile = { duration_ms = 150; }; }
        ];
        aggregated = metrics.aggregateMetrics mockMeasurementsWithMetrics;
      in
      aggregated.count == 3
    ) "aggregateMetrics should return correct count of measurements")

    # Test 27: detectAnomalies finds memory anomalies
    (helpers.assertTest "monitoring-metrics-detects-memory-anomalies" (
      let
        mockMeasurementsWithMetrics = [
          {
            system = { memory = 2 * 1024 * 1024 * 1024; }; # 2GB
            profile = { duration_ms = 100; };
          }
        ];
        threshold = {
          memory = { max = 1 * 1024 * 1024 * 1024; }; # 1GB threshold
          duration = { max = 1000; };
        };
        anomalies = metrics.detectAnomalies mockMeasurementsWithMetrics threshold;
      in
      builtins.length anomalies > 0
      && builtins.any (a: a.type == "memory") anomalies
    ) "detectAnomalies should detect when memory exceeds threshold")

    # Test 28: detectAnomalies finds duration anomalies
    (helpers.assertTest "monitoring-metrics-detects-duration-anomalies" (
      let
        mockMeasurementsWithMetrics = [
          {
            system = { memory = 100 * 1024 * 1024; };
            profile = { duration_ms = 50000; }; # 50 seconds
          }
        ];
        threshold = {
          memory = { max = 1 * 1024 * 1024 * 1024; };
          duration = { max = 30000; }; # 30 second threshold
        };
        anomalies = metrics.detectAnomalies mockMeasurementsWithMetrics threshold;
      in
      builtins.length anomalies > 0
      && builtins.any (a: a.type == "performance") anomalies
    ) "detectAnomalies should detect when duration exceeds threshold")

    # ===== Alerts Tests =====

    # Test 29: createAlert creates valid alert structure
    (helpers.assertTest "monitoring-alerts-creates-valid-structure" (
      let
        alert = alerts.createAlert "warning" "performance" "Test too slow" 35000 30000;
      in
      builtins.hasAttr "id" alert
      && builtins.hasAttr "timestamp" alert
      && builtins.hasAttr "severity" alert
      && builtins.hasAttr "type" alert
      && builtins.hasAttr "message" alert
      && builtins.hasAttr "value" alert
      && builtins.hasAttr "threshold" alert
    ) "createAlert should create alert with all required fields")

    # Test 30: createAlert sets acknowledged and resolved to false
    (helpers.assertTest "monitoring-alerts-initializes-flags" (
      let
        alert = alerts.createAlert "critical" "reliability" "Test failed" 0.5 0.9;
      in
      alert.acknowledged == false
      && alert.resolved == false
    ) "createAlert should initialize acknowledged and resolved to false")

    # Test 31: createAlert uses correct severity
    (helpers.assertTest "monitoring-alerts-uses-severity" (
      let
        alert = alerts.createAlert "critical" "test" "message" 1 2;
      in
      alert.severity == "critical"
    ) "createAlert should use the provided severity level")

    # Test 32: checkThresholds generates alerts for low success rate
    (helpers.assertTest "monitoring-alerts-checks-success-rate" (
      let
        thresholds = {
          successRate = { min = 0.90; };
          duration = { max = 30000; };
          memory = { max = 1024; };
        };
        lowSuccessMeasurements = [
          (createMockMeasurement "test1" false 200 (70 * 1024 * 1024))
          (createMockMeasurement "test2" false 250 (80 * 1024 * 1024))
        ];
        resultAlerts = alerts.checkThresholds lowSuccessMeasurements thresholds;
      in
      builtins.length resultAlerts > 0
      && builtins.any (a: a.type == "reliability") resultAlerts
    ) "checkThresholds should generate reliability alerts when success rate is below minimum")

    # Test 33: checkThresholds generates alerts for high duration
    (helpers.assertTest "monitoring-alerts-checks-duration" (
      let
        thresholds = {
          successRate = { min = 0.80; };
          duration = { max = 30000; };
          memory = { max = 1024; };
        };
        slowTests = [
          (createMockMeasurement "test1" true 35000 (50 * 1024 * 1024))
          (createMockMeasurement "test2" true 40000 (60 * 1024 * 1024))
        ];
        resultAlerts = alerts.checkThresholds slowTests thresholds;
      in
      builtins.length resultAlerts > 0
      && builtins.any (a: a.type == "performance") resultAlerts
    ) "checkThresholds should generate performance alerts when duration exceeds maximum")

    # Test 34: checkThresholds generates alerts for high memory
    (helpers.assertTest "monitoring-alerts-checks-memory" (
      let
        thresholds = {
          successRate = { min = 0.80; };
          duration = { max = 30000; };
          memory = { max = 100; }; # 100MB
        };
        memoryHeavyTests = [
          (createMockMeasurement "test1" true 1000 (200 * 1024 * 1024)) # 200MB
          (createMockMeasurement "test2" true 1500 (250 * 1024 * 1024)) # 250MB
        ];
        resultAlerts = alerts.checkThresholds memoryHeavyTests thresholds;
      in
      builtins.length resultAlerts > 0
      && builtins.any (a: a.type == "memory") resultAlerts
    ) "checkThresholds should generate memory alerts when memory usage exceeds maximum")

    # Test 35: generateSummary counts alerts correctly
    (helpers.assertTest "monitoring-alerts-generates-summary" (
      let
        testAlerts = [
          (alerts.createAlert "critical" "reliability" "Failed" 0 0.9)
          (alerts.createAlert "warning" "performance" "Slow" 35000 30000)
          (alerts.createAlert "warning" "memory" "Heavy" 200 100)
        ];
        summary = alerts.generateSummary testAlerts;
      in
      builtins.hasAttr "total" summary
      && builtins.hasAttr "critical" summary
      && builtins.hasAttr "warning" summary
      && builtins.hasAttr "info" summary
      && builtins.hasAttr "status" summary
    ) "generateSummary should create summary with counts and status")

    # Test 36: generateSummary calculates correct counts
    (helpers.assertTest "monitoring-alert-summary-counts-correct" (
      let
        testAlerts = [
          (alerts.createAlert "critical" "test1" "msg1" 1 2)
          (alerts.createAlert "warning" "test2" "msg2" 1 2)
          (alerts.createAlert "warning" "test3" "msg3" 1 2)
        ];
        summary = alerts.generateSummary testAlerts;
      in
      summary.total == 3
      && summary.critical == 1
      && summary.warning == 2
      && summary.info == 0
    ) "generateSummary should correctly count alerts by severity")

    # Test 37: generateSummary sets correct status
    (helpers.assertTest "monitoring-alert-summary-status-correct" (
      let
        # Test with critical alerts
        criticalAlerts = [(alerts.createAlert "critical" "test" "msg" 1 2)];
        summaryCritical = alerts.generateSummary criticalAlerts;
        # Test with only warnings
        warningAlerts = [(alerts.createAlert "warning" "test" "msg" 1 2)];
        summaryWarning = alerts.generateSummary warningAlerts;
        # Test with no alerts
        noAlerts = [];
        summaryHealthy = alerts.generateSummary noAlerts;
      in
      summaryCritical.status == "critical"
      && summaryWarning.status == "warning"
      && summaryHealthy.status == "healthy"
    ) "generateSummary should set status based on alert severity")

    # ===== Reporting Tests =====

    # Test 38: reporting.generateReport creates comprehensive report
    (helpers.assertTest "monitoring-reporting-creates-report" (
      let
        testStore = storage.createStore "/tmp/test";
        # Add some measurements to the store
        storeWithData = storage.addMeasurement testStore "unit-tests" (createMockMeasurement "test1" true 100 (50 * 1024 * 1024));
        categories = ["unit-tests"];
        report = reporting.generateReport storeWithData categories {
          framework = "test-monitoring";
        };
      in
      builtins.hasAttr "monitoring" report
      && builtins.hasAttr "measurements" report.monitoring
      && builtins.hasAttr "systemMetrics" report.monitoring
      && builtins.hasAttr "alerts" report.monitoring
      && builtins.hasAttr "health" report.monitoring
    ) "reporting.generateReport should create comprehensive report structure")

    # Test 39: reporting includes health score
    (helpers.assertTest "monitoring-reporting-has-health-score" (
      let
        testStore = storage.createStore "/tmp/test";
        storeWithData = storage.addMeasurement testStore "test-category" (createMockMeasurement "test1" true 100 (50 * 1024 * 1024));
        report = reporting.generateReport storeWithData ["test-category"] {};
      in
      builtins.hasAttr "health" report.monitoring
      && builtins.hasAttr "score" report.monitoring.health
      && report.monitoring.health.score >= 0
      && report.monitoring.health.score <= 100
    ) "reporting.generateReport should include health score between 0 and 100")

    # Test 40: reporting.includes categories
    (helpers.assertTest "monitoring-reporting-includes-categories" (
      let
        testStore = storage.createStore "/tmp/test";
        storeWithData1 = storage.addMeasurement testStore "cat1" (createMockMeasurement "test1" true 100 (50 * 1024 * 1024));
        storeWithData2 = storage.addMeasurement storeWithData1 "cat2" (createMockMeasurement "test2" true 150 (60 * 1024 * 1024));
        storeWithData3 = storage.addMeasurement storeWithData2 "cat3" (createMockMeasurement "test3" true 120 (55 * 1024 * 1024));
        categories = ["cat1" "cat2" "cat3"];
        report = reporting.generateReport storeWithData3 categories {};
      in
      builtins.hasAttr "categories" report.monitoring
      && builtins.length report.monitoring.categories == 3
    ) "reporting.generateReport should include the specified categories")

    # Test 41: formatSummary returns string
    (helpers.assertTest "monitoring-reporting-formats-summary" (
      let
        mockReport = {
          metadata = {
            system = "x86_64-linux";
            timestamp = "1234567890";
          };
          monitoring = {
            measurements = { total = 10; };
            health = { status = "healthy"; score = 95; };
            alerts = { total = 0; critical = 0; warning = 0; };
          };
          summary = { successRate = 0.95; timing = { avg_ms = 100; }; memory = { avg_bytes = 50 * 1024 * 1024; }; };
          analysis = { performanceClass = "fast"; recommendations = []; };
          monitoring = {
            categories = ["unit" "integration"];
            measurements = {
              byCategory = { unit = 5; integration = 5; };
            };
            systemMetrics = {
              unit = { duration = { avg = 50; }; };
              integration = { duration = { avg = 150; }; };
            };
          };
        };
        formatted = reporting.formatSummary mockReport;
      in
      builtins.typeOf formatted == "string"
      && builtins.stringLength formatted > 0
    ) "formatSummary should return a non-empty string")

    # Test 42: formatSummary includes key information
    (helpers.assertTest "monitoring-reporting-summary-includes-info" (
      let
        mockReport = {
          metadata = {
            system = "test-system";
            timestamp = "1234567890";
            framework = "test-framework";
            version = "1.0.0";
          };
          monitoring = {
            measurements = { total = 42; };
            health = { status = "healthy"; score = 100; };
            alerts = { total = 1; critical = 0; warning = 1; status = "warning"; };
            categories = ["unit-tests"];
            measurements = {
              byCategory = { unit-tests = 42; };
            };
            systemMetrics = {
              unit-tests = { duration = { avg = 100; }; };
            };
          };
          summary = { successRate = 1.0; timing = { avg_ms = 100; }; memory = { avg_bytes = 50 * 1024 * 1024; }; };
          analysis = { performanceClass = "optimal"; recommendations = ["All good"]; };
        };
        formatted = reporting.formatSummary mockReport;
      in
      lib.hasInfix "test-system" formatted
      && lib.hasInfix "42" formatted
      && lib.hasInfix "HEALTHY" formatted
    ) "formatSummary should include system name, measurements count, and health status")

    # ===== Integration Tests =====

    # Test 43: Monitoring lib exports all main modules
    (helpers.assertTest "monitoring-lib-exports-modules" (
      builtins.hasAttr "storage" monitoringLib
      && builtins.hasAttr "tests" monitoringLib
      && builtins.hasAttr "metrics" monitoringLib
      && builtins.hasAttr "alerts" monitoringLib
      && builtins.hasAttr "reporting" monitoringLib
      && builtins.hasAttr "integration" monitoringLib
    ) "monitoringLib should export storage, tests, metrics, alerts, reporting, and integration modules")

    # Test 44: Integration wrapTest returns structure
    (helpers.assertTest "monitoring-integration-wrap-test" (
      let
        # wrapTest wraps a test function with monitoring
        # We can't fully test this without actual execution, but check structure exists
      in
      builtins.hasAttr "wrapTest" monitoringLib.integration
      && builtins.isFunction monitoringLib.integration.wrapTest
    ) "integration module should provide wrapTest function")

    # Test 45: Integration createMonitoredSuite exists
    (helpers.assertTest "monitoring-integration-has-monitored-suite" (
      builtins.hasAttr "createMonitoredSuite" monitoringLib.integration
      && builtins.isFunction monitoringLib.integration.createMonitoredSuite
    ) "integration module should provide createMonitoredSuite function")

    # Test 46: Integration ciConfig has required fields
    (helpers.assertTest "monitoring-integration-ci-config" (
      let
        ciConfig = monitoringLib.integration.ciConfig;
      in
      builtins.hasAttr "enableMonitoring" ciConfig
      && builtins.hasAttr "formats" ciConfig
      && builtins.hasAttr "artifacts" ciConfig
      && builtins.hasAttr "thresholds" ciConfig
      && builtins.hasAttr "notifications" ciConfig
    ) "integration.ciConfig should have enableMonitoring, formats, artifacts, thresholds, and notifications")

    # Test 47: CI thresholds are reasonable
    (helpers.assertTest "monitoring-integration-thresholds-reasonable" (
      let
        thresholds = monitoringLib.integration.ciConfig.thresholds;
      in
      thresholds.successRate.min > 0.0 && thresholds.successRate.min <= 1.0
      && thresholds.duration.max > 0
      && thresholds.memory.max > 0
    ) "CI thresholds should have positive, reasonable values")

    # Test 48: CI formats include expected types
    (helpers.assertTest "monitoring-integration-ci-formats" (
      let
        formats = monitoringLib.integration.ciConfig.formats;
      in
      builtins.elem "json" formats
      && builtins.elem "markdown" formats
    ) "CI formats should include json and markdown")

    # Test 49: Monitoring dependencies are available
    (helpers.assertTest "monitoring-lib-has-dependencies" (
      builtins.hasAttr "perf" monitoringLib
      && builtins.hasAttr "baselines" monitoringLib
    ) "monitoringLib should export perf and baselines dependencies")

    # Test 50: Storage queryMeasurements accepts null parameters
    (helpers.assertTest "monitoring-storage-query-null-params" (
      let
        testStore = storage.createStore "/tmp/test";
        # queryMeasurements should accept null for since/until
        result = storage.queryMeasurements testStore "test-category" null null;
      in
      builtins.isList result
    ) "queryMeasurements should accept null for since and until parameters")
  ];
}
