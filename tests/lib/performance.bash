#!/usr/bin/env bash
# T039: Performance optimization for parallel execution (<5 minutes)
# Optimizes test execution to complete within 5 minutes while maintaining coverage

set -euo pipefail

# Performance configuration
PERFORMANCE_TARGET_TIME=300  # 5 minutes in seconds
PERFORMANCE_MAX_PARALLEL_JOBS=8
PERFORMANCE_MIN_PARALLEL_JOBS=2
PERFORMANCE_ADAPTIVE_SCALING=true
PERFORMANCE_MEMORY_LIMIT_MB=2048
PERFORMANCE_CPU_THRESHOLD=80

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

# Calculate optimal parallel job count based on system resources
calculate_optimal_parallelism() {
    local cpu_count
    local memory_gb
    local optimal_jobs
    
    # Get system resources
    cpu_count=$(nproc)
    memory_gb=$(( $(free -m | awk '/^Mem:/ {print $2}') / 1024 ))
    
    # Base calculation: CPU cores * 1.5, limited by memory
    optimal_jobs=$(( cpu_count + (cpu_count / 2) ))
    
    # Memory constraint: each job needs ~256MB
    local memory_limited_jobs=$(( (memory_gb * 1024) / 256 ))
    
    # Take the minimum of calculated values
    optimal_jobs=$(( optimal_jobs < memory_limited_jobs ? optimal_jobs : memory_limited_jobs ))
    
    # Apply bounds
    if [[ $optimal_jobs -lt $PERFORMANCE_MIN_PARALLEL_JOBS ]]; then
        optimal_jobs=$PERFORMANCE_MIN_PARALLEL_JOBS
    elif [[ $optimal_jobs -gt $PERFORMANCE_MAX_PARALLEL_JOBS ]]; then
        optimal_jobs=$PERFORMANCE_MAX_PARALLEL_JOBS
    fi
    
    echo "$optimal_jobs"
}

# Weight tests by execution time and complexity
weight_test_files() {
    local test_dir="$1"
    local -n weights_ref=$2
    
    # Clear existing weights
    weights_ref=()
    
    # Weight based on file size and test count
    while IFS= read -r -d '' test_file; do
        local file_size
        local test_count
        local weight
        
        file_size=$(stat -c%s "$test_file" 2>/dev/null || echo "1000")
        test_count=$(grep -c "^@test" "$test_file" 2>/dev/null || echo "1")
        
        # Base weight: size + (test_count * 100)
        weight=$(( (file_size / 100) + (test_count * 100) ))
        
        # Special weights for known slow tests
        case "$(basename "$test_file")" in
            *performance*|*integration*|*e2e*)
                weight=$(( weight * 2 ))
                ;;
            *unit*|*mock*)
                weight=$(( weight / 2 ))
                ;;
        esac
        
        weights_ref["$test_file"]=$weight
    done < <(find "$test_dir" -name "*.bats" -type f -print0)
    
    echo "Weighted ${#weights_ref[@]} test files"
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

# Fast test execution with performance optimization
execute_tests_fast() {
    local test_dir="$1"
    local output_file="${2:-/dev/null}"
    
    echo "Starting fast test execution with performance optimization"
    init_performance_tracking
    
    # Calculate optimal parallelism
    local max_parallel
    max_parallel=$(calculate_optimal_parallelism)
    echo "Using $max_parallel parallel jobs"
    
    # Schedule tests optimally
    declare -A test_schedule
    schedule_tests_optimally "$test_dir" "$max_parallel" test_schedule
    
    # Execute tests in batches
    local total_tests=${#test_schedule[@]}
    local completed_tests=0
    local failed_tests=0
    
    PERFORMANCE_METRICS["total_tests"]=$total_tests
    
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
    
    # Final performance report
    PERFORMANCE_METRICS["completed_tests"]=$completed_tests
    PERFORMANCE_METRICS["failed_tests"]=$failed_tests
    PERFORMANCE_METRICS["end_time"]=$(date +%s)
    
    generate_performance_report "$output_file"
    
    # Return appropriate exit code
    if [[ $failed_tests -gt 0 ]]; then
        echo "Test execution completed with $failed_tests failures"
        return 1
    else
        echo "All tests passed successfully"
        return 0
    fi
}

# Generate performance report
generate_performance_report() {
    local output_file="${1:-/dev/stdout}"
    
    local total_time=$(( PERFORMANCE_METRICS["end_time"] - PERFORMANCE_METRICS["start_time"] ))
    local success_rate=0
    
    if [[ ${PERFORMANCE_METRICS["total_tests"]} -gt 0 ]]; then
        success_rate=$(( (PERFORMANCE_METRICS["completed_tests"] - PERFORMANCE_METRICS["failed_tests"]) * 100 / PERFORMANCE_METRICS["total_tests"] ))
    fi
    
    {
        echo "=== Performance Report ==="
        echo "Target Time: ${PERFORMANCE_TARGET_TIME}s"
        echo "Actual Time: ${total_time}s"
        echo "Performance: $(( total_time <= PERFORMANCE_TARGET_TIME ? 100 : (PERFORMANCE_TARGET_TIME * 100 / total_time) ))%"
        echo ""
        echo "Test Execution:"
        echo "  Total Tests: ${PERFORMANCE_METRICS["total_tests"]}"
        echo "  Completed: ${PERFORMANCE_METRICS["completed_tests"]}"
        echo "  Failed: ${PERFORMANCE_METRICS["failed_tests"]}"
        echo "  Success Rate: ${success_rate}%"
        echo ""
        echo "Parallelism:"
        echo "  Peak Jobs: ${PERFORMANCE_METRICS["peak_parallel_jobs"]}"
        echo "  Memory Usage: ${PERFORMANCE_METRICS["memory_usage_mb"]}MB"
        echo "  CPU Usage: ${PERFORMANCE_METRICS["cpu_usage_percent"]}%"
        echo ""
        echo "Performance Target: $(( total_time <= PERFORMANCE_TARGET_TIME ? "MET" : "MISSED" ))"
    } > "$output_file"
}

# Export performance optimization functions
export -f init_performance_tracking
export -f calculate_optimal_parallelism
export -f weight_test_files
export -f schedule_tests_optimally
export -f monitor_system_resources
export -f adjust_parallelism_adaptively
export -f execute_tests_fast
export -f generate_performance_report