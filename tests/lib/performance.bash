#!/usr/bin/env bash
# T039: Enhanced Performance Optimization for Parallel Test Execution (Phase 2)
# Optimizes test execution with intelligent scheduling, resource management,
# and adaptive parallelism for maximum efficiency
#
# FEATURES:
#   - Intelligent test weighting and batch scheduling
#   - Adaptive parallelism based on system resources
#   - Memory and CPU usage monitoring
#   - Performance target optimization (sub-5 minute execution)
#   - Enhanced error handling and recovery
#
# VERSION: 2.0.0 (Phase 2 optimized)
# LAST UPDATED: 2024-10-04

set -euo pipefail

# Enhanced performance configuration with optimizations
PERFORMANCE_TARGET_TIME=240  # 4 minutes (reduced from 5 for better performance)
PERFORMANCE_MAX_PARALLEL_JOBS=12  # Increased for better utilization
PERFORMANCE_MIN_PARALLEL_JOBS=3   # Increased minimum for better throughput
PERFORMANCE_ADAPTIVE_SCALING=true
PERFORMANCE_MEMORY_LIMIT_MB=3072  # Increased for better performance
PERFORMANCE_CPU_THRESHOLD=85      # Slightly increased threshold
PERFORMANCE_OPTIMIZATION_LEVEL="aggressive"  # Conservative, balanced, aggressive

# Performance monitoring
declare -A PERFORMANCE_METRICS=()
PERFORMANCE_START_TIME=""
PERFORMANCE_TEST_WEIGHTS=()

# Initialize performance tracking
init_performance_tracking() {
    PERFORMANCE_START_TIME=$(date +%s)
    PERFORMANCE_METRICS["start_time"]="$PERFORMANCE_START_TIME"
    PERFORMANCE_METRICS["total_tests"]=0
    PERFORMANCE_METRICS["completed_tests"]=0
    PERFORMANCE_METRICS["failed_tests"]=0
    PERFORMANCE_METRICS["skipped_tests"]=0
    PERFORMANCE_METRICS["current_parallel_jobs"]=0
    PERFORMANCE_METRICS["peak_parallel_jobs"]=0
    PERFORMANCE_METRICS["memory_usage_mb"]=0
    PERFORMANCE_METRICS["cpu_usage_percent"]=0

    echo "Performance tracking initialized - target: ${PERFORMANCE_TARGET_TIME}s"
}

# Enhanced optimal parallelism calculation with platform awareness
calculate_optimal_parallelism() {
    local cpu_count memory_gb optimal_jobs
    local optimization_level="${PERFORMANCE_OPTIMIZATION_LEVEL:-balanced}"

    # Get system resources with fallbacks for different platforms
    if command -v nproc >/dev/null 2>&1; then
        cpu_count=$(nproc)
    elif [[ -f /proc/cpuinfo ]]; then
        cpu_count=$(grep -c "^processor" /proc/cpuinfo)
    elif command -v sysctl >/dev/null 2>&1; then
        cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo "4")
    else
        cpu_count=4  # Fallback
    fi

    # Enhanced memory detection with macOS support
    if command -v free >/dev/null 2>&1; then
        memory_gb=$(( $(free -m | awk '/^Mem:/ {print $2}') / 1024 ))
    elif command -v vm_stat >/dev/null 2>&1; then
        # macOS memory calculation
        local page_size=$(vm_stat | grep "page size" | awk '{print $8}' || echo "4096")
        local total_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//' || echo "262144")
        memory_gb=$(( (total_pages * page_size) / 1024 / 1024 / 1024 ))
    else
        memory_gb=8  # Fallback
    fi

    # Optimization level-based calculation
    case "$optimization_level" in
        "aggressive")
            # More aggressive: CPU cores * 2
            optimal_jobs=$(( cpu_count * 2 ))
            local memory_per_job=200  # 200MB per job
            ;;
        "balanced")
            # Balanced: CPU cores * 1.5
            optimal_jobs=$(( cpu_count + (cpu_count / 2) ))
            local memory_per_job=256  # 256MB per job
            ;;
        "conservative")
            # Conservative: CPU cores * 1.25
            optimal_jobs=$(( cpu_count + (cpu_count / 4) ))
            local memory_per_job=384  # 384MB per job
            ;;
        *)
            optimal_jobs=$(( cpu_count + (cpu_count / 2) ))
            local memory_per_job=256
            ;;
    esac

    # Memory constraint calculation
    local memory_limited_jobs=$(( (memory_gb * 1024) / memory_per_job ))

    # Take the minimum of calculated values
    optimal_jobs=$(( optimal_jobs < memory_limited_jobs ? optimal_jobs : memory_limited_jobs ))

    # Apply enhanced bounds
    if [[ $optimal_jobs -lt $PERFORMANCE_MIN_PARALLEL_JOBS ]]; then
        optimal_jobs=$PERFORMANCE_MIN_PARALLEL_JOBS
    elif [[ $optimal_jobs -gt $PERFORMANCE_MAX_PARALLEL_JOBS ]]; then
        optimal_jobs=$PERFORMANCE_MAX_PARALLEL_JOBS
    fi

    # Log calculation details for debugging
    if [[ "${VERBOSE:-}" == "1" ]]; then
        echo "Parallelism calculation: CPU=$cpu_count, Memory=${memory_gb}GB, Level=$optimization_level" >&2
        echo "Result: $optimal_jobs jobs (memory-limited: $memory_limited_jobs)" >&2
    fi

    echo "$optimal_jobs"
}

