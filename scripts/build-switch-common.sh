#!/bin/sh -e

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

# Load all modules
. "$LIB_DIR/logging.sh"
. "$LIB_DIR/performance.sh"
. "$LIB_DIR/progress.sh"
. "$LIB_DIR/optimization.sh"
. "$LIB_DIR/sudo-management.sh"
. "$LIB_DIR/cache-management.sh"
. "$LIB_DIR/flake-evaluation.sh"
. "$LIB_DIR/network-detection.sh"
. "$LIB_DIR/state-persistence.sh"
. "$LIB_DIR/build-logic.sh"
. "$LIB_DIR/scenario-orchestrator.sh"
. "$LIB_DIR/performance-monitor.sh"
. "$LIB_DIR/audit-logger.sh"

# Load Phase 3 modules - Enhanced validation and error handling
. "$LIB_DIR/pre-validation.sh"
. "$LIB_DIR/alternative-execution.sh"
. "$LIB_DIR/error-messaging.sh"

# Load Phase 4 modules - Performance optimization and monitoring
. "$LIB_DIR/cache-optimization.sh"
. "$LIB_DIR/performance-dashboard.sh"
. "$LIB_DIR/notification-auto-recovery.sh"

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
    cat > "$validation_results_file" << EOF
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
    sed "s/\"total_checks\": 0/\"total_checks\": $total_checks/" "$validation_results_file" | \
    sed "s/\"passed\": 0/\"passed\": $passed_count/" | \
    sed "s/\"failed\": 0/\"failed\": $failed_count/" | \
    sed "s/\"warnings\": 0/\"warnings\": $warning_count/" > "$temp_file"
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
        eval "local var_value=\${$var:-}"
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
    } >> "${results_file}.log"

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

        echo "test" > "$test_file"
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
    } >> "${results_file}.log"

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
    } >> "${results_file}.log"

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
    if ! echo "test" > "$test_file" 2>/dev/null; then
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
    } >> "${results_file}.log"

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
    } >> "${results_file}.log"

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
    } >> "${results_file}.log"

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
            cat << EOF

🚨 Cross-Platform Validation Failed

Critical issues were detected that may cause platform-specific failures.
Review the detailed log for specific problems and resolve them before proceeding.

Validation Log: ${results_file}.log

EOF
            ;;
        "warning")
            cat << EOF

⚠️  Cross-Platform Validation Warnings

Some platform compatibility issues were detected that may affect functionality.
These issues are not critical but should be reviewed.

Validation Log: ${results_file}.log

EOF
            ;;
        "success")
            cat << EOF

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
    cat > "$state_file" << EOF
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
    echo $$ > "$lock_file"

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

# Main build-switch logic loaded
# Platform-specific scripts will call execute_build_switch directly
