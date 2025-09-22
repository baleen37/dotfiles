#!/usr/bin/env bash
# T022: Parallel execution manager for test infrastructure
# Provides robust parallel test execution with job control and resource management

set -euo pipefail

# Source required models
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/models/test_utilities.bash"

# Parallel Execution Manager implementation
declare -A PARALLEL_MANAGER_INSTANCES=()
declare -A PARALLEL_JOBS=()
declare -A JOB_STATUS=()

# Parallel manager constructor
# Usage: parallel_manager_new <manager_id> <max_jobs>
parallel_manager_new() {
    local manager_id="$1"
    local max_jobs="${2:-4}"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }
    [[ "$max_jobs" =~ ^[0-9]+$ ]] || { echo "Error: max_jobs must be a number"; return 1; }
    [[ $max_jobs -gt 0 ]] || { echo "Error: max_jobs must be greater than 0"; return 1; }

    # Initialize manager instance
    PARALLEL_MANAGER_INSTANCES["${manager_id}:id"]="$manager_id"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:max_jobs"]="$max_jobs"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:current_jobs"]="0"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:completed_jobs"]="0"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:failed_jobs"]="0"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:timeout"]="300"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:fail_fast"]="false"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:cleanup_on_exit"]="true"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:job_pids"]=""
    PARALLEL_MANAGER_INSTANCES["${manager_id}:verbose"]="false"
    PARALLEL_MANAGER_INSTANCES["${manager_id}:memory_limit"]="0"  # 0 = no limit
    PARALLEL_MANAGER_INSTANCES["${manager_id}:cpu_limit"]="0"     # 0 = no limit

    # Set up signal handling for cleanup
    trap "_parallel_manager_cleanup_handler $manager_id" EXIT INT TERM

    echo "$manager_id"
}

# Get manager property
# Usage: parallel_manager_get <manager_id> <property>
parallel_manager_get() {
    local manager_id="$1"
    local property="$2"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }
    [[ -n "$property" ]] || { echo "Error: property is required"; return 1; }

    local key="${manager_id}:${property}"
    echo "${PARALLEL_MANAGER_INSTANCES[$key]:-}"
}

# Set manager property
# Usage: parallel_manager_set <manager_id> <property> <value>
parallel_manager_set() {
    local manager_id="$1"
    local property="$2"
    local value="$3"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }
    [[ -n "$property" ]] || { echo "Error: property is required"; return 1; }

    local key="${manager_id}:${property}"
    PARALLEL_MANAGER_INSTANCES["$key"]="$value"
}

# Execute command in parallel
# Usage: parallel_manager_exec <manager_id> <job_id> <command> [timeout]
parallel_manager_exec() {
    local manager_id="$1"
    local job_id="$2"
    local command="$3"
    local timeout="${4:-}"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }
    [[ -n "$job_id" ]] || { echo "Error: job_id is required"; return 1; }
    [[ -n "$command" ]] || { echo "Error: command is required"; return 1; }

    # Set timeout from manager if not provided
    if [[ -z "$timeout" ]]; then
        timeout=$(parallel_manager_get "$manager_id" "timeout")
    fi

    # Wait for available job slot
    _parallel_manager_wait_for_slot "$manager_id"

    # Check resource limits
    if ! _parallel_manager_check_resources "$manager_id"; then
        echo "Error: Resource limits exceeded, cannot start job $job_id" >&2
        return 1
    fi

    # Start job execution
    local job_pid
    job_pid=$(_parallel_manager_start_job "$manager_id" "$job_id" "$command" "$timeout")

    # Update manager state
    local current_jobs
    current_jobs=$(parallel_manager_get "$manager_id" "current_jobs")
    parallel_manager_set "$manager_id" "current_jobs" "$((current_jobs + 1))"

    # Add to job tracking
    local job_pids
    job_pids=$(parallel_manager_get "$manager_id" "job_pids")
    if [[ -n "$job_pids" ]]; then
        parallel_manager_set "$manager_id" "job_pids" "$job_pids $job_pid"
    else
        parallel_manager_set "$manager_id" "job_pids" "$job_pid"
    fi

    PARALLEL_JOBS["$job_pid"]="$manager_id:$job_id"
    JOB_STATUS["$job_pid"]="running"

    echo "$job_pid"
}

# Wait for a job slot to become available
# Usage: _parallel_manager_wait_for_slot <manager_id>
_parallel_manager_wait_for_slot() {
    local manager_id="$1"

    local max_jobs current_jobs
    max_jobs=$(parallel_manager_get "$manager_id" "max_jobs")

    while true; do
        current_jobs=$(parallel_manager_get "$manager_id" "current_jobs")

        if [[ $current_jobs -lt $max_jobs ]]; then
            break
        fi

        # Wait for a job to complete
        _parallel_manager_wait_for_any_job "$manager_id"

        # Check fail-fast condition
        local fail_fast
        fail_fast=$(parallel_manager_get "$manager_id" "fail_fast")
        if [[ "$fail_fast" == "true" ]]; then
            local failed_jobs
            failed_jobs=$(parallel_manager_get "$manager_id" "failed_jobs")
            if [[ $failed_jobs -gt 0 ]]; then
                echo "Fail-fast enabled, stopping due to job failures" >&2
                parallel_manager_kill_all "$manager_id"
                return 1
            fi
        fi
    done
}

