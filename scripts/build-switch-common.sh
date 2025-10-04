#!/usr/bin/env bash

# build-switch-common.sh - Modular Build & Switch Logic
# Simplified main script that orchestrates modular components

# Environment setup
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8

# Set USER if not already set (Darwin-specific)
if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

# Parse arguments
VERBOSE=false
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=true
    break
  fi
done

# Get script directory for module loading
SCRIPT_DIR="$(dirname "$0")"
# Determine if we're being called from an app (contains PROJECT_ROOT) or directly
if [ -n "${PROJECT_ROOT:-}" ]; then
  LIB_DIR="$PROJECT_ROOT/scripts/lib"
else
  LIB_DIR="$SCRIPT_DIR/lib"
fi

# Load all modules (suppress warnings for missing files)
[ -f "$LIB_DIR/logging.sh" ] && . "$LIB_DIR/logging.sh"
[ -f "$LIB_DIR/performance.sh" ] && . "$LIB_DIR/performance.sh"
[ -f "$LIB_DIR/progress.sh" ] && . "$LIB_DIR/progress.sh"
[ -f "$LIB_DIR/optimization.sh" ] && . "$LIB_DIR/optimization.sh"
[ -f "$LIB_DIR/sudo-management.sh" ] && . "$LIB_DIR/sudo-management.sh"
[ -f "$LIB_DIR/cache-management.sh" ] && . "$LIB_DIR/cache-management.sh"
[ -f "$LIB_DIR/flake-evaluation.sh" ] && . "$LIB_DIR/flake-evaluation.sh"
[ -f "$LIB_DIR/network-detection.sh" ] && . "$LIB_DIR/network-detection.sh"
[ -f "$LIB_DIR/state-persistence.sh" ] && . "$LIB_DIR/state-persistence.sh"
[ -f "$LIB_DIR/build-logic.sh" ] && . "$LIB_DIR/build-logic.sh"
[ -f "$LIB_DIR/scenario-orchestrator.sh" ] && . "$LIB_DIR/scenario-orchestrator.sh"
[ -f "$LIB_DIR/performance-monitor.sh" ] && . "$LIB_DIR/performance-monitor.sh"
[ -f "$LIB_DIR/audit-logger.sh" ] && . "$LIB_DIR/audit-logger.sh"

# Load Phase 3 modules - Enhanced validation and error handling
[ -f "$LIB_DIR/pre-validation.sh" ] && . "$LIB_DIR/pre-validation.sh"
[ -f "$LIB_DIR/alternative-execution.sh" ] && . "$LIB_DIR/alternative-execution.sh"
[ -f "$LIB_DIR/error-messaging.sh" ] && . "$LIB_DIR/error-messaging.sh"

# Load Phase 4 modules - Performance optimization and monitoring
[ -f "$LIB_DIR/cache-optimization.sh" ] && . "$LIB_DIR/cache-optimization.sh"
[ -f "$LIB_DIR/performance-dashboard.sh" ] && . "$LIB_DIR/performance-dashboard.sh"
[ -f "$LIB_DIR/notification-auto-recovery.sh" ] && . "$LIB_DIR/notification-auto-recovery.sh"

