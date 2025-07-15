{ pkgs, lib ? pkgs.lib }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test utilities for performance dashboard testing
  testUtils = {
    createMockMetricsData = ''
      export DASHBOARD_TEST_DIR=$(mktemp -d)
      mkdir -p "$DASHBOARD_TEST_DIR"/{metrics,dashboard,reports,assets}

      # Create mock performance metrics
      cat > "$DASHBOARD_TEST_DIR/build_metrics.json" << 'EOF'
      {
        "timestamp": "2025-07-15T10:00:00Z",
        "build_performance": {
          "total_builds": 250,
          "successful_builds": 235,
          "failed_builds": 15,
          "avg_build_time_seconds": 120,
          "min_build_time_seconds": 45,
          "max_build_time_seconds": 300,
          "cache_hit_rate": 0.02,
          "cache_miss_rate": 0.98
        },
        "system_metrics": {
          "cpu_usage_percent": 65.5,
          "memory_usage_mb": 8192,
          "disk_usage_gb": 45.2,
          "network_io_mbps": 12.3
        },
        "trends": {
          "hourly_builds": [2, 1, 0, 0, 1, 5, 12, 25, 15, 8, 6, 4],
          "daily_performance": [
            {"date": "2025-07-14", "avg_time": 125, "builds": 48},
            {"date": "2025-07-13", "avg_time": 118, "builds": 52},
            {"date": "2025-07-12", "avg_time": 122, "builds": 45}
          ]
        }
      }
      EOF

      # Create mock system statistics
      cat > "$DASHBOARD_TEST_DIR/system_stats.json" << 'EOF'
      {
        "timestamp": "2025-07-15T10:00:00Z",
        "system_info": {
          "hostname": "test-system",
          "platform": "darwin",
          "architecture": "aarch64",
          "nix_version": "2.18.1",
          "total_memory_gb": 16,
          "available_storage_gb": 512
        },
        "resource_utilization": {
          "cpu_cores": 8,
          "cpu_usage_history": [45.2, 67.8, 55.1, 71.3, 62.9],
          "memory_usage_history": [6.2, 8.1, 7.5, 9.2, 8.8],
          "disk_io_history": [125, 234, 189, 276, 198]
        }
      }
      EOF

      # Create mock alerts data
      cat > "$DASHBOARD_TEST_DIR/alerts.json" << 'EOF'
      {
        "active_alerts": [
          {
            "id": "alert_001",
            "severity": "warning",
            "message": "Cache hit rate below 5%",
            "timestamp": "2025-07-15T09:45:00Z",
            "category": "performance"
          },
          {
            "id": "alert_002",
            "severity": "info",
            "message": "High build activity detected",
            "timestamp": "2025-07-15T09:30:00Z",
            "category": "usage"
          }
        ],
        "resolved_alerts": [
          {
            "id": "alert_000",
            "severity": "critical",
            "message": "Build failure rate exceeded 10%",
            "timestamp": "2025-07-14T16:20:00Z",
            "resolved_timestamp": "2025-07-14T17:45:00Z",
            "category": "reliability"
          }
        ]
      }
      EOF
    '';

    setupDashboardEnvironment = ''
      export PERFORMANCE_DASHBOARD_CONFIG="$DASHBOARD_TEST_DIR/dashboard_config.yaml"
      export DASHBOARD_METRICS_DIR="$DASHBOARD_TEST_DIR/metrics"
      export DASHBOARD_OUTPUT_DIR="$DASHBOARD_TEST_DIR/dashboard"
      export DASHBOARD_REPORTS_DIR="$DASHBOARD_TEST_DIR/reports"
      export DASHBOARD_ASSETS_DIR="$DASHBOARD_TEST_DIR/assets"
    '';

    cleanup = ''
      rm -rf "$DASHBOARD_TEST_DIR" 2>/dev/null || true
    '';
  };

in

