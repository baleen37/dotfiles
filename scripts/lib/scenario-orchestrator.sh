#!/bin/sh
# Scenario Orchestrator Module for Build Scripts
# Provides complex scenario management and orchestration for testing and operations

# Global configuration for scenario orchestration
SCENARIO_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/scenarios"
SCENARIO_LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/build-switch/scenario-logs"
SCENARIO_CONFIG_FILE="$SCENARIO_STATE_DIR/orchestration.json"
MAX_CONCURRENT_SCENARIOS=3

# Initialize scenario orchestration system
init_scenario_orchestration() {
    log_debug "Initializing scenario orchestration system"

    # Create scenario directories
    mkdir -p "$SCENARIO_STATE_DIR" "$SCENARIO_LOG_DIR" || {
        log_error "Failed to create scenario directories"
        return 1
    }

    # Initialize orchestration configuration
    if [ ! -f "$SCENARIO_CONFIG_FILE" ]; then
        cat > "$SCENARIO_CONFIG_FILE" << EOF
{
  "orchestration": {
    "initialized": "$(date -Iseconds)",
    "version": "1.0",
    "max_concurrent": $MAX_CONCURRENT_SCENARIOS
  },
  "active_scenarios": [],
  "completed_scenarios": [],
  "failed_scenarios": []
}
EOF
    fi

    log_debug "Scenario orchestration system initialized: $SCENARIO_STATE_DIR"
    return 0
}

# Execute complex scenario with network interruption
execute_network_interruption_scenario() {
    local scenario_id="network_interruption_$(date +%s)"
    log_info "Starting network interruption scenario: $scenario_id"

    # Register scenario start
    register_scenario_start "$scenario_id" "network_interruption" || return 1

    # Phase 1: Pre-interruption setup
    log_step "Phase 1: Pre-interruption setup"
    if ! setup_network_monitoring; then
        log_error "Failed to setup network monitoring"
        register_scenario_failure "$scenario_id" "setup_failure"
        return 1
    fi

    # Phase 2: Execute build with simulated network issues
    log_step "Phase 2: Build execution with network simulation"
    if ! execute_build_with_network_simulation "$scenario_id"; then
        unified_log_warning "Build with network simulation encountered issues"
        # Don't fail here - this might be expected
    fi

    # Phase 3: Network recovery and completion
    log_step "Phase 3: Network recovery and completion"
    if ! recover_from_network_interruption "$scenario_id"; then
        log_error "Failed to recover from network interruption"
        register_scenario_failure "$scenario_id" "recovery_failure"
        return 1
    fi

    # Register scenario completion
    register_scenario_completion "$scenario_id" "success"
    unified_log_success "Network interruption scenario completed: $scenario_id"
    return 0
}

# Setup network monitoring for scenario
setup_network_monitoring() {
    log_debug "Setting up network monitoring for scenario"

    # Create network state tracking
    local network_state_file="$SCENARIO_STATE_DIR/network_state.json"
    cat > "$network_state_file" << EOF
{
  "monitoring_start": "$(date -Iseconds)",
  "initial_connectivity": $(check_network_connectivity && echo "true" || echo "false"),
  "interruptions": [],
  "recovery_events": []
}
EOF

    # Start network monitoring background process
    monitor_network_for_scenario &
    local monitor_pid=$!
    echo "$monitor_pid" > "$SCENARIO_STATE_DIR/network_monitor.pid"

    log_debug "Network monitoring setup completed (PID: $monitor_pid)"
    return 0
}

# Monitor network connectivity in background
monitor_network_for_scenario() {
    local state_file="$SCENARIO_STATE_DIR/network_state.json"
    local previous_state="unknown"

    while [ -f "$SCENARIO_STATE_DIR/network_monitor.pid" ]; do
        local current_state
        if check_network_connectivity; then
            current_state="connected"
        else
            current_state="disconnected"
        fi

        # Log state changes
        if [ "$current_state" != "$previous_state" ]; then
            log_debug "Network state change: $previous_state -> $current_state"

            # Update state file (simplified - would use jq in production)
            if [ "$current_state" = "disconnected" ]; then
                echo "Network interruption detected at $(date -Iseconds)" >> "$SCENARIO_LOG_DIR/network_events.log"
            elif [ "$current_state" = "connected" ] && [ "$previous_state" = "disconnected" ]; then
                echo "Network recovery detected at $(date -Iseconds)" >> "$SCENARIO_LOG_DIR/network_events.log"
            fi
        fi

        previous_state="$current_state"
        sleep 5
    done
}

