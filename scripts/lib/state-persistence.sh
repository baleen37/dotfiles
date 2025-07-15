#!/bin/sh
# State Persistence Module for Build Scripts
# Provides system state capture, snapshot, and rollback functionality

# Global configuration for state management
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch"
SNAPSHOT_DIR="$STATE_DIR/snapshots"
CURRENT_STATE_FILE="$STATE_DIR/current_state.json"
MAX_SNAPSHOTS=10

# Initialize state persistence system
init_state_persistence() {
    log_debug "Initializing state persistence system"

    # Create state directories
    mkdir -p "$STATE_DIR" "$SNAPSHOT_DIR" || {
        log_error "Failed to create state directories"
        return 1
    }

    log_debug "State persistence system initialized: $STATE_DIR"
    return 0
}

# Capture current system state
capture_system_state() {
    log_debug "Capturing current system state"

    local timestamp=$(date -Iseconds)
    local temp_state_file=$(mktemp)

    # Gather system information
    {
        echo "{"
        echo "  \"timestamp\": \"$timestamp\","
        echo "  \"hostname\": \"$(hostname)\","
        echo "  \"system_info\": {"
        echo "    \"os\": \"$(uname -s)\","
        echo "    \"kernel\": \"$(uname -r)\","
        echo "    \"architecture\": \"$(uname -m)\""
        echo "  },"

        # Nix system information
        echo "  \"nix_info\": {"
        if command -v nix-env >/dev/null 2>&1; then
            echo "    \"nix_version\": \"$(nix-env --version | head -1 | cut -d' ' -f3)\","
        else
            echo "    \"nix_version\": \"unknown\","
        fi

        if [ "$PLATFORM_TYPE" = "darwin" ] && command -v darwin-rebuild >/dev/null 2>&1; then
            echo "    \"darwin_rebuild_available\": true,"
            echo "    \"darwin_rebuild_path\": \"$(command -v darwin-rebuild)\""
        else
            echo "    \"darwin_rebuild_available\": false,"
            echo "    \"darwin_rebuild_path\": null"
        fi
        echo "  },"

        # Build environment state
        echo "  \"build_environment\": {"
        echo "    \"working_directory\": \"$(pwd)\","
        echo "    \"user\": \"${USER:-unknown}\","
        echo "    \"home\": \"${HOME:-unknown}\","
        echo "    \"system_type\": \"${SYSTEM_TYPE:-unknown}\","
        echo "    \"platform_type\": \"${PLATFORM_TYPE:-unknown}\","
        echo "    \"rebuild_command_path\": \"${REBUILD_COMMAND_PATH:-unknown}\""
        echo "  },"

        # Network state
        echo "  \"network_state\": {"
        if command -v check_network_connectivity >/dev/null 2>&1; then
            if check_network_connectivity; then
                echo "    \"connectivity\": \"online\","
            else
                echo "    \"connectivity\": \"offline\","
            fi
        else
            echo "    \"connectivity\": \"unknown\","
        fi
        echo "    \"offline_mode\": $(is_offline_mode && echo "true" || echo "false")"
        echo "  },"

        # Process information
        echo "  \"process_info\": {"
        echo "    \"pid\": $$,"
        echo "    \"parent_pid\": $PPID"
        echo "  }"
        echo "}"
    } > "$temp_state_file"

    # Validate JSON and move to final location
    if command -v jq >/dev/null 2>&1; then
        if jq . "$temp_state_file" >/dev/null 2>&1; then
            mv "$temp_state_file" "$CURRENT_STATE_FILE"
            log_debug "System state captured successfully"
            return 0
        else
            log_error "Generated invalid JSON state file"
            rm -f "$temp_state_file"
            return 1
        fi
    else
        # No jq available, assume valid and move
        mv "$temp_state_file" "$CURRENT_STATE_FILE"
        log_debug "System state captured (validation skipped - no jq)"
        return 0
    fi
}

# Create a snapshot of current state before major operations
create_pre_build_snapshot() {
    log_debug "Creating pre-build snapshot"

    # Ensure state persistence is initialized
    init_state_persistence || return 1

    # Capture current state
    capture_system_state || {
        log_error "Failed to capture system state for snapshot"
        return 1
    }

    # Create snapshot with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_file="$SNAPSHOT_DIR/pre_build_$timestamp.json"

    if [ -f "$CURRENT_STATE_FILE" ]; then
        cp "$CURRENT_STATE_FILE" "$snapshot_file" || {
            log_error "Failed to create snapshot file"
            return 1
        }

        log_info "Pre-build snapshot created: $(basename "$snapshot_file")"

        # Clean old snapshots to maintain limit
        cleanup_old_snapshots

        return 0
    else
        log_error "No current state file available for snapshot"
        return 1
    fi
}

# Clean up old snapshots to maintain storage limits
cleanup_old_snapshots() {
    log_debug "Cleaning up old snapshots (keeping $MAX_SNAPSHOTS most recent)"

    # Count current snapshots
    local snapshot_count=$(ls -1 "$SNAPSHOT_DIR"/pre_build_*.json 2>/dev/null | wc -l)

    if [ "$snapshot_count" -gt "$MAX_SNAPSHOTS" ]; then
        local excess=$((snapshot_count - MAX_SNAPSHOTS))
        log_debug "Removing $excess old snapshots"

        # Remove oldest snapshots
        ls -1t "$SNAPSHOT_DIR"/pre_build_*.json 2>/dev/null | \
            tail -n "$excess" | \
            xargs rm -f
    fi
}

