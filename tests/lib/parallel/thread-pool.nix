# Thread Pool Management for Parallel Test Execution
# Day 17: Green Phase - Advanced thread pool implementation

{ pkgs }:

{
  # Thread pool implementation
  threadPool = ''
    # Thread pool configuration
    THREAD_POOL_SIZE=''${THREAD_POOL_SIZE:-4}
    THREAD_POOL_TIMEOUT=''${THREAD_POOL_TIMEOUT:-30}

    # Thread pool state
    declare -a THREAD_POOL
    declare -a THREAD_STATES
    declare -A THREAD_JOBS
    declare -A THREAD_START_TIMES

    # Initialize thread pool
    init_thread_pool() {
      echo "🧵 Initializing thread pool (size: $THREAD_POOL_SIZE)"

      for ((i=0; i<THREAD_POOL_SIZE; i++)); do
        THREAD_POOL[$i]="thread_$i"
        THREAD_STATES[$i]="idle"
        THREAD_JOBS["thread_$i"]=""
        THREAD_START_TIMES["thread_$i"]=0
      done

      echo "✅ Thread pool initialized with $THREAD_POOL_SIZE threads"
    }

    # Get available thread
    get_available_thread() {
      for ((i=0; i<THREAD_POOL_SIZE; i++)); do
        if [[ "''${THREAD_STATES[$i]}" == "idle" ]]; then
          echo "thread_$i"
          return 0
        fi
      done

      # No idle thread available
      return 1
    }

    # Assign job to thread
    assign_job_to_thread() {
      local thread_id="$1"
      local job_id="$2"
      local job_command="$3"

      # Extract thread index
      local thread_index=''${thread_id#thread_}

      echo "🔄 Assigning job '$job_id' to $thread_id"

      # Update thread state
      THREAD_STATES[$thread_index]="busy"
      THREAD_JOBS["$thread_id"]="$job_id"
      THREAD_START_TIMES["$thread_id"]=$(date +%s)

      # Execute job in background
      (
        echo "Thread $thread_id executing job $job_id"
        eval "$job_command"
        local exit_code=$?

        # Update thread state when job completes
        THREAD_STATES[$thread_index]="idle"
        THREAD_JOBS["$thread_id"]=""
        THREAD_START_TIMES["$thread_id"]=0

        echo "Thread $thread_id completed job $job_id with exit code $exit_code"
        exit $exit_code
      ) &

      local job_pid=$!
      echo "✅ Job $job_id started on $thread_id (PID: $job_pid)"

      return 0
    }

    # Check thread status
    check_thread_status() {
      local current_time=$(date +%s)

      echo "🔍 Thread pool status:"
      for ((i=0; i<THREAD_POOL_SIZE; i++)); do
        local thread_id="thread_$i"
        local state="''${THREAD_STATES[$i]}"
        local job="''${THREAD_JOBS[$thread_id]}"
        local start_time="''${THREAD_START_TIMES[$thread_id]}"

        if [[ "$state" == "busy" && "$start_time" != "0" ]]; then
          local duration=$((current_time - start_time))
          echo "   $thread_id: $state (job: $job, duration: ''${duration}s)"

          # Check for timeout
          if [[ $duration -gt $THREAD_POOL_TIMEOUT ]]; then
            echo "⚠️  $thread_id job '$job' has exceeded timeout (''${duration}s > ''${THREAD_POOL_TIMEOUT}s)"
          fi
        else
          echo "   $thread_id: $state"
        fi
      done
    }

    # Wait for all threads to complete
    wait_for_thread_pool() {
      echo "⏳ Waiting for all threads to complete..."

      local max_wait_time=300  # 5 minutes max wait
      local wait_start=$(date +%s)

      while true; do
        local busy_threads=0

        for ((i=0; i<THREAD_POOL_SIZE; i++)); do
          if [[ "''${THREAD_STATES[$i]}" == "busy" ]]; then
            ((busy_threads++))
          fi
        done

        if [[ $busy_threads -eq 0 ]]; then
          echo "✅ All threads completed"
          break
        fi

        local current_time=$(date +%s)
        local wait_duration=$((current_time - wait_start))

        if [[ $wait_duration -gt $max_wait_time ]]; then
          echo "⚠️  Timeout waiting for threads to complete after ''${wait_duration}s"
          break
        fi

        echo "⏳ Waiting for $busy_threads threads to complete... (''${wait_duration}s elapsed)"
        sleep 1
      done
    }

    # Cleanup thread pool
    cleanup_thread_pool() {
      echo "🧹 Cleaning up thread pool..."

      # Force kill any remaining background jobs
      jobs -p | xargs -r kill 2>/dev/null || true

      # Reset thread pool state
      for ((i=0; i<THREAD_POOL_SIZE; i++)); do
        THREAD_STATES[$i]="idle"
        THREAD_JOBS["thread_$i"]=""
        THREAD_START_TIMES["thread_$i"]=0
      done

      echo "✅ Thread pool cleanup completed"
    }
  '';

  # Advanced thread pool features
  advancedThreadPool = ''
    # Load balancing for thread assignment
    get_least_loaded_thread() {
      local min_load=999999
      local best_thread=""

      for ((i=0; i<THREAD_POOL_SIZE; i++)); do
        local thread_id="thread_$i"
        local state="''${THREAD_STATES[$i]}"

        if [[ "$state" == "idle" ]]; then
          echo "$thread_id"
          return 0
        fi

        # If all threads are busy, find the one that started most recently
        if [[ "$state" == "busy" ]]; then
          local start_time="''${THREAD_START_TIMES[$thread_id]}"
          if [[ $start_time -lt $min_load ]]; then
            min_load=$start_time
            best_thread=$thread_id
          fi
        fi
      done

      if [[ -n "$best_thread" ]]; then
        echo "$best_thread"
        return 0
      else
        return 1
      fi
    }

    # Thread pool performance metrics
    get_thread_pool_metrics() {
      local total_threads=$THREAD_POOL_SIZE
      local busy_threads=0
      local idle_threads=0

      for ((i=0; i<THREAD_POOL_SIZE; i++)); do
        case "''${THREAD_STATES[$i]}" in
          "busy") ((busy_threads++)) ;;
          "idle") ((idle_threads++)) ;;
        esac
      done

      local utilization=0
      if [[ $total_threads -gt 0 ]]; then
        utilization=$((busy_threads * 100 / total_threads))
      fi

      echo "📊 Thread Pool Metrics:"
      echo "   Total threads: $total_threads"
      echo "   Busy threads: $busy_threads"
      echo "   Idle threads: $idle_threads"
      echo "   Utilization: ''${utilization}%"
    }

    # Adaptive thread pool sizing
    adapt_thread_pool_size() {
      local cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
      local current_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' | cut -d'.' -f1 || echo "0")

      # Adaptive sizing based on CPU cores and current load
      local optimal_size=$cpu_cores

      if [[ $current_load -gt $cpu_cores ]]; then
        # System is loaded, reduce thread pool size
        optimal_size=$((cpu_cores / 2))
        if [[ $optimal_size -lt 2 ]]; then
          optimal_size=2
        fi
      elif [[ $current_load -lt $((cpu_cores / 2)) ]]; then
        # System has capacity, can increase thread pool size
        optimal_size=$((cpu_cores * 2))
      fi

      if [[ $optimal_size -ne $THREAD_POOL_SIZE ]]; then
        echo "🔧 Adapting thread pool size from $THREAD_POOL_SIZE to $optimal_size"
        THREAD_POOL_SIZE=$optimal_size
        init_thread_pool
      fi
    }
  '';
}
