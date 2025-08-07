#!/bin/sh
# Performance Monitor Module for Build Scripts
# Provides performance degradation detection, monitoring, and alerting

# Global configuration for performance monitoring
PERF_MONITOR_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance"
PERF_LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/build-switch/performance-logs"
PERF_CONFIG_FILE="$PERF_MONITOR_DIR/monitor_config.json"

# Performance thresholds (in seconds)
PERF_THRESHOLD_BUILD_TIME=3600      # 1 hour
PERF_THRESHOLD_SWITCH_TIME=600      # 10 minutes
PERF_THRESHOLD_TOTAL_TIME=4200      # 70 minutes
PERF_THRESHOLD_MEMORY_MB=4096       # 4 GB
PERF_THRESHOLD_DISK_USAGE_MB=10240  # 10 GB

# Initialize performance monitoring system
init_performance_monitor() {
    log_debug "Initializing performance monitoring system"

    # Create monitoring directories
    mkdir -p "$PERF_MONITOR_DIR" "$PERF_LOG_DIR" || {
        log_error "Failed to create performance monitoring directories"
        return 1
    }

    # Initialize monitoring configuration
    if [ ! -f "$PERF_CONFIG_FILE" ]; then
        create_performance_config
    fi

    # Start system resource monitoring
    start_resource_monitoring

    log_debug "Performance monitoring system initialized: $PERF_MONITOR_DIR"
    return 0
}

# Create performance monitoring configuration
create_performance_config() {
    cat > "$PERF_CONFIG_FILE" << EOF
{
  "monitoring": {
    "initialized": "$(date -Iseconds)",
    "version": "1.0",
    "enabled": true
  },
  "thresholds": {
    "build_time_seconds": $PERF_THRESHOLD_BUILD_TIME,
    "switch_time_seconds": $PERF_THRESHOLD_SWITCH_TIME,
    "total_time_seconds": $PERF_THRESHOLD_TOTAL_TIME,
    "memory_usage_mb": $PERF_THRESHOLD_MEMORY_MB,
    "disk_usage_mb": $PERF_THRESHOLD_DISK_USAGE_MB
  },
  "alerting": {
    "enabled": true,
    "escalation_levels": ["warning", "critical", "emergency"]
  },
  "history": {
    "retention_days": 30,
    "max_entries": 1000
  }
}
EOF
}

# Start resource monitoring in background
start_resource_monitoring() {
    log_debug "Starting resource monitoring background process"

    # Create monitoring script
    local monitor_script="$PERF_MONITOR_DIR/resource_monitor.sh"
    cat > "$monitor_script" << 'EOF'
#!/bin/sh
# Background resource monitoring script

PERF_LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/build-switch/performance-logs"
MONITOR_PID_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance/monitor.pid"

# Function to get memory usage
get_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        # Linux
        free -m | awk 'NR==2{printf "%.0f", $3}'
    elif command -v vm_stat >/dev/null 2>&1; then
        # macOS
        vm_stat | awk '/Pages active/ {active=$3} /Pages inactive/ {inactive=$3} /Pages speculative/ {spec=$3} /Pages wired/ {wired=$4} END {print int((active+inactive+spec+wired)*4096/1024/1024)}'
    else
        echo "0"
    fi
}

# Function to get disk usage
get_disk_usage() {
    if command -v df >/dev/null 2>&1; then
        df -m . | awk 'NR==2{print $3}'
    else
        echo "0"
    fi
}

# Function to get CPU usage
get_cpu_usage() {
    if command -v top >/dev/null 2>&1; then
        # This is a simplified version - would need platform-specific implementation
        top -l 1 -s 0 | awk '/CPU usage/ {print $3}' | sed 's/%//' 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Monitor loop
while [ -f "$MONITOR_PID_FILE" ]; do
    timestamp=$(date -Iseconds)
    memory_mb=$(get_memory_usage)
    disk_mb=$(get_disk_usage)
    cpu_percent=$(get_cpu_usage)

    # Log resource usage
    echo "$timestamp,$memory_mb,$disk_mb,$cpu_percent" >> "$PERF_LOG_DIR/resource_usage.csv"

    sleep 30  # Monitor every 30 seconds
done
EOF

    chmod +x "$monitor_script"

    # Start monitoring in background
    "$monitor_script" &
    local monitor_pid=$!
    echo "$monitor_pid" > "$PERF_MONITOR_DIR/monitor.pid"

    log_debug "Resource monitoring started (PID: $monitor_pid)"
}