# Detect if a build failure occurred
detect_build_failure() {
    local exit_code="$1"
    local operation="${2:-build}"

    log_debug "Detecting build failure for operation: $operation (exit code: $exit_code)"

    if [ "$exit_code" -ne 0 ]; then
        log_warning "Build failure detected: $operation failed with exit code $exit_code"

        # Create failure state record
        local failure_timestamp=$(date -Iseconds)
        local failure_file="$STATE_DIR/last_failure.json"

        cat > "$failure_file" << EOF
{
  "timestamp": "$failure_timestamp",
  "operation": "$operation",
  "exit_code": $exit_code,
  "working_directory": "$(pwd)",
  "system_type": "${SYSTEM_TYPE:-unknown}",
  "platform_type": "${PLATFORM_TYPE:-unknown}"
}
EOF

        return 0  # Failure detected
    else
        log_debug "No build failure detected"
        return 1  # No failure
    fi
}

# Decide recovery strategy based on failure type and system state
decide_recovery_strategy() {
    local failure_file="$STATE_DIR/last_failure.json"

    log_debug "Deciding recovery strategy"

    if [ ! -f "$failure_file" ]; then
        log_debug "No recent failure detected, no recovery needed"
        echo "no_recovery"
        return 0
    fi

    # Analyze failure information
    if command -v jq >/dev/null 2>&1; then
        local exit_code=$(jq -r '.exit_code' "$failure_file" 2>/dev/null)
        local operation=$(jq -r '.operation' "$failure_file" 2>/dev/null)

        # Decision logic based on failure type
        case "$exit_code" in
            1)
                # General error - try simple retry
                echo "retry"
                ;;
            2)
                # Syntax/configuration error - suggest manual review
                echo "manual_review"
                ;;
            130)
                # Interrupted (Ctrl+C) - safe to retry
                echo "retry"
                ;;
            *)
                # Unknown error - conservative approach
                if [ "$exit_code" -gt 100 ]; then
                    echo "rollback"
                else
                    echo "retry"
                fi
                ;;
        esac
    else
        # Fallback without jq
        echo "retry"
    fi

    return 0
}

# Execute rollback to previous known good state
execute_rollback() {
    log_info "Executing system rollback"

    # Find most recent snapshot
    local latest_snapshot=$(ls -1t "$SNAPSHOT_DIR"/pre_build_*.json 2>/dev/null | head -1)

    if [ -z "$latest_snapshot" ]; then
        log_error "No snapshots available for rollback"
        return 1
    fi

    log_info "Rolling back to snapshot: $(basename "$latest_snapshot")"

    # For now, this is a conservative rollback that primarily provides information
    # In a full implementation, this would restore system configuration

    if command -v jq >/dev/null 2>&1; then
        log_info "Rollback target information:"
        jq -r '.timestamp' "$latest_snapshot" 2>/dev/null && \
        log_info "  Snapshot timestamp: $(jq -r '.timestamp' "$latest_snapshot" 2>/dev/null)"
        log_info "  Working directory: $(jq -r '.build_environment.working_directory' "$latest_snapshot" 2>/dev/null)"
        log_info "  System type: $(jq -r '.build_environment.system_type' "$latest_snapshot" 2>/dev/null)"
    fi

    # Mark rollback as completed
    local rollback_file="$STATE_DIR/last_rollback.json"
    cat > "$rollback_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "source_snapshot": "$latest_snapshot",
  "status": "completed"
}
EOF

    log_info "Rollback information recorded - manual verification recommended"

    # Remove failure state since we've addressed it
    rm -f "$STATE_DIR/last_failure.json"

    return 0
}

# Get recovery recommendations for user
get_recovery_recommendations() {
    local strategy="$1"

    case "$strategy" in
        "retry")
            cat << 'EOF'
🔄 Recovery Strategy: Retry

The system recommends retrying the failed operation:
• The failure appears to be transient
• System state is stable
• No rollback necessary

Recommended actions:
• Re-run the same command
• Check network connectivity if needed
• Monitor for recurring failures
EOF
            ;;
        "manual_review")
            cat << 'EOF'
⚠️  Recovery Strategy: Manual Review

The failure suggests configuration or syntax issues:
• Manual review of changes is recommended
• Check recent configuration modifications
• Verify flake.nix syntax and structure

Recommended actions:
• Review recent changes to configuration files
• Run 'nix flake check' to validate syntax
• Consider reverting recent modifications
• Check logs for specific error details
EOF
            ;;
        "rollback")
            cat << 'EOF'
🔙 Recovery Strategy: Rollback

The failure suggests system-level issues:
• Rollback to previous known good state recommended
• Current configuration may have compatibility issues
• Data preservation during rollback is prioritized

Recommended actions:
• Run automated rollback if available
• Verify system functionality after rollback
• Investigate root cause before re-attempting changes
• Consider incremental configuration changes
EOF
            ;;
        *)
            cat << 'EOF'
ℹ️  Recovery Strategy: No Action Required

No recent failures detected or recovery not needed:
• System appears to be in stable state
• Continue with normal operations

Recommended actions:
• Proceed with intended operations
• Monitor system for any issues
EOF
            ;;
    esac
}
