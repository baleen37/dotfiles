#!/bin/sh
# Audit Logger Module for Build Scripts
# Provides comprehensive audit logging and tracking for security and compliance

# Global configuration for audit logging
AUDIT_LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/build-switch/audit-logs"
AUDIT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/audit"
AUDIT_CONFIG_FILE="$AUDIT_STATE_DIR/audit_config.json"
AUDIT_SESSION_FILE="$AUDIT_STATE_DIR/current_session.json"

# Audit logging levels
AUDIT_LEVEL_INFO="INFO"
AUDIT_LEVEL_WARNING="WARNING"
AUDIT_LEVEL_ERROR="ERROR"
AUDIT_LEVEL_SECURITY="SECURITY"
AUDIT_LEVEL_COMPLIANCE="COMPLIANCE"

# Initialize audit logging system
init_audit_logger() {
    log_debug "Initializing audit logging system"

    # Create audit directories
    mkdir -p "$AUDIT_LOG_DIR" "$AUDIT_STATE_DIR" || {
        log_error "Failed to create audit directories"
        return 1
    }

    # Set secure permissions on audit directories
    chmod 750 "$AUDIT_LOG_DIR" "$AUDIT_STATE_DIR" 2>/dev/null || true

    # Initialize audit configuration
    if [ ! -f "$AUDIT_CONFIG_FILE" ]; then
        create_audit_config
    fi

    # Start audit session
    start_audit_session

    log_debug "Audit logging system initialized: $AUDIT_LOG_DIR"
    return 0
}

# Create audit logging configuration
create_audit_config() {
    cat > "$AUDIT_CONFIG_FILE" << EOF
{
  "audit": {
    "initialized": "$(date -Iseconds)",
    "version": "1.0",
    "enabled": true,
    "session_tracking": true,
    "security_logging": true
  },
  "logging": {
    "levels": ["INFO", "WARNING", "ERROR", "SECURITY", "COMPLIANCE"],
    "retention_days": 90,
    "max_file_size_mb": 100,
    "compression_enabled": true
  },
  "security": {
    "track_privilege_escalation": true,
    "track_file_modifications": true,
    "track_network_operations": true,
    "track_system_changes": true
  },
  "compliance": {
    "include_timestamps": true,
    "include_user_context": true,
    "include_system_context": true,
    "digital_signatures": false
  }
}
EOF
}

# Start audit session
start_audit_session() {
    local session_id="session_$(date +%s)_$$"

    log_debug "Starting audit session: $session_id"

    cat > "$AUDIT_SESSION_FILE" << EOF
{
  "session": {
    "id": "$session_id",
    "start_time": "$(date -Iseconds)",
    "user": "${USER:-unknown}",
    "uid": "$(id -u 2>/dev/null || echo unknown)",
    "gid": "$(id -g 2>/dev/null || echo unknown)",
    "working_directory": "$(pwd)",
    "command_line": "$0 $*",
    "environment": {
      "system_type": "${SYSTEM_TYPE:-unknown}",
      "platform_type": "${PLATFORM_TYPE:-unknown}",
      "shell": "${SHELL:-unknown}",
      "term": "${TERM:-unknown}"
    }
  },
  "activity": {
    "operations": [],
    "security_events": [],
    "file_modifications": [],
    "network_operations": [],
    "privilege_escalations": []
  }
}
EOF

    # Create session-specific log file
    local session_log="$AUDIT_LOG_DIR/${session_id}.log"
    {
        echo "=== AUDIT SESSION START ==="
        echo "Session ID: $session_id"
        echo "Timestamp: $(date -Iseconds)"
        echo "User: ${USER:-unknown} (UID: $(id -u 2>/dev/null || echo unknown))"
        echo "Working Directory: $(pwd)"
        echo "Command: $0 $*"
        echo "System: ${SYSTEM_TYPE:-unknown} on ${PLATFORM_TYPE:-unknown}"
        echo "=========================="
        echo ""
    } > "$session_log"

    export AUDIT_SESSION_ID="$session_id"
    export AUDIT_SESSION_LOG="$session_log"
}

