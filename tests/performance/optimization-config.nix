# Performance Optimization Configuration for Testing Framework
# Intelligent caching, parallel execution, and resource management

{ lib
, stdenv
, writeShellScript
, writeText
, jq
, coreutils
,
}:

let
  # Performance configuration schema
  optimizationConfig = {
    # Parallel execution settings
    parallelExecution = {
      enabled = true;
      maxWorkers = 8; # Auto-detect based on CPU cores
      workerPoolSize = 4;
      taskScheduling = "dynamic"; # dynamic, static, priority
      loadBalancing = true;
    };

    # Caching strategies
    caching = {
      enabled = true;
      nixEvaluationCache = true;
      testResultCache = true;
      dependencyCache = true;
      cacheDirectory = ".test-cache";
      cacheTTL = 3600; # 1 hour in seconds
      maxCacheSize = "1G";
    };

    # Memory optimization
    memoryOptimization = {
      enabled = true;
      maxMemoryPerTest = "256M";
      memoryPooling = true;
      garbageCollection = "aggressive";
      swapOptimization = false;
    };

    # I/O optimization
    ioOptimization = {
      enabled = true;
      useRAMDisk = false; # For temporary files
      bufferSize = "64K";
      asyncIO = true;
      batchOperations = true;
    };

    # Test execution optimization
    testOptimization = {
      smartTestSelection = true;
      incrementalTesting = true;
      failFastMode = false;
      testPrioritization = "failure-rate"; # failure-rate, duration, dependency
      mockExpensiveOperations = true;
    };

    # Resource monitoring
    monitoring = {
      enabled = true;
      metricsCollection = true;
      performanceAlerting = true;
      resourceThresholds = {
        maxCPU = 80; # percentage
        maxMemory = 70; # percentage
        maxDiskIO = 80; # percentage
        maxDuration = 180; # seconds
      };
    };
  };

  # Generate configuration file
  configFile = writeText "optimization-config.json" (builtins.toJSON optimizationConfig);

  # Parallel execution optimizer
  parallelExecutor = writeShellScript "parallel-executor" ''
    set -euo pipefail

    # Load configuration
    CONFIG_FILE="''${1:-${configFile}}"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "❌ Configuration file not found: $CONFIG_FILE"
      exit 1
    fi

    # Extract configuration values
    MAX_WORKERS=$(${jq}/bin/jq -r '.parallelExecution.maxWorkers' "$CONFIG_FILE")
    POOL_SIZE=$(${jq}/bin/jq -r '.parallelExecution.workerPoolSize' "$CONFIG_FILE")
    SCHEDULING=$(${jq}/bin/jq -r '.parallelExecution.taskScheduling' "$CONFIG_FILE")
    LOAD_BALANCING=$(${jq}/bin/jq -r '.parallelExecution.loadBalancing' "$CONFIG_FILE")

    # Auto-detect optimal worker count
    detect_optimal_workers() {
      local cpu_cores=$(nproc 2>/dev/null || echo "4")
      local available_memory=$(free -m 2>/dev/null | awk '/^Mem:/ {print $7}' || echo "2048")

      # Calculate optimal workers based on CPU and memory
      local memory_based_workers=$((available_memory / 512))  # 512MB per worker
      local optimal_workers=$((cpu_cores > memory_based_workers ? memory_based_workers : cpu_cores))

      # Cap at configured maximum
      if [ $optimal_workers -gt $MAX_WORKERS ]; then
        optimal_workers=$MAX_WORKERS
      fi

      echo $optimal_workers
    }

    # Dynamic task scheduler
    schedule_tasks() {
      local tasks=("$@")
      local workers=$(detect_optimal_workers)

      echo "🚀 Parallel Execution Optimizer"
      echo "Workers: $workers"
      echo "Scheduling: $SCHEDULING"
      echo "Load Balancing: $LOAD_BALANCING"
      echo ""

      case "$SCHEDULING" in
        "dynamic")
          schedule_dynamic "''${tasks[@]}"
          ;;
        "static")
          schedule_static "''${tasks[@]}"
          ;;
        "priority")
          schedule_priority "''${tasks[@]}"
          ;;
        *)
          echo "❌ Unknown scheduling strategy: $SCHEDULING"
          exit 1
          ;;
      esac
    }

    # Dynamic scheduling implementation
    schedule_dynamic() {
      local tasks=("$@")
      local workers=$(detect_optimal_workers)
      local active_jobs=()
      local completed=0
      local failed=0

      echo "📊 Dynamic Task Scheduling (workers: $workers)"

      for task in "''${tasks[@]}"; do
        # Wait for available worker slot
        while [ ''${#active_jobs[@]} -ge $workers ]; do
          # Check for completed jobs
          local new_active_jobs=()
          for job_pid in "''${active_jobs[@]}"; do
            if kill -0 "$job_pid" 2>/dev/null; then
              new_active_jobs+=("$job_pid")
            else
              wait "$job_pid"
              if [ $? -eq 0 ]; then
                ((completed++))
              else
                ((failed++))
              fi
            fi
          done
          active_jobs=("''${new_active_jobs[@]}")

          # Brief sleep to avoid busy waiting
          sleep 0.1
        done

        # Start new task
        echo "🏃 Starting: $task"
        eval "$task" &
        active_jobs+=($!)
      done

      # Wait for all remaining jobs
      for job_pid in "''${active_jobs[@]}"; do
        wait "$job_pid"
        if [ $? -eq 0 ]; then
          ((completed++))
        else
          ((failed++))
        fi
      done

      echo ""
      echo "✅ Dynamic scheduling complete:"
      echo "  Completed: $completed"
      echo "  Failed: $failed"
      echo "  Total: $((completed + failed))"
    }

    # Static scheduling implementation
    schedule_static() {
      local tasks=("$@")
      local workers=$(detect_optimal_workers)
      local total_tasks=''${#tasks[@]}
      local tasks_per_worker=$(( (total_tasks + workers - 1) / workers ))

      echo "📊 Static Task Scheduling"
      echo "  Total tasks: $total_tasks"
      echo "  Workers: $workers"
      echo "  Tasks per worker: $tasks_per_worker"

      local worker_pids=()

      for ((worker=0; worker<workers; worker++)); do
        local start_idx=$((worker * tasks_per_worker))
        local end_idx=$(( start_idx + tasks_per_worker - 1 ))

        if [ $start_idx -lt $total_tasks ]; then
          if [ $end_idx -ge $total_tasks ]; then
            end_idx=$((total_tasks - 1))
          fi

          # Create worker script
          {
            for ((task_idx=start_idx; task_idx<=end_idx; task_idx++)); do
              if [ $task_idx -lt $total_tasks ]; then
                echo "🏃 Worker $worker executing: ''${tasks[$task_idx]}"
                eval "''${tasks[$task_idx]}"
              fi
            done
          } &

          worker_pids+=($!)
        fi
      done

      # Wait for all workers
      local completed=0
      local failed=0

      for pid in "''${worker_pids[@]}"; do
        wait "$pid"
        if [ $? -eq 0 ]; then
          ((completed++))
        else
          ((failed++))
        fi
      done

      echo ""
      echo "✅ Static scheduling complete:"
      echo "  Worker batches completed: $completed"
      echo "  Worker batches failed: $failed"
    }

    # Priority-based scheduling
    schedule_priority() {
      local tasks=("$@")

      echo "📊 Priority-Based Task Scheduling"
      echo "⚠️  Priority scheduling requires task metadata"
      echo "Falling back to dynamic scheduling..."

      schedule_dynamic "''${tasks[@]}"
    }

    # Load balancing monitor
    monitor_load_balance() {
      if [ "$LOAD_BALANCING" = "true" ]; then
        while true; do
          local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | tr -d ' ')
          local cpu_count=$(nproc 2>/dev/null || echo "4")

          # Simple load balancing: if load > CPU count, wait
          if (( $(echo "$load_avg > $cpu_count" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚖️  High load detected ($load_avg), throttling..."
            sleep 2
          else
            break
          fi
        done
      fi
    }

    # Example usage
    if [ $# -eq 0 ]; then
      echo "Usage: $0 [config_file] task1 task2 task3 ..."
      echo "Example: $0 optimization-config.json 'echo test1' 'echo test2' 'echo test3'"
      exit 1
    fi

    # Skip config file if it's a task
    if [ "$1" != "$CONFIG_FILE" ] && [[ "$1" != *.json ]]; then
      schedule_tasks "$@"
    else
      shift  # Remove config file from arguments
      schedule_tasks "$@"
    fi
  '';

  # Intelligent caching system
  cachingSystem = writeShellScript "caching-system" ''
        set -euo pipefail

        # Load configuration
        CONFIG_FILE="''${1:-${configFile}}"
        CACHE_DIR=$(${jq}/bin/jq -r '.caching.cacheDirectory' "$CONFIG_FILE" 2>/dev/null || echo ".test-cache")
        CACHE_TTL=$(${jq}/bin/jq -r '.caching.cacheTTL' "$CONFIG_FILE" 2>/dev/null || echo "3600")
        MAX_CACHE_SIZE=$(${jq}/bin/jq -r '.caching.maxCacheSize' "$CONFIG_FILE" 2>/dev/null || echo "1G")

        echo "🗄️  Intelligent Caching System"
        echo "=============================="
        echo "Cache directory: $CACHE_DIR"
        echo "Cache TTL: $CACHE_TTL seconds"
        echo "Max cache size: $MAX_CACHE_SIZE"

        # Initialize cache directory
        mkdir -p "$CACHE_DIR"/{nix-eval,test-results,dependencies,metadata}

        # Cache key generation
        generate_cache_key() {
          local input="$1"
          echo -n "$input" | sha256sum | cut -d' ' -f1
        }

        # Nix evaluation caching
        cache_nix_evaluation() {
          local nix_expr="$1"
          local cache_key=$(generate_cache_key "$nix_expr")
          local cache_file="$CACHE_DIR/nix-eval/$cache_key"

          if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file"))) -lt $CACHE_TTL ]; then
            echo "🎯 Cache HIT for Nix evaluation"
            cat "$cache_file"
            return 0
          else
            echo "💾 Cache MISS for Nix evaluation"
            local result=$(eval "$nix_expr" 2>&1)
            echo "$result" > "$cache_file"
            echo "$result"
            return 0
          fi
        }

        # Test result caching
        cache_test_result() {
          local test_command="$1"
          local cache_key=$(generate_cache_key "$test_command")
          local cache_file="$CACHE_DIR/test-results/$cache_key"
          local metadata_file="$CACHE_DIR/metadata/$cache_key.json"

          if [ -f "$cache_file" ] && [ -f "$metadata_file" ]; then
            local cached_time=$(${jq}/bin/jq -r '.timestamp' "$metadata_file" 2>/dev/null || echo "0")
            local current_time=$(date +%s)

            if [ $((current_time - cached_time)) -lt $CACHE_TTL ]; then
              echo "🎯 Cache HIT for test result"
              ${jq}/bin/jq -r '.result' "$metadata_file"
              return $(${jq}/bin/jq -r '.exit_code' "$metadata_file")
            fi
          fi

          echo "💾 Cache MISS for test result"
          local start_time=$(date +%s.%N)
          local result=$(eval "$test_command" 2>&1)
          local exit_code=$?
          local end_time=$(date +%s.%N)
          local duration=$(echo "$end_time - $start_time" | bc -l)

          # Store result and metadata
          echo "$result" > "$cache_file"
          cat > "$metadata_file" << EOF
    {
      "command": $(echo "$test_command" | ${jq}/bin/jq -R .),
      "result": $(echo "$result" | ${jq}/bin/jq -Rs .),
      "exit_code": $exit_code,
      "duration": $duration,
      "timestamp": $(date +%s)
    }
    EOF

          echo "$result"
          return $exit_code
        }

        # Cache cleanup and management
        manage_cache() {
          echo ""
          echo "🧹 Cache Management"

          # Calculate current cache size
          local current_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
          echo "Current cache size: $current_size"

          # Convert max size to bytes for comparison
          local max_bytes
          case "$MAX_CACHE_SIZE" in
            *G) max_bytes=$(echo "''${MAX_CACHE_SIZE%G} * 1024 * 1024 * 1024" | bc) ;;
            *M) max_bytes=$(echo "''${MAX_CACHE_SIZE%M} * 1024 * 1024" | bc) ;;
            *K) max_bytes=$(echo "''${MAX_CACHE_SIZE%K} * 1024" | bc) ;;
            *) max_bytes=$MAX_CACHE_SIZE ;;
          esac

          local current_bytes=$(du -sb "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")

          if [ $current_bytes -gt $max_bytes ]; then
            echo "🗑️  Cache size exceeded, cleaning up..."

            # Remove oldest files first
            find "$CACHE_DIR" -type f -printf '%T@ %p\n' | sort -n | head -n 50 | cut -d' ' -f2- | xargs rm -f

            local new_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
            echo "Cache cleaned up. New size: $new_size"
          fi

          # Remove expired entries
          find "$CACHE_DIR" -type f -mtime +$(($CACHE_TTL / 86400)) -delete 2>/dev/null || true

          # Cache statistics
          local total_files=$(find "$CACHE_DIR" -type f | wc -l)
          local nix_cache_files=$(find "$CACHE_DIR/nix-eval" -type f | wc -l)
          local test_cache_files=$(find "$CACHE_DIR/test-results" -type f | wc -l)

          echo ""
          echo "📊 Cache Statistics:"
          echo "  Total cached files: $total_files"
          echo "  Nix evaluations: $nix_cache_files"
          echo "  Test results: $test_cache_files"
        }

        # Main caching operations
        case "''${2:-status}" in
          "nix-eval")
            cache_nix_evaluation "$3"
            ;;
          "test-result")
            cache_test_result "$3"
            ;;
          "cleanup")
            manage_cache
            ;;
          "status"|*)
            manage_cache
            ;;
        esac
  '';

  # Performance monitoring system
  performanceMonitor = writeShellScript "performance-monitor" ''
    set -euo pipefail

    # Load configuration
    CONFIG_FILE="''${1:-${configFile}}"

    # Extract monitoring settings
    ENABLED=$(${jq}/bin/jq -r '.monitoring.enabled' "$CONFIG_FILE" 2>/dev/null || echo "true")
    MAX_CPU=$(${jq}/bin/jq -r '.monitoring.resourceThresholds.maxCPU' "$CONFIG_FILE" 2>/dev/null || echo "80")
    MAX_MEMORY=$(${jq}/bin/jq -r '.monitoring.resourceThresholds.maxMemory' "$CONFIG_FILE" 2>/dev/null || echo "70")
    MAX_DURATION=$(${jq}/bin/jq -r '.monitoring.resourceThresholds.maxDuration' "$CONFIG_FILE" 2>/dev/null || echo "180")

    if [ "$ENABLED" != "true" ]; then
      echo "📊 Performance monitoring disabled"
      exit 0
    fi

    echo "📊 Performance Monitoring System"
    echo "==============================="
    echo "CPU threshold: $MAX_CPU%"
    echo "Memory threshold: $MAX_MEMORY%"
    echo "Duration threshold: $MAX_DURATION seconds"

    # Resource monitoring function
    monitor_resources() {
      local test_pid="$1"
      local test_name="$2"
      local start_time=$(date +%s)

      while kill -0 "$test_pid" 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        # Check duration threshold
        if [ $elapsed -gt $MAX_DURATION ]; then
          echo "⚠️  ALERT: Test duration exceeded ($elapsed > $MAX_DURATION seconds)"
          echo "🔴 Terminating long-running test: $test_name"
          kill "$test_pid" 2>/dev/null || true
          return 1
        fi

        # Check CPU usage
        if command -v top >/dev/null 2>&1; then
          local cpu_usage=$(top -bn1 -p "$test_pid" 2>/dev/null | tail -1 | awk '{print $9}' | cut -d'%' -f1 || echo "0")
          if [ -n "$cpu_usage" ] && [ "$cpu_usage" -gt "$MAX_CPU" ]; then
            echo "⚠️  ALERT: High CPU usage detected: $cpu_usage% (threshold: $MAX_CPU%)"
          fi
        fi

        # Check memory usage
        if command -v ps >/dev/null 2>&1; then
          local mem_kb=$(ps -o rss= -p "$test_pid" 2>/dev/null || echo "0")
          local total_mem_kb=$(free | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "8388608")  # Default 8GB
          local mem_percent=$(echo "scale=1; $mem_kb * 100 / $total_mem_kb" | bc -l 2>/dev/null || echo "0")

          if (( $(echo "$mem_percent > $MAX_MEMORY" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚠️  ALERT: High memory usage detected: $mem_percent% (threshold: $MAX_MEMORY%)"
          fi
        fi

        sleep 1
      done
    }

    # Main monitoring function
    if [ $# -ge 3 ]; then
      monitor_resources "$2" "$3"
    else
      echo "Usage: $0 <config_file> <test_pid> <test_name>"
      echo "Example: $0 config.json 1234 'unit-test'"
    fi
  '';

in
{
  # Export all optimization components
  inherit
    optimizationConfig
    configFile
    parallelExecutor
    cachingSystem
    performanceMonitor
    ;

  # Main optimization controller
  optimizationController = writeShellScript "optimization-controller" ''
    set -euo pipefail

    echo "⚡ Performance Optimization Controller"
    echo "===================================="

    CONFIG_FILE="''${1:-${configFile}}"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "❌ Configuration file not found: $CONFIG_FILE"
      exit 1
    fi

    echo "📋 Loading optimization configuration..."
    echo "Config file: $CONFIG_FILE"
    echo ""

    # Initialize caching system
    echo "🗄️  Initializing caching system..."
    ${cachingSystem} "$CONFIG_FILE" status
    echo ""

    # Display current configuration
    echo "⚙️  Current Optimization Settings:"
    ${jq}/bin/jq -r '
      "  Parallel Execution: " + (.parallelExecution.enabled | tostring) +
      " (workers: " + (.parallelExecution.maxWorkers | tostring) + ")" +
      "\n  Caching: " + (.caching.enabled | tostring) +
      " (TTL: " + (.caching.cacheTTL | tostring) + "s)" +
      "\n  Memory Optimization: " + (.memoryOptimization.enabled | tostring) +
      "\n  I/O Optimization: " + (.ioOptimization.enabled | tostring) +
      "\n  Performance Monitoring: " + (.monitoring.enabled | tostring)
    ' "$CONFIG_FILE"

    echo ""
    echo "✅ Optimization system ready!"
    echo ""
    echo "Available commands:"
    echo "  - Use parallel-executor for optimized task execution"
    echo "  - Use caching-system for intelligent result caching"
    echo "  - Use performance-monitor for resource monitoring"
  '';
}