# Stop resource monitoring
stop_resource_monitoring() {
    log_debug "Stopping resource monitoring"

    if [ -f "$PERF_MONITOR_DIR/monitor.pid" ]; then
        local monitor_pid=$(cat "$PERF_MONITOR_DIR/monitor.pid")
        kill "$monitor_pid" 2>/dev/null || true
        rm -f "$PERF_MONITOR_DIR/monitor.pid"
        log_debug "Resource monitoring stopped (PID: $monitor_pid)"
    fi
}

# Detect performance degradation
detect_performance_degradation() {
    local operation="$1"
    local duration_seconds="$2"
    local memory_usage_mb="${3:-0}"

    log_debug "Detecting performance degradation for $operation (duration: ${duration_seconds}s, memory: ${memory_usage_mb}MB)"

    local degradation_detected=false
    local degradation_level="normal"
    local issues=""

    # Check duration thresholds
    case "$operation" in
        "build")
            if [ "$duration_seconds" -gt $PERF_THRESHOLD_BUILD_TIME ]; then
                degradation_detected=true
                degradation_level="critical"
                issues="$issues build_time_exceeded"
            elif [ "$duration_seconds" -gt $((PERF_THRESHOLD_BUILD_TIME * 3 / 4)) ]; then
                degradation_detected=true
                degradation_level="warning"
                issues="$issues build_time_high"
            fi
            ;;
        "switch")
            if [ "$duration_seconds" -gt $PERF_THRESHOLD_SWITCH_TIME ]; then
                degradation_detected=true
                degradation_level="critical"
                issues="$issues switch_time_exceeded"
            elif [ "$duration_seconds" -gt $((PERF_THRESHOLD_SWITCH_TIME * 3 / 4)) ]; then
                degradation_detected=true
                degradation_level="warning"
                issues="$issues switch_time_high"
            fi
            ;;
        "total")
            if [ "$duration_seconds" -gt $PERF_THRESHOLD_TOTAL_TIME ]; then
                degradation_detected=true
                degradation_level="critical"
                issues="$issues total_time_exceeded"
            elif [ "$duration_seconds" -gt $((PERF_THRESHOLD_TOTAL_TIME * 3 / 4)) ]; then
                degradation_detected=true
                degradation_level="warning"
                issues="$issues total_time_high"
            fi
            ;;
    esac

    # Check memory usage
    if [ "$memory_usage_mb" -gt $PERF_THRESHOLD_MEMORY_MB ]; then
        degradation_detected=true
        if [ "$degradation_level" = "normal" ]; then
            degradation_level="critical"
        fi
        issues="$issues memory_exceeded"
    elif [ "$memory_usage_mb" -gt $((PERF_THRESHOLD_MEMORY_MB * 3 / 4)) ]; then
        degradation_detected=true
        if [ "$degradation_level" = "normal" ]; then
            degradation_level="warning"
        fi
        issues="$issues memory_high"
    fi

    # Record degradation event
    if [ "$degradation_detected" = "true" ]; then
        record_performance_event "$operation" "$degradation_level" "$duration_seconds" "$memory_usage_mb" "$issues"

        case "$degradation_level" in
            "warning")
                log_warning "Performance degradation detected for $operation: $issues"
                ;;
            "critical")
                log_error "Critical performance degradation detected for $operation: $issues"
                trigger_performance_alert "$operation" "$degradation_level" "$issues"
                ;;
        esac

        return 0  # Degradation detected
    else
        log_debug "No performance degradation detected for $operation"
        return 1  # No degradation
    fi
}