# Log audit event
audit_log() {
    local level="$1"
    local category="$2"
    local event="$3"
    local details="${4:-}"

    local timestamp=$(date -Iseconds)
    local session_id="${AUDIT_SESSION_ID:-unknown}"

    # Create audit log entry
    local audit_entry="[$timestamp] [$level] [$category] [$session_id] $event"
    if [ -n "$details" ]; then
        audit_entry="$audit_entry | Details: $details"
    fi

    # Add context information
    audit_entry="$audit_entry | User: ${USER:-unknown} | PWD: $(pwd)"

    # Write to session log
    if [ -n "${AUDIT_SESSION_LOG:-}" ] && [ -f "$AUDIT_SESSION_LOG" ]; then
        echo "$audit_entry" >> "$AUDIT_SESSION_LOG"
    fi

    # Write to category-specific log
    local category_log="$AUDIT_LOG_DIR/${category}_$(date +%Y%m%d).log"
    echo "$audit_entry" >> "$category_log"

    # Write to main audit log
    local main_log="$AUDIT_LOG_DIR/audit_$(date +%Y%m%d).log"
    echo "$audit_entry" >> "$main_log"

    # For security events, also write to security log
    if [ "$level" = "$AUDIT_LEVEL_SECURITY" ]; then
        local security_log="$AUDIT_LOG_DIR/security_$(date +%Y%m%d).log"
        echo "$audit_entry" >> "$security_log"
    fi
}

# Log system operation
audit_log_operation() {
    local operation="$1"
    local status="${2:-started}"
    local details="${3:-}"

    audit_log "$AUDIT_LEVEL_INFO" "operation" "Operation: $operation ($status)" "$details"
}

# Log security event
audit_log_security() {
    local event="$1"
    local severity="${2:-medium}"
    local details="${3:-}"

    audit_log "$AUDIT_LEVEL_SECURITY" "security" "Security Event: $event (severity: $severity)" "$details"
}

# Log privilege escalation
audit_log_privilege_escalation() {
    local method="$1"
    local target_user="${2:-root}"
    local reason="${3:-}"

    audit_log_security "Privilege escalation via $method to $target_user" "high" "Reason: $reason"

    # Update session tracking
    if [ -f "$AUDIT_SESSION_FILE" ]; then
        local temp_file=$(mktemp)
        {
            echo "Privilege escalation logged at $(date -Iseconds)"
            echo "Method: $method"
            echo "Target user: $target_user"
            echo "Reason: $reason"
            echo "---"
        } >> "${AUDIT_SESSION_FILE}.privilege_log"
    fi
}

# Log file modification
audit_log_file_modification() {
    local file_path="$1"
    local operation="${2:-modify}"
    local backup_created="${3:-false}"

    audit_log "$AUDIT_LEVEL_INFO" "file_modification" "File $operation: $file_path" "Backup created: $backup_created"

    # Get file information if file exists
    if [ -f "$file_path" ]; then
        local file_info="Size: $(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null || echo unknown)"
        local file_perms="Permissions: $(stat -c%a "$file_path" 2>/dev/null || stat -f%Lp "$file_path" 2>/dev/null || echo unknown)"
        audit_log "$AUDIT_LEVEL_INFO" "file_modification" "File details: $file_path" "$file_info, $file_perms"
    fi
}

# Log network operation
audit_log_network_operation() {
    local operation="$1"
    local target="${2:-unknown}"
    local status="${3:-attempted}"

    audit_log "$AUDIT_LEVEL_INFO" "network" "Network $operation to $target ($status)"

    # For security-sensitive network operations
    case "$operation" in
        "download"|"upload"|"sync")
            audit_log_security "Network data transfer: $operation" "medium" "Target: $target"
            ;;
    esac
}

# Log system changes
audit_log_system_change() {
    local change_type="$1"
    local description="$2"
    local affected_components="${3:-unknown}"

    audit_log "$AUDIT_LEVEL_INFO" "system_change" "System change: $change_type" "Description: $description, Affected: $affected_components"

    # For major system changes, also log as compliance event
    case "$change_type" in
        "configuration"|"package_installation"|"service_modification")
            audit_log "$AUDIT_LEVEL_COMPLIANCE" "compliance" "System configuration change: $change_type" "$description"
            ;;
    esac
}

# Log build operation
audit_log_build_operation() {
    local phase="$1"
    local status="$2"
    local duration="${3:-unknown}"
    local details="${4:-}"

    audit_log_operation "build_$phase" "$status" "Duration: $duration, Details: $details"

    # Log as system change for completed operations
    if [ "$status" = "completed" ]; then
        audit_log_system_change "build_phase_completion" "Build phase $phase completed" "system configuration"
    elif [ "$status" = "failed" ]; then
        audit_log "$AUDIT_LEVEL_ERROR" "build_error" "Build phase $phase failed" "$details"
    fi
}

# Log compliance event
audit_log_compliance() {
    local event="$1"
    local regulation="${2:-internal}"
    local details="${3:-}"

    audit_log "$AUDIT_LEVEL_COMPLIANCE" "compliance" "Compliance Event: $event (regulation: $regulation)" "$details"
}

