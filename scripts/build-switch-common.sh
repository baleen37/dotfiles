#!/bin/sh -e

# build-switch-common.sh - Shared build and switch logic for all platforms
# This script is sourced by platform-specific build-switch scripts

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
DIM='\033[2m'
NC='\033[0m'

# Environment setup
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8

# Set USER if not already set (Darwin-specific)
if [ -z "$USER" ]; then
    export USER=$(whoami)
fi

# Sudo session management with sudo-helper
SUDO_HELPER_PATH=""
SUDO_REQUIRED=false

# Performance monitoring variables
PERF_START_TIME=""
PERF_BUILD_START_TIME=""
PERF_SWITCH_START_TIME=""
PERF_BUILD_DURATION=""
PERF_SWITCH_DURATION=""

# Parse arguments
VERBOSE=false
for arg in "$@"; do
    if [ "$arg" = "--verbose" ]; then
        VERBOSE=true
        break
    fi
done

# Logging functions
log_header() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}  ${PLATFORM_NAME} Build & Switch${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_step() {
    echo "${YELLOW}▶ $1${NC}"
}

log_info() {
    echo "${DIM}  $1${NC}"
}

log_warning() {
    echo "${YELLOW}⚠ $1${NC}" >&2
}

log_success() {
    echo "${GREEN}✓ $1${NC}"
}

log_error() {
    echo "${RED}✗ $1${NC}" >&2
}

log_footer() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ "$1" = "success" ]; then
        echo "${GREEN}✓ Build & switch completed successfully${NC}"
    else
        echo "${RED}✗ Build & switch failed${NC}"
    fi
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Performance monitoring functions
perf_start_total() {
    PERF_START_TIME=$(date +%s)
}

perf_start_phase() {
    case "$1" in
        "build")
            PERF_BUILD_START_TIME=$(date +%s)
            ;;
        "switch")
            PERF_SWITCH_START_TIME=$(date +%s)
            ;;
    esac
}

perf_end_phase() {
    local end_time=$(date +%s)
    case "$1" in
        "build")
            if [ -n "$PERF_BUILD_START_TIME" ]; then
                PERF_BUILD_DURATION=$((end_time - PERF_BUILD_START_TIME))
                log_info "Build phase completed in ${PERF_BUILD_DURATION}s"
            fi
            ;;
        "switch")
            if [ -n "$PERF_SWITCH_START_TIME" ]; then
                PERF_SWITCH_DURATION=$((end_time - PERF_SWITCH_START_TIME))
                log_info "Switch phase completed in ${PERF_SWITCH_DURATION}s"
            fi
            ;;
    esac
}

perf_show_summary() {
    if [ -n "$PERF_START_TIME" ]; then
        local end_time=$(date +%s)
        local total_duration=$((end_time - PERF_START_TIME))

        echo ""
        echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "${BLUE}  Performance Summary${NC}"
        echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        if [ -n "$PERF_BUILD_DURATION" ] && [ -n "$PERF_SWITCH_DURATION" ]; then
            echo "${DIM}  Build phase:  ${PERF_BUILD_DURATION}s${NC}"
            echo "${DIM}  Switch phase: ${PERF_SWITCH_DURATION}s${NC}"
        fi
        echo "${DIM}  Total time:   ${total_duration}s${NC}"
        echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
}

# Sudo helper integration functions
get_sudo_helper_path() {
    if [ -n "$SUDO_HELPER_PATH" ]; then
        echo "$SUDO_HELPER_PATH"
        return 0
    fi

    # Try to get sudo-helper from nix run
    if command -v nix >/dev/null 2>&1; then
        # Try to get the sudo-helper app path
        SUDO_HELPER_PATH=$(nix eval --impure --raw .#apps.${SYSTEM_TYPE}.sudo-helper.program 2>/dev/null || echo "")
        if [ -n "$SUDO_HELPER_PATH" ] && [ -x "$SUDO_HELPER_PATH" ]; then
            echo "$SUDO_HELPER_PATH"
            return 0
        fi
    fi

    log_error "sudo-helper not found. Please ensure the flake build is working correctly."
    return 1
}

# Sudo management functions using sudo-helper
check_current_privileges() {
    local sudo_helper
    sudo_helper=$(get_sudo_helper_path) || return 1

    "$sudo_helper" check
}

acquire_sudo_early() {
    local sudo_helper
    sudo_helper=$(get_sudo_helper_path) || return 1

    # Use sudo-helper to acquire permissions early
    # This includes explanation, early acquisition, and session management
    "$sudo_helper" acquire
}

# Register cleanup handlers (delegated to sudo-helper)
register_cleanup() {
    # sudo-helper manages its own cleanup via traps
    return 0
}

# Cleanup sudo session (delegated to sudo-helper)
cleanup_sudo_session() {
    local sudo_helper
    if sudo_helper=$(get_sudo_helper_path 2>/dev/null); then
        "$sudo_helper" cleanup 2>/dev/null || true
    fi
}

# Detect optimal number of build jobs for parallelization
detect_optimal_jobs() {
    # Check environment override first
    if [ -n "${NIX_BUILD_JOBS:-}" ]; then
        if [ "$NIX_BUILD_JOBS" -gt 0 ] 2>/dev/null; then
            echo "$NIX_BUILD_JOBS"
            return 0
        fi
    fi

    # Auto-detect based on platform
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    else
        CORES=$(nproc 2>/dev/null || echo 1)
    fi

    # Apply conservative limits for CI environments
    if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
        # In CI: Use at most 2 jobs to prevent resource contention and timeouts
        CORES=$([ "$CORES" -gt 2 ] && echo 2 || echo "$CORES")
        log_info "CI environment detected, limiting parallel jobs to $CORES"
    else
        # Local development: Use more cores but cap at 8 for safety
        CORES=$([ "$CORES" -gt 8 ] && echo 8 || echo "$CORES")
    fi

    # Return cores (minimum 1)
    echo "$([ "$CORES" -gt 0 ] && echo "$CORES" || echo 1)"
}

# Determine if sudo will be needed later
check_sudo_requirement() {
    # Skip if already root
    if check_current_privileges; then
        SUDO_REQUIRED=false
        return 0
    fi

    # Check if sudo-helper is available
    if ! get_sudo_helper_path >/dev/null 2>&1; then
        log_error "sudo-helper not available. Please ensure the flake is built correctly."
        return 1
    fi

    SUDO_REQUIRED=true
    return 0
}

get_sudo_prefix() {
    if [ "$SUDO_REQUIRED" = "true" ]; then
        local sudo_helper
        sudo_helper=$(get_sudo_helper_path) || return 1

        # Get the appropriate sudo prefix from sudo-helper
        "$sudo_helper" prefix
    else
        echo ""
    fi
}

# Execute platform-specific build
run_build() {
    perf_start_phase "build"

    log_step "Building system configuration"
    log_info "Target: ${SYSTEM_TYPE}"
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        log_info "User: ${USER}"
    fi

    # Get optimal job count for parallelization
    JOBS=$(detect_optimal_jobs)
    log_info "Using ${JOBS} parallel jobs for build"

    if [ "$VERBOSE" = "true" ]; then
        nix --extra-experimental-features 'nix-command flakes' build --impure --max-jobs "$JOBS" --cores 0 .#$FLAKE_SYSTEM "$@" || {
            log_error "Build failed"
            log_footer "failed"
            exit 1
        }
    else
        nix --extra-experimental-features 'nix-command flakes' build --impure --max-jobs "$JOBS" --cores 0 .#$FLAKE_SYSTEM "$@" 2>/dev/null || {
            log_error "Build failed. Run with --verbose for details"
            log_footer "failed"
            exit 1
        }
    fi

    perf_end_phase "build"
    log_success "Build completed"
}