# Record performance event
record_performance_event() {
    local operation="$1"
    local level="$2"
    local duration="$3"
    local memory="$4"
    local issues="$5"

    local event_file="$PERF_LOG_DIR/performance_events.log"
    local timestamp=$(date -Iseconds)

    {
        echo "=== Performance Event ==="
        echo "Timestamp: $timestamp"
        echo "Operation: $operation"
        echo "Level: $level"
        echo "Duration: ${duration}s"
        echo "Memory: ${memory}MB"
        echo "Issues: $issues"
        echo "Working Directory: $(pwd)"
        echo "System Type: ${SYSTEM_TYPE:-unknown}"
        echo "Platform Type: ${PLATFORM_TYPE:-unknown}"
        echo ""
    } >> "$event_file"
}

# Trigger performance alert
trigger_performance_alert() {
    local operation="$1"
    local level="$2"
    local issues="$3"

    log_warning "Triggering performance alert: $operation ($level)"

    # Create alert notification
    local alert_file="$PERF_LOG_DIR/alert_$(date +%s).json"
    cat > "$alert_file" << EOF
{
  "alert": {
    "timestamp": "$(date -Iseconds)",
    "operation": "$operation",
    "level": "$level",
    "issues": "$issues",
    "recommendations": []
  },
  "system_info": {
    "working_directory": "$(pwd)",
    "system_type": "${SYSTEM_TYPE:-unknown}",
    "platform_type": "${PLATFORM_TYPE:-unknown}",
    "user": "${USER:-unknown}"
  }
}
EOF

    # Generate recommendations based on issues
    generate_performance_recommendations "$issues" >> "$alert_file.recommendations"

    # Display alert
    display_performance_alert "$operation" "$level" "$issues"
}

# Generate performance recommendations
generate_performance_recommendations() {
    local issues="$1"

    echo "Performance Recommendations:"
    echo ""

    for issue in $issues; do
        case "$issue" in
            "build_time_exceeded"|"build_time_high")
                echo "• Build Performance:"
                echo "  - Consider increasing parallel jobs (--max-jobs)"
                echo "  - Check available CPU cores and adjust accordingly"
                echo "  - Review build cache configuration"
                echo "  - Verify network connectivity for binary caches"
                echo ""
                ;;
            "switch_time_exceeded"|"switch_time_high")
                echo "• Switch Performance:"
                echo "  - Check disk I/O performance"
                echo "  - Verify available disk space"
                echo "  - Consider reducing concurrent operations"
                echo "  - Review system load during switch"
                echo ""
                ;;
            "total_time_exceeded"|"total_time_high")
                echo "• Overall Performance:"
                echo "  - Review system resource allocation"
                echo "  - Check for background processes consuming resources"
                echo "  - Consider system reboot if performance persists"
                echo "  - Monitor system logs for errors"
                echo ""
                ;;
            "memory_exceeded"|"memory_high")
                echo "• Memory Usage:"
                echo "  - Close unnecessary applications"
                echo "  - Consider reducing parallel jobs"
                echo "  - Check for memory leaks in long-running processes"
                echo "  - Monitor swap usage"
                echo ""
                ;;
        esac
    done
}

# Display performance alert
display_performance_alert() {
    local operation="$1"
    local level="$2"
    local issues="$3"

    case "$level" in
        "warning")
            cat << EOF

⚠️  Performance Warning: $operation

Performance degradation detected with the following issues:
$(echo "$issues" | tr ' ' '\n' | sed 's/^/• /')

Recommendations:
EOF
            ;;
        "critical")
            cat << EOF

🚨 Critical Performance Alert: $operation

Severe performance degradation detected with the following issues:
$(echo "$issues" | tr ' ' '\n' | sed 's/^/• /')

Immediate action recommended:
EOF
            ;;
    esac

    generate_performance_recommendations "$issues"
    echo ""
}

