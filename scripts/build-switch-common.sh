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

# Sudo session management (simplified)
SUDO_REQUIRED=false

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

# Sudo management functions
check_current_privileges() {
    if [ "$(id -u)" -eq 0 ]; then
        log_info "Already running with administrator privileges"
        return 0
    else
        return 1
    fi
}

explain_sudo_requirement() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}  Administrator Privileges Required${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "${YELLOW}Why are administrator privileges needed?${NC}"
    echo ""
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        echo "• System configuration changes require elevated privileges"
        echo "• Darwin rebuild needs to modify system-level settings"
        echo "• Nix store operations may need root access"
    else
        echo "• NixOS rebuild requires root to modify system configuration"
        echo "• System service management needs elevated privileges"
        echo "• Bootloader updates require root access"
        echo "• SSH key forwarding for private repository access"
    fi
    echo ""
    echo "${DIM}Administrator access will be requested when needed for the rebuild command.${NC}"
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Simplified cleanup - no sudo session management needed
register_cleanup() {
    # No cleanup needed for just-in-time sudo usage
    return 0
}

# No sudo session cleanup needed
cleanup_sudo_session() {
    # No cleanup needed for just-in-time sudo usage
    return 0
}

# Determine if sudo will be needed later
check_sudo_requirement() {
    # Skip if already root
    if check_current_privileges; then
        SUDO_REQUIRED=false
        return 0
    fi

    # Check sudo availability
    if ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo command not found. Please install sudo or run as root."
        return 1
    fi

    SUDO_REQUIRED=true

    # Explain why we need sudo (but don't acquire it yet)
    explain_sudo_requirement

    return 0
}

get_sudo_prefix() {
    if [ "$SUDO_REQUIRED" = "true" ]; then
        if [ "$PLATFORM_TYPE" = "darwin" ]; then
            echo "sudo -E USER=\"$USER\""
        elif [ -n "${SSH_AUTH_SOCK:-}" ]; then
            echo "sudo SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
        else
            echo "sudo"
        fi
    else
        echo ""
    fi
}

# Execute platform-specific build
run_build() {
    log_step "Building system configuration"
    log_info "Target: ${SYSTEM_TYPE}"
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        log_info "User: ${USER}"
    fi

    if [ "$VERBOSE" = "true" ]; then
        nix --extra-experimental-features 'nix-command flakes' build --impure .#$FLAKE_SYSTEM "$@" || {
            log_error "Build failed"
            log_footer "failed"
            exit 1
        }
    else
        nix --extra-experimental-features 'nix-command flakes' build --impure .#$FLAKE_SYSTEM "$@" 2>/dev/null || {
            log_error "Build failed. Run with --verbose for details"
            log_footer "failed"
            exit 1
        }
    fi
    log_success "Build completed"
}

# Execute platform-specific switch
run_switch() {
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

    if [ "$VERBOSE" = "true" ]; then
        log_info "Command: ${REBUILD_COMMAND} switch --impure --flake .#${SYSTEM_TYPE}"
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --impure --flake .#${SYSTEM_TYPE} \"\$@\"" || {
                log_error "Switch failed (exit code: $?)"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" ${REBUILD_COMMAND_PATH} switch --impure --flake .#${SYSTEM_TYPE} "$@" 2>&1 || {
                    log_error "Switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --impure --flake .#${SYSTEM_TYPE} "$@" 2>&1 || {
                    log_error "Switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    else
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --impure --flake .#${SYSTEM_TYPE} \"\$@\"" >/dev/null || {
                log_error "Switch failed. Run with --verbose for details"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" ${REBUILD_COMMAND_PATH} switch --impure --flake .#${SYSTEM_TYPE} "$@" >/dev/null 2>&1 || {
                    log_error "Switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --impure --flake .#${SYSTEM_TYPE} "$@" >/dev/null 2>&1 || {
                    log_error "Switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    fi
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
    # Check if sudo will be needed (but don't acquire privileges yet)
    if ! check_sudo_requirement; then
        log_error "Cannot proceed without administrator privileges"
        exit 1
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

        if [ "$VERBOSE" = "true" ]; then
            log_info "Command: ${REBUILD_COMMAND} switch --flake .#${SYSTEM_TYPE}"
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --flake .#${SYSTEM_TYPE} \"\$@\"" || {
                    log_error "Build & switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --flake .#${SYSTEM_TYPE} "$@" || {
                    log_error "Build & switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        else
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --flake .#${SYSTEM_TYPE} \"\$@\"" >/dev/null || {
                    log_error "Build & switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --flake .#${SYSTEM_TYPE} "$@" 2>/dev/null || {
                    log_error "Build & switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
        log_success "Configuration applied"
    fi

    # Cleanup phase
    run_cleanup

    # Done
    log_footer "success"
    if [ "$VERBOSE" = "false" ]; then
        echo "${DIM}Tip: Use --verbose for detailed output${NC}"
    fi
}
