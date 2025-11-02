# lib/performance-reporting.nix
# Performance reporting and analysis tools
# Provides comprehensive performance reporting, trend analysis, and visualization

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
}:

let
  # Import performance framework
  perf = import ./performance.nix { inherit lib pkgs; };
  baselines = import ./performance-baselines.nix { inherit lib pkgs; };

  # Performance reporting utilities
  reporting = {
    # Generate comprehensive performance report
    generateReport =
      measurements: metadata:
      let
        summary = perf.report.summary measurements;
        trends = perf.regression.analyzeTrend measurements;
        system = metadata.system or "unknown";
        timestamp = metadata.timestamp or builtins.toString perf.time.now;
      in
      {
        metadata = {
          inherit system timestamp;
          framework = "nix-performance-framework";
          version = "1.0.0";
          testCount = builtins.length measurements;
        };

        summary = summary // {
          performance = {
            excellent = summary.successRate >= 0.95 && summary.timing.avg_ms <= 1000;
            good = summary.successRate >= 0.90 && summary.timing.avg_ms <= 5000;
            acceptable = summary.successRate >= 0.80 && summary.timing.avg_ms <= 10000;
            poor = summary.successRate < 0.80 || summary.timing.avg_ms > 10000;
          };
        };

        trends = trends;

        analysis = {
          # Performance classification
          performanceClass =
            if summary.timing.avg_ms <= 100 && summary.successRate >= 0.95 then
              "excellent"
            else if summary.timing.avg_ms <= 500 && summary.successRate >= 0.90 then
              "good"
            else if summary.timing.avg_ms <= 2000 && summary.successRate >= 0.80 then
              "acceptable"
            else
              "needs-improvement";

          # Resource efficiency
          resourceEfficiency =
            if summary.memory.avg_bytes <= 10 * 1024 * 1024 then
              "excellent" # 10MB
            else if summary.memory.avg_bytes <= 50 * 1024 * 1024 then
              "good" # 50MB
            else if summary.memory.avg_bytes <= 100 * 1024 * 1024 then
              "acceptable" # 100MB
            else
              "high-usage";

          # Stability assessment
          stability =
            let
              timeVariance =
                if summary.timing.max_ms > 0 then
                  (summary.timing.max_ms - summary.timing.min_ms) / summary.timing.avg_ms
                else
                  0;
              memoryVariance =
                if summary.memory.max_bytes > 0 then
                  (summary.memory.max_bytes - summary.memory.min_bytes) / summary.memory.avg_bytes
                else
                  0;
            in
            if timeVariance <= 0.2 && memoryVariance <= 0.2 then
              "stable"
            else if timeVariance <= 0.5 && memoryVariance <= 0.5 then
              "moderately-stable"
            else
              "unstable";

          recommendations =
            let
              recs = [ ];
              recs =
                if summary.timing.avg_ms > 5000 then
                  recs ++ [ "Consider optimizing algorithms for better performance" ]
                else
                  recs;
              recs =
                if summary.memory.avg_bytes > 100 * 1024 * 1024 then
                  recs ++ [ "Memory usage is high, consider data structure optimization" ]
                else
                  recs;
              recs =
                if summary.successRate < 0.90 then
                  recs ++ [ "Investigate test failures and improve reliability" ]
                else
                  recs;
              recs =
                if trends.trend == "degrading" then
                  recs ++ [ "Performance is degrading over time, investigate root causes" ]
                else
                  recs;
              recs =
                if trends.changePercent < -10 then
                  recs ++ [ "Performance is improving, consider what changes helped" ]
                else
                  recs;
              recs = if recs == [ ] then [ "Performance is within acceptable ranges" ] else recs;
            in
            recs;
        };

        # Raw measurements for detailed analysis
        measurements = measurements;
      };

    # Format performance report as Markdown
    formatMarkdown = report: ''
      # Performance Analysis Report

      ## Metadata
      - **System**: ${report.metadata.system}
      - **Timestamp**: ${report.metadata.timestamp}
      - **Framework**: ${report.metadata.framework} v${report.metadata.version}
      - **Test Count**: ${toString report.metadata.testCount}

      ## Executive Summary
      - **Performance Class**: ${lib.strings.toUpper report.analysis.performanceClass}
      - **Success Rate**: ${toString (report.summary.successRate * 100)}%
      - **Average Time**: ${toString report.summary.timing.avg_ms}ms
      - **Average Memory**: ${toString (report.summary.memory.avg_bytes / 1024 / 1024)}MB
      - **Stability**: ${
        lib.strings.toUpper (lib.string.replaceStrings [ "-" ] [ " " ] report.analysis.stability)
      }

      ## Performance Metrics
      ### Timing Analysis
      - **Average**: ${toString report.summary.timing.avg_ms}ms
      - **Minimum**: ${toString report.summary.timing.min_ms}ms
      - **Maximum**: ${toString report.summary.timing.max_ms}ms
      - **Total**: ${toString report.summary.timing.total_ms}ms

      ### Memory Usage
      - **Average**: ${toString (report.summary.memory.avg_bytes / 1024 / 1024)}MB
      - **Minimum**: ${toString (report.summary.memory.min_bytes / 1024 / 1024)}MB
      - **Maximum**: ${toString (report.summary.memory.max_bytes / 1024 / 1024)}MB
      - **Total**: ${toString (report.summary.memory.total_bytes / 1024 / 1024)}MB

      ## Trend Analysis
      - **Trend Direction**: ${report.trends.direction}
      - **Trend Status**: ${report.trends.trend}
      - **Change Percentage**: ${toString report.trends.changePercent}%
      - **Recent Average**: ${toString report.trends.recentAverage}ms
      - **Overall Average**: ${toString report.trends.overallAverage}ms

      ## Performance Assessment
      ### Classification
      - **Performance**: ${report.analysis.performanceClass}
      - **Resource Efficiency**: ${report.analysis.resourceEfficiency}
      - **Stability**: ${report.analysis.stability}

      ### Recommendations
      ${lib.concatMapStringsSep "\n" (r: "- ${r}") report.analysis.recommendations}

      ## Detailed Results
      ${lib.concatMapStringsSep "\n" (m: ''
        - **Test**: Duration ${toString m.duration_ms}ms, Memory ${
          toString (m.memoryAfter / 1024 / 1024)
        }MB, Success ${if m.success then "✅" else "❌"}
      '') report.measurements}

      ---
      *Report generated by Nix Performance Framework*
      *Timestamp: ${report.metadata.timestamp}*
    '';

    # Format performance report as JSON
    formatJSON = report: builtins.toJSON report;

    # Generate comparison report between two performance runs
    generateComparisonReport =
      baselineReport: currentReport:
      let
        baselineSummary = baselineReport.summary;
        currentSummary = currentReport.summary;

        timeChange =
          if baselineSummary.timing.avg_ms > 0 then
            ((currentSummary.timing.avg_ms - baselineSummary.timing.avg_ms) / baselineSummary.timing.avg_ms)
            * 100
          else
            0;
        memoryChange =
          if baselineSummary.memory.avg_bytes > 0 then
            (
              (currentSummary.memory.avg_bytes - baselineSummary.memory.avg_bytes)
              / baselineSummary.memory.avg_bytes
            )
            * 100
          else
            0;
        successRateChange = (currentSummary.successRate - baselineSummary.successRate) * 100;
      in
      {
        comparison = {
          timestamp = builtins.toString perf.time.now;
          baseline = baselineReport.metadata.timestamp;
          current = currentReport.metadata.timestamp;
        };

        changes = {
          timing = {
            baseline_ms = baselineSummary.timing.avg_ms;
            current_ms = currentSummary.timing.avg_ms;
            change_percent = timeChange;
            improved = timeChange < 0;
            significant = builtins.abs timeChange > 10;
          };

          memory = {
            baseline_bytes = baselineSummary.memory.avg_bytes;
            current_bytes = currentSummary.memory.avg_bytes;
            change_percent = memoryChange;
            improved = memoryChange < 0;
            significant = builtins.abs memoryChange > 10;
          };

          reliability = {
            baseline_rate = baselineSummary.successRate;
            current_rate = currentSummary.successRate;
            change_percent = successRateChange;
            improved = successRateChange > 0;
            significant = builtins.abs successRateChange > 5;
          };
        };

        assessment = {
          overall =
            if timeChange < -10 && memoryChange < -10 && successRateChange > 5 then
              "significant-improvement"
            else if timeChange < -5 && memoryChange < -5 && successRateChange > 0 then
              "improvement"
            else if timeChange > 10 || memoryChange > 10 || successRateChange < -5 then
              "regression"
            else
              "stable";

          alerts =
            let
              alerts = [ ];
              alerts =
                if timeChange > 50 then alerts ++ [ "Critical: Performance degradation > 50%" ] else alerts;
              alerts =
                if memoryChange > 50 then alerts ++ [ "Critical: Memory usage increase > 50%" ] else alerts;
              alerts =
                if successRateChange < -20 then alerts ++ [ "Critical: Reliability drop > 20%" ] else alerts;
              alerts = if timeChange > 20 then alerts ++ [ "Warning: Performance degradation > 20%" ] else alerts;
              alerts = if memoryChange > 20 then alerts ++ [ "Warning: Memory usage increase > 20%" ] else alerts;
              alerts =
                if successRateChange < -10 then alerts ++ [ "Warning: Reliability drop > 10%" ] else alerts;
            in
            alerts;
        };
      };

    # Format comparison report as Markdown
    formatComparisonMarkdown = comparison: ''
      # Performance Comparison Report

      ## Comparison Overview
      - **Baseline**: ${comparison.comparison.baseline}
      - **Current**: ${comparison.comparison.current}
      - **Generated**: ${comparison.comparison.timestamp}

      ## Performance Changes

      ### Timing Performance
      - **Baseline**: ${toString comparison.changes.timing.baseline_ms}ms
      - **Current**: ${toString comparison.changes.timing.current_ms}ms
      - **Change**: ${toString comparison.changes.timing.change_percent}%
      - **Status**: ${
        if comparison.changes.timing.improved then
          "✅ Improved"
        else if comparison.changes.timing.significant then
          "❌ Degraded"
        else
          "➡️ Stable"
      }

      ### Memory Usage
      - **Baseline**: ${toString (comparison.changes.memory.baseline_bytes / 1024 / 1024)}MB
      - **Current**: ${toString (comparison.changes.memory.current_bytes / 1024 / 1024)}MB
      - **Change**: ${toString comparison.changes.memory.change_percent}%
      - **Status**: ${
        if comparison.changes.memory.improved then
          "✅ Improved"
        else if comparison.changes.memory.significant then
          "❌ Increased"
        else
          "➡️ Stable"
      }

      ### Reliability
      - **Baseline**: ${toString (comparison.changes.reliability.baseline_rate * 100)}%
      - **Current**: ${toString (comparison.changes.reliability.current_rate * 100)}%
      - **Change**: ${toString comparison.changes.reliability.change_percent}%
      - **Status**: ${
        if comparison.changes.reliability.improved then
          "✅ Improved"
        else if comparison.changes.reliability.significant then
          "❌ Degraded"
        else
          "➡️ Stable"
      }

      ## Overall Assessment
      - **Status**: ${
        lib.strings.toUpper (lib.string.replaceStrings [ "-" ] [ " " ] comparison.assessment.overall)
      }

      ## Alerts
      ${
        if builtins.length comparison.assessment.alerts > 0 then
          lib.concatMapStringsSep "\n" (alert: "- **${alert}**") comparison.assessment.alerts
        else
          "✅ No performance alerts detected"
      }

      ---
      *Comparison generated by Nix Performance Framework*
    '';

    # Generate performance dashboard data
    generateDashboard =
      reports:
      let
        latest = builtins.head reports;
        count = builtins.length reports;

        # Calculate aggregates across all reports
        allTimings = map (r: r.summary.timing.avg_ms) reports;
        allMemories = map (r: r.summary.memory.avg_bytes) reports;
        allSuccessRates = map (r: r.summary.successRate) reports;

        avgTiming =
          if builtins.length allTimings > 0 then
            lib.foldl (acc: t: acc + t) 0 allTimings / builtins.length allTimings
          else
            0;
        avgMemory =
          if builtins.length allMemories > 0 then
            lib.foldl (acc: m: acc + m) 0 allMemories / builtins.length allMemories
          else
            0;
        avgSuccessRate =
          if builtins.length allSuccessRates > 0 then
            lib.foldl (acc: s: acc + s) 0 allSuccessRates / builtins.length allSuccessRates
          else
            0;
      in
      {
        overview = {
          totalReports = count;
          latestTimestamp = latest.metadata.timestamp;
          latestSystem = latest.metadata.system;
          latestPerformanceClass = latest.analysis.performanceClass;
        };

        currentMetrics = {
          timing = latest.summary.timing;
          memory = latest.summary.memory;
          successRate = latest.summary.successRate;
          trends = latest.trends;
        };

        aggregates = {
          avgTiming = avgTiming;
          avgMemory = avgMemory;
          avgSuccessRate = avgSuccessRate;
        };

        health = {
          status =
            if avgSuccessRate >= 0.95 && avgTiming <= 1000 then
              "excellent"
            else if avgSuccessRate >= 0.90 && avgTiming <= 5000 then
              "good"
            else if avgSuccessRate >= 0.80 && avgTiming <= 10000 then
              "acceptable"
            else
              "critical";

          issues =
            let
              issues = [ ];
              issues = if avgSuccessRate < 0.80 then issues ++ [ "Low reliability" ] else issues;
              issues = if avgTiming > 10000 then issues ++ [ "Poor performance" ] else issues;
              issues = if avgMemory > 100 * 1024 * 1024 then issues ++ [ "High memory usage" ] else issues;
            in
            issues;
        };

        # Chart data for visualization
        chartData = {
          timeline = map (r: {
            timestamp = r.metadata.timestamp;
            timing = r.summary.timing.avg_ms;
            memory = r.summary.memory.avg_bytes / 1024 / 1024;
            successRate = r.summary.successRate * 100;
          }) reports;

          distribution = {
            timing = {
              min = lib.foldl (acc: t: if t < acc then t else acc) 999999 allTimings;
              max = lib.foldl (acc: t: if t > acc then t else acc) 0 allTimings;
              avg = avgTiming;
            };
            memory = {
              min = lib.foldl (acc: m: if m < acc then m else acc) 999999999 allMemories;
              max = lib.foldl (acc: m: if m > acc then m else acc) 0 allMemories;
              avg = avgMemory;
            };
          };
        };
      };
  };

in
{
  inherit reporting;
  inherit (reporting)
    generateReport
    formatMarkdown
    formatJSON
    generateComparisonReport
    formatComparisonMarkdown
    generateDashboard
    ;
  inherit (perf)
    time
    memory
    build
    resources
    regression
    report
    testing
    ;
  inherit (baselines) systemBaselines operationBaselines regressionThresholds;
}