# Execute build with network simulation
execute_build_with_network_simulation() {
    local scenario_id="$1"
    log_debug "Executing build with network simulation for scenario: $scenario_id"

    # Create scenario-specific log
    local scenario_log="$SCENARIO_LOG_DIR/${scenario_id}_execution.log"

    {
        echo "=== Build Execution with Network Simulation ==="
        echo "Scenario ID: $scenario_id"
        echo "Start Time: $(date -Iseconds)"
        echo ""
    } > "$scenario_log"

    # Simulate network interruption during build
    simulate_network_interruption &
    local simulation_pid=$!

    # Execute build process
    local build_result=0
    if [ -n "${REBUILD_COMMAND_PATH:-}" ] && [ -n "${SYSTEM_TYPE:-}" ]; then
        log_info "Executing build with simulated network conditions"

        # Use offline mode to simulate network issues
        local original_offline_mode="${NIX_OFFLINE_MODE:-}"
        export NIX_OFFLINE_MODE=1

        # Attempt build (may fail due to simulated network issues)
        if execute_platform_build --test-mode 2>>"$scenario_log"; then
            unified_log_success "Build completed despite network simulation"
            build_result=0
        else
            unified_log_warning "Build failed during network simulation (expected behavior)"
            build_result=1
        fi

        # Restore original offline mode
        if [ -n "$original_offline_mode" ]; then
            export NIX_OFFLINE_MODE="$original_offline_mode"
        else
            unset NIX_OFFLINE_MODE
        fi
    else
        unified_log_warning "Build simulation skipped - test environment"
        echo "Build simulation skipped - test environment" >> "$scenario_log"
    fi

    # Stop network simulation
    kill "$simulation_pid" 2>/dev/null || true
    wait "$simulation_pid" 2>/dev/null || true

    {
        echo ""
        echo "Build Result: $build_result"
        echo "End Time: $(date -Iseconds)"
    } >> "$scenario_log"

    return $build_result
}

