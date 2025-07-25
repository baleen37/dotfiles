#!/usr/bin/env bash

# Day 19: Performance Profiling and Measurement System
# Comprehensive performance analysis and profiling

set -euo pipefail

echo "=== Day 19: Performance Profiling and Measurement System ==="

# Configuration
PROFILER_ENABLED=true
BENCHMARK_ITERATIONS=5
START_TIME=$(date +%s)

# Create test temporary directory
TEST_TMP_DIR=$(mktemp -d -t "profiling-test-XXXXXX")
export TEST_TMP_DIR

# Cleanup function
cleanup() {
  if [[ -n "${TEST_TMP_DIR:-}" && -d "$TEST_TMP_DIR" ]]; then
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Source profiling utilities (embedded simplified version)
source <(cat << 'EOF'
# Embedded performance profiling utilities

# Profiler state
declare -A PROFILER_METRICS
declare -A PROFILER_TIMESTAMPS
declare -A PROFILER_COUNTERS
declare -a PROFILER_SAMPLES
declare -a BENCHMARK_RESULTS
declare -A BENCHMARK_STATS

# Initialize profiler
init_profiler() {
  echo "📊 Initializing performance profiler..."

  PROFILER_COUNTERS["samples_taken"]=0
  PROFILER_COUNTERS["functions_profiled"]=0
  PROFILER_SAMPLES=()

  echo "✅ Performance profiler initialized"
}

# Start profiling
profile_start() {
  local function_name="$1"
  local context="${2:-default}"

  local timestamp=$(date +%s%3N 2>/dev/null || date +%s)
  local memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

  PROFILER_TIMESTAMPS["${function_name}_start"]="$timestamp"
  PROFILER_METRICS["${function_name}_memory_start"]="$memory"
  PROFILER_METRICS["${function_name}_context"]="$context"

  echo "🚀 Profiling started: $function_name"
}

# End profiling
profile_end() {
  local function_name="$1"

  local end_timestamp=$(date +%s%3N 2>/dev/null || date +%s)
  local end_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

  local start_timestamp="${PROFILER_TIMESTAMPS[${function_name}_start]:-0}"
  local start_memory="${PROFILER_METRICS[${function_name}_memory_start]:-0}"
  local context="${PROFILER_METRICS[${function_name}_context]:-default}"

  if [[ "$start_timestamp" != "0" ]]; then
    local duration=$((end_timestamp - start_timestamp))
    local memory_delta=$((end_memory - start_memory))

    # Store results
    PROFILER_METRICS["${function_name}_duration"]="$duration"
    PROFILER_METRICS["${function_name}_memory_delta"]="$memory_delta"

    # Add to samples
    local sample="$function_name|$duration|$memory_delta|$context|$end_timestamp"
    PROFILER_SAMPLES+=("$sample")

    # Update counters
    PROFILER_COUNTERS["samples_taken"]=$((${PROFILER_COUNTERS["samples_taken"]} + 1))
    PROFILER_COUNTERS["functions_profiled"]=$((${PROFILER_COUNTERS["functions_profiled"]} + 1))

    echo "✅ Profiling completed: $function_name (${duration}ms, ${memory_delta}KB)"
  fi
}

# Run benchmark
run_benchmark() {
  local benchmark_name="$1"
  local benchmark_function="$2"
  local iterations="${3:-5}"

  echo "🏃 Running benchmark: $benchmark_name ($iterations iterations)"

  BENCHMARK_RESULTS=()

  # Warmup
  echo "   Warming up..."
  eval "$benchmark_function" >/dev/null 2>&1 || true

  # Benchmark runs
  for ((i=0; i<iterations; i++)); do
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    local start_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

    eval "$benchmark_function" >/dev/null 2>&1 || true

    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    local end_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

    local duration=$((end_time - start_time))
    local memory_delta=$((end_memory - start_memory))

    BENCHMARK_RESULTS+=("$duration|$memory_delta|0")
    echo "     Iteration $((i+1)): ${duration}ms (${memory_delta}KB)"
  done

  calculate_benchmark_stats "$benchmark_name"
}

# Calculate benchmark statistics
calculate_benchmark_stats() {
  local benchmark_name="$1"

  local total_duration=0
  local total_memory=0
  local min_duration=999999999
  local max_duration=0

  for result in "${BENCHMARK_RESULTS[@]}"; do
    IFS='|' read -r duration memory_delta exit_code <<< "$result"

    total_duration=$((total_duration + duration))
    total_memory=$((total_memory + memory_delta))

    if [[ $duration -lt $min_duration ]]; then
      min_duration=$duration
    fi

    if [[ $duration -gt $max_duration ]]; then
      max_duration=$duration
    fi
  done

  local result_count=${#BENCHMARK_RESULTS[@]}
  local avg_duration=$((total_duration / result_count))
  local avg_memory=$((total_memory / result_count))

  BENCHMARK_STATS["${benchmark_name}_avg_duration"]="$avg_duration"
  BENCHMARK_STATS["${benchmark_name}_min_duration"]="$min_duration"
  BENCHMARK_STATS["${benchmark_name}_max_duration"]="$max_duration"
  BENCHMARK_STATS["${benchmark_name}_avg_memory"]="$avg_memory"

  echo ""
  echo "📊 Benchmark Results: $benchmark_name"
  echo "   Average time: ${avg_duration}ms"
  echo "   Min time: ${min_duration}ms"
  echo "   Max time: ${max_duration}ms"
  echo "   Average memory delta: ${avg_memory}KB"
}

# Generate profiling report
generate_profile_report() {
  echo ""
  echo "=== Performance Profile Report ==="
  echo "📊 Profiler Statistics:"
  echo "   Total samples: ${PROFILER_COUNTERS["samples_taken"]}"
  echo "   Functions profiled: ${PROFILER_COUNTERS["functions_profiled"]}"

  if [[ ${#PROFILER_SAMPLES[@]} -eq 0 ]]; then
    echo "   No profiling data available"
    return 0
  fi

  echo ""
  echo "📈 Performance Hotspots:"

  # Sort samples by duration
  local sorted_samples=()
  while IFS= read -r sample; do
    sorted_samples+=("$sample")
  done < <(printf '%s\n' "${PROFILER_SAMPLES[@]}" | sort -t'|' -k2 -nr | head -5)

  for sample in "${sorted_samples[@]}"; do
    IFS='|' read -r func duration memory_delta context timestamp <<< "$sample"
    echo "   $func: ${duration}ms (${memory_delta}KB) [$context]"
  done
}

# Compare benchmarks
compare_benchmarks() {
  local benchmark1="$1"
  local benchmark2="$2"

  local avg1="${BENCHMARK_STATS[${benchmark1}_avg_duration]:-0}"
  local avg2="${BENCHMARK_STATS[${benchmark2}_avg_duration]:-0}"

  if [[ $avg1 -eq 0 || $avg2 -eq 0 ]]; then
    echo "⚠️  Cannot compare: missing benchmark data"
    return 1
  fi

  echo ""
  echo "🔄 Benchmark Comparison: $benchmark1 vs $benchmark2"
  echo "   $benchmark1 average: ${avg1}ms"
  echo "   $benchmark2 average: ${avg2}ms"

  if [[ $avg1 -lt $avg2 ]]; then
    local improvement=$(( (avg2 - avg1) * 100 / avg2 ))
    echo "   Winner: $benchmark1 (${improvement}% faster)"
  elif [[ $avg2 -lt $avg1 ]]; then
    local improvement=$(( (avg1 - avg2) * 100 / avg1 ))
    echo "   Winner: $benchmark2 (${improvement}% faster)"
  else
    echo "   Result: Tie (equal performance)"
  fi
}
EOF
)

echo "Performance profiling utilities loaded"

# Section 1: Profiler Initialization and Basic Testing
echo ""
echo "🔍 Section 1: Profiler initialization and basic testing..."

init_profiler

# Test basic profiling functionality
profile_start "test_function_1" "basic_test"
sleep 0.1
echo "Simulating test function execution..."
profile_end "test_function_1"

profile_start "test_function_2" "memory_test"
# Simulate memory usage
data=""
for ((i=0; i<100; i++)); do
  data="${data}test data $i "
done
echo "Test data created: ${#data} characters"
profile_end "test_function_2"

# Section 2: Benchmark Testing
echo ""
echo "🔍 Section 2: Benchmark performance testing..."

# Define test functions for benchmarking
cpu_intensive_task() {
  local result=0
  for ((i=0; i<1000; i++)); do
    result=$((result + i))
  done
  echo "CPU task result: $result" > /dev/null
}

io_intensive_task() {
  for ((i=0; i<10; i++)); do
    echo "I/O test data line $i" > "${TEST_TMP_DIR}/io_test_$i.txt"
    cat "${TEST_TMP_DIR}/io_test_$i.txt" > /dev/null
    rm -f "${TEST_TMP_DIR}/io_test_$i.txt"
  done
}

memory_intensive_task() {
  local data=""
  for ((i=0; i<500; i++)); do
    data="${data}Memory test data line $i with some additional content. "
  done
  echo "Memory task completed: ${#data} characters" > /dev/null
}

# Run benchmarks
run_benchmark "cpu_intensive" "cpu_intensive_task" $BENCHMARK_ITERATIONS
run_benchmark "io_intensive" "io_intensive_task" $BENCHMARK_ITERATIONS
run_benchmark "memory_intensive" "memory_intensive_task" $BENCHMARK_ITERATIONS

# Section 3: Performance Comparison Analysis
echo ""
echo "🔍 Section 3: Performance comparison analysis..."

# Compare different task types
compare_benchmarks "cpu_intensive" "io_intensive"
compare_benchmarks "cpu_intensive" "memory_intensive"
compare_benchmarks "io_intensive" "memory_intensive"

# Section 4: Advanced Profiling Scenarios
echo ""
echo "🔍 Section 4: Advanced profiling scenarios..."

# Profile a complex workflow
profile_start "complex_workflow" "integration_test"

echo "Step 1: Data preparation..."
profile_start "data_preparation" "workflow_step"
for ((i=0; i<50; i++)); do
  echo "Preparation data $i" > "${TEST_TMP_DIR}/prep_$i.txt"
done
profile_end "data_preparation"

echo "Step 2: Data processing..."
profile_start "data_processing" "workflow_step"
for file in "${TEST_TMP_DIR}"/prep_*.txt; do
  if [[ -f "$file" ]]; then
    wc -l "$file" > /dev/null
  fi
done
profile_end "data_processing"

echo "Step 3: Data cleanup..."
profile_start "data_cleanup" "workflow_step"
rm -f "${TEST_TMP_DIR}"/prep_*.txt
profile_end "data_cleanup"

profile_end "complex_workflow"

# Section 5: Performance Target Analysis
echo ""
echo "🔍 Section 5: Performance target analysis..."

# Calculate overall performance metrics
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

echo "📊 Overall Performance Analysis:"
echo "  Total test duration: ${TOTAL_DURATION}s"
echo "  Profiling samples collected: ${PROFILER_COUNTERS["samples_taken"]}"
echo "  Functions profiled: ${PROFILER_COUNTERS["functions_profiled"]}"

# Performance targets assessment
echo ""
echo "🎯 Performance Targets Assessment:"

# Target 1: Test execution time under 30 seconds
if [[ $TOTAL_DURATION -le 30 ]]; then
  echo "✅ Execution time target MET: ${TOTAL_DURATION}s ≤ 30s"
else
  echo "⚠️  Execution time target MISSED: ${TOTAL_DURATION}s > 30s"
fi

# Target 2: Profiling overhead should be minimal
PROFILING_SAMPLES=${PROFILER_COUNTERS["samples_taken"]}
if [[ $PROFILING_SAMPLES -ge 5 ]]; then
  echo "✅ Profiling coverage target MET: ${PROFILING_SAMPLES} samples collected"
else
  echo "⚠️  Profiling coverage target MISSED: ${PROFILING_SAMPLES} samples < 5"
fi

# Target 3: Benchmark consistency (check if we have stable results)
CPU_AVG=${BENCHMARK_STATS["cpu_intensive_avg_duration"]:-0}
CPU_MIN=${BENCHMARK_STATS["cpu_intensive_min_duration"]:-0}
CPU_MAX=${BENCHMARK_STATS["cpu_intensive_max_duration"]:-0}

if [[ $CPU_AVG -gt 0 && $CPU_MIN -gt 0 && $CPU_MAX -gt 0 ]]; then
  CPU_VARIANCE=$(( (CPU_MAX - CPU_MIN) * 100 / CPU_AVG ))

  if [[ $CPU_VARIANCE -le 50 ]]; then
    echo "✅ Benchmark consistency target MET: ${CPU_VARIANCE}% variance ≤ 50%"
  else
    echo "⚠️  Benchmark consistency target MISSED: ${CPU_VARIANCE}% variance > 50%"
  fi
else
  echo "⚠️  Cannot assess benchmark consistency: insufficient data"
fi

# Generate comprehensive report
generate_profile_report

# Section 6: Performance Recommendations
echo ""
echo "🔍 Section 6: Performance optimization recommendations..."

echo "💡 Performance Optimization Recommendations:"

# Check for performance hotspots
if [[ ${#PROFILER_SAMPLES[@]} -gt 0 ]]; then
  # Find the slowest operation
  local slowest_sample=""
  local slowest_duration=0

  for sample in "${PROFILER_SAMPLES[@]}"; do
    IFS='|' read -r func duration memory_delta context timestamp <<< "$sample"
    if [[ $duration -gt $slowest_duration ]]; then
      slowest_duration=$duration
      slowest_sample=$sample
    fi
  done

  if [[ -n "$slowest_sample" ]]; then
    IFS='|' read -r func duration memory_delta context timestamp <<< "$slowest_sample"
    echo "   🐌 Slowest operation: $func (${duration}ms)"
    echo "      Consider optimizing this function for better performance"
  fi

  # Check for memory-heavy operations
  local memory_heavy_sample=""
  local highest_memory=0

  for sample in "${PROFILER_SAMPLES[@]}"; do
    IFS='|' read -r func duration memory_delta context timestamp <<< "$sample"
    if [[ $memory_delta -gt $highest_memory ]]; then
      highest_memory=$memory_delta
      memory_heavy_sample=$sample
    fi
  done

  if [[ -n "$memory_heavy_sample" && $highest_memory -gt 100 ]]; then
    IFS='|' read -r func duration memory_delta context timestamp <<< "$memory_heavy_sample"
    echo "   🧠 Memory-heavy operation: $func (+${memory_delta}KB)"
    echo "      Consider implementing memory optimization techniques"
  fi
fi

# System-specific recommendations
CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
if [[ "$CPU_CORES" != "unknown" ]]; then
  echo "   🖥️  System has $CPU_CORES CPU cores"
  echo "      Consider parallel processing for CPU-intensive tasks"
fi

echo ""
echo "=== Day 19 Performance Profiling Complete ==="
echo "✅ Performance profiling system implemented"
echo "📊 Comprehensive benchmarking completed"
echo "🎯 Performance targets assessed"
echo "💡 Optimization recommendations provided"
echo "🚀 Ready for Day 20: Final integration and validation"
