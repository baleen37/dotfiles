# lib/monitoring.nix
# Comprehensive monitoring system for test execution and performance metrics
# Provides historical tracking, trend analysis, and automated alerting

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
}:

let
  # Import existing performance frameworks
  perf = import ./performance.nix { inherit lib pkgs; };

  baselines = import ./performance-baselines.nix { inherit lib pkgs; };

  # Current system detection
  currentSystem = builtins.currentSystem or "unknown";

  # Core monitoring system
  monitoring = {
    # Data storage and management
    storage = {
      # Create monitoring data store
      createStore = path: {
        inherit path;
        data = { };
        metadata = {
          version = "1.0.0";
          created = perf.time.now;
          system = currentSystem;
        };
      };

      # Add measurement to store
      addMeasurement =
        store: category: measurement:
        let
          timestamp = toString perf.time.now;
          existingData = store.data.${category} or [ ];
          newData = existingData ++ [
            {
              inherit timestamp measurement;
              id = "${category}-${timestamp}";
            }
          ];
        in
        store
        // {
          data = store.data // {
            "${category}" = newData;
          };
          metadata = store.metadata // {
            lastUpdated = perf.time.now;
            totalMeasurements = lib.foldl (acc: cat: acc + builtins.length store.data.${cat} or [ ]) 0 (
              lib.attrNames store.data
            );
          };
        };

      # Query measurements from store
      queryMeasurements =
        store: category: since: until:
        let
          allMeasurements = store.data.${category} or [ ];
          filtered =
            let
              sinceTime = if since != null then since else 0;
              untilTime = if until != null then until else 999999999999999999;
            in
            builtins.filter (
              m: (builtins.toInt m.timestamp) >= sinceTime && (builtins.toInt m.timestamp) <= untilTime
            ) allMeasurements;
        in
        map (m: m.measurement) filtered;

      # Get latest measurements
      getLatest =
        store: category: count:
        let
          allMeasurements = store.data.${category} or [ ];
          sorted = builtins.sort (
            a: b: (builtins.toInt a.timestamp) > (builtins.toInt b.timestamp)
          ) allMeasurements;
        in
        map (m: m.measurement) (builtins.sublist 0 count sorted);

      # Clean old measurements
      cleanup =
        store: category: maxAge:
        let
          cutoffTime = perf.time.now - maxAge;
          allMeasurements = store.data.${category} or [ ];
          filtered = builtins.filter (m: (builtins.toInt m.timestamp) >= cutoffTime) allMeasurements;
        in
        store
        // {
          data = store.data // {
            "${category}" = filtered;
          };
        };
    };

    # Test execution monitoring
    tests = {
      # Track test execution
      trackExecution =
        testName: testType: result:
        let
          baseMeasurement = {
            testName = testName;
            testType = testType; # unit, integration, e2e, performance
            timestamp = perf.time.now;
            system = currentSystem;
          };
        in
        baseMeasurement
        // {
          duration_ms = if result ? duration then result.duration else 0;
          memory_bytes = if result ? memory then result.memory else 0;
          success = if result ? success then result.success else true;
          exitCode = if result ? exitCode then result.exitCode else 0;
          metrics = {
            cpu = result.cpu or 0;
            disk = result.disk or 0;
            network = result.network or 0;
          };
          context = {
            gitCommit = result.gitCommit or "unknown";
            branch = result.branch or "unknown";
            buildId = result.buildId or "unknown";
            ci = result.ci or false;
          };
        };

      # Measure test execution with comprehensive metrics
      measureExecution =
        testName: testType: testFunc:
        let
          profile = perf.resources.profile testFunc;
          testResult = profile.value;
          executionTime = profile.duration_ms;
          memoryUsage = profile.memoryAfter;
        in
        {
          measurement = monitoring.tests.trackExecution testName testType {
            duration = executionTime;
            memory = memoryUsage;
            success = if testResult ? success then testResult.success else true;
            exitCode = if testResult ? exitCode then testResult.exitCode else 0;
            value = testResult;
          };
          profile = profile;
        };

      # Analyze test execution trends
      analyzeTrends =
        measurements:
        let
          count = builtins.length measurements;
          successful = builtins.filter (m: m.success) measurements;
          durations = map (m: m.duration_ms) measurements;
          memories = map (m: m.memory_bytes) measurements;

          successRate = if count > 0 then (builtins.length successful) / count else 0;
          avgDuration =
            if builtins.length durations > 0 then
              (lib.foldl (acc: d: acc + d) 0 durations) / builtins.length durations
            else
              0;
          avgMemory =
            if builtins.length memories > 0 then
              (lib.foldl (acc: m: acc + m) 0 memories) / builtins.length memories
            else
              0;
        in
        {
          summary = {
            totalRuns = count;
            successfulRuns = builtins.length successful;
            successRate = successRate;
            avgDuration_ms = avgDuration;
            avgMemory_mb = avgMemory / 1024 / 1024;
          };

          # Performance trend analysis
          performance = perf.regression.analyzeTrend measurements;

          # Reliability analysis
          reliability = {
            stability =
              if successRate >= 0.95 then
                "excellent"
              else if successRate >= 0.90 then
                "good"
              else if successRate >= 0.80 then
                "acceptable"
              else
                "poor";
            trend =
              let
                recentCount = lib.min 5 count;
                recentMeasurements = builtins.sublist (count - recentCount) recentCount measurements;
                recentSuccessRate =
                  if recentCount > 0 then
                    (builtins.length (builtins.filter (m: m.success) recentMeasurements)) / recentCount
                  else
                    0;
              in
              if recentSuccessRate > successRate + 0.05 then
                "improving"
              else if recentSuccessRate < successRate - 0.05 then
                "degrading"
              else
                "stable";
          };

          # Alert generation
          alerts =
            let
              baseAlerts = [ ];
              reliabilityAlerts =
                if successRate < 0.80 then
                  [
                    {
                      severity = "critical";
                      type = "reliability";
                      message = "Test success rate below 80%";
                      value = successRate;
                    }
                  ]
                else
                  [ ];
              performanceAlerts =
                if avgDuration > 30000 then
                  [
                    {
                      severity = "warning";
                      type = "performance";
                      message = "Test execution time exceeding 30 seconds";
                      value = avgDuration;
                    }
                  ]
                else
                  [ ];
              memoryAlerts =
                if avgMemory > 1024 * 1024 * 1024 then
                  [
                    {
                      severity = "warning";
                      type = "memory";
                      message = "Test memory usage exceeding 1GB";
                      value = avgMemory;
                    }
                  ]
                else
                  [ ];
            in
            baseAlerts ++ reliabilityAlerts ++ performanceAlerts ++ memoryAlerts;
        };

      # Generate test execution report
      generateReport =
        testName: measurements: metadata:
        let
          analysis = monitoring.tests.analyzeTrends measurements;
          baseline = baselines.systemBaselines.${currentSystem} or baselines.systemBaselines."x86_64-linux";
        in
        {
          metadata = {
            testName = testName;
            system = currentSystem;
            timestamp = toString perf.time.now;
            framework = "nix-test-monitoring";
            version = "1.0.0";
            measurementCount = builtins.length measurements;
          }
          // metadata;

          summary = analysis.summary;

          performance = {
            current = {
              avgDuration_ms = analysis.summary.avgDuration_ms;
              avgMemory_mb = analysis.summary.avgMemory_mb;
            };
            baseline = {
              maxDuration_ms =
                if testName ? "unit" then
                  baseline.test.maxUnitTestTimeMs
                else if testName ? "integration" then
                  baseline.test.maxIntegrationTestTimeMs
                else
                  baseline.test.maxVmTestTimeMs;
              maxMemory_mb = baseline.memory.maxConfigMemoryMb;
            };
            status =
              if analysis.summary.avgDuration_ms > baseline.test.maxUnitTestTimeMs then
                "slow"
              else if analysis.summary.avgMemory_mb > baseline.memory.maxConfigMemoryMb then
                "memory-heavy"
              else
                "optimal";
          };

          reliability = analysis.reliability;

          trends = analysis.performance;

          alerts = analysis.alerts;

          recommendations =
            let
              baseRecs = [ ];
              reliabilityRecs =
                if analysis.summary.successRate < 0.90 then
                  [ "Investigate test failures and improve test reliability" ]
                else
                  [ ];
              performanceRecs =
                if analysis.summary.avgDuration_ms > baseline.test.maxUnitTestTimeMs then
                  [ "Consider optimizing test execution or test structure" ]
                else
                  [ ];
              memoryRecs =
                if analysis.summary.avgMemory_mb > baseline.memory.maxConfigMemoryMb then
                  [ "Test memory usage is high, consider optimization" ]
                else
                  [ ];
              trendRecs =
                if analysis.performance.trend == "degrading" then
                  [ "Performance is degrading over time, investigate root causes" ]
                else
                  [ ];
            in
            baseRecs ++ reliabilityRecs ++ performanceRecs ++ memoryRecs ++ trendRecs;

          measurements = measurements;
        };
    };

    # Performance metrics collection
    metrics = {
      # Collect system metrics during test execution
      collectSystemMetrics =
        operation:
        let
          startMetrics = monitoring.metrics.getCurrentSystemMetrics;
          profile = perf.resources.profile operation;
          endMetrics = monitoring.metrics.getCurrentSystemMetrics;
        in
        {
          operation = operation;
          profile = profile;
          system = {
            before = startMetrics;
            after = endMetrics;
            delta = {
              memory = endMetrics.memory - startMetrics.memory;
              cpu = endMetrics.cpu - startMetrics.cpu;
              disk = endMetrics.disk - startMetrics.disk;
            };
          };
        };

      # Get current system metrics (simulated for Nix environment)
      getCurrentSystemMetrics = {
        timestamp = perf.time.now;
        memory =
          let
            # Simulate memory usage based on current evaluation
            dummyEval = builtins.deepSeq (builtins.currentSystem) builtins.currentSystem;
          in
          100 * 1024 * 1024 + (lib.mod (perf.time.now / 1000) 50) * 1024 * 1024; # 100-150MB
        cpu = lib.mod (perf.time.now / 100) 100; # 0-99%
        disk = 1000 * 1024 * 1024 + (lib.mod (perf.time.now / 10000) 500) * 1024 * 1024; # 1-1.5GB
        network = (lib.mod (perf.time.now / 5000) 10) * 1024 * 1024; # 0-10MB
      };

      # Aggregate metrics over time
      aggregateMetrics =
        measurements:
        let
          count = builtins.length measurements;
          memories = map (m: m.system.memory) measurements;
          cpus = map (m: m.system.cpu) measurements;
          durations = map (m: m.profile.duration_ms) measurements;
        in
        {
          count = count;
          memory = {
            avg = if count > 0 then (lib.foldl (acc: m: acc + m) 0 memories) / count else 0;
            min =
              if count > 0 then
                lib.foldl (acc: m: if m < acc then m else acc) (builtins.head memories) memories
              else
                0;
            max =
              if count > 0 then
                lib.foldl (acc: m: if m > acc then m else acc) (builtins.head memories) memories
              else
                0;
          };
          cpu = {
            avg = if count > 0 then (lib.foldl (acc: c: acc + c) 0 cpus) / count else 0;
            min =
              if count > 0 then lib.foldl (acc: c: if c < acc then c else acc) (builtins.head cpus) cpus else 0;
            max =
              if count > 0 then lib.foldl (acc: c: if c > acc then c else acc) (builtins.head cpus) cpus else 0;
          };
          duration = {
            avg = if count > 0 then (lib.foldl (acc: d: acc + d) 0 durations) / count else 0;
            min =
              if count > 0 then
                lib.foldl (acc: d: if d < acc then d else acc) (builtins.head durations) durations
              else
                0;
            max =
              if count > 0 then
                lib.foldl (acc: d: if d > acc then d else acc) (builtins.head durations) durations
              else
                0;
          };
        };

      # Detect performance anomalies
      detectAnomalies =
        measurements: threshold:
        let
          aggregates = monitoring.metrics.aggregateMetrics measurements;
          anomalies = [ ];

          # Memory anomalies
          memoryAnomalies =
            if aggregates.memory.avg > threshold.memory.max then
              [
                {
                  type = "memory";
                  severity = "warning";
                  message = "Average memory usage exceeds threshold";
                  actual = aggregates.memory.avg;
                  threshold = threshold.memory.max;
                }
              ]
            else
              [ ];

          # Duration anomalies
          durationAnomalies =
            if aggregates.duration.avg > threshold.duration.max then
              [
                {
                  type = "performance";
                  severity = "warning";
                  message = "Average execution time exceeds threshold";
                  actual = aggregates.duration.avg;
                  threshold = threshold.duration.max;
                }
              ]
            else
              [ ];
        in
        memoryAnomalies ++ durationAnomalies;
    };

    # Alerting system
    alerts = {
      # Create alert
      createAlert = severity: type: message: value: threshold: {
        id = "alert-${toString perf.time.now}-${type}";
        timestamp = perf.time.now;
        inherit
          severity
          type
          message
          value
          threshold
          ;
        acknowledged = false;
        resolved = false;
      };

      # Check performance against thresholds and generate alerts
      checkThresholds =
        measurements: thresholds:
        let
          analysis = monitoring.tests.analyzeTrends measurements;
          alerts = [ ];

          # Success rate alerts
          successAlerts =
            if analysis.summary.successRate < thresholds.successRate.min then
              [
                monitoring.alerts.createAlert
                "critical"
                "reliability"
                "Success rate below threshold"
                analysis.summary.successRate
                thresholds.successRate.min
              ]
            else
              [ ];

          # Performance alerts
          performanceAlerts =
            if analysis.summary.avgDuration_ms > thresholds.duration.max then
              [
                monitoring.alerts.createAlert
                "warning"
                "performance"
                "Average duration exceeds threshold"
                analysis.summary.avgDuration_ms
                thresholds.duration.max
              ]
            else
              [ ];

          # Memory alerts
          memoryAlerts =
            if analysis.summary.avgMemory_mb > thresholds.memory.max then
              [
                monitoring.alerts.createAlert
                "warning"
                "memory"
                "Average memory usage exceeds threshold"
                analysis.summary.avgMemory_mb
                thresholds.memory.max
              ]
            else
              [ ];
        in
        successAlerts ++ performanceAlerts ++ memoryAlerts;

      # Generate alert summary
      generateSummary =
        alerts:
        let
          critical = builtins.filter (a: a.severity == "critical") alerts;
          warning = builtins.filter (a: a.severity == "warning") alerts;
          info = builtins.filter (a: a.severity == "info") alerts;
        in
        {
          total = builtins.length alerts;
          critical = builtins.length critical;
          warning = builtins.length warning;
          info = builtins.length info;
          status =
            if builtins.length critical > 0 then
              "critical"
            else if builtins.length warning > 0 then
              "warning"
            else
              "healthy";
          alerts = alerts;
        };
    };

    # Reporting and dashboard
    reporting = {
      # Generate comprehensive monitoring report
      generateReport =
        store: categories: metadata:
        let
          # Collect measurements from all categories
          allMeasurements = lib.foldl (
            acc: cat: acc ++ (monitoring.storage.queryMeasurements store cat)
          ) [ ] categories;

          # Generate performance report using existing framework
          perfReport = perf.report.summary allMeasurements;

          # System-specific metrics
          systemMetrics = lib.foldl (
            acc: cat:
            let
              measurements = monitoring.storage.queryMeasurements store cat;
              aggregated = monitoring.metrics.aggregateMetrics measurements;
            in
            acc // { "${cat}" = aggregated; }
          ) { } categories;

          # Alerts from all categories
          allAlerts = lib.foldl (
            acc: cat:
            let
              measurements = monitoring.storage.queryMeasurements store cat;
              categoryAlerts = monitoring.tests.analyzeTrends measurements;
            in
            acc ++ categoryAlerts.alerts
          ) [ ] categories;

          alertSummary = monitoring.alerts.generateSummary allAlerts;
        in
        perfReport
        // {
          monitoring = {
            categories = categories;
            measurements = {
              total = builtins.length allMeasurements;
              byCategory = lib.foldl (
                acc: cat: acc // { "${cat}" = builtins.length (monitoring.storage.queryMeasurements store cat); }
              ) { } categories;
            };
            systemMetrics = systemMetrics;
            alerts = alertSummary;
            health = {
              status = alertSummary.status;
              score =
                let
                  baseScore = 100;
                  criticalPenalty = alertSummary.critical * 30;
                  warningPenalty = alertSummary.warning * 10;
                in
                lib.max 0 (baseScore - criticalPenalty - warningPenalty);
            };
          };
        };

      # Format monitoring report for display
      formatSummary = report: ''
        # Test Execution Monitoring Report

        ## Executive Summary
        - **System**: ${report.metadata.system}
        - **Timestamp**: ${report.metadata.timestamp}
        - **Total Measurements**: ${toString report.monitoring.measurements.total}
        - **Health Status**: ${lib.strings.toUpper report.monitoring.health.status}
        - **Health Score**: ${toString report.monitoring.health.score}/100

        ## Performance Overview
        - **Success Rate**: ${toString (report.summary.successRate * 100)}%
        - **Average Duration**: ${toString report.summary.timing.avg_ms}ms
        - **Average Memory**: ${toString (report.summary.memory.avg_bytes / 1024 / 1024)}MB
        - **Performance Class**: ${report.analysis.performanceClass}

        ## Alerts Summary
        - **Total Alerts**: ${toString report.monitoring.alerts.total}
        - **Critical**: ${toString report.monitoring.alerts.critical}
        - **Warning**: ${toString report.monitoring.alerts.warning}
        - **Status**: ${lib.strings.toUpper report.monitoring.alerts.status}

        ## Recommendations
        ${lib.concatMapStringsSep "\n" (r: "- ${r}") report.analysis.recommendations}

        ## Categories Monitored
        ${lib.concatMapStringsSep "\n" (
          cat:
          let
            count = report.monitoring.measurements.byCategory.${cat} or 0;
            metrics = report.monitoring.systemMetrics.${cat} or { };
          in
          "- **${cat}**: ${toString count} measurements, Avg: ${toString metrics.duration.avg or 0}ms"
        ) report.monitoring.categories}

        ---
        *Generated by Nix Test Monitoring System*
        *Framework: ${report.metadata.framework} v${report.metadata.version}*
      '';
    };

    # Integration utilities
    integration = {
      # Hook into test execution
      wrapTest =
        testName: testType: testFunc:
        let
          result = monitoring.tests.measureExecution testName testType testFunc;
        in
        {
          testResult = result.profile.value;
          measurement = result.measurement;
          profile = result.profile;
        };

      # Create monitoring-enabled test suite
      createMonitoredSuite =
        name: tests:
        let
          executedTests = map (
            test: monitoring.integration.wrapTest test.name test.type test.operation
          ) tests;
          measurements = map (t: t.measurement) executedTests;
        in
        {
          inherit name executedTests measurements;
          report = monitoring.tests.generateReport name measurements {
            framework = "nix-test-monitoring";
            suiteName = name;
          };
        };

      # CI/CD integration helpers
      ciConfig = {
        # Enable monitoring in CI
        enableMonitoring = true;

        # Output formats
        formats = [
          "json"
          "markdown"
        ];

        # Artifact paths
        artifacts = {
          reports = "monitoring-reports";
          data = "monitoring-data";
          alerts = "monitoring-alerts";
        };

        # Thresholds for CI
        thresholds = {
          successRate = {
            min = 0.90;
          };
          duration = {
            max = 30000;
          }; # 30 seconds
          memory = {
            max = 1024;
          }; # 1GB
        };

        # Notification settings
        notifications = {
          onFailure = true;
          onDegradation = true;
          onNewAlerts = true;
        };
      };
    };
  };

in
{
  inherit monitoring;
  inherit (monitoring)
    storage
    tests
    metrics
    alerts
    reporting
    integration
    ;
  inherit (perf) perf;

  inherit (baselines) baselines;
}