# Validate cross-platform behavior consistency
validate_cross_platform_behavior() {
  local validation_context="${1:-full}"
  local strict_mode="${2:-false}"

  log_debug "Validating cross-platform behavior (context: $validation_context, strict: $strict_mode)"

  # Initialize validation tracking
  local validation_id="validation_$(date +%s)"
  local validation_results_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/cross_platform_validation_${validation_id}.json"
  local validation_issues=""
  local validation_warnings=""
  local validation_errors=""

  mkdir -p "$(dirname "$validation_results_file")"

  # Initialize validation results
  cat >"$validation_results_file" <<EOF
{
  "validation": {
    "id": "$validation_id",
    "timestamp": "$(date -Iseconds)",
    "context": "$validation_context",
    "strict_mode": $strict_mode,
    "platform_type": "${PLATFORM_TYPE:-unknown}",
    "system_type": "${SYSTEM_TYPE:-unknown}"
  },
  "checks": [],
  "issues": [],
  "summary": {
    "total_checks": 0,
    "passed": 0,
    "failed": 0,
    "warnings": 0
  }
}
EOF

  # Audit log the validation start
  if command -v audit_log_operation >/dev/null 2>&1; then
    audit_log_operation "cross_platform_validation" "started" "Context: $validation_context, Strict: $strict_mode"
  fi

  # Check 1: Environment variable consistency
  log_debug "Validating environment variable consistency"
  if ! validate_environment_consistency "$validation_results_file"; then
    validation_issues="$validation_issues env_consistency"
    if [ "$strict_mode" = "true" ]; then
      validation_errors="$validation_errors env_consistency"
    else
      validation_warnings="$validation_warnings env_consistency"
    fi
  fi

  # Check 2: Path resolution behavior
  log_debug "Validating path resolution behavior"
  if ! validate_path_resolution_behavior "$validation_results_file"; then
    validation_issues="$validation_issues path_resolution"
    if [ "$strict_mode" = "true" ]; then
      validation_errors="$validation_errors path_resolution"
    else
      validation_warnings="$validation_warnings path_resolution"
    fi
  fi

  # Check 3: Command availability and behavior
  log_debug "Validating command availability and behavior"
  if ! validate_command_behavior "$validation_results_file"; then
    validation_issues="$validation_issues command_behavior"
    validation_warnings="$validation_warnings command_behavior"
  fi

  # Check 4: File system behavior
  log_debug "Validating file system behavior"
  if ! validate_filesystem_behavior "$validation_results_file"; then
    validation_issues="$validation_issues filesystem_behavior"
    validation_warnings="$validation_warnings filesystem_behavior"
  fi

  # Check 5: Network behavior consistency
  log_debug "Validating network behavior consistency"
  if ! validate_network_behavior_consistency "$validation_results_file"; then
    validation_issues="$validation_issues network_behavior"
    validation_warnings="$validation_warnings network_behavior"
  fi

  # Check 6: Build tool behavior
  if [ "$validation_context" = "full" ] || [ "$validation_context" = "build" ]; then
    log_debug "Validating build tool behavior"
    if ! validate_build_tool_behavior "$validation_results_file"; then
      validation_issues="$validation_issues build_tool_behavior"
      validation_warnings="$validation_warnings build_tool_behavior"
    fi
  fi

  # Generate validation summary
  local total_checks=6
  local failed_count=$(echo "$validation_errors" | wc -w)
  local warning_count=$(echo "$validation_warnings" | wc -w)
  local passed_count=$((total_checks - failed_count - warning_count))

  # Update validation results
  local temp_file=$(mktemp)
  sed "s/\"total_checks\": 0/\"total_checks\": $total_checks/" "$validation_results_file" |
    sed "s/\"passed\": 0/\"passed\": $passed_count/" |
    sed "s/\"failed\": 0/\"failed\": $failed_count/" |
    sed "s/\"warnings\": 0/\"warnings\": $warning_count/" >"$temp_file"
  mv "$temp_file" "$validation_results_file"

  # Log validation results
  if [ -n "$validation_errors" ]; then
    log_error "Cross-platform validation failed with errors: $validation_errors"
    if command -v audit_log_operation >/dev/null 2>&1; then
      audit_log_operation "cross_platform_validation" "failed" "Errors: $validation_errors"
    fi

    # Display validation report
    display_validation_report "$validation_results_file" "error"
    return 1
  elif [ -n "$validation_warnings" ]; then
    log_warning "Cross-platform validation completed with warnings: $validation_warnings"
    if command -v audit_log_operation >/dev/null 2>&1; then
      audit_log_operation "cross_platform_validation" "completed_with_warnings" "Warnings: $validation_warnings"
    fi

    # Display validation report
    display_validation_report "$validation_results_file" "warning"

    if [ "$strict_mode" = "true" ]; then
      return 1
    else
      return 0
    fi
  else
    log_success "Cross-platform validation completed successfully"
    if command -v audit_log_operation >/dev/null 2>&1; then
      audit_log_operation "cross_platform_validation" "completed" "All checks passed"
    fi

    # Display validation report
    display_validation_report "$validation_results_file" "success"
    return 0
  fi
}

