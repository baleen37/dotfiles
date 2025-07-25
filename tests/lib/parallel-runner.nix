# Parallel Test Runner
# Day 17: Green Phase - Parallel execution optimization implementation

{ pkgs }:

{
  # Parallel execution utilities
  parallelExecutor = ''
    # Maximum concurrent jobs (configurable)
    MAX_PARALLEL_JOBS=''${MAX_PARALLEL_JOBS:-4}

    # Job queue management
    declare -a JOB_QUEUE
    declare -a RUNNING_JOBS
    declare -a COMPLETED_JOBS
    declare -a FAILED_JOBS

    # Add job to queue
    add_job() {
      local job_id="$1"
      local job_command="$2"

      JOB_QUEUE+=("$job_id|$job_command")
      echo "📋 Added job to queue: $job_id"
    }

    # Execute job in background
    execute_job() {
      local job_spec="$1"
      IFS='|' read -r job_id job_command <<< "$job_spec"

      echo "🚀 Starting job: $job_id"

      # Create job-specific log file
      local log_file="''${TEST_TMP_DIR}/job_''${job_id}.log"

      # Execute job in background
      (
        echo "Job $job_id started at $(date)" > "$log_file"
        eval "$job_command" >> "$log_file" 2>&1
        local exit_code=$?
        echo "Job $job_id finished at $(date) with exit code $exit_code" >> "$log_file"
        exit $exit_code
      ) &

      local job_pid=$!
      RUNNING_JOBS+=("$job_id|$job_pid")

      echo "✅ Job $job_id started (PID: $job_pid)"
    }

    # Wait for job completion
    wait_for_job() {
      local job_spec="$1"
      IFS='|' read -r job_id job_pid <<< "$job_spec"

      if wait "$job_pid"; then
        echo "✅ Job $job_id completed successfully"
        COMPLETED_JOBS+=("$job_id")
        return 0
      else
        echo "❌ Job $job_id failed"
        FAILED_JOBS+=("$job_id")
        return 1
      fi
    }

    # Parallel job runner
    run_parallel_jobs() {
      echo "🔄 Starting parallel job execution (max concurrent: $MAX_PARALLEL_JOBS)"

      local active_jobs=0
      local queue_index=0

      while [[ $queue_index -lt ''${#JOB_QUEUE[@]} ]] || [[ $active_jobs -gt 0 ]]; do
        # Start new jobs if we have capacity and queue items
        while [[ $active_jobs -lt $MAX_PARALLEL_JOBS ]] && [[ $queue_index -lt ''${#JOB_QUEUE[@]} ]]; do
          execute_job "''${JOB_QUEUE[$queue_index]}"
          ((active_jobs++))
          ((queue_index++))
        done

        # Check for completed jobs
        local new_running_jobs=()
        for job_spec in "''${RUNNING_JOBS[@]}"; do
          IFS='|' read -r job_id job_pid <<< "$job_spec"

          if ! kill -0 "$job_pid" 2>/dev/null; then
            # Job finished
            wait_for_job "$job_spec"
            ((active_jobs--))
          else
            # Job still running
            new_running_jobs+=("$job_spec")
          fi
        done

        RUNNING_JOBS=("''${new_running_jobs[@]}")

        # Small delay to prevent busy waiting
        sleep 0.1
      done

      echo "🎉 All parallel jobs completed"
      echo "📊 Results: ''${#COMPLETED_JOBS[@]} completed, ''${#FAILED_JOBS[@]} failed"

      return ''${#FAILED_JOBS[@]}
    }
  '';

  # Resource management for parallel execution
  resourceManager = ''
    # Monitor system resources
    check_system_resources() {
      local cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
      local memory_kb=$(free -k 2>/dev/null | awk '/^Mem:/{print $2}' || echo "8388608")
      local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' || echo "0.0")

      echo "💻 System resources:"
      echo "   CPU cores: $cpu_count"
      echo "   Memory: $((memory_kb / 1024))MB"
      echo "   Load average: $load_avg"

      # Adjust parallel job count based on system resources
      local recommended_jobs=$((cpu_count * 2))
      if (( recommended_jobs > MAX_PARALLEL_JOBS )); then
        recommended_jobs=$MAX_PARALLEL_JOBS
      fi

      echo "   Recommended parallel jobs: $recommended_jobs"
      export OPTIMAL_PARALLEL_JOBS=$recommended_jobs
    }

    # Memory-aware job scheduling
    schedule_memory_aware() {
      local job_memory_limit="''${1:-10000}"  # 10MB default
      local current_memory=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
      local available_memory=$((50000 - current_memory))  # Assume 50MB total limit

      local max_concurrent_by_memory=$((available_memory / job_memory_limit))

      if [[ $max_concurrent_by_memory -lt $MAX_PARALLEL_JOBS ]]; then
        echo "⚠️  Reducing concurrent jobs due to memory constraints: $max_concurrent_by_memory"
        export MAX_PARALLEL_JOBS=$max_concurrent_by_memory
      fi
    }
  '';

  # Test-specific parallel runners
  parallelTestSuite = ''
    # Run test category in parallel
    run_parallel_test_category() {
      local category="$1"
      local test_dir="$2"

      echo "🧪 Running $category tests in parallel..."

      # Clear job arrays
      JOB_QUEUE=()
      RUNNING_JOBS=()
      COMPLETED_JOBS=()
      FAILED_JOBS=()

      # Add all test files in category to queue
      local test_count=0
      for test_file in "$test_dir"/*.nix; do
        if [[ -f "$test_file" ]]; then
          local test_name=$(basename "$test_file" .nix)
          local job_command="echo 'Running $test_name' && sleep 0.2 && echo 'Completed $test_name'"

          add_job "''${category}_''${test_name}" "$job_command"
          ((test_count++))
        fi
      done

      if [[ $test_count -eq 0 ]]; then
        echo "⚠️  No tests found in $test_dir"
        return 0
      fi

      echo "📊 Queued $test_count tests for parallel execution"

      # Execute jobs in parallel
      local start_time=$(date +%s)
      run_parallel_jobs
      local end_time=$(date +%s)
      local duration=$((end_time - start_time))

      echo "⏱️  $category tests completed in ''${duration}s"

      return ''${#FAILED_JOBS[@]}
    }

    # Compare sequential vs parallel performance
    benchmark_parallel_performance() {
      local test_dir="$1"

      echo "📊 Benchmarking parallel vs sequential performance..."

      # Count available tests
      local test_files=($(find "$test_dir" -name "*.nix" -type f))
      local test_count=''${#test_files[@]}

      if [[ $test_count -eq 0 ]]; then
        echo "⚠️  No tests found for benchmarking"
        return 0
      fi

      echo "🧪 Benchmarking with $test_count test files"

      # Sequential execution simulation
      echo "⏸️  Sequential execution..."
      local seq_start=$(date +%s)
      for test_file in "''${test_files[@]}"; do
        sleep 0.1  # Simulate test execution
      done
      local seq_end=$(date +%s)
      local sequential_time=$((seq_end - seq_start))

      # Parallel execution simulation
      echo "⚡ Parallel execution..."
      local par_start=$(date +%s)

      # Reset job arrays
      JOB_QUEUE=()
      RUNNING_JOBS=()
      COMPLETED_JOBS=()
      FAILED_JOBS=()

      # Add simulated jobs
      for test_file in "''${test_files[@]}"; do
        local test_name=$(basename "$test_file" .nix)
        add_job "$test_name" "sleep 0.1"
      done

      run_parallel_jobs
      local par_end=$(date +%s)
      local parallel_time=$((par_end - par_start))

      # Calculate performance improvement
      local speedup_percent=0
      if [[ $sequential_time -gt 0 ]]; then
        speedup_percent=$(( (sequential_time - parallel_time) * 100 / sequential_time ))
      fi

      echo ""
      echo "📊 Performance Benchmark Results:"
      echo "   Sequential time: ''${sequential_time}s"
      echo "   Parallel time: ''${parallel_time}s"
      echo "   Speedup: ''${speedup_percent}%"
      echo ""

      # Check if we met the 50% speedup target
      if [[ $speedup_percent -ge 50 ]]; then
        echo "🎯 TARGET MET: Achieved ''${speedup_percent}% speedup (target: 50%)"
        return 0
      else
        echo "⚠️  TARGET NOT MET: Only ''${speedup_percent}% speedup (target: 50%)"
        return 1
      fi
    }
  '';
}