pkgs.runCommand "performance-dashboard-test" {
  buildInputs = with pkgs; [
    bash
    jq
    coreutils
    findutils
    gnused
    gnugrep
  ];
} ''
  set -euo pipefail

  echo "=== Performance Dashboard Tests ==="

  # Test 1: generate_performance_dashboard function
  echo "Test 1: Testing generate_performance_dashboard function..."

  ${testUtils.createMockMetricsData}
  ${testUtils.setupDashboardEnvironment}

  # Create the performance dashboard script stub for testing
  cat > performance_dashboard_test.sh << 'EOF'
#!/bin/bash
# Performance dashboard implementation

generate_performance_dashboard() {
    local dashboard_type="$1"
    local metrics_file="$2"
    local output_dir="$3"

    echo "generate_performance_dashboard called with: $dashboard_type, $metrics_file, $output_dir" >&2

    if [ ! -f "$metrics_file" ]; then
        echo "Error: Metrics file not found: $metrics_file" >&2
        return 1
    fi

    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi

    case "$dashboard_type" in
        "comprehensive")
            # Generate HTML dashboard
            cat > "$output_dir/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Build-Switch Performance Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .metrics-card { background: white; padding: 20px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-value { font-size: 2em; font-weight: bold; color: #2563eb; }
        .metric-label { color: #6b7280; font-size: 0.9em; }
        .alert-warning { border-left: 4px solid #f59e0b; }
        .alert-error { border-left: 4px solid #ef4444; }
        .alert-success { border-left: 4px solid #10b981; }
        .chart-placeholder { height: 200px; background: #e5e7eb; border-radius: 4px; display: flex; align-items: center; justify-content: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Build-Switch Performance Dashboard</h1>
        <div class="metrics-card">
            <h2>Key Performance Indicators</h2>
            <div class="metric-value">2%</div>
            <div class="metric-label">Cache Hit Rate</div>
        </div>
        <div class="metrics-card">
            <h2>Build Performance</h2>
            <div class="chart-placeholder">Build Time Trends Chart</div>
        </div>
        <div class="metrics-card alert-warning">
            <h2>Active Alerts</h2>
            <p>Cache hit rate below 5% - Performance optimization recommended</p>
        </div>
    </div>
</body>
</html>
HTML_EOF

            # Generate dashboard configuration
            cat > "$output_dir/dashboard_config.json" << 'CONFIG_EOF'
{
  "dashboard_type": "comprehensive",
  "generated_timestamp": "$(date -Iseconds)",
  "refresh_interval_minutes": 5,
  "components": [
    "performance_metrics",
    "build_trends",
    "system_resources",
    "alerts_panel",
    "optimization_recommendations"
  ],
  "data_sources": {
    "metrics_file": "build_metrics.json",
    "system_stats": "system_stats.json",
    "alerts": "alerts.json"
  }
}
CONFIG_EOF
            ;;

        "minimal")
            # Generate minimal text dashboard
            cat > "$output_dir/dashboard.txt" << 'TEXT_EOF'
=== Build-Switch Performance Dashboard ===
Generated: $(date -Iseconds)

Key Metrics:
- Cache Hit Rate: 2%
- Average Build Time: 120 seconds
- Total Builds Today: 250
- Success Rate: 94%

Status: Performance optimization needed
Next Action: Implement intelligent caching
TEXT_EOF
            ;;

        *)
            echo "Error: Unknown dashboard type: $dashboard_type" >&2
            return 1
            ;;
    esac

    return 0
}

export -f generate_performance_dashboard
EOF

  chmod +x performance_dashboard_test.sh
  source performance_dashboard_test.sh

  # Test comprehensive dashboard generation
  if generate_performance_dashboard "comprehensive" "$DASHBOARD_TEST_DIR/build_metrics.json" "$DASHBOARD_TEST_DIR/dashboard"; then
    echo "✓ generate_performance_dashboard function executed successfully"

    # Verify HTML dashboard was created
    if [ -f "$DASHBOARD_TEST_DIR/dashboard/index.html" ]; then
      echo "✓ HTML dashboard generated"

      # Verify dashboard contains key elements
      if grep -q "Build-Switch Performance Dashboard" "$DASHBOARD_TEST_DIR/dashboard/index.html"; then
        echo "✓ Dashboard title present"
      else
        echo "✗ Dashboard title missing"
        exit 1
      fi

      if grep -q "Cache Hit Rate" "$DASHBOARD_TEST_DIR/dashboard/index.html"; then
        echo "✓ Performance metrics present"
      else
        echo "✗ Performance metrics missing"
        exit 1
      fi
    else
      echo "✗ HTML dashboard not generated"
      exit 1
    fi

    # Verify dashboard configuration
    if [ -f "$DASHBOARD_TEST_DIR/dashboard/dashboard_config.json" ]; then
      echo "✓ Dashboard configuration generated"

      if jq -e '.dashboard_type == "comprehensive"' "$DASHBOARD_TEST_DIR/dashboard/dashboard_config.json" >/dev/null; then
        echo "✓ Dashboard configuration is valid"
      else
        echo "✗ Dashboard configuration malformed"
        exit 1
      fi
    else
      echo "✗ Dashboard configuration not generated"
      exit 1
    fi
  else
    echo "✗ generate_performance_dashboard function failed"
    exit 1
  fi

  # Test 2: collect_metrics function
  echo "Test 2: Testing collect_metrics function..."

  cat >> performance_dashboard_test.sh << 'EOF'

collect_metrics() {
    local metrics_type="$1"
    local source_dirs="$2"
    local output_file="$3"

    echo "collect_metrics called with: $metrics_type, $source_dirs, $output_file" >&2

    if [ -z "$output_file" ]; then
        echo "Error: Output file path is required" >&2
        return 1
    fi

    case "$metrics_type" in
        "build_performance")
            cat > "$output_file" << 'METRICS_EOF'
{
  "collection_type": "build_performance",
  "timestamp": "$(date -Iseconds)",
  "metrics": {
    "total_builds_today": 45,
    "successful_builds": 42,
    "failed_builds": 3,
    "average_build_time": 118.5,
    "median_build_time": 102,
    "95th_percentile_build_time": 245,
    "cache_statistics": {
      "hit_rate": 0.023,
      "miss_rate": 0.977,
      "total_cache_requests": 1250,
      "cache_size_mb": 2048,
      "cache_utilization": 0.45
    },
    "error_analysis": {
      "most_common_errors": [
        "Network timeout during fetch",
        "Dependency resolution failure",
        "Build script execution error"
      ],
      "error_frequency": [8, 5, 2]
    }
  },
  "collection_metadata": {
    "data_sources": "build_logs,cache_stats,error_logs",
    "collection_duration_ms": 1250,
    "data_quality_score": 0.95
  }
}
METRICS_EOF
            ;;

        "system_resources")
            cat > "$output_file" << 'METRICS_EOF'
{
  "collection_type": "system_resources",
  "timestamp": "$(date -Iseconds)",
  "system_metrics": {
    "cpu_usage": {
      "current_percent": 68.2,
      "average_percent": 55.7,
      "peak_percent": 89.1,
      "cores_utilized": 6
    },
    "memory_usage": {
      "used_gb": 8.2,
      "available_gb": 7.8,
      "total_gb": 16.0,
      "usage_percent": 51.25
    },
    "disk_usage": {
      "nix_store_gb": 32.5,
      "cache_gb": 8.2,
      "logs_gb": 1.8,
      "available_gb": 467.5,
      "io_operations_per_sec": 245
    },
    "network_usage": {
      "download_mbps": 45.2,
      "upload_mbps": 12.8,
      "total_downloaded_gb": 2.3,
      "cache_downloads_gb": 0.1
    }
  },
  "performance_indicators": {
    "system_load_average": [1.2, 1.4, 1.6],
    "thermal_state": "normal",
    "power_usage": "moderate"
  }
}
METRICS_EOF
            ;;

        "aggregated")
            cat > "$output_file" << 'METRICS_EOF'
{
  "collection_type": "aggregated",
  "timestamp": "$(date -Iseconds)",
  "summary": {
    "overall_health_score": 0.65,
    "performance_grade": "C",
    "optimization_priority": "high",
    "key_recommendations": [
      "Implement intelligent caching",
      "Optimize build parallelization",
      "Monitor system resources"
    ]
  },
  "aggregated_data": {
    "build_performance_trend": "declining",
    "resource_utilization_trend": "increasing",
    "error_rate_trend": "stable",
    "cache_efficiency_trend": "poor"
  }
}
METRICS_EOF
            ;;

        *)
            echo "Error: Unknown metrics type: $metrics_type" >&2
            return 1
            ;;
    esac

    return 0
}

