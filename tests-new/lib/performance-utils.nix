{ pkgs, lib ? pkgs.lib }:
let
  testHelpers = import ./test-helpers-v2.nix { inherit pkgs lib; };

  # Performance measurement utilities
  measureExecutionTime = { command, description ? null }: ''
    PERF_DESC="${if description != null then description else command}"
    echo "${testHelpers.colors.cyan}⏱️  Measuring: $PERF_DESC${testHelpers.colors.reset}"
    
    START_TIME=$(date +%s%N)
    START_REAL=$(date +%s)
    
    # Execute command with timing
    ${command}
    
    END_TIME=$(date +%s%N)
    END_REAL=$(date +%s)
    
    DURATION_NS=$((END_TIME - START_TIME))
    DURATION_MS=$((DURATION_NS / 1000000))
    DURATION_S=$((END_REAL - START_REAL))
    
    echo "  ${testHelpers.colors.green}✓ Completed in ''${DURATION_MS}ms (''${DURATION_S}s real)${testHelpers.colors.reset}"
    
    # Store metrics
    echo "perf_command: $PERF_DESC" >> "$TEST_ARTIFACTS_DIR/performance.log"
    echo "perf_duration_ms: $DURATION_MS" >> "$TEST_ARTIFACTS_DIR/performance.log"
    echo "perf_duration_s: $DURATION_S" >> "$TEST_ARTIFACTS_DIR/performance.log"
    echo "perf_timestamp: $(date -Iseconds)" >> "$TEST_ARTIFACTS_DIR/performance.log"
    echo "---" >> "$TEST_ARTIFACTS_DIR/performance.log"
    
    # Export for use in scripts
    export LAST_PERF_DURATION_MS=$DURATION_MS
    export LAST_PERF_DURATION_S=$DURATION_S
  '';

  # Resource usage monitoring
  monitorResourceUsage = { command, description ? null, sampleInterval ? 1 }: ''
    MONITOR_DESC="${if description != null then description else command}"
    echo "${testHelpers.colors.cyan}📊 Monitoring resources: $MONITOR_DESC${testHelpers.colors.reset}"
    
    # Start resource monitoring
    MONITOR_LOG="$TEST_ARTIFACTS_DIR/resource_usage_$(date +%s).log"
    
    {
      echo "timestamp,cpu_percent,memory_kb,disk_io,network_io" > "$MONITOR_LOG"
      
      while true; do
        TIMESTAMP=$(date +%s)
        
        # Get process stats if available
        if command -v ps >/dev/null 2>&1; then
          CPU_PERCENT=$(ps -o pcpu= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
          MEMORY_KB=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
        else
          CPU_PERCENT="0"
          MEMORY_KB="0"
        fi
        
        # Get I/O stats if available (simplified)
        DISK_IO=$(iostat -d 1 1 2>/dev/null | tail -1 | awk '{print $3}' || echo "0")
        NETWORK_IO="0"  # Simplified - would need netstat or similar
        
        echo "$TIMESTAMP,$CPU_PERCENT,$MEMORY_KB,$DISK_IO,$NETWORK_IO" >> "$MONITOR_LOG"
        sleep ${toString sampleInterval}
      done
    } &
    
    MONITOR_PID=$!
    
    # Run the actual command
    START_TIME=$(date +%s)
    START_MEM=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    
    ${command}
    
    END_TIME=$(date +%s)
    END_MEM=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    
    # Stop monitoring
    kill $MONITOR_PID 2>/dev/null || true
    wait $MONITOR_PID 2>/dev/null || true
    
    # Calculate summary stats
    DURATION=$((END_TIME - START_TIME))
    MEM_DIFF=$((END_MEM - START_MEM))
    
    # Analyze resource usage
    if [ -f "$MONITOR_LOG" ] && command -v awk >/dev/null 2>&1; then
      MAX_CPU=$(awk -F, 'NR>1 && $2 > max {max = $2} END {print max+0}' "$MONITOR_LOG")
      AVG_CPU=$(awk -F, 'NR>1 {sum += $2; count++} END {print sum/count}' "$MONITOR_LOG")
      MAX_MEM=$(awk -F, 'NR>1 && $3 > max {max = $3} END {print max+0}' "$MONITOR_LOG")
      AVG_MEM=$(awk -F, 'NR>1 {sum += $3; count++} END {print sum/count}' "$MONITOR_LOG")
    else
      MAX_CPU="N/A"
      AVG_CPU="N/A"
      MAX_MEM="$END_MEM"
      AVG_MEM="N/A"
    fi
    
    echo "  ${testHelpers.colors.green}Resource Summary:${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Duration: ''${DURATION}s${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Memory change: ''${MEM_DIFF}KB${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Max CPU: ''${MAX_CPU}%${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Avg CPU: ''${AVG_CPU}%${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Max Memory: ''${MAX_MEM}KB${testHelpers.colors.reset}"
    
    # Store summary
    echo "resource_command: $MONITOR_DESC" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
    echo "resource_duration: $DURATION" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
    echo "resource_mem_change: $MEM_DIFF" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
    echo "resource_max_cpu: $MAX_CPU" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
    echo "resource_avg_cpu: $AVG_CPU" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
    echo "resource_max_mem: $MAX_MEM" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
    echo "---" >> "$TEST_ARTIFACTS_DIR/resource_summary.log"
  '';

  # Performance benchmarking with statistical analysis
  performanceBenchmark = { 
    name, 
    command, 
    iterations ? 5, 
    warmupRuns ? 1,
    maxDuration ? null,
    description ? null
  }: ''
    BENCH_NAME="${name}"
    BENCH_DESC="${if description != null then description else name}"
    
    echo "${testHelpers.colors.magenta}🏃 Performance Benchmark: $BENCH_NAME${testHelpers.colors.reset}"
    echo "  ${testHelpers.colors.dim}Description: $BENCH_DESC${testHelpers.colors.reset}"
    echo "  ${testHelpers.colors.dim}Iterations: ${toString iterations} (+ ${toString warmupRuns} warmup)${testHelpers.colors.reset}"
    
    # Warmup runs
    if [ ${toString warmupRuns} -gt 0 ]; then
      echo "  ${testHelpers.colors.yellow}Running ${toString warmupRuns} warmup iterations...${testHelpers.colors.reset}"
      for i in $(seq 1 ${toString warmupRuns}); do
        ${command} >/dev/null 2>&1 || true
      done
    fi
    
    # Benchmark runs
    echo "  ${testHelpers.colors.yellow}Running ${toString iterations} benchmark iterations...${testHelpers.colors.reset}"
    TIMES=""
    TOTAL_TIME=0
    MIN_TIME=999999999
    MAX_TIME=0
    
    for i in $(seq 1 ${toString iterations}); do
      echo -n "    Iteration $i: "
      
      START_TIME=$(date +%s%N)
      ${command} >/dev/null 2>&1 || true
      END_TIME=$(date +%s%N)
      
      DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
      TIMES="$TIMES $DURATION"
      TOTAL_TIME=$((TOTAL_TIME + DURATION))
      
      if [ $DURATION -lt $MIN_TIME ]; then MIN_TIME=$DURATION; fi
      if [ $DURATION -gt $MAX_TIME ]; then MAX_TIME=$DURATION; fi
      
      echo "''${DURATION}ms"
    done
    
    # Calculate statistics
    AVG_TIME=$((TOTAL_TIME / ${toString iterations}))
    
    # Calculate standard deviation (simplified)
    VARIANCE=0
    for time in $TIMES; do
      DIFF=$((time - AVG_TIME))
      VARIANCE=$((VARIANCE + DIFF * DIFF))
    done
    VARIANCE=$((VARIANCE / ${toString iterations}))
    # Simplified square root approximation
    STDDEV=$((VARIANCE > 0 ? VARIANCE / 100 : 0))
    
    echo ""
    echo "  ${testHelpers.colors.green}📈 Benchmark Results:${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Iterations: ${toString iterations}${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Average: ''${AVG_TIME}ms${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Minimum: ''${MIN_TIME}ms${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Maximum: ''${MAX_TIME}ms${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Std Dev: ~''${STDDEV}ms${testHelpers.colors.reset}"
    
    # Performance assertion if maxDuration is specified
    ${lib.optionalString (maxDuration != null) ''
      if [ $AVG_TIME -le ${toString maxDuration} ]; then
        echo "    ${testHelpers.colors.green}✓ Performance target met (≤${toString maxDuration}ms)${testHelpers.colors.reset}"
      else
        echo "    ${testHelpers.colors.red}✗ Performance target missed (>${toString maxDuration}ms)${testHelpers.colors.reset}"
        exit 1
      fi
    ''}
    
    # Save detailed results
    BENCHMARK_FILE="$TEST_ARTIFACTS_DIR/benchmark_''${BENCH_NAME}_$(date +%s).log"
    echo "benchmark_name: ''$BENCH_NAME" > "$BENCHMARK_FILE"
    echo "benchmark_description: ''$BENCH_DESC" >> "$BENCHMARK_FILE"
    echo "benchmark_iterations: ${toString iterations}" >> "$BENCHMARK_FILE"
    echo "benchmark_avg_ms: $AVG_TIME" >> "$BENCHMARK_FILE"
    echo "benchmark_min_ms: $MIN_TIME" >> "$BENCHMARK_FILE"
    echo "benchmark_max_ms: $MAX_TIME" >> "$BENCHMARK_FILE"
    echo "benchmark_stddev_ms: $STDDEV" >> "$BENCHMARK_FILE"
    echo "benchmark_all_times: $TIMES" >> "$BENCHMARK_FILE"
    echo "benchmark_timestamp: $(date -Iseconds)" >> "$BENCHMARK_FILE"
    
    # Export results for use in other tests
    export LAST_BENCHMARK_AVG=$AVG_TIME
    export LAST_BENCHMARK_MIN=$MIN_TIME
    export LAST_BENCHMARK_MAX=$MAX_TIME
  '';

  # Memory usage profiling
  profileMemoryUsage = { command, description ? null }: ''
    PROFILE_DESC="${if description != null then description else command}"
    echo "${testHelpers.colors.cyan}🧠 Memory Profile: $PROFILE_DESC${testHelpers.colors.reset}"
    
    # Get initial memory state
    INITIAL_MEM=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    echo "  ${testHelpers.colors.dim}Initial memory: ''${INITIAL_MEM}KB${testHelpers.colors.reset}"
    
    # Monitor memory during execution
    {
      while true; do
        CURRENT_MEM=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
        echo "$(date +%s) $CURRENT_MEM" >> "$TEST_ARTIFACTS_DIR/memory_profile.log"
        sleep 0.5
      done
    } &
    MONITOR_PID=$!
    
    # Execute command
    ${command}
    
    # Stop monitoring
    kill $MONITOR_PID 2>/dev/null || true
    wait $MONITOR_PID 2>/dev/null || true
    
    # Get final memory state
    FINAL_MEM=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    MEM_CHANGE=$((FINAL_MEM - INITIAL_MEM))
    
    # Analyze memory usage patterns
    if [ -f "$TEST_ARTIFACTS_DIR/memory_profile.log" ] && command -v awk >/dev/null 2>&1; then
      PEAK_MEM=$(awk '{if ($2 > max) max = $2} END {print max+0}' "$TEST_ARTIFACTS_DIR/memory_profile.log")
      AVG_MEM=$(awk '{sum += $2; count++} END {print int(sum/count)}' "$TEST_ARTIFACTS_DIR/memory_profile.log")
    else
      PEAK_MEM=$FINAL_MEM
      AVG_MEM=$FINAL_MEM
    fi
    
    echo "  ${testHelpers.colors.green}Memory Analysis:${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Final memory: ''${FINAL_MEM}KB${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Memory change: ''${MEM_CHANGE}KB${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Peak memory: ''${PEAK_MEM}KB${testHelpers.colors.reset}"
    echo "    ${testHelpers.colors.dim}Average memory: ''${AVG_MEM}KB${testHelpers.colors.reset}"
    
    # Save memory profile summary
    echo "memory_command: $PROFILE_DESC" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
    echo "memory_initial: $INITIAL_MEM" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
    echo "memory_final: $FINAL_MEM" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
    echo "memory_change: $MEM_CHANGE" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
    echo "memory_peak: $PEAK_MEM" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
    echo "memory_average: $AVG_MEM" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
    echo "---" >> "$TEST_ARTIFACTS_DIR/memory_profiles.log"
  '';

  # Performance regression detection
  checkPerformanceRegression = { 
    testName, 
    currentMetric, 
    baselineFile ? null,
    thresholdPercent ? 10
  }: ''
    echo "${testHelpers.colors.cyan}📉 Regression Check: ${testName}${testHelpers.colors.reset}"
    
    BASELINE_FILE="${if baselineFile != null then baselineFile else "$TEST_ARTIFACTS_DIR/baselines/${testName}.baseline"}"
    CURRENT_VALUE=${toString currentMetric}
    
    if [ -f "$BASELINE_FILE" ]; then
      BASELINE_VALUE=$(cat "$BASELINE_FILE")
      
      # Calculate percentage change
      if [ "$BASELINE_VALUE" -gt 0 ]; then
        CHANGE=$(( (CURRENT_VALUE - BASELINE_VALUE) * 100 / BASELINE_VALUE ))
        ABS_CHANGE=$(( CHANGE < 0 ? -CHANGE : CHANGE ))
        
        echo "  ${testHelpers.colors.dim}Baseline: ''${BASELINE_VALUE}${testHelpers.colors.reset}"
        echo "  ${testHelpers.colors.dim}Current: ''${CURRENT_VALUE}${testHelpers.colors.reset}"
        echo "  ${testHelpers.colors.dim}Change: ''${CHANGE}%${testHelpers.colors.reset}"
        
        if [ $ABS_CHANGE -gt ${toString thresholdPercent} ]; then
          if [ $CHANGE -gt 0 ]; then
            echo "  ${testHelpers.colors.red}⚠️  Performance regression detected: +''${CHANGE}% (threshold: ${toString thresholdPercent}%)${testHelpers.colors.reset}"
            echo "regression_detected: true" >> "$TEST_ARTIFACTS_DIR/regression_report.log"
            echo "regression_test: ${testName}" >> "$TEST_ARTIFACTS_DIR/regression_report.log"
            echo "regression_change: $CHANGE" >> "$TEST_ARTIFACTS_DIR/regression_report.log"
            echo "---" >> "$TEST_ARTIFACTS_DIR/regression_report.log"
            exit 1
          else
            echo "  ${testHelpers.colors.green}✓ Performance improvement: ''${CHANGE}%${testHelpers.colors.reset}"
          fi
        else
          echo "  ${testHelpers.colors.green}✓ Performance within acceptable range${testHelpers.colors.reset}"
        fi
      else
        echo "  ${testHelpers.colors.yellow}⚠️  Invalid baseline value: $BASELINE_VALUE${testHelpers.colors.reset}"
      fi
    else
      echo "  ${testHelpers.colors.yellow}📝 No baseline found, creating new baseline${testHelpers.colors.reset}"
      mkdir -p "$(dirname "$BASELINE_FILE")"
      echo "$CURRENT_VALUE" > "$BASELINE_FILE"
    fi
  '';

  # Performance report generation
  generatePerformanceReport = { testSuite ? "unknown" }: ''
    echo "${testHelpers.colors.magenta}📊 Generating Performance Report${testHelpers.colors.reset}"
    
    REPORT_FILE="$TEST_ARTIFACTS_DIR/performance_report_$(date +%Y%m%d_%H%M%S).html"
    
    cat > "$REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Performance Report - ${testSuite}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .metric { margin: 10px 0; padding: 10px; border-left: 3px solid #007acc; }
        .benchmark { background-color: #f9f9f9; padding: 15px; margin: 10px 0; }
        .good { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Performance Report</h1>
        <p>Test Suite: ${testSuite}</p>
        <p>Generated: $(date)</p>
        <p>Platform: ${testHelpers.platform.systemId}</p>
    </div>
EOF
    
    # Add benchmark results if available
    if [ -f "$TEST_ARTIFACTS_DIR/benchmarks.log" ]; then
      echo '<h2>Benchmark Results</h2>' >> "$REPORT_FILE"
      
      awk '
        /^benchmark_name:/ { name = substr($0, 17) }
        /^benchmark_avg:/ { avg = substr($0, 16) }
        /^benchmark_min:/ { min = substr($0, 16) }
        /^benchmark_max:/ { max = substr($0, 16) }
        /^---$/ { 
          print "<div class=\"benchmark\">"
          print "<h3>" name "</h3>"
          print "<p>Average: " avg "ms</p>"
          print "<p>Min: " min "ms</p>"
          print "<p>Max: " max "ms</p>"
          print "</div>"
        }
      ' "$TEST_ARTIFACTS_DIR/benchmarks.log" >> "$REPORT_FILE"
    fi
    
    # Add resource usage if available
    if [ -f "$TEST_ARTIFACTS_DIR/resource_summary.log" ]; then
      echo '<h2>Resource Usage</h2>' >> "$REPORT_FILE"
      
      awk '
        /^resource_command:/ { cmd = substr($0, 18) }
        /^resource_duration:/ { dur = substr($0, 19) }
        /^resource_mem_change:/ { mem = substr($0, 21) }
        /^resource_max_cpu:/ { cpu = substr($0, 17) }
        /^---$/ {
          print "<div class=\"metric\">"
          print "<h4>" cmd "</h4>"
          print "<p>Duration: " dur "s</p>"
          print "<p>Memory Change: " mem "KB</p>"
          print "<p>Max CPU: " cpu "%</p>"
          print "</div>"
        }
      ' "$TEST_ARTIFACTS_DIR/resource_summary.log" >> "$REPORT_FILE"
    fi
    
    echo '</body></html>' >> "$REPORT_FILE"
    
    echo "  ${testHelpers.colors.green}✓ Performance report generated: $REPORT_FILE${testHelpers.colors.reset}"
  '';

  # Load testing utilities
  loadTest = { 
    name,
    command, 
    concurrency ? 1, 
    duration ? 10,
    rampUp ? 0 
  }: ''
    echo "${testHelpers.colors.magenta}🔥 Load Test: ${name}${testHelpers.colors.reset}"
    echo "  ${testHelpers.colors.dim}Concurrency: ${toString concurrency}${testHelpers.colors.reset}"
    echo "  ${testHelpers.colors.dim}Duration: ${toString duration}s${testHelpers.colors.reset}"
    echo "  ${testHelpers.colors.dim}Ramp-up: ${toString rampUp}s${testHelpers.colors.reset}"
    
    LOAD_LOG="$TEST_ARTIFACTS_DIR/load_test_${name}_$(date +%s).log"
    PIDS=""
    
    # Start load test processes
    for i in $(seq 1 ${toString concurrency}); do
      {
        # Ramp-up delay
        if [ ${toString rampUp} -gt 0 ]; then
          DELAY=$(( ${toString rampUp} * (i - 1) / ${toString concurrency} ))
          sleep $DELAY
        fi
        
        # Run load for specified duration
        END_TIME=$(($(date +%s) + ${toString duration}))
        REQUESTS=0
        ERRORS=0
        
        while [ $(date +%s) -lt $END_TIME ]; do
          if ${command} >/dev/null 2>&1; then
            REQUESTS=$((REQUESTS + 1))
          else
            ERRORS=$((ERRORS + 1))
          fi
        done
        
        echo "worker_$i: $REQUESTS requests, $ERRORS errors" >> "$LOAD_LOG"
      } &
      PIDS="$PIDS $!"
    done
    
    # Wait for all workers to complete
    for pid in $PIDS; do
      wait $pid
    done
    
    # Analyze results
    if [ -f "$LOAD_LOG" ]; then
      TOTAL_REQUESTS=$(awk -F'[ :,]' '{sum += $2} END {print sum+0}' "$LOAD_LOG")
      TOTAL_ERRORS=$(awk -F'[ :,]' '{sum += $4} END {print sum+0}' "$LOAD_LOG")
      SUCCESS_RATE=$(( TOTAL_REQUESTS > 0 ? (TOTAL_REQUESTS - TOTAL_ERRORS) * 100 / TOTAL_REQUESTS : 0 ))
      THROUGHPUT=$(( TOTAL_REQUESTS / ${toString duration} ))
      
      echo "  ${testHelpers.colors.green}Load Test Results:${testHelpers.colors.reset}"
      echo "    ${testHelpers.colors.dim}Total Requests: $TOTAL_REQUESTS${testHelpers.colors.reset}"
      echo "    ${testHelpers.colors.dim}Total Errors: $TOTAL_ERRORS${testHelpers.colors.reset}"
      echo "    ${testHelpers.colors.dim}Success Rate: ''${SUCCESS_RATE}%${testHelpers.colors.reset}"
      echo "    ${testHelpers.colors.dim}Throughput: ''${THROUGHPUT} req/s${testHelpers.colors.reset}"
    fi
  '';

in
{
  inherit measureExecutionTime monitorResourceUsage performanceBenchmark;
  inherit profileMemoryUsage checkPerformanceRegression generatePerformanceReport;
  inherit loadTest;

  # Convenience functions
  quickBenchmark = name: command: performanceBenchmark { inherit name command; };
  
  measureCommand = command: measureExecutionTime { inherit command; };
  
  profileCommand = command: profileMemoryUsage { inherit command; };
  
  # Performance test creation helper
  createPerformanceTest = { name, setup ? "", teardown ? "", benchmarks }:
    testHelpers.createTestScript {
      inherit name;
      script = ''
        ${testHelpers.setupEnhancedTestEnv}
        
        echo "${testHelpers.colors.bold}${testHelpers.colors.magenta}🏁 Performance Test Suite: ${name}${testHelpers.colors.reset}"
        
        # Setup
        ${setup}
        
        # Run benchmarks
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (benchName: benchConfig:
          performanceBenchmark ({ name = benchName; } // benchConfig)
        ) benchmarks)}
        
        # Generate report
        ${generatePerformanceReport { testSuite = name; }}
        
        # Teardown
        ${teardown}
        
        echo "${testHelpers.colors.bold}${testHelpers.colors.green}✅ Performance test suite completed${testHelpers.colors.reset}"
      '';
    };

  # Performance regression test helper
  createRegressionTest = { name, metric, command, thresholdPercent ? 10 }:
    testHelpers.createTestScript {
      inherit name;
      script = ''
        ${testHelpers.setupEnhancedTestEnv}
        
        echo "${testHelpers.colors.cyan}🔍 Performance Regression Test: ${name}${testHelpers.colors.reset}"
        
        # Measure current performance
        ${measureExecutionTime { inherit command; description = name; }}
        CURRENT_METRIC=$LAST_PERF_DURATION_MS
        
        # Check for regression
        ${checkPerformanceRegression { 
          testName = name; 
          currentMetric = "$CURRENT_METRIC";
          inherit thresholdPercent;
        }}
      '';
    };
}