# Check system resource limits
# Usage: _parallel_manager_check_resources <manager_id>
_parallel_manager_check_resources() {
    local manager_id="$1"

    local memory_limit cpu_limit
    memory_limit=$(parallel_manager_get "$manager_id" "memory_limit")
    cpu_limit=$(parallel_manager_get "$manager_id" "cpu_limit")

    # Check memory limit (if set)
    if [[ $memory_limit -gt 0 ]]; then
        local current_memory
        current_memory=$(ps -o pid,rss --no-headers -p $$ | awk '{print $2}')
        current_memory=$((current_memory / 1024))  # Convert to MB

        if [[ $current_memory -gt $memory_limit ]]; then
            echo "Memory limit exceeded: ${current_memory}MB > ${memory_limit}MB" >&2
            return 1
        fi
    fi

    # Check CPU load (if limit set)
    if [[ $cpu_limit -gt 0 ]]; then
        local cpu_load
        cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
        cpu_load=${cpu_load%.*}  # Remove decimal part for comparison

        if [[ ${cpu_load:-0} -gt $cpu_limit ]]; then
            echo "CPU load limit exceeded: $cpu_load > $cpu_limit" >&2
            return 1
        fi
    fi

    return 0
}

# Start a background job
# Usage: _parallel_manager_start_job <manager_id> <job_id> <command> <timeout>
_parallel_manager_start_job() {
    local manager_id="$1"
    local job_id="$2"
    local command="$3"
    local timeout="$4"

    local verbose
    verbose=$(parallel_manager_get "$manager_id" "verbose")

    # Create job script
    local job_script
    job_script=$(mktemp)

    cat > "$job_script" <<EOF
#!/usr/bin/env bash
set -euo pipefail

# Job execution wrapper
job_start_time=\$(date +%s%3N)
job_exit_code=0

# Execute command with timeout
if timeout "$timeout" bash -c '$command' > "/tmp/job_${job_id}.out" 2> "/tmp/job_${job_id}.err"; then
    job_exit_code=0
else
    job_exit_code=\$?
fi

job_end_time=\$(date +%s%3N)
job_duration=\$((job_end_time - job_start_time))

# Write job result
cat > "/tmp/job_${job_id}.result" <<RESULT
{
    "job_id": "$job_id",
    "exit_code": \$job_exit_code,
    "duration_ms": \$job_duration,
    "start_time": \$job_start_time,
    "end_time": \$job_end_time
}
RESULT

exit \$job_exit_code
EOF

    chmod +x "$job_script"

    # Start job in background
    if [[ "$verbose" == "true" ]]; then
        echo "Starting job $job_id: $command" >&2
    fi

    bash "$job_script" &
    local job_pid=$!

    # Clean up script file
    rm -f "$job_script"

    echo "$job_pid"
}

# Wait for any job to complete
# Usage: _parallel_manager_wait_for_any_job <manager_id>
_parallel_manager_wait_for_any_job() {
    local manager_id="$1"

    local job_pids
    job_pids=$(parallel_manager_get "$manager_id" "job_pids")
    [[ -n "$job_pids" ]] || return 0

    # Convert space-separated PIDs to array
    local pids=($job_pids)

    # Wait for any job to complete
    local completed_pid=""
    for pid in "${pids[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            completed_pid="$pid"
            break
        fi
    done

    # If no job completed yet, wait a bit and check again
    if [[ -z "$completed_pid" ]]; then
        sleep 0.1
        return 0
    fi

    # Process completed job
    _parallel_manager_process_completed_job "$manager_id" "$completed_pid"
}

# Process a completed job
# Usage: _parallel_manager_process_completed_job <manager_id> <pid>
_parallel_manager_process_completed_job() {
    local manager_id="$1"
    local pid="$2"

    # Get job info
    local job_info job_id exit_code
    job_info="${PARALLEL_JOBS[$pid]:-}"
    [[ -n "$job_info" ]] || return 0

    job_id="${job_info#*:}"

    # Get exit code
    wait "$pid" 2>/dev/null
    exit_code=$?

    # Update status
    if [[ $exit_code -eq 0 ]]; then
        JOB_STATUS["$pid"]="completed"
    else
        JOB_STATUS["$pid"]="failed"

        # Update failed jobs count
        local failed_jobs
        failed_jobs=$(parallel_manager_get "$manager_id" "failed_jobs")
        parallel_manager_set "$manager_id" "failed_jobs" "$((failed_jobs + 1))"
    fi

    # Update completed jobs count
    local completed_jobs
    completed_jobs=$(parallel_manager_get "$manager_id" "completed_jobs")
    parallel_manager_set "$manager_id" "completed_jobs" "$((completed_jobs + 1))"

    # Update current jobs count
    local current_jobs
    current_jobs=$(parallel_manager_get "$manager_id" "current_jobs")
    parallel_manager_set "$manager_id" "current_jobs" "$((current_jobs - 1))"

    # Remove from job tracking
    local job_pids
    job_pids=$(parallel_manager_get "$manager_id" "job_pids")
    job_pids=$(echo "$job_pids" | sed "s/\b$pid\b//g" | tr -s ' ')
    parallel_manager_set "$manager_id" "job_pids" "$job_pids"

    # Log completion
    local verbose
    verbose=$(parallel_manager_get "$manager_id" "verbose")
    if [[ "$verbose" == "true" ]]; then
        echo "Job $job_id (PID $pid) completed with exit code $exit_code" >&2
    fi

    # Clean up temporary files
    rm -f "/tmp/job_${job_id}.out" "/tmp/job_${job_id}.err" "/tmp/job_${job_id}.result"

    # Remove from tracking arrays
    unset PARALLEL_JOBS["$pid"]
    unset JOB_STATUS["$pid"]
}

