#!/bin/sh
# unified-error-handling.sh - Unified error handling system for all scripts
# Centralizes error processing, logging, and recovery guidance across the entire build system

# Import dependencies
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(dirname "$0")")}"
. "${SCRIPTS_DIR}/lib/unified-colors.sh"

# Global configuration
ERROR_REPORT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/error-reports"
ERROR_MESSAGE_FORMAT="${ERROR_MESSAGE_FORMAT:-console}"
INTERACTIVE_GUIDANCE="${INTERACTIVE_GUIDANCE:-false}"
ERROR_CONFIG_FILE="${CONFIG_DIR:-./config}/error-handling.yaml"

# Initialize error handling system
init_error_handling() {
    # Create error report directory
    mkdir -p "$ERROR_REPORT_DIR"

    # Load error handling configuration if available
    if [ -f "$ERROR_CONFIG_FILE" ]; then
        unified_log_debug "Loading error handling configuration from: $ERROR_CONFIG_FILE" "INIT"
    else
        unified_log_debug "Using default error handling configuration" "INIT"
    fi

    # Set up signal handlers for graceful error handling
    trap 'unified_cleanup_on_error $? "$LINENO"' EXIT
    trap 'unified_handle_interrupt' INT TERM
}

# Unified error logging function - replaces all log_error/print_error functions
unified_log_error() {
    local message="$1"
    local context="${2:-GENERAL}"
    local severity="${3:-medium}"
    local show_guidance="${4:-true}"

    # Format error with context tag and colors
    local formatted_message="${ERROR_COLOR}❌ [$context] $message${NC}"

    # Output to stderr with timestamp
    echo "$(date '+%H:%M:%S') $formatted_message" >&2

    # Log to persistent error log if available
    if [ -n "$ERROR_LOG_FILE" ]; then
        echo "$(date -Iseconds) [$context] ERROR: $message" >> "$ERROR_LOG_FILE"
    fi

    # Generate diagnostic report for medium/high severity errors
    if [ "$severity" != "low" ] && [ "$show_guidance" = "true" ]; then
        local report_file="$ERROR_REPORT_DIR/error_$(date +%Y%m%d_%H%M%S)_$$.txt"
        generate_error_report "$context" "$message" "$severity" "$report_file"

        # Show immediate guidance for high severity errors
        if [ "$severity" = "high" ]; then
            show_immediate_guidance "$context" "$message"
        fi
    fi
}

# Unified warning function
unified_log_warning() {
    local message="$1"
    local context="${2:-GENERAL}"

    echo "${WARNING_COLOR}⚠️  [$context] $message${NC}" >&2

    if [ -n "$ERROR_LOG_FILE" ]; then
        echo "$(date -Iseconds) [$context] WARNING: $message" >> "$ERROR_LOG_FILE"
    fi
}

# Unified success logging
unified_log_success() {
    local message="$1"
    local context="${2:-GENERAL}"

    echo "${SUCCESS_COLOR}✅ [$context] $message${NC}"

    if [ -n "$SUCCESS_LOG_FILE" ]; then
        echo "$(date -Iseconds) [$context] SUCCESS: $message" >> "$SUCCESS_LOG_FILE"
    fi
}

# Unified info logging
unified_log_info() {
    local message="$1"
    local context="${2:-GENERAL}"
    local use_color="${3:-true}"

    if [ "$use_color" = "true" ]; then
        echo "${INFO_COLOR}ℹ️  [$context] $message${NC}"
    else
        echo "[$context] $message"
    fi

    if [ -n "$INFO_LOG_FILE" ]; then
        echo "$(date -Iseconds) [$context] INFO: $message" >> "$INFO_LOG_FILE"
    fi
}

# Unified debug logging
unified_log_debug() {
    local message="$1"
    local context="${2:-GENERAL}"

    if [ "$VERBOSE" = "true" ] || [ "$DEBUG" = "true" ]; then
        echo "${DEBUG_COLOR}🔍 [$context] $message${NC}" >&2
    fi

    if [ -n "$DEBUG_LOG_FILE" ]; then
        echo "$(date -Iseconds) [$context] DEBUG: $message" >> "$DEBUG_LOG_FILE"
    fi
}

