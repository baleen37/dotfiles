#!/usr/bin/env bash
# Sudo Management Module for Build Scripts
# Contains privilege management and sudo-related functions

# Sudo session management
#
# This module implements persistent sudo session management to reduce password prompts
# during long-running build operations. The strategy includes:
#
# 1. Early privilege acquisition with session validation
# 2. Background daemon to refresh sudo session periodically
# 3. Automatic cleanup when build process completes
#
# The refresh interval is set to 4 minutes (240 seconds) which is safely below
# the default sudo timeout of 5 minutes, ensuring the session stays alive.

SUDO_REQUIRED=false
SUDO_REFRESH_PID=""
SUDO_REFRESH_INTERVAL=${SUDO_REFRESH_INTERVAL:-240}  # 4 minutes (configurable via environment)

# Enhanced cleanup function for sudo management
cleanup_sudo_environment() {
    if command -v log_debug >/dev/null 2>&1; then
        log_debug "Starting sudo cleanup process"
    fi

    # Stop sudo refresh daemon
    stop_sudo_refresh_daemon

    # Clean up progress if available
    if command -v progress_cleanup >/dev/null 2>&1; then
        progress_cleanup 2>/dev/null || true
    fi
}

# Set up signal handlers for sudo management
setup_sudo_signal_handlers() {
    trap 'cleanup_sudo_environment; exit 130' INT
    trap 'cleanup_sudo_environment; exit 143' TERM
    trap 'cleanup_sudo_environment' EXIT
}

# Basic sudo management functions
check_current_privileges() {
    [ "$(id -u)" -eq 0 ]
}

acquire_sudo_early() {
    # Set up signal handlers for sudo management
    setup_sudo_signal_handlers

    # Skip if already root
    if check_current_privileges; then
        return 0
    fi

    # Check if we're in non-interactive environment
    if [ ! -t 0 ]; then
        if command -v log_warning >/dev/null 2>&1; then
            log_warning "Non-interactive environment - will attempt passwordless sudo"
        fi
        # Try passwordless sudo first
        if sudo -n true 2>/dev/null; then
            if command -v log_success >/dev/null 2>&1; then
                log_success "Passwordless sudo access confirmed"
            fi
            return 0
        else
            if command -v log_error >/dev/null 2>&1; then
                log_error "Passwordless sudo not available - manual sudo execution required"
            fi
            return 1
        fi
    fi

    # Simple sudo validation
    if ! sudo -v; then
        if command -v log_error >/dev/null 2>&1; then
            log_error "Failed to acquire sudo privileges"
        fi
        return 1
    fi

    # Configure extended sudo session for build process
    configure_sudo_timeout

    # Start background daemon to keep sudo session alive
    start_sudo_refresh_daemon

    if command -v log_success >/dev/null 2>&1; then
        log_success "Sudo privileges acquired with session persistence"
    fi
    return 0
}

# Register cleanup handlers
register_cleanup() {
    return 0
}

# Cleanup sudo session
cleanup_sudo_session() {
    # Stop sudo refresh daemon if running
    stop_sudo_refresh_daemon

    if command -v log_info >/dev/null 2>&1; then
        log_info "Sudo session cleanup completed"
    fi
    return 0
}

# Explain why sudo is required for system changes
explain_sudo_requirement() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}  Administrator Privileges Required${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "${YELLOW}▶ Why sudo is needed:${NC}"
    echo "${DIM}  • System configuration changes require administrator privileges${NC}"
    echo "${DIM}  • ${PLATFORM_NAME} rebuild commands must modify system files${NC}"
    echo "${DIM}  • This ensures your system is properly configured and secure${NC}"
    echo ""
    echo "${YELLOW}▶ What will happen:${NC}"
    echo "${DIM}  • You'll be prompted for your password once${NC}"
    echo "${DIM}  • A background process will keep the session alive during build${NC}"
    echo "${DIM}  • Privileges will be used only for system configuration${NC}"
    echo "${DIM}  • Session will be cleaned up automatically when done${NC}"
    echo ""
}

# Determine if sudo will be needed later
check_sudo_requirement() {
    # Skip if already root
    if check_current_privileges; then
        SUDO_REQUIRED=false
        return 0
    fi

    # Check if we're in non-interactive environment (Claude Code)
    if [ ! -t 0 ]; then
        if command -v log_warning >/dev/null 2>&1; then
            log_warning "Non-interactive environment detected"
        fi
        if command -v log_info >/dev/null 2>&1; then
            log_info "System changes will require manual sudo execution"
        fi
        # Darwin always requires sudo for system activation, even in non-interactive mode
        if [ "$PLATFORM_TYPE" = "darwin" ]; then
            SUDO_REQUIRED=true
        else
            SUDO_REQUIRED=false
        fi
        return 0
    fi

    # Explain why sudo is needed
    explain_sudo_requirement

    SUDO_REQUIRED=true

    # Acquire sudo immediately to avoid duplicate prompts
    if ! acquire_sudo_early; then
        if [ "$PLATFORM_TYPE" = "darwin" ]; then
            # For Darwin, continue without sudo but warn
            log_warning "Administrator privileges not available - build will continue, switch will require manual execution"
            SUDO_REQUIRED=false
            return 0
        else
            return 1
        fi
    fi

    return 0
}