# Execute platform-specific switch
run_switch() {
    perf_start_phase "switch"

    echo ""
    log_step "Applying system configuration"
    if [ "$SUDO_REQUIRED" = "true" ]; then
        log_info "Administrator privileges will be requested for system changes"
        if [ "$PLATFORM_TYPE" = "linux" ] && [ -n "${SSH_AUTH_SOCK:-}" ]; then
            log_info "SSH forwarding enabled for private repositories"
        fi
    else
        log_info "Running with current privileges"
    fi

    SUDO_PREFIX=$(get_sudo_prefix)

    # Get optimal job count for parallelization
    JOBS=$(detect_optimal_jobs)

    if [ "$VERBOSE" = "true" ]; then
        log_info "Command: ${REBUILD_COMMAND} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}"
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} \"\$@\"" || {
                log_error "Switch failed (exit code: $?)"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" 2>&1 || {
                    log_error "Switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" 2>&1 || {
                    log_error "Switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    else
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} \"\$@\"" >/dev/null || {
                log_error "Switch failed. Run with --verbose for details"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" >/dev/null 2>&1 || {
                    log_error "Switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" >/dev/null 2>&1 || {
                    log_error "Switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    fi

    perf_end_phase "switch"
    log_success "Configuration applied"
}

# Cleanup function
run_cleanup() {
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        echo ""
        log_step "Cleaning up"
        unlink ./result >/dev/null 2>&1
        log_success "Cleanup completed"
    fi
}

# Main execution function
execute_build_switch() {
    # Start performance monitoring
    perf_start_total

    # Check if sudo will be needed
    if ! check_sudo_requirement; then
        log_error "Cannot proceed without administrator privileges"
        exit 1
    fi

    # Acquire sudo privileges EARLY if needed
    if [ "$SUDO_REQUIRED" = "true" ]; then
        if ! acquire_sudo_early; then
            log_error "Failed to acquire administrator privileges"
            exit 1
        fi
    fi

    # Main execution
    log_header

    # Build phase (Darwin) or Build & Switch phase (Linux)
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        # Darwin: separate build and switch phases
        run_build "$@"
        run_switch "$@"
    else
        # Linux: combined build & switch phase
        perf_start_phase "build"
        log_step "Building and switching system configuration"
        log_info "Target: ${SYSTEM_TYPE}"
        if [ "$SUDO_REQUIRED" = "true" ]; then
            log_info "Administrator privileges will be requested for system changes"
            if [ -n "${SSH_AUTH_SOCK:-}" ]; then
                log_info "SSH forwarding enabled for private repositories"
            fi
        else
            log_info "Running with current privileges"
        fi

        SUDO_PREFIX=$(get_sudo_prefix)

        # Get optimal job count for parallelization
        JOBS=$(detect_optimal_jobs)

        if [ "$VERBOSE" = "true" ]; then
            log_info "Command: ${REBUILD_COMMAND} switch --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}"
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} \"\$@\"" || {
                    log_error "Build & switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" || {
                    log_error "Build & switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        else
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} \"\$@\"" >/dev/null || {
                    log_error "Build & switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" 2>/dev/null || {
                    log_error "Build & switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
        perf_end_phase "build"
        log_success "Configuration applied"
    fi

    # Cleanup phase
    run_cleanup

    # Show performance summary
    perf_show_summary

    # Done
    log_footer "success"
    if [ "$VERBOSE" = "false" ]; then
        echo "${DIM}Tip: Use --verbose for detailed output${NC}"
    fi
}