# Validate environment variable consistency
validate_environment_consistency() {
  local results_file="$1"

  log_debug "Checking environment variable consistency"

  # Check essential environment variables
  local essential_vars="HOME USER PATH SHELL"
  local missing_vars=""
  local inconsistent_vars=""

  for var in $essential_vars; do
    eval "var_value=\${$var:-}"
    if [ -z "$var_value" ]; then
      missing_vars="$missing_vars $var"
    fi

    # Check for platform-specific inconsistencies
    case "$var" in
    "PATH")
      # Check for platform-appropriate paths
      case "$PLATFORM_TYPE" in
      "darwin")
        if ! echo "$var_value" | grep -q "/usr/bin"; then
          inconsistent_vars="$inconsistent_vars PATH_missing_usr_bin"
        fi
        ;;
      "linux")
        if ! echo "$var_value" | grep -q "/bin"; then
          inconsistent_vars="$inconsistent_vars PATH_missing_bin"
        fi
        ;;
      esac
      ;;
    esac
  done

  # Record check result
  {
    echo "Environment consistency check:"
    echo "  Missing variables: $missing_vars"
    echo "  Inconsistent variables: $inconsistent_vars"
    echo "  Platform type: $PLATFORM_TYPE"
    echo "---"
  } >>"${results_file}.log"

  if [ -n "$missing_vars" ] || [ -n "$inconsistent_vars" ]; then
    return 1
  else
    return 0
  fi
}

# Validate path resolution behavior
validate_path_resolution_behavior() {
  local results_file="$1"

  log_debug "Checking path resolution behavior"

  local issues=""

  # Test relative path resolution
  local test_relative_path="./test_path_resolution"
  local resolved_path=$(readlink -f "$test_relative_path" 2>/dev/null || realpath "$test_relative_path" 2>/dev/null || echo "$PWD/$test_relative_path")

  if [ -z "$resolved_path" ]; then
    issues="$issues path_resolution_failed"
  fi

  # Test home directory expansion
  local test_home_path="~/test"
  eval "local expanded_path=\"$test_home_path\""

  if [ "$expanded_path" = "~/test" ]; then
    issues="$issues home_expansion_failed"
  fi

  # Test symlink behavior (if available)
  if command -v ln >/dev/null 2>&1; then
    local temp_dir=$(mktemp -d)
    local test_file="$temp_dir/test_file"
    local test_link="$temp_dir/test_link"

    echo "test" >"$test_file"
    ln -s "$test_file" "$test_link" 2>/dev/null || issues="$issues symlink_creation_failed"

    if [ -L "$test_link" ] && [ ! -f "$test_link" ]; then
      issues="$issues symlink_resolution_failed"
    fi

    rm -rf "$temp_dir" 2>/dev/null || true
  fi

  # Record check result
  {
    echo "Path resolution behavior check:"
    echo "  Issues: $issues"
    echo "  PWD: $PWD"
    echo "  HOME: $HOME"
    echo "---"
  } >>"${results_file}.log"

  if [ -n "$issues" ]; then
    return 1
  else
    return 0
  fi
}

# Validate command availability and behavior
validate_command_behavior() {
  local results_file="$1"

  log_debug "Checking command availability and behavior"

  local issues=""
  local expected_commands="sh bash nix"
  local optional_commands="jq curl wget"

  # Check essential commands
  for cmd in $expected_commands; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      issues="$issues missing_${cmd}"
    fi
  done

  # Check optional commands (warnings only)
  local missing_optional=""
  for cmd in $optional_commands; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_optional="$missing_optional $cmd"
    fi
  done

  # Test command behavior consistency
  if command -v date >/dev/null 2>&1; then
    # Test date command ISO format support
    if ! date -Iseconds >/dev/null 2>&1; then
      issues="$issues date_iso_format_unsupported"
    fi
  fi

  # Record check result
  {
    echo "Command behavior check:"
    echo "  Critical issues: $issues"
    echo "  Missing optional commands: $missing_optional"
    echo "  Platform type: $PLATFORM_TYPE"
    echo "---"
  } >>"${results_file}.log"

  if [ -n "$issues" ]; then
    return 1
  else
    return 0
  fi
}