# Unified retry operation function - consolidates all retry logic
unified_retry_operation() {
    local operation_cmd="$1"
    local max_attempts="${2:-3}"
    local delay="${3:-2}"
    local context="${4:-RETRY}"
    local should_escalate="${5:-true}"

    local attempt=1
    local exit_code=0

    unified_log_info "Starting operation with retry logic (max: $max_attempts attempts)" "$context"

    while [ $attempt -le $max_attempts ]; do
        unified_log_debug "Attempt $attempt of $max_attempts: $operation_cmd" "$context"

        # Execute the operation
        if eval "$operation_cmd"; then
            unified_log_success "Operation succeeded on attempt $attempt" "$context"
            return 0
        else
            exit_code=$?
            unified_log_warning "Attempt $attempt failed (exit code: $exit_code)" "$context"

            # Don't wait after the last attempt
            if [ $attempt -lt $max_attempts ]; then
                unified_log_info "Waiting ${delay}s before retry..." "$context"
                sleep "$delay"
            fi
        fi

        attempt=$((attempt + 1))
    done

    # All attempts failed
    unified_log_error "Operation failed after $max_attempts attempts" "$context" "high"

    # Provide escalation guidance if enabled
    if [ "$should_escalate" = "true" ]; then
        show_retry_escalation_guidance "$operation_cmd" "$max_attempts" "$exit_code" "$context"
    fi

    return $exit_code
}

# Generate comprehensive error report
generate_error_report() {
    local context="$1"
    local error_message="$2"
    local severity="$3"
    local output_file="$4"

    unified_log_debug "Generating error report: $output_file" "ERROR_REPORT"

    # Create report directory if needed
    mkdir -p "$(dirname "$output_file")"

    # Generate unique report ID
    local report_id="$(date +%Y%m%d_%H%M%S)_$$"
    local timestamp=$(date -Iseconds)

    cat > "$output_file" << EOF
=== ERROR DIAGNOSTIC REPORT ===
Report ID: $report_id
Timestamp: $timestamp
Context: $context
Severity: $severity
Platform: ${PLATFORM_TYPE:-unknown}
System: ${SYSTEM_TYPE:-unknown}

=== ERROR DETAILS ===
$error_message

=== SYSTEM ENVIRONMENT ===
Working Directory: $PWD
User: ${USER:-$(whoami 2>/dev/null || echo unknown)}
Shell: ${SHELL:-unknown}
Hostname: ${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}

=== NIX ENVIRONMENT ===
EOF

    # Add Nix-specific diagnostics
    {
        echo "Nix Version: $(nix --version 2>/dev/null || echo 'not available')"
        echo "Flake Support: $(nix --extra-experimental-features 'nix-command flakes' --help >/dev/null 2>&1 && echo 'enabled' || echo 'disabled')"
        echo "Disk Space: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo 'unknown')"
        echo "Nix Store: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'unknown')"
        echo "Build Cache: $(du -sh ~/.cache/nix 2>/dev/null | cut -f1 || echo 'unknown')"

        if [ -f flake.lock ]; then
            echo "Flake Lock: present"
        else
            echo "Flake Lock: missing"
        fi

        # Platform-specific tools
        case "${PLATFORM_TYPE:-}" in
            "darwin")
                echo "darwin-rebuild: $(command -v darwin-rebuild >/dev/null && echo 'available' || echo 'not found')"
                ;;
            "linux")
                echo "nixos-rebuild: $(command -v nixos-rebuild >/dev/null && echo 'available' || echo 'not found')"
                ;;
        esac

    } >> "$output_file"

    # Add context-specific diagnostics
    add_context_diagnostics "$context" "$output_file"

    # Add recovery recommendations
    add_recovery_recommendations "$context" "$error_message" "$output_file"

    unified_log_info "Error report saved: $output_file" "ERROR_REPORT"
}

# Add context-specific diagnostic information
add_context_diagnostics() {
    local context="$1"
    local output_file="$2"

    echo "" >> "$output_file"
    echo "=== CONTEXT-SPECIFIC DIAGNOSTICS ===" >> "$output_file"

    case "$context" in
        "BUILD"|"DARWIN_BUILD"|"NIXOS_BUILD")
            {
                echo "Build Environment Analysis:"
                echo "- Build Type: ${BUILD_TYPE:-default}"
                echo "- User Mode Only: ${USER_MODE_ONLY:-false}"
                echo "- Offline Mode: ${OFFLINE_MODE:-false}"
                echo "- Emergency Mode: ${EMERGENCY_MODE:-false}"
                echo "- Max Jobs: ${NIX_MAX_JOBS:-auto}"
                echo "- Cores: ${NIX_CORES:-auto}"
            } >> "$output_file"
            ;;
        "TEST"|"UNIT_TEST"|"INTEGRATION_TEST"|"E2E_TEST")
            {
                echo "Test Environment Analysis:"
                echo "- Test Type: ${TEST_TYPE:-unknown}"
                echo "- Test Mode: ${TEST_MODE:-normal}"
                echo "- Parallel Tests: ${PARALLEL_TESTS:-true}"
                echo "- Test Timeout: ${TEST_TIMEOUT:-300}"
            } >> "$output_file"
            ;;
        "AUTO_UPDATE"|"FLAKE_UPDATE")
            {
                echo "Update Environment Analysis:"
                echo "- Auto Update: ${AUTO_UPDATE:-false}"
                echo "- Update Strategy: ${UPDATE_STRATEGY:-conservative}"
                echo "- Backup Enabled: ${BACKUP_ENABLED:-true}"
                echo "- Network Mode: ${NETWORK_MODE:-online}"
            } >> "$output_file"
            ;;
        "NETWORK"|"CACHE"|"SUBSTITUTER")
            {
                echo "Network Environment Analysis:"
                echo "- Internet: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo 'online' || echo 'offline')"
                echo "- DNS: $(nslookup google.com >/dev/null 2>&1 && echo 'working' || echo 'failed')"
                echo "- Proxy: ${HTTP_PROXY:-none} / ${HTTPS_PROXY:-none}"
                echo "- Substituters: ${NIX_CONFIG:-default}"
            } >> "$output_file"
            ;;
    esac
}