# End audit session
end_audit_session() {
    local session_id="${AUDIT_SESSION_ID:-unknown}"
    local exit_status="${1:-0}"

    log_debug "Ending audit session: $session_id"

    # Update session file
    if [ -f "$AUDIT_SESSION_FILE" ]; then
        local temp_file=$(mktemp)
        sed '/^{$/a\
  "session_end": {\
    "end_time": "'$(date -Iseconds)'",\
    "exit_status": '$exit_status',\
    "duration_seconds": '$(( $(date +%s) - $(date -d "$(jq -r '.session.start_time' "$AUDIT_SESSION_FILE" 2>/dev/null || echo "$(date -Iseconds)")" +%s 2>/dev/null || echo "0") ))'\
  },' "$AUDIT_SESSION_FILE" > "$temp_file" 2>/dev/null || {
            # Fallback if jq is not available
            cp "$AUDIT_SESSION_FILE" "$temp_file"
        }
        mv "$temp_file" "$AUDIT_SESSION_FILE"
    fi

    # Write session end to log
    if [ -n "${AUDIT_SESSION_LOG:-}" ] && [ -f "$AUDIT_SESSION_LOG" ]; then
        {
            echo ""
            echo "=== AUDIT SESSION END ==="
            echo "Session ID: $session_id"
            echo "End Time: $(date -Iseconds)"
            echo "Exit Status: $exit_status"
            echo "========================="
        } >> "$AUDIT_SESSION_LOG"
    fi

    audit_log "$AUDIT_LEVEL_INFO" "session" "Session ended: $session_id" "Exit status: $exit_status"

    # Archive session file
    if [ -f "$AUDIT_SESSION_FILE" ]; then
        local archive_dir="$AUDIT_STATE_DIR/archived_sessions"
        mkdir -p "$archive_dir"
        mv "$AUDIT_SESSION_FILE" "$archive_dir/${session_id}.json"
    fi

    unset AUDIT_SESSION_ID AUDIT_SESSION_LOG
}