# Validate filesystem behavior
validate_filesystem_behavior() {
  local results_file="$1"

  log_debug "Checking filesystem behavior"

  local issues=""
  local temp_dir=$(mktemp -d)

  # Test file creation and permissions
  local test_file="$temp_dir/test_file"
  if ! echo "test" >"$test_file" 2>/dev/null; then
    issues="$issues file_creation_failed"
  fi

  # Test permission setting
  if ! chmod 755 "$test_file" 2>/dev/null; then
    issues="$issues permission_setting_failed"
  fi

  # Test file deletion
  if ! rm "$test_file" 2>/dev/null; then
    issues="$issues file_deletion_failed"
  fi

  # Test directory operations
  local test_subdir="$temp_dir/subdir"
  if ! mkdir -p "$test_subdir" 2>/dev/null; then
    issues="$issues directory_creation_failed"
  fi

  if ! rmdir "$test_subdir" 2>/dev/null; then
    issues="$issues directory_deletion_failed"
  fi

  # Cleanup
  rm -rf "$temp_dir" 2>/dev/null || true

  # Record check result
  {
    echo "Filesystem behavior check:"
    echo "  Issues: $issues"
    echo "  Platform type: $PLATFORM_TYPE"
    echo "---"
  } >>"${results_file}.log"

  if [ -n "$issues" ]; then
    return 1
  else
    return 0
  fi
}

# Validate network behavior consistency
validate_network_behavior_consistency() {
  local results_file="$1"

  log_debug "Checking network behavior consistency"

  local issues=""

  # Test network connectivity detection
  if command -v check_network_connectivity >/dev/null 2>&1; then
    if ! check_network_connectivity >/dev/null 2>&1; then
      # Network might be offline, this is not necessarily an issue
      log_debug "Network connectivity check indicates offline mode"
    fi
  else
    issues="$issues network_detection_unavailable"
  fi

  # Test DNS resolution tools
  local dns_tools="nslookup dig getent"
  local available_dns_tools=""

  for tool in $dns_tools; do
    if command -v "$tool" >/dev/null 2>&1; then
      available_dns_tools="$available_dns_tools $tool"
    fi
  done

  if [ -z "$available_dns_tools" ]; then
    issues="$issues no_dns_tools_available"
  fi

  # Test HTTP client tools
  local http_tools="curl wget"
  local available_http_tools=""

  for tool in $http_tools; do
    if command -v "$tool" >/dev/null 2>&1; then
      available_http_tools="$available_http_tools $tool"
    fi
  done

  if [ -z "$available_http_tools" ]; then
    issues="$issues no_http_tools_available"
  fi

  # Record check result
  {
    echo "Network behavior consistency check:"
    echo "  Issues: $issues"
    echo "  Available DNS tools: $available_dns_tools"
    echo "  Available HTTP tools: $available_http_tools"
    echo "---"
  } >>"${results_file}.log"

  if [ -n "$issues" ]; then
    return 1
  else
    return 0
  fi
}

# Validate build tool behavior
validate_build_tool_behavior() {
  local results_file="$1"

  log_debug "Checking build tool behavior"

  local issues=""

  # Check Nix availability and basic functionality
  if ! command -v nix >/dev/null 2>&1; then
    issues="$issues nix_unavailable"
  else
    # Test basic nix command
    if ! nix --version >/dev/null 2>&1; then
      issues="$issues nix_version_check_failed"
    fi

    # Check for experimental features support
    if ! nix --extra-experimental-features 'nix-command flakes' --help >/dev/null 2>&1; then
      issues="$issues nix_experimental_features_unsupported"
    fi
  fi

  # Check platform-specific rebuild command
  case "$PLATFORM_TYPE" in
  "darwin")
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
      issues="$issues darwin_rebuild_unavailable"
    fi
    ;;
  "linux")
    if ! command -v nixos-rebuild >/dev/null 2>&1; then
      issues="$issues nixos_rebuild_unavailable"
    fi
    ;;
  esac

  # Check sudo availability if required
  if [ "${SUDO_REQUIRED:-false}" = "true" ]; then
    if ! command -v sudo >/dev/null 2>&1; then
      issues="$issues sudo_unavailable_but_required"
    fi
  fi

  # Record check result
  {
    echo "Build tool behavior check:"
    echo "  Issues: $issues"
    echo "  Platform type: $PLATFORM_TYPE"
    echo "  Sudo required: ${SUDO_REQUIRED:-false}"
    echo "---"
  } >>"${results_file}.log"

  if [ -n "$issues" ]; then
    return 1
  else
    return 0
  fi
}