# Add recovery recommendations based on context
add_recovery_recommendations() {
    local context="$1"
    local error_message="$2"
    local output_file="$3"

    echo "" >> "$output_file"
    echo "=== RECOVERY RECOMMENDATIONS ===" >> "$output_file"

    case "$context" in
        "BUILD"|"DARWIN_BUILD"|"NIXOS_BUILD")
            cat >> "$output_file" << 'EOF'
BUILD FAILURE RECOVERY:
1. [IMMEDIATE] Clean and retry:
   nix-collect-garbage -d
   rm -rf ~/.cache/nix
   retry build with --show-trace

2. [ALTERNATIVE] Try different build modes:
   export BUILD_TYPE=minimal && retry
   export USER_MODE_ONLY=true && retry
   export OFFLINE_MODE=true && retry

3. [ADVANCED] Dependency management:
   nix flake update
   nix flake check
   nix build --refresh

4. [FALLBACK] Component-wise building:
   nix build .#homeConfigurations.${USER}
   nix build .#darwinConfigurations.${HOSTNAME}
EOF
            ;;
        "NETWORK"|"CACHE"|"SUBSTITUTER")
            cat >> "$output_file" << 'EOF'
NETWORK FAILURE RECOVERY:
1. [IMMEDIATE] Enable offline mode:
   export OFFLINE_MODE=true
   export NIX_CONFIG="substituters = "

2. [CONNECTIVITY] Test and diagnose:
   ping -c 3 google.com
   nslookup cache.nixos.org
   curl -I https://cache.nixos.org

3. [ALTERNATIVES] Use different sources:
   export NIX_CONFIG="substituters = https://mirror.nixos.org/nix-cache"
   cachix use <alternative-cache>

4. [FALLBACK] Build from source:
   nix build --option substitute false
   nix build --offline
EOF
            ;;
        "TEST"|"UNIT_TEST"|"INTEGRATION_TEST"|"E2E_TEST")
            cat >> "$output_file" << 'EOF'
TEST FAILURE RECOVERY:
1. [IMMEDIATE] Run single test:
   Run specific failing test in isolation
   Check test dependencies and setup

2. [ENVIRONMENT] Verify test environment:
   Ensure test data is available
   Check test configuration files
   Verify test permissions

3. [DEBUGGING] Enable debug mode:
   export TEST_DEBUG=true
   export VERBOSE=true
   Run with --show-trace

4. [FALLBACK] Skip problematic tests:
   export SKIP_FAILING_TESTS=true
   Run core tests only
EOF
            ;;
    esac

    # Add error-specific recommendations
    if echo "$error_message" | grep -qi "permission"; then
        echo "" >> "$output_file"
        echo "PERMISSION-SPECIFIC RECOMMENDATIONS:" >> "$output_file"
        echo "- Try user-only mode: export USER_MODE_ONLY=true" >> "$output_file"
        echo "- Check sudo access: sudo -v" >> "$output_file"
        echo "- Use home-manager: home-manager switch --flake ." >> "$output_file"
    fi

    if echo "$error_message" | grep -qi "space\|disk"; then
        echo "" >> "$output_file"
        echo "DISK SPACE RECOMMENDATIONS:" >> "$output_file"
        echo "- Free space: nix-collect-garbage -d" >> "$output_file"
        echo "- Clean Docker: docker system prune -af" >> "$output_file"
        echo "- Check usage: du -sh ~/.cache/nix" >> "$output_file"
    fi
}