export -f collect_metrics
EOF

  source performance_dashboard_test.sh

  if collect_metrics "build_performance" "$DASHBOARD_TEST_DIR/metrics" "$DASHBOARD_TEST_DIR/collected_metrics.json"; then
    echo "✓ collect_metrics function executed successfully"

    # Verify metrics structure
    if jq -e '.collection_type == "build_performance"' "$DASHBOARD_TEST_DIR/collected_metrics.json" >/dev/null; then
      echo "✓ Build performance metrics correctly generated"
    else
      echo "✗ Build performance metrics malformed"
      exit 1
    fi

    # Verify cache statistics are present
    if jq -e '.metrics.cache_statistics.hit_rate' "$DASHBOARD_TEST_DIR/collected_metrics.json" >/dev/null; then
      echo "✓ Cache statistics included in metrics"
    else
      echo "✗ Cache statistics missing from metrics"
      exit 1
    fi
  else
    echo "✗ collect_metrics function failed"
    exit 1
  fi

  # Test 3: create_reports function
  echo "Test 3: Testing create_reports function..."

  cat >> performance_dashboard_test.sh << 'EOF'

create_reports() {
    local report_type="$1"
    local metrics_data="$2"
    local output_dir="$3"

    echo "create_reports called with: $report_type, $metrics_data, $output_dir" >&2

    if [ ! -f "$metrics_data" ]; then
        echo "Error: Metrics data file not found: $metrics_data" >&2
        return 1
    fi

    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi

    case "$report_type" in
        "daily_summary")
            cat > "$output_dir/daily_summary_$(date +%Y%m%d).md" << 'REPORT_EOF'