# Display validation report
display_validation_report() {
  local results_file="$1"
  local report_type="${2:-info}"

  case "$report_type" in
  "error")
    cat <<EOF

🚨 Cross-Platform Validation Failed

Critical issues were detected that may cause platform-specific failures.
Review the detailed log for specific problems and resolve them before proceeding.

Validation Log: ${results_file}.log

EOF
    ;;
  "warning")
    cat <<EOF

⚠️  Cross-Platform Validation Warnings

Some platform compatibility issues were detected that may affect functionality.
These issues are not critical but should be reviewed.

Validation Log: ${results_file}.log

EOF
    ;;
  "success")
    cat <<EOF

✅ Cross-Platform Validation Successful

All platform compatibility checks passed successfully.
The system appears to be properly configured for cross-platform operation.

EOF
    ;;
  esac

  # Show summary if available
  if [ -f "$results_file" ] && command -v jq >/dev/null 2>&1; then
    echo "Validation Summary:"
    jq -r '.summary | "  Total Checks: \(.total_checks), Passed: \(.passed), Failed: \(.failed), Warnings: \(.warnings)"' "$results_file" 2>/dev/null || true
    echo ""
  fi
}

# System state management functions
capture_system_state() {
  local state_id="${1:-$(date +%s)}"
  local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/system_state_${state_id}.json"

  mkdir -p "$(dirname "$state_file")"

  # Capture current system state
  cat >"$state_file" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "state_id": "$state_id",
  "platform": "${PLATFORM_TYPE:-unknown}",
  "system_type": "${SYSTEM_TYPE:-unknown}",
  "working_directory": "$PWD",
  "git_status": "$(git status --porcelain 2>/dev/null || echo 'not_a_git_repo')",
  "result_symlink": "$(readlink result 2>/dev/null || echo 'none')",
  "user": "${USER:-unknown}",
  "environment": {
    "PATH": "$PATH",
    "NIXPKGS_ALLOW_UNFREE": "${NIXPKGS_ALLOW_UNFREE:-unset}"
  }
}
EOF

  echo "$state_file"
}

restore_system_state() {
  local state_file="$1"

  if [ ! -f "$state_file" ]; then
    log_error "State file not found: $state_file"
    return 1
  fi

  log_info "Restoring system state from: $state_file"

  # Extract state information (basic implementation)
  if command -v jq >/dev/null 2>&1; then
    local original_dir=$(jq -r '.working_directory' "$state_file")
    if [ "$original_dir" != "$PWD" ]; then
      log_info "Changing directory to: $original_dir"
      cd "$original_dir" || return 1
    fi
  fi

  log_info "System state restoration completed"
  return 0
}

manage_state_transition() {
  local from_state="$1"
  local to_state="$2"
  local operation="${3:-build}"

  log_debug "Managing state transition: $from_state -> $to_state ($operation)"

  # Capture current state before transition
  local state_file=$(capture_system_state "transition_${operation}")

  case "$operation" in
  "build")
    log_info "Managing build state transition"
    ;;
  "switch")
    log_info "Managing switch state transition"
    ;;
  "rollback")
    log_info "Managing rollback state transition"
    ;;
  *)
    log_warning "Unknown operation: $operation"
    ;;
  esac

  return 0
}

detect_concurrent_operations() {
  local lock_file="${XDG_RUNTIME_DIR:-/tmp}/build-switch.lock"

  if [ -f "$lock_file" ]; then
    local pid=$(cat "$lock_file")
    if kill -0 "$pid" 2>/dev/null; then
      log_warning "Concurrent build-switch operation detected (PID: $pid)"
      return 1
    else
      log_info "Removing stale lock file"
      rm -f "$lock_file"
    fi
  fi

  # Create lock file
  echo $$ >"$lock_file"

  # Register cleanup on exit
  trap "rm -f '$lock_file'" EXIT

  return 0
}

validate_system_state() {
  local validation_mode="${1:-basic}"

  log_debug "Validating system state (mode: $validation_mode)"

  # Basic validation
  if [ -z "$PLATFORM_TYPE" ]; then
    log_error "PLATFORM_TYPE not set"
    return 1
  fi

  if [ -z "$SYSTEM_TYPE" ]; then
    log_error "SYSTEM_TYPE not set"
    return 1
  fi

  # Extended validation
  if [ "$validation_mode" = "extended" ]; then
    if [ ! -f "flake.nix" ]; then
      log_error "flake.nix not found in current directory"
      return 1
    fi

    if ! command -v nix >/dev/null 2>&1; then
      log_error "nix command not available"
      return 1
    fi
  fi

  log_debug "System state validation passed"
  return 0
}