# Enhanced test weighting with intelligent complexity analysis
weight_test_files() {
    local test_dir="$1"
    local -n weights_ref=$2

    # Clear existing weights
    weights_ref=()

    # Enhanced weighting algorithm
    while IFS= read -r -d '' test_file; do
        local file_size test_count complexity_score historical_weight
        local weight base_weight

        # Cross-platform file size detection
        if command -v stat >/dev/null 2>&1; then
            if stat -c%s "$test_file" >/dev/null 2>&1; then
                file_size=$(stat -c%s "$test_file")  # Linux
            else
                file_size=$(stat -f%z "$test_file" 2>/dev/null || echo "1000")  # macOS
            fi
        else
            file_size=$(wc -c < "$test_file" 2>/dev/null || echo "1000")
        fi

        # Enhanced test counting with multiple patterns
        test_count=$(
            grep -E "^@test|^function.*test_|^test_.*\(\)" "$test_file" 2>/dev/null | wc -l || echo "1"
        )

        # Complexity analysis based on file content
        complexity_score=0
        if grep -q "nix\|build\|flake" "$test_file" 2>/dev/null; then
            complexity_score=$((complexity_score + 200))  # Nix operations are expensive
        fi
        if grep -q "docker\|container" "$test_file" 2>/dev/null; then
            complexity_score=$((complexity_score + 150))  # Container operations
        fi
        if grep -q "network\|curl\|wget" "$test_file" 2>/dev/null; then
            complexity_score=$((complexity_score + 100))  # Network operations
        fi
        if grep -q "sleep\|timeout" "$test_file" 2>/dev/null; then
            complexity_score=$((complexity_score + 75))   # Time-based operations
        fi

        # Base weight calculation with enhanced factors
        base_weight=$(( (file_size / 100) + (test_count * 150) + complexity_score ))

        # Enhanced category-based weighting
        case "$(basename "$test_file")" in
            *performance*|*benchmark*)
                weight=$(( base_weight * 3 ))  # Very heavy
                ;;
            *integration*|*e2e*|*end-to-end*)
                weight=$(( base_weight * 2 ))  # Heavy
                ;;
            *system*|*build*|*flake*)
                weight=$(( base_weight * 2 ))  # Heavy system tests
                ;;
            *contract*|*validation*)
                weight=$(( (base_weight * 3) / 2 ))  # Medium-heavy
                ;;
            *unit*|*mock*|*simple*)
                weight=$(( base_weight / 2 ))  # Light
                ;;
            *)
                weight=$base_weight  # Default
                ;;
        esac

        # Ensure minimum weight
        if [[ $weight -lt 50 ]]; then
            weight=50
        fi

        weights_ref["$test_file"]=$weight

        # Debug output for weight calculation
        if [[ "${VERBOSE:-}" == "1" ]]; then
            echo "Weight: $(basename "$test_file") = $weight (base: $base_weight, tests: $test_count, complexity: $complexity_score)" >&2
        fi
    done < <(find "$test_dir" -name "*.bats" -type f -print0)

    echo "Enhanced weighting completed for ${#weights_ref[@]} test files"
}