# Wait for all jobs to complete
# Usage: parallel_manager_wait_all <manager_id>
parallel_manager_wait_all() {
    local manager_id="$1"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }

    local current_jobs
    while true; do
        current_jobs=$(parallel_manager_get "$manager_id" "current_jobs")
        [[ $current_jobs -gt 0 ]] || break

        _parallel_manager_wait_for_any_job "$manager_id"

        # Check fail-fast condition
        local fail_fast
        fail_fast=$(parallel_manager_get "$manager_id" "fail_fast")
        if [[ "$fail_fast" == "true" ]]; then
            local failed_jobs
            failed_jobs=$(parallel_manager_get "$manager_id" "failed_jobs")
            if [[ $failed_jobs -gt 0 ]]; then
                echo "Fail-fast enabled, terminating remaining jobs" >&2
                parallel_manager_kill_all "$manager_id"
                return 1
            fi
        fi
    done

    return 0
}

# Kill all running jobs
# Usage: parallel_manager_kill_all <manager_id>
parallel_manager_kill_all() {
    local manager_id="$1"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }

    local job_pids
    job_pids=$(parallel_manager_get "$manager_id" "job_pids")
    [[ -n "$job_pids" ]] || return 0

    # Convert to array and kill each job
    local pids=($job_pids)
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "Killing job PID $pid" >&2
            kill -TERM "$pid" 2>/dev/null || true

            # Give it a moment to terminate gracefully
            sleep 0.5

            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi

        # Clean up tracking
        unset PARALLEL_JOBS["$pid"] 2>/dev/null || true
        unset JOB_STATUS["$pid"] 2>/dev/null || true
    done

    # Reset job counts
    parallel_manager_set "$manager_id" "current_jobs" "0"
    parallel_manager_set "$manager_id" "job_pids" ""
}

# Get execution statistics
# Usage: parallel_manager_get_stats <manager_id>
parallel_manager_get_stats() {
    local manager_id="$1"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }

    local completed_jobs failed_jobs current_jobs max_jobs
    completed_jobs=$(parallel_manager_get "$manager_id" "completed_jobs")
    failed_jobs=$(parallel_manager_get "$manager_id" "failed_jobs")
    current_jobs=$(parallel_manager_get "$manager_id" "current_jobs")
    max_jobs=$(parallel_manager_get "$manager_id" "max_jobs")

    cat <<EOF
{
  "max_jobs": $max_jobs,
  "current_jobs": $current_jobs,
  "completed_jobs": $completed_jobs,
  "failed_jobs": $failed_jobs,
  "success_rate": $(( completed_jobs > 0 ? ((completed_jobs - failed_jobs) * 100) / completed_jobs : 0 ))
}
EOF
}

# Cleanup handler for signal handling
# Usage: _parallel_manager_cleanup_handler <manager_id>
_parallel_manager_cleanup_handler() {
    local manager_id="$1"

    local cleanup_on_exit
    cleanup_on_exit=$(parallel_manager_get "$manager_id" "cleanup_on_exit")

    if [[ "$cleanup_on_exit" == "true" ]]; then
        echo "Cleaning up parallel manager $manager_id..." >&2
        parallel_manager_kill_all "$manager_id"
    fi
}

# Clean up manager instance
# Usage: parallel_manager_destroy <manager_id>
parallel_manager_destroy() {
    local manager_id="$1"

    [[ -n "$manager_id" ]] || { echo "Error: manager_id is required"; return 1; }

    # Kill all running jobs
    parallel_manager_kill_all "$manager_id"

    # Remove all manager data
    for key in "${!PARALLEL_MANAGER_INSTANCES[@]}"; do
        if [[ "$key" == "${manager_id}:"* ]]; then
            unset PARALLEL_MANAGER_INSTANCES["$key"]
        fi
    done
}

# Export functions for use in other scripts
export -f parallel_manager_new
export -f parallel_manager_get
export -f parallel_manager_set
export -f parallel_manager_exec
export -f parallel_manager_wait_all
export -f parallel_manager_kill_all
export -f parallel_manager_get_stats
export -f parallel_manager_destroy