# Performance regression detection functions
establish_performance_baseline() {
  local baseline_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance_baseline.json"
  local current_metrics="$1"

  mkdir -p "$(dirname "$baseline_file")"

  # Create or update baseline
  if [ ! -f "$baseline_file" ]; then
    log_info "Creating initial performance baseline"
    cat >"$baseline_file" <<EOF
{
  "created": "$(date -Iseconds)",
  "updated": "$(date -Iseconds)",
  "baseline_metrics": {
    "build_time": ${current_metrics:-90},
    "memory_usage": 1000,
    "cache_hit_rate": 0.5,
    "cpu_usage": 0.8
  },
  "thresholds": {
    "build_time_regression": 1.2,
    "memory_regression": 1.5,
    "cache_hit_degradation": 0.8,
    "cpu_usage_increase": 1.3
  }
}
EOF
  else
    log_info "Updating performance baseline"
    # Update existing baseline (basic implementation)
    local temp_file=$(mktemp)
    sed "s/\"updated\": \"[^\"]*\"/\"updated\": \"$(date -Iseconds)\"/" "$baseline_file" >"$temp_file"
    mv "$temp_file" "$baseline_file"
  fi

  echo "$baseline_file"
}

start_performance_monitoring() {
  local monitoring_id="${1:-$(date +%s)}"
  local monitoring_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance_monitoring_${monitoring_id}.json"

  mkdir -p "$(dirname "$monitoring_file")"

  # Start monitoring
  cat >"$monitoring_file" <<EOF
{
  "monitoring_id": "$monitoring_id",
  "started": "$(date -Iseconds)",
  "status": "active",
  "start_time": $(date +%s),
  "start_memory": $(ps -o rss= -p $$ 2>/dev/null || echo "0"),
  "start_cpu": $(ps -o %cpu= -p $$ 2>/dev/null || echo "0")
}
EOF

  echo "$monitoring_file"
}

stop_performance_monitoring() {
  local monitoring_file="$1"

  if [ ! -f "$monitoring_file" ]; then
    log_error "Monitoring file not found: $monitoring_file"
    return 1
  fi

  # Stop monitoring and calculate metrics
  local end_time=$(date +%s)
  local end_memory=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
  local end_cpu=$(ps -o %cpu= -p $$ 2>/dev/null || echo "0")

  # Update monitoring file with end metrics
  local temp_file=$(mktemp)
  sed 's/"status": "active"/"status": "completed"/' "$monitoring_file" |
    sed "s/}/,\"end_time\": $end_time, \"end_memory\": $end_memory, \"end_cpu\": $end_cpu}/" >"$temp_file"
  mv "$temp_file" "$monitoring_file"

  log_info "Performance monitoring stopped"
  return 0
}

detect_performance_regression() {
  local current_metrics_file="$1"
  local baseline_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance_baseline.json"

  if [ ! -f "$baseline_file" ]; then
    log_warning "No performance baseline found, creating one"
    establish_performance_baseline
    return 0
  fi

  if [ ! -f "$current_metrics_file" ]; then
    log_error "Current metrics file not found: $current_metrics_file"
    return 1
  fi

  log_info "Detecting performance regression"

  # Basic regression detection (simplified)
  if command -v jq >/dev/null 2>&1; then
    local baseline_build_time=$(jq -r '.baseline_metrics.build_time' "$baseline_file" 2>/dev/null || echo "90")
    local threshold=$(jq -r '.thresholds.build_time_regression' "$baseline_file" 2>/dev/null || echo "1.2")

    # Calculate current build time from monitoring file
    local start_time=$(jq -r '.start_time' "$current_metrics_file" 2>/dev/null || echo "0")
    local end_time=$(jq -r '.end_time' "$current_metrics_file" 2>/dev/null || echo "0")
    local current_build_time=$((end_time - start_time))

    # Check for regression
    if [ "$current_build_time" -gt 0 ] && [ "$baseline_build_time" -gt 0 ]; then
      local regression_ratio=$(echo "scale=2; $current_build_time / $baseline_build_time" | bc 2>/dev/null || echo "1.0")

      if [ "$(echo "$regression_ratio > $threshold" | bc 2>/dev/null)" = "1" ]; then
        log_warning "Performance regression detected: build time increased by ${regression_ratio}x"
        return 1
      fi
    fi
  fi

  log_info "No performance regression detected"
  return 0
}