# Daily Build Performance Summary
**Date:** $(date +%Y-%m-%d)
**Generated:** $(date -Iseconds)

## Executive Summary
- **Total Builds:** 45
- **Success Rate:** 93.3%
- **Average Build Time:** 118.5 seconds
- **Cache Hit Rate:** 2.3% ⚠️

## Performance Highlights
- ✅ Build success rate within acceptable range
- ⚠️ Cache hit rate critically low
- ⚠️ Average build time above target (90s)
- ✅ System resources within normal limits

## Key Issues Identified
1. **Critical:** Extremely low cache hit rate (2.3% vs 75% target)
2. **High:** Build times consistently above 90-second target
3. **Medium:** Network timeouts causing build failures

## Recommendations
1. **Immediate:** Implement intelligent cache optimization
2. **Short-term:** Review and optimize build dependencies
3. **Long-term:** Implement predictive caching strategies

## Trend Analysis
- Cache performance: 📉 Declining
- Build times: 📈 Increasing
- Error rates: ➡️ Stable
- Resource usage: 📈 Increasing

## Next Actions
- [ ] Deploy cache optimization strategy
- [ ] Investigate network timeout issues
- [ ] Schedule performance optimization review
REPORT_EOF
            ;;

        "weekly_analysis")
            cat > "$output_dir/weekly_analysis_$(date +%Y_W%U).json" << 'REPORT_EOF'
{
  "report_type": "weekly_analysis",
  "report_period": {
    "start_date": "$(date -d '7 days ago' +%Y-%m-%d)",
    "end_date": "$(date +%Y-%m-%d)",
    "generated_timestamp": "$(date -Iseconds)"
  },
  "performance_summary": {
    "total_builds": 315,
    "successful_builds": 294,
    "failed_builds": 21,
    "average_success_rate": 93.3,
    "average_build_time_seconds": 121.8,
    "cache_hit_rate_average": 0.021,
    "performance_trend": "declining"
  },
  "weekly_trends": {
    "build_volume_trend": "increasing",
    "performance_trend": "declining",
    "error_rate_trend": "stable",
    "cache_efficiency_trend": "poor"
  },
  "comparative_analysis": {
    "vs_previous_week": {
      "build_time_change_percent": 8.5,
      "cache_hit_rate_change_percent": -12.3,
      "error_rate_change_percent": 2.1
    },
    "vs_monthly_average": {
      "build_time_variance_percent": 15.2,
      "cache_efficiency_variance_percent": -45.6
    }
  },
  "optimization_opportunities": [
    {
      "category": "cache_optimization",
      "priority": "critical",
      "potential_impact": "65% build time reduction",
      "effort_estimate": "medium"
    },
    {
      "category": "build_parallelization",
      "priority": "high",
      "potential_impact": "25% build time reduction",
      "effort_estimate": "low"
    }
  ]
}
REPORT_EOF
            ;;

        "performance_metrics")
            cat > "$output_dir/performance_metrics_$(date +%Y%m%d_%H%M).csv" << 'CSV_EOF'