# Get performance monitoring status
get_performance_monitor_status() {
    log_debug "Getting performance monitor status"

    echo "=== Performance Monitor Status ==="
    echo "Monitor Directory: $PERF_MONITOR_DIR"
    echo "Log Directory: $PERF_LOG_DIR"

    if [ -f "$PERF_CONFIG_FILE" ]; then
        echo "Configuration: Available"
        if command -v jq >/dev/null 2>&1; then
            local enabled=$(jq -r '.monitoring.enabled' "$PERF_CONFIG_FILE" 2>/dev/null)
            echo "Monitoring Enabled: $enabled"
        fi
    else
        echo "Configuration: Missing"
    fi

    if [ -f "$PERF_MONITOR_DIR/monitor.pid" ]; then
        local monitor_pid=$(cat "$PERF_MONITOR_DIR/monitor.pid")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            echo "Resource Monitor: Running (PID: $monitor_pid)"
        else
            echo "Resource Monitor: Stopped (stale PID file)"
            rm -f "$PERF_MONITOR_DIR/monitor.pid"
        fi
    else
        echo "Resource Monitor: Not running"
    fi

    # Show recent performance events
    if [ -f "$PERF_LOG_DIR/performance_events.log" ]; then
        local recent_events=$(tail -n 10 "$PERF_LOG_DIR/performance_events.log" | grep -c "=== Performance Event ===" 2>/dev/null || echo "0")
        echo "Recent Events: $recent_events"
    else
        echo "Recent Events: 0"
    fi

    return 0
}

# Analyze performance trends
analyze_performance_trends() {
    local days="${1:-7}"

    log_info "Analyzing performance trends over last $days days"

    local trend_file="$PERF_LOG_DIR/trend_analysis_$(date +%s).txt"

    {
        echo "=== Performance Trend Analysis ==="
        echo "Analysis Period: Last $days days"
        echo "Generated: $(date -Iseconds)"
        echo ""

        # Analyze recent performance events
        if [ -f "$PERF_LOG_DIR/performance_events.log" ]; then
            echo "Recent Performance Events:"

            # Get events from last N days (simplified)
            local cutoff_date=$(date -d "${days} days ago" +%Y-%m-%d 2>/dev/null || date -v-${days}d +%Y-%m-%d 2>/dev/null || echo "2000-01-01")

            local warning_count=$(grep -c "Level: warning" "$PERF_LOG_DIR/performance_events.log" 2>/dev/null || echo "0")
            local critical_count=$(grep -c "Level: critical" "$PERF_LOG_DIR/performance_events.log" 2>/dev/null || echo "0")

            echo "  Warning Events: $warning_count"
            echo "  Critical Events: $critical_count"
            echo ""

            # Show most common issues
            echo "Most Common Issues:"
            if [ -f "$PERF_LOG_DIR/performance_events.log" ]; then
                grep "Issues:" "$PERF_LOG_DIR/performance_events.log" | \
                cut -d':' -f2- | \
                tr ' ' '\n' | \
                sort | uniq -c | sort -nr | head -5 | \
                sed 's/^/  /'
            fi
        else
            echo "No performance events recorded"
        fi

        echo ""
        echo "Recommendations:"
        echo "• Monitor system resource usage regularly"
        echo "• Address recurring performance issues"
        echo "• Consider system optimization if critical events are frequent"
        echo "• Review build configuration for performance improvements"

    } > "$trend_file"

    # Display analysis
    cat "$trend_file"

    log_info "Performance trend analysis saved to: $trend_file"
    return 0
}

# Cleanup performance monitoring
cleanup_performance_monitor() {
    log_debug "Cleaning up performance monitoring"

    # Stop resource monitoring
    stop_resource_monitoring

    # Clean old log files (keep last 30 days)
    if [ -d "$PERF_LOG_DIR" ]; then
        find "$PERF_LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
        find "$PERF_LOG_DIR" -name "alert_*.json" -mtime +7 -delete 2>/dev/null || true
    fi

    log_debug "Performance monitoring cleanup completed"
    return 0
}