generate_performance_report() {
  local monitoring_file="$1"
  local report_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance_report_$(date +%s).json"

  mkdir -p "$(dirname "$report_file")"

  if [ ! -f "$monitoring_file" ]; then
    log_error "Monitoring file not found: $monitoring_file"
    return 1
  fi

  # Generate performance report
  cat >"$report_file" <<EOF
{
  "report_generated": "$(date -Iseconds)",
  "monitoring_data": $(cat "$monitoring_file"),
  "analysis": {
    "status": "completed",
    "regression_detected": false,
    "recommendations": []
  }
}
EOF

  log_info "Performance report generated: $report_file"
  echo "$report_file"
}

trigger_performance_alert() {
  local alert_type="$1"
  local alert_message="$2"
  local alert_file="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/performance_alert_$(date +%s).json"

  mkdir -p "$(dirname "$alert_file")"

  # Create alert
  cat >"$alert_file" <<EOF
{
  "alert_type": "$alert_type",
  "message": "$alert_message",
  "timestamp": "$(date -Iseconds)",
  "severity": "warning",
  "acknowledged": false
}
EOF

  # Log alert
  case "$alert_type" in
  "regression")
    log_warning "PERFORMANCE ALERT: $alert_message"
    ;;
  "degradation")
    log_warning "PERFORMANCE DEGRADATION: $alert_message"
    ;;
  *)
    log_info "PERFORMANCE NOTIFICATION: $alert_message"
    ;;
  esac

  echo "$alert_file"
}

# Security and edge case handling functions
validate_input_parameters() {
  local param_name="$1"
  local param_value="$2"
  local validation_type="${3:-basic}"

  log_debug "Validating input parameter: $param_name (type: $validation_type)"

  # Basic validation
  case "$validation_type" in
  "path")
    # Path validation
    if [[ $param_value =~ \.\./|\.\.\\ ]]; then
      log_error "Path traversal attempt detected in $param_name: $param_value"
      return 1
    fi
    ;;
  "system_type")
    # System type validation
    if [[ ! $param_value =~ ^[a-zA-Z0-9_-]+$ ]]; then
      log_error "Invalid system type format: $param_value"
      return 1
    fi
    ;;
  "command")
    # Command validation
    if [[ $param_value =~ [\;\&\|'\`'\$\(\)] ]]; then
      log_error "Potentially dangerous command detected: $param_value"
      return 1
    fi
    ;;
  *)
    # Basic string validation
    if [ ${#param_value} -gt 1000 ]; then
      log_error "Parameter value too long: $param_name"
      return 1
    fi
    ;;
  esac

  log_debug "Input parameter validation passed: $param_name"
  return 0
}

prevent_path_traversal() {
  local input_path="$1"
  local base_path="${2:-$PWD}"

  # Normalize path
  local normalized_path=$(realpath "$input_path" 2>/dev/null || echo "$input_path")
  local normalized_base=$(realpath "$base_path" 2>/dev/null || echo "$base_path")

  # Check if path is within base directory
  if [[ $normalized_path != "$normalized_base"* ]]; then
    log_error "Path traversal attempt detected: $input_path"
    return 1
  fi

  # Check for dangerous patterns
  if [[ $input_path =~ \.\./|\.\.\\ ]]; then
    log_error "Path traversal pattern detected: $input_path"
    return 1
  fi

  log_debug "Path traversal check passed: $input_path"
  return 0
}

check_privilege_escalation() {
  local current_user="$USER"
  local effective_uid=$(id -u)
  local real_uid=$(id -ru)

  log_debug "Checking privilege escalation: user=$current_user, euid=$effective_uid, ruid=$real_uid"

  # Check for unexpected privilege escalation
  if [ "$effective_uid" -eq 0 ] && [ "$real_uid" -ne 0 ]; then
    log_warning "Privilege escalation detected: running as root but started as user $real_uid"

    # Check if this is expected (via sudo)
    if [ -z "${SUDO_USER:-}" ]; then
      log_error "Unexpected privilege escalation - no SUDO_USER set"
      return 1
    fi
  fi

  # Check for setuid/setgid executables
  if command -v find >/dev/null 2>&1; then
    local suspicious_files=$(find . -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -5)
    if [ -n "$suspicious_files" ]; then
      log_warning "Setuid/setgid files detected in current directory:"
      echo "$suspicious_files" | while read -r file; do
        log_warning "  - $file"
      done
    fi
  fi

  log_debug "Privilege escalation check passed"
  return 0
}

monitor_resource_usage() {
  local monitoring_type="${1:-basic}"
  local pid="${2:-$$}"

  log_debug "Monitoring resource usage: type=$monitoring_type, pid=$pid"

  # Check memory usage
  if command -v ps >/dev/null 2>&1; then
    local memory_mb=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print int($1/1024)}')
    if [ "$memory_mb" -gt 2000 ]; then
      log_warning "High memory usage detected: ${memory_mb}MB"
    fi
  fi

  # Check CPU usage
  if command -v ps >/dev/null 2>&1; then
    local cpu_usage=$(ps -o %cpu= -p "$pid" 2>/dev/null | awk '{print int($1)}')
    if [ "$cpu_usage" -gt 80 ]; then
      log_warning "High CPU usage detected: ${cpu_usage}%"
    fi
  fi

  # Check disk usage
  if command -v df >/dev/null 2>&1; then
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
      log_warning "High disk usage detected: ${disk_usage}%"
    fi
  fi

  log_debug "Resource usage monitoring completed"
  return 0
}