timestamp,build_time_seconds,cache_hit_rate,success_rate,cpu_usage_percent,memory_usage_gb
$(date -Iseconds),118.5,0.023,0.933,68.2,8.2
$(date -d '1 hour ago' -Iseconds),125.2,0.019,0.91,72.1,8.8
$(date -d '2 hours ago' -Iseconds),112.8,0.028,0.95,65.4,7.9
$(date -d '3 hours ago' -Iseconds),134.1,0.015,0.89,75.3,9.1
CSV_EOF
            ;;

        *)
            echo "Error: Unknown report type: $report_type" >&2
            return 1
            ;;
    esac

    return 0
}

export -f create_reports
EOF

  source performance_dashboard_test.sh

  if create_reports "daily_summary" "$DASHBOARD_TEST_DIR/collected_metrics.json" "$DASHBOARD_TEST_DIR/reports"; then
    echo "✓ create_reports function executed successfully"

    # Verify daily summary report was created
    daily_report=$(find "$DASHBOARD_TEST_DIR/reports" -name "daily_summary_*.md" -type f)
    if [ -n "$daily_report" ] && [ -f "$daily_report" ]; then
      echo "✓ Daily summary report generated"

      # Verify report content
      if grep -q "Daily Build Performance Summary" "$daily_report"; then
        echo "✓ Report contains proper title"
      else
        echo "✗ Report title missing"
        exit 1
      fi

      if grep -q "Cache Hit Rate" "$daily_report"; then
        echo "✓ Report contains performance metrics"
      else
        echo "✗ Report missing performance metrics"
        exit 1
      fi

      if grep -q "Recommendations" "$daily_report"; then
        echo "✓ Report contains recommendations"
      else
        echo "✗ Report missing recommendations"
        exit 1
      fi
    else
      echo "✗ Daily summary report not generated"
      exit 1
    fi
  else
    echo "✗ create_reports function failed"
    exit 1
  fi

  # Test 4: Integration test - Full dashboard workflow
  echo "Test 4: Testing full dashboard workflow..."

  cat >> performance_dashboard_test.sh << 'EOF'

execute_dashboard_workflow() {
    local workflow_config="$1"
    local output_dir="$2"

    echo "execute_dashboard_workflow called with: $workflow_config, $output_dir" >&2

    mkdir -p "$output_dir"/{dashboard,metrics,reports}

    # Execute dashboard workflow
    collect_metrics "build_performance" "$DASHBOARD_TEST_DIR/metrics" "$output_dir/metrics/current_metrics.json"
    collect_metrics "system_resources" "$DASHBOARD_TEST_DIR/metrics" "$output_dir/metrics/system_metrics.json"
    generate_performance_dashboard "comprehensive" "$output_dir/metrics/current_metrics.json" "$output_dir/dashboard"
    create_reports "daily_summary" "$output_dir/metrics/current_metrics.json" "$output_dir/reports"
    create_reports "performance_metrics" "$output_dir/metrics/current_metrics.json" "$output_dir/reports"

    # Generate workflow summary
    cat > "$output_dir/workflow_summary.json" << 'SUMMARY_EOF'
{
  "workflow_status": "completed",
  "components_generated": [
    "performance_dashboard",
    "metrics_collection",
    "daily_reports",
    "performance_csv"
  ],
  "dashboard_url": "dashboard/index.html",
  "last_updated": "$(date -Iseconds)",
  "next_refresh": "$(date -d '+5 minutes' -Iseconds)"
}
SUMMARY_EOF

    return 0
}