# Show immediate guidance for high-severity errors
show_immediate_guidance() {
    local context="$1"
    local error_message="$2"

    echo "" >&2
    echo "${HIGHLIGHT_COLOR}🚨 IMMEDIATE ACTION REQUIRED${NC}" >&2
    echo "${ERROR_COLOR}Context: $context${NC}" >&2
    echo "${ERROR_COLOR}Error: $error_message${NC}" >&2
    echo "" >&2

    case "$context" in
        "BUILD"|"DARWIN_BUILD"|"NIXOS_BUILD")
            echo "${INFO_COLOR}Quick fixes to try:${NC}" >&2
            echo "${INFO_COLOR}  1. nix-collect-garbage -d${NC}" >&2
            echo "${INFO_COLOR}  2. export USER_MODE_ONLY=true && retry${NC}" >&2
            echo "${INFO_COLOR}  3. export OFFLINE_MODE=true && retry${NC}" >&2
            ;;
        "NETWORK"|"CACHE")
            echo "${INFO_COLOR}Quick fixes to try:${NC}" >&2
            echo "${INFO_COLOR}  1. ping google.com (test connectivity)${NC}" >&2
            echo "${INFO_COLOR}  2. export OFFLINE_MODE=true && retry${NC}" >&2
            echo "${INFO_COLOR}  3. nix build --offline${NC}" >&2
            ;;
        "TEST")
            echo "${INFO_COLOR}Quick fixes to try:${NC}" >&2
            echo "${INFO_COLOR}  1. Run single test to isolate issue${NC}" >&2
            echo "${INFO_COLOR}  2. export TEST_DEBUG=true && retry${NC}" >&2
            echo "${INFO_COLOR}  3. Check test data and dependencies${NC}" >&2
            ;;
    esac

    echo "" >&2
}

# Show escalation guidance after retry failures
show_retry_escalation_guidance() {
    local operation_cmd="$1"
    local max_attempts="$2"
    local final_exit_code="$3"
    local context="$4"

    echo "" >&2
    echo "${ERROR_COLOR}🔄 RETRY ESCALATION GUIDANCE${NC}" >&2
    echo "${ERROR_COLOR}Operation: $operation_cmd${NC}" >&2
    echo "${ERROR_COLOR}Failed after: $max_attempts attempts${NC}" >&2
    echo "${ERROR_COLOR}Final exit code: $final_exit_code${NC}" >&2
    echo "" >&2

    echo "${INFO_COLOR}Escalation options:${NC}" >&2
    echo "${INFO_COLOR}  1. Increase retry attempts: unified_retry_operation \"$operation_cmd\" 5${NC}" >&2
    echo "${INFO_COLOR}  2. Add delay between retries: unified_retry_operation \"$operation_cmd\" 3 5${NC}" >&2
    echo "${INFO_COLOR}  3. Try alternative approach based on context${NC}" >&2
    echo "${INFO_COLOR}  4. Check detailed error report for root cause${NC}" >&2
    echo "" >&2
}

# Handle interrupt signals gracefully
unified_handle_interrupt() {
    unified_log_warning "Received interrupt signal - cleaning up..." "SIGNAL"

    # Perform any necessary cleanup
    if [ -n "$CLEANUP_FUNCTION" ] && command -v "$CLEANUP_FUNCTION" >/dev/null; then
        unified_log_info "Running cleanup function: $CLEANUP_FUNCTION" "SIGNAL"
        "$CLEANUP_FUNCTION"
    fi

    unified_log_info "Cleanup completed - exiting" "SIGNAL"
    exit 130
}

# Cleanup on error/exit
unified_cleanup_on_error() {
    local exit_code="$1"
    local line_number="$2"

    # Only run cleanup on non-zero exit codes
    if [ "$exit_code" -ne 0 ]; then
        unified_log_debug "Script exited with code $exit_code at line $line_number" "EXIT"

        # Run any registered cleanup functions
        if [ -n "$CLEANUP_FUNCTION" ] && command -v "$CLEANUP_FUNCTION" >/dev/null; then
            unified_log_debug "Running cleanup function: $CLEANUP_FUNCTION" "EXIT"
            "$CLEANUP_FUNCTION"
        fi
    fi
}

# Export all unified functions for use by other scripts
export -f init_error_handling
export -f unified_log_error
export -f unified_log_warning
export -f unified_log_success
export -f unified_log_info
export -f unified_log_debug
export -f unified_retry_operation
export -f generate_error_report
export -f show_immediate_guidance
export -f unified_handle_interrupt
export -f unified_cleanup_on_error

# Backwards compatibility aliases for existing scripts
alias log_error='unified_log_error'
alias print_error='unified_log_error'
alias log_warning='unified_log_warning'
alias log_success='unified_log_success'
alias log_info='unified_log_info'
alias log_debug='unified_log_debug'
alias retry_operation='unified_retry_operation'

# Initialize error handling when this script is sourced
init_error_handling