detect_malicious_symlinks() {
  local check_path="${1:-.}"
  local max_depth="${2:-3}"

  log_debug "Detecting malicious symlinks in: $check_path (depth: $max_depth)"

  if ! command -v find >/dev/null 2>&1; then
    log_warning "find command not available, skipping symlink detection"
    return 0
  fi

  # Check for symlinks pointing outside the project
  local suspicious_links=$(find "$check_path" -maxdepth "$max_depth" -type l 2>/dev/null | while read -r link; do
    local target=$(readlink "$link" 2>/dev/null || echo "")
    if [ -n "$target" ]; then
      # Check for absolute paths outside expected directories
      if [[ $target =~ ^/etc/|^/usr/bin/|^/bin/|^/sbin/ ]]; then
        echo "$link -> $target"
      fi
      # Check for path traversal in symlinks
      if [[ $target =~ \.\./|\.\.\\ ]]; then
        echo "$link -> $target (traversal)"
      fi
    fi
  done)

  if [ -n "$suspicious_links" ]; then
    log_warning "Suspicious symlinks detected:"
    echo "$suspicious_links" | while read -r link; do
      log_warning "  - $link"
    done
    return 1
  fi

  log_debug "Malicious symlink detection completed - no issues found"
  return 0
}

sanitize_environment() {
  local sanitization_level="${1:-standard}"

  log_debug "Sanitizing environment: level=$sanitization_level"

  # List of potentially dangerous environment variables
  local dangerous_vars="IFS CDPATH ENV BASH_ENV GLOBIGNORE"

  # Clear dangerous variables
  for var in $dangerous_vars; do
    # Use eval to safely check if variable is set
    if eval "[ -n \"\${${var}:-}\" ]"; then
      log_warning "Clearing potentially dangerous environment variable: $var"
      unset "$var"
    fi
  done

  # Sanitize PATH
  if [ "$sanitization_level" = "strict" ]; then
    log_info "Applying strict PATH sanitization"
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
  else
    # Remove current directory from PATH if present
    export PATH=$(echo "$PATH" | sed 's/:\.:/:/g' | sed 's/^\.://' | sed 's/:\.$//')
  fi

  # Ensure essential variables are set
  if [ -z "${USER:-}" ]; then
    export USER=$(whoami 2>/dev/null || echo "unknown")
  fi

  if [ -z "${HOME:-}" ]; then
    HOME=$(eval echo ~$USER 2>/dev/null || echo "/tmp")
    export HOME
  fi

  log_debug "Environment sanitization completed"
  return 0
}

# Main build-switch logic loaded
# Platform-specific scripts will call execute_build_switch directly