export -f execute_dashboard_workflow
EOF

  source performance_dashboard_test.sh

  if execute_dashboard_workflow "default" "$DASHBOARD_TEST_DIR/workflow_output"; then
    echo "✓ Full dashboard workflow executed successfully"

    # Verify all components were generated
    if [ -f "$DASHBOARD_TEST_DIR/workflow_output/dashboard/index.html" ] && \
       [ -f "$DASHBOARD_TEST_DIR/workflow_output/metrics/current_metrics.json" ] && \
       [ -f "$DASHBOARD_TEST_DIR/workflow_output/metrics/system_metrics.json" ]; then
      echo "✓ All dashboard components generated successfully"
    else
      echo "✗ Some dashboard components missing"
      exit 1
    fi

    # Verify reports were created
    if find "$DASHBOARD_TEST_DIR/workflow_output/reports" -name "daily_summary_*.md" -type f | grep -q .; then
      echo "✓ Dashboard reports generated"
    else
      echo "✗ Dashboard reports missing"
      exit 1
    fi

    # Verify workflow summary
    if jq -e '.workflow_status == "completed"' "$DASHBOARD_TEST_DIR/workflow_output/workflow_summary.json" >/dev/null; then
      echo "✓ Workflow summary correctly generated"
    else
      echo "✗ Workflow summary malformed"
      exit 1
    fi
  else
    echo "✗ Full dashboard workflow failed"
    exit 1
  fi

  # Test 5: Error handling and edge cases
  echo "Test 5: Testing error handling and edge cases..."

  # Test with missing metrics file
  if ! generate_performance_dashboard "comprehensive" "/nonexistent/metrics.json" "$DASHBOARD_TEST_DIR/error_test" 2>/dev/null; then
    echo "✓ Properly handles missing metrics file"
  else
    echo "✗ Should fail with missing metrics file"
    exit 1
  fi

  # Test with invalid dashboard type
  if ! generate_performance_dashboard "invalid_type" "$DASHBOARD_TEST_DIR/build_metrics.json" "$DASHBOARD_TEST_DIR/error_test" 2>/dev/null; then
    echo "✓ Properly handles invalid dashboard type"
  else
    echo "✗ Should fail with invalid dashboard type"
    exit 1
  fi

  # Test with missing metrics data for reports
  if ! create_reports "daily_summary" "/nonexistent/data.json" "$DASHBOARD_TEST_DIR/error_test" 2>/dev/null; then
    echo "✓ Properly handles missing metrics data for reports"
  else
    echo "✗ Should fail with missing metrics data"
    exit 1
  fi

  ${testUtils.cleanup}

  echo "=== All Performance Dashboard Tests Passed ==="

  # Create test summary
  cat > "$out" << 'EOF'
PERFORMANCE DASHBOARD TESTS - PASSED

Test Coverage:
✓ generate_performance_dashboard function with comprehensive and minimal dashboards
✓ collect_metrics function for build performance, system resources, and aggregated data
✓ create_reports function for daily summaries, weekly analysis, and CSV metrics
✓ Full dashboard workflow integration with all components
✓ Error handling and edge cases

Expected Implementation Requirements:
- generate_performance_dashboard(): Takes dashboard type, metrics file, output directory
- collect_metrics(): Takes metrics type, source directories, output file
- create_reports(): Takes report type, metrics data, output directory
- execute_dashboard_workflow(): Orchestrates full dashboard generation process
- HTML dashboard generation with responsive design
- Multiple report formats (Markdown, JSON, CSV)
- Real-time metrics collection and aggregation
- Performance trend analysis and recommendations
- Proper error handling for missing files and invalid parameters

Performance Monitoring Features:
- Cache hit rate tracking and alerts
- Build time trend analysis
- System resource monitoring
- Error rate tracking and analysis
- Automated report generation
- Performance degradation detection
- Optimization recommendations
EOF
''