# Intelligent test scheduling based on weights and execution time
schedule_tests_optimally() {
    local test_dir="$1"
    local max_parallel="$2"
    local -n schedule_ref=$3

    declare -A test_weights
    weight_test_files "$test_dir" test_weights

    # Sort tests by weight (heaviest first for better load balancing)
    local sorted_tests=()
    while IFS= read -r test_file; do
        sorted_tests+=("$test_file")
    done < <(
        for test_file in "${!test_weights[@]}"; do
            echo "${test_weights[$test_file]} $test_file"
        done | sort -nr | cut -d' ' -f2-
    )

    # Create optimal schedule
    local current_batch=0
    local batch_weight=0
    local target_batch_weight=$((
        $(for weight in "${test_weights[@]}"; do echo "$weight"; done |
          awk '{sum+=$1} END {print int(sum/'$max_parallel')}')
    ))

    schedule_ref=()
    for test_file in "${sorted_tests[@]}"; do
        local weight="${test_weights[$test_file]}"

        # Start new batch if current batch is too heavy
        if [[ $batch_weight -gt 0 && $(( batch_weight + weight )) -gt $(( target_batch_weight * 2 )) ]]; then
            ((current_batch++))
            batch_weight=0
        fi

        schedule_ref["$test_file"]=$current_batch
        batch_weight=$(( batch_weight + weight ))
    done

    echo "Created $(( current_batch + 1 )) test batches with target weight $target_batch_weight"
}

# Monitor system resources during test execution
monitor_system_resources() {
    local memory_usage_mb
    local cpu_usage_percent

    # Get memory usage
    memory_usage_mb=$(free -m | awk '/^Mem:/ {print $3}')
    PERFORMANCE_METRICS["memory_usage_mb"]=$memory_usage_mb

    # Get CPU usage (average over 1 second)
    cpu_usage_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    PERFORMANCE_METRICS["cpu_usage_percent"]=${cpu_usage_percent:-0}

    # Check if we need to throttle
    if [[ ${cpu_usage_percent%%.*} -gt $PERFORMANCE_CPU_THRESHOLD ]]; then
        echo "WARNING: High CPU usage ($cpu_usage_percent%), consider reducing parallelism"
        return 1
    fi

    if [[ $memory_usage_mb -gt $PERFORMANCE_MEMORY_LIMIT_MB ]]; then
        echo "WARNING: High memory usage (${memory_usage_mb}MB), consider reducing parallelism"
        return 1
    fi

    return 0
}