# Simulate network interruption
simulate_network_interruption() {
    log_debug "Starting network interruption simulation"

    # Create interruption schedule
    local interruption_schedule=(3 7 15 25 40)  # seconds
    local recovery_schedule=(5 10 20 30 45)     # seconds

    for i in $(seq 0 $((${#interruption_schedule[@]} - 1))); do
        local interrupt_at=${interruption_schedule[$i]}
        local recover_at=${recovery_schedule[$i]}

        sleep "$interrupt_at"

        # Simulate interruption
        log_debug "Simulating network interruption #$((i + 1))"
        touch "$SCENARIO_STATE_DIR/network_interrupted"

        sleep $((recover_at - interrupt_at))

        # Simulate recovery
        log_debug "Simulating network recovery #$((i + 1))"
        rm -f "$SCENARIO_STATE_DIR/network_interrupted"
    done
}

# Recover from network interruption
recover_from_network_interruption() {
    local scenario_id="$1"
    log_debug "Recovering from network interruption for scenario: $scenario_id"

    # Stop network monitoring
    if [ -f "$SCENARIO_STATE_DIR/network_monitor.pid" ]; then
        local monitor_pid=$(cat "$SCENARIO_STATE_DIR/network_monitor.pid")
        kill "$monitor_pid" 2>/dev/null || true
        rm -f "$SCENARIO_STATE_DIR/network_monitor.pid"
    fi

    # Verify network recovery
    local recovery_attempts=0
    local max_recovery_attempts=5

    while [ $recovery_attempts -lt $max_recovery_attempts ]; do
        if check_network_connectivity; then
            unified_log_success "Network connectivity restored"
            break
        fi

        recovery_attempts=$((recovery_attempts + 1))
        log_debug "Network recovery attempt $recovery_attempts/$max_recovery_attempts"
        sleep 2
    done

    if [ $recovery_attempts -ge $max_recovery_attempts ]; then
        unified_log_warning "Network recovery verification failed - continuing with offline mode"
        enable_offline_mode
    else
        # Re-enable online mode if we were in offline mode
        if is_offline_mode; then
            disable_offline_mode
        fi
    fi

    # Cleanup scenario state
    cleanup_scenario_state "$scenario_id"

    return 0
}

# Register scenario start
register_scenario_start() {
    local scenario_id="$1"
    local scenario_type="$2"

    log_debug "Registering scenario start: $scenario_id ($scenario_type)"

    # Create scenario record
    local scenario_file="$SCENARIO_STATE_DIR/${scenario_id}.json"
    cat > "$scenario_file" << EOF
{
  "id": "$scenario_id",
  "type": "$scenario_type",
  "status": "running",
  "start_time": "$(date -Iseconds)",
  "phases": [],
  "metadata": {
    "working_directory": "$(pwd)",
    "user": "${USER:-unknown}",
    "system_type": "${SYSTEM_TYPE:-unknown}",
    "platform_type": "${PLATFORM_TYPE:-unknown}"
  }
}
EOF

    return 0
}

# Register scenario completion
register_scenario_completion() {
    local scenario_id="$1"
    local status="$2"

    log_debug "Registering scenario completion: $scenario_id ($status)"

    local scenario_file="$SCENARIO_STATE_DIR/${scenario_id}.json"
    if [ -f "$scenario_file" ]; then
        # Update scenario record (simplified - would use jq in production)
        sed -i.bak \
            -e "s/\"status\": \"running\"/\"status\": \"$status\"/" \
            -e "/\"start_time\":/a\\
  \"end_time\": \"$(date -Iseconds)\"," \
            "$scenario_file"
        rm -f "${scenario_file}.bak"
    fi

    return 0
}

# Register scenario failure
register_scenario_failure() {
    local scenario_id="$1"
    local failure_reason="$2"

    unified_log_warning "Registering scenario failure: $scenario_id ($failure_reason)"

    local scenario_file="$SCENARIO_STATE_DIR/${scenario_id}.json"
    if [ -f "$scenario_file" ]; then
        # Update scenario record with failure info
        sed -i.bak \
            -e "s/\"status\": \"running\"/\"status\": \"failed\"/" \
            -e "/\"start_time\":/a\\
  \"end_time\": \"$(date -Iseconds)\",\\
  \"failure_reason\": \"$failure_reason\"," \
            "$scenario_file"
        rm -f "${scenario_file}.bak"
    fi

    return 0
}

# Cleanup scenario state
cleanup_scenario_state() {
    local scenario_id="$1"

    log_debug "Cleaning up scenario state: $scenario_id"

    # Remove temporary files
    rm -f "$SCENARIO_STATE_DIR/network_interrupted"
    rm -f "$SCENARIO_STATE_DIR/network_state.json"

    # Archive scenario logs
    if [ -f "$SCENARIO_LOG_DIR/${scenario_id}_execution.log" ]; then
        mkdir -p "$SCENARIO_LOG_DIR/archived"
        mv "$SCENARIO_LOG_DIR/${scenario_id}_execution.log" "$SCENARIO_LOG_DIR/archived/"
    fi

    return 0
}

# Orchestrate multiple scenarios in sequence
orchestrate_scenario_chain() {
    local scenarios="$*"
    log_info "Orchestrating scenario chain: $scenarios"

    local chain_id="chain_$(date +%s)"
    local chain_log="$SCENARIO_LOG_DIR/${chain_id}_orchestration.log"

    {
        echo "=== Scenario Chain Orchestration ==="
        echo "Chain ID: $chain_id"
        echo "Scenarios: $scenarios"
        echo "Start Time: $(date -Iseconds)"
        echo ""
    } > "$chain_log"

    local failed_scenarios=""
    local completed_scenarios=""

    for scenario in $scenarios; do
        log_info "Executing scenario: $scenario"
        echo "Executing scenario: $scenario at $(date -Iseconds)" >> "$chain_log"

        case "$scenario" in
            "network_interruption")
                if execute_network_interruption_scenario; then
                    completed_scenarios="$completed_scenarios $scenario"
                    echo "✓ $scenario completed successfully" >> "$chain_log"
                else
                    failed_scenarios="$failed_scenarios $scenario"
                    echo "✗ $scenario failed" >> "$chain_log"
                fi
                ;;
            *)
                unified_log_warning "Unknown scenario: $scenario"
                echo "⚠ Unknown scenario: $scenario" >> "$chain_log"
                ;;
        esac
    done

    {
        echo ""
        echo "=== Chain Results ==="
        echo "Completed: $completed_scenarios"
        echo "Failed: $failed_scenarios"
        echo "End Time: $(date -Iseconds)"
    } >> "$chain_log"

    if [ -n "$failed_scenarios" ]; then
        unified_log_warning "Scenario chain completed with failures: $failed_scenarios"
        return 1
    else
        unified_log_success "Scenario chain completed successfully"
        return 0
    fi
}

# Get scenario orchestration status
get_orchestration_status() {
    log_debug "Getting orchestration status"

    if [ ! -d "$SCENARIO_STATE_DIR" ]; then
        echo "Orchestration not initialized"
        return 1
    fi

    echo "=== Scenario Orchestration Status ==="
    echo "State Directory: $SCENARIO_STATE_DIR"
    echo "Log Directory: $SCENARIO_LOG_DIR"

    local active_scenarios=$(ls -1 "$SCENARIO_STATE_DIR"/*.json 2>/dev/null | wc -l)
    echo "Active Scenarios: $active_scenarios"

    local log_files=$(ls -1 "$SCENARIO_LOG_DIR"/*.log 2>/dev/null | wc -l)
    echo "Log Files: $log_files"

    if [ -f "$SCENARIO_CONFIG_FILE" ]; then
        echo "Configuration: Available"
    else
        echo "Configuration: Missing"
    fi

    return 0
}
