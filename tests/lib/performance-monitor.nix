# Performance Monitor and Profiler
# Day 19: TDD Performance measurement and profiling system

{ pkgs }:

{
  # Advanced performance profiler
  performanceProfiler = ''
    # Profiler configuration
    PROFILER_ENABLED=''${PROFILER_ENABLED:-true}
    PROFILER_SAMPLING_INTERVAL=''${PROFILER_SAMPLING_INTERVAL:-100}  # 100ms
    PROFILER_MAX_SAMPLES=''${PROFILER_MAX_SAMPLES:-1000}

    # Profiler state
    declare -A PROFILER_METRICS
    declare -A PROFILER_TIMESTAMPS
    declare -A PROFILER_COUNTERS
    declare -a PROFILER_SAMPLES

    # Initialize profiler
    init_profiler() {
      if [[ "$PROFILER_ENABLED" != "true" ]]; then
        return 0
      fi

      echo "📊 Initializing performance profiler..."
      echo "   Sampling interval: ''${PROFILER_SAMPLING_INTERVAL}ms"
      echo "   Max samples: $PROFILER_MAX_SAMPLES"

      # Initialize metric counters
      PROFILER_COUNTERS["samples_taken"]=0
      PROFILER_COUNTERS["functions_profiled"]=0
      PROFILER_COUNTERS["memory_samples"]=0

      # Clear previous data
      PROFILER_SAMPLES=()

      echo "✅ Performance profiler initialized"
    }

    # Start profiling a function
    profile_start() {
      local function_name="$1"
      local context="''${2:-default}"

      if [[ "$PROFILER_ENABLED" != "true" ]]; then
        return 0
      fi

      local timestamp=$(date +%s%3N 2>/dev/null || date +%s)
      local memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

      PROFILER_TIMESTAMPS["''${function_name}_start"]="$timestamp"
      PROFILER_METRICS["''${function_name}_memory_start"]="$memory"
      PROFILER_METRICS["''${function_name}_context"]="$context"

      echo "🚀 Profiling started: $function_name"
    }

    # End profiling a function
    profile_end() {
      local function_name="$1"

      if [[ "$PROFILER_ENABLED" != "true" ]]; then
        return 0
      fi

      local end_timestamp=$(date +%s%3N 2>/dev/null || date +%s)
      local end_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

      local start_timestamp="''${PROFILER_TIMESTAMPS[''${function_name}_start]:-0}"
      local start_memory="''${PROFILER_METRICS[''${function_name}_memory_start]:-0}"
      local context="''${PROFILER_METRICS[''${function_name}_context]:-default}"

      if [[ "$start_timestamp" != "0" ]]; then
        local duration=$((end_timestamp - start_timestamp))
        local memory_delta=$((end_memory - start_memory))

        # Store profiling results
        PROFILER_METRICS["''${function_name}_duration"]="$duration"
        PROFILER_METRICS["''${function_name}_memory_delta"]="$memory_delta"
        PROFILER_METRICS["''${function_name}_end_timestamp"]="$end_timestamp"

        # Add to samples
        local sample="$function_name|$duration|$memory_delta|$context|$end_timestamp"
        PROFILER_SAMPLES+=("$sample")

        # Update counters
        PROFILER_COUNTERS["samples_taken"]=$((''${PROFILER_COUNTERS["samples_taken"]} + 1))
        PROFILER_COUNTERS["functions_profiled"]=$((''${PROFILER_COUNTERS["functions_profiled"]} + 1))

        echo "✅ Profiling completed: $function_name (''${duration}ms, ''${memory_delta}KB)"

        # Maintain sample limit
        if [[ ''${#PROFILER_SAMPLES[@]} -gt $PROFILER_MAX_SAMPLES ]]; then
          PROFILER_SAMPLES=("''${PROFILER_SAMPLES[@]:1}")
        fi
      else
        echo "⚠️  No profiling start found for: $function_name"
      fi
    }

    # Profile a command execution
    profile_command() {
      local command="$1"
      local label="''${2:-command}"

      profile_start "$label" "command_execution"

      # Execute the command and capture result
      local exit_code=0
      eval "$command" || exit_code=$?

      profile_end "$label"

      return $exit_code
    }

    # Generate profiling report
    generate_profile_report() {
      if [[ "$PROFILER_ENABLED" != "true" ]]; then
        echo "⚠️  Profiler is disabled"
        return 0
      fi

      echo ""
      echo "=== Performance Profile Report ==="
      echo "📊 Profiler Statistics:"
      echo "   Total samples: ''${PROFILER_COUNTERS["samples_taken"]}"
      echo "   Functions profiled: ''${PROFILER_COUNTERS["functions_profiled"]}"
      echo "   Sample buffer size: ''${#PROFILER_SAMPLES[@]}"

      if [[ ''${#PROFILER_SAMPLES[@]} -eq 0 ]]; then
        echo "   No profiling data available"
        return 0
      fi

      echo ""
      echo "📈 Top Performance Hotspots:"

      # Sort samples by duration (descending)
      local sorted_samples=()
      while IFS= read -r sample; do
        sorted_samples+=("$sample")
      done < <(printf '%s\n' "''${PROFILER_SAMPLES[@]}" | sort -t'|' -k2 -nr | head -10)

      for sample in "''${sorted_samples[@]}"; do
        IFS='|' read -r func duration memory_delta context timestamp <<< "$sample"
        echo "   $func: ''${duration}ms (''${memory_delta}KB) [$context]"
      done

      echo ""
      echo "💾 Memory Usage Analysis:"

      # Sort by memory delta
      local memory_samples=()
      while IFS= read -r sample; do
        memory_samples+=("$sample")
      done < <(printf '%s\n' "''${PROFILER_SAMPLES[@]}" | sort -t'|' -k3 -nr | head -5)

      for sample in "''${memory_samples[@]}"; do
        IFS='|' read -r func duration memory_delta context timestamp <<< "$sample"
        if [[ $memory_delta -gt 0 ]]; then
          echo "   $func: +''${memory_delta}KB (''${duration}ms)"
        fi
      done

      # Calculate averages
      local total_duration=0
      local total_memory=0
      local sample_count=''${#PROFILER_SAMPLES[@]}

      for sample in "''${PROFILER_SAMPLES[@]}"; do
        IFS='|' read -r func duration memory_delta context timestamp <<< "$sample"
        total_duration=$((total_duration + duration))
        total_memory=$((total_memory + memory_delta))
      done

      if [[ $sample_count -gt 0 ]]; then
        local avg_duration=$((total_duration / sample_count))
        local avg_memory=$((total_memory / sample_count))

        echo ""
        echo "📊 Performance Averages:"
        echo "   Average execution time: ''${avg_duration}ms"
        echo "   Average memory delta: ''${avg_memory}KB"
        echo "   Total execution time: ''${total_duration}ms"
        echo "   Total memory delta: ''${total_memory}KB"
      fi
    }
  '';

  # Performance benchmarking utilities
  benchmarkSuite = ''
    # Benchmark configuration
    BENCHMARK_ITERATIONS=''${BENCHMARK_ITERATIONS:-10}
    BENCHMARK_WARMUP_ITERATIONS=''${BENCHMARK_WARMUP_ITERATIONS:-3}

    # Benchmark state
    declare -a BENCHMARK_RESULTS
    declare -A BENCHMARK_STATS

    # Run benchmark
    run_benchmark() {
      local benchmark_name="$1"
      local benchmark_function="$2"
      local iterations="''${3:-$BENCHMARK_ITERATIONS}"

      echo "🏃 Running benchmark: $benchmark_name"
      echo "   Iterations: $iterations"
      echo "   Warmup iterations: $BENCHMARK_WARMUP_ITERATIONS"

      # Clear previous results
      BENCHMARK_RESULTS=()

      # Warmup runs
      echo "   Warming up..."
      for ((i=0; i<BENCHMARK_WARMUP_ITERATIONS; i++)); do
        eval "$benchmark_function" >/dev/null 2>&1 || true
      done

      # Actual benchmark runs
      echo "   Benchmarking..."
      for ((i=0; i<iterations; i++)); do
        local start_time=$(date +%s%3N 2>/dev/null || date +%s)
        local start_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

        # Run benchmark function
        local exit_code=0
        eval "$benchmark_function" >/dev/null 2>&1 || exit_code=$?

        local end_time=$(date +%s%3N 2>/dev/null || date +%s)
        local end_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

        local duration=$((end_time - start_time))
        local memory_delta=$((end_memory - start_memory))

        BENCHMARK_RESULTS+=("$duration|$memory_delta|$exit_code")

        echo "     Iteration $((i+1)): ''${duration}ms (''${memory_delta}KB)"
      done

      # Calculate statistics
      calculate_benchmark_stats "$benchmark_name"
    }

    # Calculate benchmark statistics
    calculate_benchmark_stats() {
      local benchmark_name="$1"

      if [[ ''${#BENCHMARK_RESULTS[@]} -eq 0 ]]; then
        echo "⚠️  No benchmark results to analyze"
        return 1
      fi

      local total_duration=0
      local total_memory=0
      local min_duration=999999999
      local max_duration=0
      local successful_runs=0

      # Calculate totals and find min/max
      for result in "''${BENCHMARK_RESULTS[@]}"; do
        IFS='|' read -r duration memory_delta exit_code <<< "$result"

        total_duration=$((total_duration + duration))
        total_memory=$((total_memory + memory_delta))

        if [[ $duration -lt $min_duration ]]; then
          min_duration=$duration
        fi

        if [[ $duration -gt $max_duration ]]; then
          max_duration=$duration
        fi

        if [[ $exit_code -eq 0 ]]; then
          ((successful_runs++))
        fi
      done

      local result_count=''${#BENCHMARK_RESULTS[@]}
      local avg_duration=$((total_duration / result_count))
      local avg_memory=$((total_memory / result_count))
      local success_rate=$((successful_runs * 100 / result_count))

      # Store statistics
      BENCHMARK_STATS["''${benchmark_name}_avg_duration"]="$avg_duration"
      BENCHMARK_STATS["''${benchmark_name}_avg_memory"]="$avg_memory"
      BENCHMARK_STATS["''${benchmark_name}_min_duration"]="$min_duration"
      BENCHMARK_STATS["''${benchmark_name}_max_duration"]="$max_duration"
      BENCHMARK_STATS["''${benchmark_name}_success_rate"]="$success_rate"
      BENCHMARK_STATS["''${benchmark_name}_iterations"]="$result_count"

      echo ""
      echo "📊 Benchmark Results: $benchmark_name"
      echo "   Iterations: $result_count"
      echo "   Success rate: ''${success_rate}%"
      echo "   Average time: ''${avg_duration}ms"
      echo "   Min time: ''${min_duration}ms"
      echo "   Max time: ''${max_duration}ms"
      echo "   Average memory delta: ''${avg_memory}KB"
      echo "   Total time: ''${total_duration}ms"
    }

    # Compare benchmarks
    compare_benchmarks() {
      local benchmark1="$1"
      local benchmark2="$2"

      local avg1="''${BENCHMARK_STATS[''${benchmark1}_avg_duration]:-0}"
      local avg2="''${BENCHMARK_STATS[''${benchmark2}_avg_duration]:-0}"

      if [[ $avg1 -eq 0 || $avg2 -eq 0 ]]; then
        echo "⚠️  Cannot compare: missing benchmark data"
        return 1
      fi

      echo ""
      echo "🔄 Benchmark Comparison: $benchmark1 vs $benchmark2"
      echo "   $benchmark1 average: ''${avg1}ms"
      echo "   $benchmark2 average: ''${avg2}ms"

      if [[ $avg1 -lt $avg2 ]]; then
        local improvement=$(( (avg2 - avg1) * 100 / avg2 ))
        echo "   Winner: $benchmark1 (''${improvement}% faster)"
      elif [[ $avg2 -lt $avg1 ]]; then
        local improvement=$(( (avg1 - avg2) * 100 / avg1 ))
        echo "   Winner: $benchmark2 (''${improvement}% faster)"
      else
        echo "   Result: Tie (equal performance)"
      fi
    }
  '';

  # System resource monitoring
  resourceMonitor = ''
    # Resource monitoring configuration
    MONITOR_INTERVAL=''${MONITOR_INTERVAL:-5}  # 5 seconds
    MONITOR_DURATION=''${MONITOR_DURATION:-60}  # 60 seconds

    # Resource monitoring state
    declare -a RESOURCE_SAMPLES
    declare -A RESOURCE_STATS

    # Monitor system resources
    monitor_resources() {
      local duration="''${1:-$MONITOR_DURATION}"
      local interval="''${2:-$MONITOR_INTERVAL}"

      echo "📡 Monitoring system resources..."
      echo "   Duration: ''${duration}s"
      echo "   Interval: ''${interval}s"

      # Clear previous samples
      RESOURCE_SAMPLES=()

      local start_time=$(date +%s)
      local sample_count=0

      while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [[ $elapsed -ge $duration ]]; then
          break
        fi

        # Collect resource data
        local memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
        local timestamp=$(date +%s)

        # Get load average if available
        local load_avg="N/A"
        if command -v uptime >/dev/null 2>&1; then
          load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' || echo "N/A")
        fi

        # Get CPU count if available
        local cpu_count="N/A"
        if command -v nproc >/dev/null 2>&1; then
          cpu_count=$(nproc)
        elif command -v sysctl >/dev/null 2>&1; then
          cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo "N/A")
        fi

        local sample="$timestamp|$memory|$load_avg|$cpu_count"
        RESOURCE_SAMPLES+=("$sample")

        ((sample_count++))
        echo "   Sample $sample_count: Memory=''${memory}KB, Load=''${load_avg}, CPUs=''${cpu_count}"

        sleep "$interval"
      done

      echo "✅ Resource monitoring completed (''${sample_count} samples)"
      analyze_resource_usage
    }

    # Analyze resource usage
    analyze_resource_usage() {
      if [[ ''${#RESOURCE_SAMPLES[@]} -eq 0 ]]; then
        echo "⚠️  No resource samples to analyze"
        return 1
      fi

      echo ""
      echo "📊 Resource Usage Analysis:"

      # Calculate memory statistics
      local total_memory=0
      local min_memory=999999999
      local max_memory=0
      local sample_count=''${#RESOURCE_SAMPLES[@]}

      for sample in "''${RESOURCE_SAMPLES[@]}"; do
        IFS='|' read -r timestamp memory load_avg cpu_count <<< "$sample"

        total_memory=$((total_memory + memory))

        if [[ $memory -lt $min_memory ]]; then
          min_memory=$memory
        fi

        if [[ $memory -gt $max_memory ]]; then
          max_memory=$memory
        fi
      done

      local avg_memory=$((total_memory / sample_count))
      local memory_range=$((max_memory - min_memory))

      echo "   Memory usage:"
      echo "     Average: ''${avg_memory}KB"
      echo "     Minimum: ''${min_memory}KB"
      echo "     Maximum: ''${max_memory}KB"
      echo "     Range: ''${memory_range}KB"

      # Store statistics
      RESOURCE_STATS["avg_memory"]="$avg_memory"
      RESOURCE_STATS["min_memory"]="$min_memory"
      RESOURCE_STATS["max_memory"]="$max_memory"
      RESOURCE_STATS["memory_range"]="$memory_range"
      RESOURCE_STATS["sample_count"]="$sample_count"
    }
  '';
}