get_sudo_prefix() {
    if [ "$SUDO_REQUIRED" = "true" ]; then
        echo "sudo"
    else
        echo ""
    fi
}

# Configure sudo timeout for extended sessions
configure_sudo_timeout() {
    if [ "$SUDO_REQUIRED" = "true" ] && [ -t 0 ]; then
        # Validate and refresh the current sudo session
        # This ensures the session is active before starting the background daemon
        if sudo -v 2>/dev/null; then
            if command -v log_info >/dev/null 2>&1; then
                log_info "Sudo session validated and configured for extended build process"
            fi
        else
            if command -v log_warning >/dev/null 2>&1; then
                log_warning "Failed to validate sudo session"
            fi
            return 1
        fi
    fi
    return 0
}

# Keep sudo session alive with periodic refresh
keep_sudo_session_alive() {
    if [ "$SUDO_REQUIRED" = "true" ] && [ -t 0 ]; then
        # Refresh sudo session to prevent timeout
        sudo -v 2>/dev/null || true
        if command -v log_debug >/dev/null 2>&1; then
            log_debug "Sudo session refreshed"
        fi
    fi
}

# Start background daemon to refresh sudo session
start_sudo_refresh_daemon() {
    # Only start daemon in interactive environments where sudo was actually acquired
    if [ "$SUDO_REQUIRED" = "true" ] && [ -t 0 ]; then
        # Ensure no existing daemon is running
        stop_sudo_refresh_daemon

        # Start background process to refresh sudo session periodically
        (
            # Set up signal handlers for clean termination
            trap 'exit 0' TERM INT

            # Main refresh loop
            while true; do
                sleep "$SUDO_REFRESH_INTERVAL"

                # Check if parent process still exists
                if ! kill -0 $$ 2>/dev/null; then
                    if command -v log_debug >/dev/null 2>&1; then
                        log_debug "Parent process ended, stopping sudo refresh daemon"
                    fi
                    break
                fi

                # Refresh sudo session (fail silently if sudo expires)
                if ! sudo -v 2>/dev/null; then
                    if command -v log_warning >/dev/null 2>&1; then
                        log_warning "Sudo session expired, stopping refresh daemon"
                    fi
                    break
                fi

                if command -v log_debug >/dev/null 2>&1; then
                    log_debug "Sudo session refreshed successfully"
                fi
            done
        ) &
        SUDO_REFRESH_PID=$!

        if command -v log_info >/dev/null 2>&1; then
            log_info "Sudo session refresh daemon started (PID: $SUDO_REFRESH_PID, interval: ${SUDO_REFRESH_INTERVAL}s)"
        fi
    fi
}

# Stop background sudo refresh daemon
stop_sudo_refresh_daemon() {
    if [ -n "$SUDO_REFRESH_PID" ]; then
        if kill -0 "$SUDO_REFRESH_PID" 2>/dev/null; then
            # Send TERM signal first for graceful shutdown
            kill -TERM "$SUDO_REFRESH_PID" 2>/dev/null || true

            # Wait longer for graceful shutdown
            local wait_count=0
            while [ $wait_count -lt 5 ] && kill -0 "$SUDO_REFRESH_PID" 2>/dev/null; do
                sleep 0.5
                wait_count=$((wait_count + 1))
            done

            # Only force kill if absolutely necessary
            if kill -0 "$SUDO_REFRESH_PID" 2>/dev/null; then
                kill -KILL "$SUDO_REFRESH_PID" 2>/dev/null || true
                # Suppress the "Killed: 9" message by redirecting to null
                wait "$SUDO_REFRESH_PID" 2>/dev/null || true
                if command -v log_debug >/dev/null 2>&1; then
                    log_debug "Sudo refresh daemon force-killed" >&2
                fi
            fi

            if command -v log_info >/dev/null 2>&1; then
                log_info "Sudo session refresh daemon stopped (PID: $SUDO_REFRESH_PID)"
            fi
        else
            if command -v log_debug >/dev/null 2>&1; then
                log_debug "Sudo refresh daemon was not running (PID: $SUDO_REFRESH_PID)"
            fi
        fi
        SUDO_REFRESH_PID=""
    fi
}