# Get audit status
get_audit_status() {
    log_debug "Getting audit logging status"

    echo "=== Audit Logging Status ==="
    echo "Log Directory: $AUDIT_LOG_DIR"
    echo "State Directory: $AUDIT_STATE_DIR"

    if [ -f "$AUDIT_CONFIG_FILE" ]; then
        echo "Configuration: Available"
        if command -v jq >/dev/null 2>&1; then
            local enabled=$(jq -r '.audit.enabled' "$AUDIT_CONFIG_FILE" 2>/dev/null)
            echo "Audit Enabled: $enabled"
        fi
    else
        echo "Configuration: Missing"
    fi

    if [ -n "${AUDIT_SESSION_ID:-}" ]; then
        echo "Current Session: $AUDIT_SESSION_ID"
    else
        echo "Current Session: None"
    fi

    # Count log files
    local log_count=$(ls -1 "$AUDIT_LOG_DIR"/*.log 2>/dev/null | wc -l)
    echo "Log Files: $log_count"

    # Show recent activity
    if [ -f "$AUDIT_LOG_DIR/audit_$(date +%Y%m%d).log" ]; then
        local today_entries=$(wc -l < "$AUDIT_LOG_DIR/audit_$(date +%Y%m%d).log" 2>/dev/null || echo "0")
        echo "Today's Entries: $today_entries"
    else
        echo "Today's Entries: 0"
    fi

    return 0
}

# Search audit logs
search_audit_logs() {
    local search_term="$1"
    local days="${2:-7}"
    local category="${3:-all}"

    log_info "Searching audit logs for: $search_term (last $days days, category: $category)"

    local search_results="$AUDIT_LOG_DIR/search_results_$(date +%s).txt"

    {
        echo "=== Audit Log Search Results ==="
        echo "Search Term: $search_term"
        echo "Period: Last $days days"
        echo "Category: $category"
        echo "Search Time: $(date -Iseconds)"
        echo ""
    } > "$search_results"

    # Search in relevant log files
    local search_pattern=""
    if [ "$category" = "all" ]; then
        search_pattern="$AUDIT_LOG_DIR/*.log"
    else
        search_pattern="$AUDIT_LOG_DIR/${category}_*.log"
    fi

    # Find log files within the specified time range
    local cutoff_date=$(date -d "${days} days ago" +%Y%m%d 2>/dev/null || date -v-${days}d +%Y%m%d 2>/dev/null || echo "20000101")

    for log_file in $search_pattern; do
        if [ -f "$log_file" ]; then
            local file_date=$(basename "$log_file" | sed 's/.*_\([0-9]\{8\}\)\.log/\1/' 2>/dev/null || echo "99999999")
            if [ "$file_date" -ge "$cutoff_date" ]; then
                echo "--- $(basename "$log_file") ---" >> "$search_results"
                grep -i "$search_term" "$log_file" 2>/dev/null >> "$search_results" || true
                echo "" >> "$search_results"
            fi
        fi
    done

    # Display results
    cat "$search_results"

    log_info "Search results saved to: $search_results"
    return 0
}

# Generate audit report
generate_audit_report() {
    local report_type="${1:-summary}"
    local period="${2:-7}"

    log_info "Generating audit report: $report_type (last $period days)"

    local report_file="$AUDIT_LOG_DIR/audit_report_${report_type}_$(date +%s).txt"

    {
        echo "=== Audit Report: $report_type ==="
        echo "Period: Last $period days"
        echo "Generated: $(date -Iseconds)"
        echo "Generated by: ${USER:-unknown}"
        echo ""

        case "$report_type" in
            "summary")
                echo "Summary Statistics:"

                # Count entries by type
                local total_entries=0
                local security_entries=0
                local error_entries=0
                local compliance_entries=0

                local cutoff_date=$(date -d "${period} days ago" +%Y%m%d 2>/dev/null || date -v-${period}d +%Y%m%d 2>/dev/null || echo "20000101")

                for log_file in "$AUDIT_LOG_DIR"/audit_*.log; do
                    if [ -f "$log_file" ]; then
                        local file_date=$(basename "$log_file" | sed 's/audit_\([0-9]\{8\}\)\.log/\1/' 2>/dev/null || echo "99999999")
                        if [ "$file_date" -ge "$cutoff_date" ]; then
                            local file_entries=$(wc -l < "$log_file" 2>/dev/null || echo "0")
                            total_entries=$((total_entries + file_entries))

                            local file_security=$(grep -c "\[SECURITY\]" "$log_file" 2>/dev/null || echo "0")
                            security_entries=$((security_entries + file_security))

                            local file_errors=$(grep -c "\[ERROR\]" "$log_file" 2>/dev/null || echo "0")
                            error_entries=$((error_entries + file_errors))

                            local file_compliance=$(grep -c "\[COMPLIANCE\]" "$log_file" 2>/dev/null || echo "0")
                            compliance_entries=$((compliance_entries + file_compliance))
                        fi
                    fi
                done

                echo "  Total Entries: $total_entries"
                echo "  Security Events: $security_entries"
                echo "  Error Events: $error_entries"
                echo "  Compliance Events: $compliance_entries"
                echo ""

                echo "Recent Activity (Last 24 hours):"
                if [ -f "$AUDIT_LOG_DIR/audit_$(date +%Y%m%d).log" ]; then
                    local today_entries=$(wc -l < "$AUDIT_LOG_DIR/audit_$(date +%Y%m%d).log" 2>/dev/null || echo "0")
                    echo "  Today's Entries: $today_entries"
                fi
                ;;

            "security")
                echo "Security Events Report:"
                echo ""

                for log_file in "$AUDIT_LOG_DIR"/security_*.log; do
                    if [ -f "$log_file" ]; then
                        echo "--- $(basename "$log_file") ---"
                        cat "$log_file"
                        echo ""
                    fi
                done
                ;;

            "compliance")
                echo "Compliance Events Report:"
                echo ""

                for log_file in "$AUDIT_LOG_DIR"/*.log; do
                    if [ -f "$log_file" ]; then
                        local compliance_events=$(grep "\[COMPLIANCE\]" "$log_file" 2>/dev/null)
                        if [ -n "$compliance_events" ]; then
                            echo "--- $(basename "$log_file") ---"
                            echo "$compliance_events"
                            echo ""
                        fi
                    fi
                done
                ;;
        esac

        echo ""
        echo "Report generated at: $(date -Iseconds)"

    } > "$report_file"

    # Display report
    cat "$report_file"

    log_info "Audit report saved to: $report_file"
    return 0
}

# Cleanup audit logs
cleanup_audit_logs() {
    local retention_days="${1:-90}"

    log_info "Cleaning up audit logs older than $retention_days days"

    local cleaned_count=0

    # Clean main audit logs
    if [ -d "$AUDIT_LOG_DIR" ]; then
        cleaned_count=$(find "$AUDIT_LOG_DIR" -name "*.log" -mtime +$retention_days 2>/dev/null | wc -l)
        find "$AUDIT_LOG_DIR" -name "*.log" -mtime +$retention_days -delete 2>/dev/null || true
    fi

    # Clean archived sessions
    if [ -d "$AUDIT_STATE_DIR/archived_sessions" ]; then
        local archived_cleaned=$(find "$AUDIT_STATE_DIR/archived_sessions" -name "*.json" -mtime +$retention_days 2>/dev/null | wc -l)
        find "$AUDIT_STATE_DIR/archived_sessions" -name "*.json" -mtime +$retention_days -delete 2>/dev/null || true
        cleaned_count=$((cleaned_count + archived_cleaned))
    fi

    audit_log "$AUDIT_LEVEL_INFO" "maintenance" "Audit log cleanup completed" "Files cleaned: $cleaned_count, Retention: $retention_days days"

    log_info "Audit log cleanup completed: $cleaned_count files removed"
    return 0
}