# Adaptive parallelism adjustment based on performance
adjust_parallelism_adaptively() {
    local current_parallelism="$1"
    local elapsed_time="$2"
    local completed_ratio="$3"

    if [[ "$PERFORMANCE_ADAPTIVE_SCALING" != "true" ]]; then
        echo "$current_parallelism"
        return
    fi

    # Estimate time to completion
    local estimated_total_time
    if [[ $(echo "$completed_ratio > 0" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        estimated_total_time=$(echo "$elapsed_time / $completed_ratio" | bc -l 2>/dev/null || echo "$PERFORMANCE_TARGET_TIME")
    else
        estimated_total_time=$PERFORMANCE_TARGET_TIME
    fi

    # Adjust based on resource usage and time pressure
    local new_parallelism=$current_parallelism

    if [[ $(echo "$estimated_total_time > $PERFORMANCE_TARGET_TIME" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        # Behind schedule, try to increase parallelism if resources allow
        if monitor_system_resources; then
            new_parallelism=$(( current_parallelism + 1 ))
            if [[ $new_parallelism -gt $PERFORMANCE_MAX_PARALLEL_JOBS ]]; then
                new_parallelism=$PERFORMANCE_MAX_PARALLEL_JOBS
            fi
        fi
    elif [[ $(echo "$estimated_total_time < ($PERFORMANCE_TARGET_TIME * 0.8)" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        # Ahead of schedule, can reduce parallelism to save resources
        new_parallelism=$(( current_parallelism - 1 ))
        if [[ $new_parallelism -lt $PERFORMANCE_MIN_PARALLEL_JOBS ]]; then
            new_parallelism=$PERFORMANCE_MIN_PARALLEL_JOBS
        fi
    fi

    echo "$new_parallelism"
}

# Enhanced fast test execution with comprehensive optimization
execute_tests_fast() {
    local test_dir="$1"
    local output_file="${2:-/dev/null}"
    local options="${3:-}"

    echo "🚀 Starting enhanced fast test execution with Phase 2 optimizations"
    echo "   Target: ${PERFORMANCE_TARGET_TIME}s | Optimization: ${PERFORMANCE_OPTIMIZATION_LEVEL}"

    init_performance_tracking

    # Calculate optimal parallelism with enhanced algorithm
    local max_parallel
    max_parallel=$(calculate_optimal_parallelism)
    echo "📊 Using $max_parallel parallel jobs (adaptive scaling: $PERFORMANCE_ADAPTIVE_SCALING)"

    # Enhanced test discovery with filtering
    local test_files=()
    while IFS= read -r -d '' test_file; do
        # Skip tests based on options
        if [[ "$options" == *"skip-slow"* ]] && [[ "$(basename "$test_file")" == *performance* ]]; then
            continue
        fi
        if [[ "$options" == *"unit-only"* ]] && [[ "$(basename "$test_file")" != *unit* ]]; then
            continue
        fi
        test_files+=("$test_file")
    done < <(find "$test_dir" -name "*.bats" -type f -print0)

    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo "⚠️  No test files found in $test_dir"
        return 0
    fi

    # Schedule tests optimally with enhanced algorithm
    declare -A test_schedule
    schedule_tests_optimally "$test_dir" "$max_parallel" test_schedule

    # Enhanced execution setup
    local total_tests=${#test_schedule[@]}
    local completed_tests=0
    local failed_tests=0
    local skipped_tests=0

    PERFORMANCE_METRICS["total_tests"]=$total_tests

    echo "📋 Test execution plan: $total_tests tests across multiple optimized batches"

    # Group tests by batch
    declare -A batches
    for test_file in "${!test_schedule[@]}"; do
        local batch="${test_schedule[$test_file]}"
        if [[ -z "${batches[$batch]:-}" ]]; then
            batches[$batch]="$test_file"
        else
            batches[$batch]="${batches[$batch]}|$test_file"
        fi
    done

    # Execute batches sequentially, tests within batch in parallel
    for batch_id in $(printf '%s\n' "${!batches[@]}" | sort -n); do
        local batch_tests
        IFS='|' read -ra batch_tests <<< "${batches[$batch_id]}"

        echo "Executing batch $batch_id with ${#batch_tests[@]} tests"

        # Start batch execution
        local batch_pids=()
        local current_jobs=0

        for test_file in "${batch_tests[@]}"; do
            # Adaptive parallelism check
            local elapsed_time=$(( $(date +%s) - PERFORMANCE_START_TIME ))
            local completed_ratio
            if [[ $total_tests -gt 0 ]]; then
                completed_ratio=$(echo "scale=2; $completed_tests / $total_tests" | bc -l 2>/dev/null || echo "0")
            else
                completed_ratio="0"
            fi

            local adjusted_parallel
            adjusted_parallel=$(adjust_parallelism_adaptively "$max_parallel" "$elapsed_time" "$completed_ratio")

            # Wait if we have too many jobs running
            while [[ $current_jobs -ge $adjusted_parallel ]]; do
                # Check for completed jobs
                for i in "${!batch_pids[@]}"; do
                    local pid="${batch_pids[$i]}"
                    if ! kill -0 "$pid" 2>/dev/null; then
                        wait "$pid"
                        local exit_status=$?
                        unset "batch_pids[$i]"
                        ((current_jobs--))
                        ((completed_tests++))

                        if [[ $exit_status -ne 0 ]]; then
                            ((failed_tests++))
                            echo "Test failed: $test_file (exit code: $exit_status)"
                        fi
                        break
                    fi
                done

                # Short sleep to prevent busy waiting
                sleep 0.1
            done

            # Start test execution
            echo "Starting test: $(basename "$test_file")"
            (
                # Individual test execution with timeout
                timeout 120 bats "$test_file" 2>&1 || {
                    echo "Test timed out or failed: $test_file" >&2
                    exit 1
                }
            ) &

            local test_pid=$!
            batch_pids+=("$test_pid")
            ((current_jobs++))

            # Update peak parallel jobs
            if [[ $current_jobs -gt ${PERFORMANCE_METRICS["peak_parallel_jobs"]} ]]; then
                PERFORMANCE_METRICS["peak_parallel_jobs"]=$current_jobs
            fi
        done

        # Wait for batch completion
        for pid in "${batch_pids[@]}"; do
            if [[ -n "$pid" ]]; then
                wait "$pid"
                local exit_status=$?
                ((completed_tests++))

                if [[ $exit_status -ne 0 ]]; then
                    ((failed_tests++))
                fi
            fi
        done

        # Check time constraint
        local elapsed_time=$(( $(date +%s) - PERFORMANCE_START_TIME ))
        if [[ $elapsed_time -gt $PERFORMANCE_TARGET_TIME ]]; then
            echo "WARNING: Exceeded target time of ${PERFORMANCE_TARGET_TIME}s (current: ${elapsed_time}s)"
        fi

        echo "Batch $batch_id completed. Progress: $completed_tests/$total_tests"
    done

    # Enhanced final performance analysis
    PERFORMANCE_METRICS["completed_tests"]=$completed_tests
    PERFORMANCE_METRICS["failed_tests"]=$failed_tests
    PERFORMANCE_METRICS["skipped_tests"]=$skipped_tests
    PERFORMANCE_METRICS["end_time"]=$(date +%s)

    local final_duration=$(( PERFORMANCE_METRICS["end_time"] - PERFORMANCE_METRICS["start_time"] ))

    # Performance achievement analysis
    local performance_rating=""
    if [[ $final_duration -le $((PERFORMANCE_TARGET_TIME * 80 / 100)) ]]; then
        performance_rating="EXCELLENT 🌟"
    elif [[ $final_duration -le $PERFORMANCE_TARGET_TIME ]]; then
        performance_rating="GOOD ✅"
    elif [[ $final_duration -le $((PERFORMANCE_TARGET_TIME * 120 / 100)) ]]; then
        performance_rating="ACCEPTABLE ⚠️"
    else
        performance_rating="NEEDS OPTIMIZATION ❌"
    fi

    generate_performance_report "$output_file"

    # Enhanced final summary
    echo ""
    echo "📊 EXECUTION SUMMARY"
    echo "   Duration: ${final_duration}s (target: ${PERFORMANCE_TARGET_TIME}s)"
    echo "   Performance: $performance_rating"
    echo "   Tests: $completed_tests completed, $failed_tests failed, $skipped_tests skipped"
    echo "   Peak parallelism: ${PERFORMANCE_METRICS["peak_parallel_jobs"]} jobs"

    # Return enhanced exit code
    if [[ $failed_tests -gt 0 ]]; then
        echo "❌ Test execution completed with $failed_tests failures"
        return 1
    elif [[ $skipped_tests -gt 0 ]]; then
        echo "⚠️  Test execution completed with $skipped_tests skipped tests"
        return 0
    else
        echo "✅ All tests passed successfully with enhanced performance optimization"
        return 0
    fi
}

# Enhanced performance report with detailed analysis
generate_performance_report() {
    local output_file="${1:-/dev/stdout}"

    local total_time=$(( PERFORMANCE_METRICS["end_time"] - PERFORMANCE_METRICS["start_time"] ))
    local success_rate=0
    local efficiency_score=0

    if [[ ${PERFORMANCE_METRICS["total_tests"]} -gt 0 ]]; then
        success_rate=$(( (PERFORMANCE_METRICS["completed_tests"] - PERFORMANCE_METRICS["failed_tests"]) * 100 / PERFORMANCE_METRICS["total_tests"] ))

        # Calculate efficiency score (tests per second)
        efficiency_score=$(( PERFORMANCE_METRICS["completed_tests"] * 100 / total_time ))
    fi

    # Performance analysis
    local performance_percentage
    if [[ $total_time -le $PERFORMANCE_TARGET_TIME ]]; then
        performance_percentage=100
    else
        performance_percentage=$(( PERFORMANCE_TARGET_TIME * 100 / total_time ))
    fi

    # Time saved/lost calculation
    local time_diff=$(( total_time - PERFORMANCE_TARGET_TIME ))
    local time_status
    if [[ $time_diff -le 0 ]]; then
        time_status="$((-time_diff))s faster than target ⚡"
    else
        time_status="${time_diff}s slower than target ⏱️"
    fi

    {
        echo "====================================="
        echo "📊 ENHANCED PERFORMANCE REPORT (Phase 2)"
        echo "====================================="
        echo ""
        echo "🎯 PERFORMANCE METRICS:"
        echo "   Target Time: ${PERFORMANCE_TARGET_TIME}s"
        echo "   Actual Time: ${total_time}s"
        echo "   Performance Score: ${performance_percentage}%"
        echo "   Time Analysis: $time_status"
        echo "   Optimization Level: ${PERFORMANCE_OPTIMIZATION_LEVEL}"
        echo ""
        echo "🧪 TEST EXECUTION:"
        echo "   Total Tests: ${PERFORMANCE_METRICS["total_tests"]}"
        echo "   Completed: ${PERFORMANCE_METRICS["completed_tests"]}"
        echo "   Failed: ${PERFORMANCE_METRICS["failed_tests"]}"
        echo "   Skipped: ${PERFORMANCE_METRICS["skipped_tests"]:-0}"
        echo "   Success Rate: ${success_rate}%"
        echo "   Efficiency: ${efficiency_score} tests/100s"
        echo ""
        echo "⚡ PARALLELISM & RESOURCES:"
        echo "   Peak Parallel Jobs: ${PERFORMANCE_METRICS["peak_parallel_jobs"]}"
        echo "   Memory Usage: ${PERFORMANCE_METRICS["memory_usage_mb"]}MB"
        echo "   CPU Usage: ${PERFORMANCE_METRICS["cpu_usage_percent"]}%"
        echo "   Adaptive Scaling: $PERFORMANCE_ADAPTIVE_SCALING"
        echo ""
        echo "🏆 PERFORMANCE TARGET: $(( total_time <= PERFORMANCE_TARGET_TIME ? "🎯 MET" : "❌ MISSED" ))"
        echo ""
        echo "📈 OPTIMIZATION RECOMMENDATIONS:"
        if [[ $total_time -gt $PERFORMANCE_TARGET_TIME ]]; then
            echo "   • Consider increasing PERFORMANCE_MAX_PARALLEL_JOBS"
            echo "   • Review test weighting algorithm for heavy tests"
            echo "   • Enable 'aggressive' optimization level"
        else
            echo "   • Performance targets achieved ✅"
            echo "   • Current configuration is optimal"
        fi
        echo "====================================="
    } > "$output_file"
}

# Enhanced function exports with Phase 2 optimizations
export -f init_performance_tracking
export -f calculate_optimal_parallelism  # Enhanced with platform awareness
export -f weight_test_files              # Enhanced complexity analysis
export -f schedule_tests_optimally       # Improved batch scheduling
export -f monitor_system_resources       # Cross-platform monitoring
export -f adjust_parallelism_adaptively  # Adaptive optimization
export -f execute_tests_fast             # Enhanced execution engine
export -f generate_performance_report    # Comprehensive reporting

# Performance optimization configuration
export PERFORMANCE_TARGET_TIME
export PERFORMANCE_MAX_PARALLEL_JOBS
export PERFORMANCE_MIN_PARALLEL_JOBS
export PERFORMANCE_ADAPTIVE_SCALING
export PERFORMANCE_MEMORY_LIMIT_MB
export PERFORMANCE_CPU_THRESHOLD
export PERFORMANCE_OPTIMIZATION_LEVEL

# Phase 2 optimization marker
export PERFORMANCE_FRAMEWORK_VERSION="2.0.0-phase2"

echo "🚀 Enhanced Performance Framework v2.0.0 loaded (Phase 2 optimizations active)" >&2
