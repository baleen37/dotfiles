#!/bin/sh
# Build Logic Module for Build Scripts
# Contains core build, switch, and orchestration functions

# Pre-flight checks for Darwin system
check_darwin_prerequisites() {
    local conflicts_found=false

    log_step "Checking system prerequisites"

    # Check for conflicting system files
    if [ -f "/etc/bashrc" ] && [ ! -f "/etc/bashrc.before-nix-darwin" ]; then
        log_warning "Found /etc/bashrc - will be backed up during activation"
        conflicts_found=true
    fi

    if [ -f "/etc/zshrc" ] && [ ! -f "/etc/zshrc.before-nix-darwin" ]; then
        log_warning "Found /etc/zshrc - will be backed up during activation"
        conflicts_found=true
    fi

    # Check for nix configuration conflicts
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        log_info "Checking nix configuration consistency"

        # This will be caught during build, but we can provide better messaging
        if grep -q "nix\.enable.*=.*false" "$PROJECT_ROOT/hosts/darwin/default.nix" 2>/dev/null; then
            if grep -q "nix\.gc\.automatic.*=.*true" "$PROJECT_ROOT/hosts/darwin/default.nix" 2>/dev/null; then
                log_warning "Detected potential nix configuration conflict"
                log_info "  nix.enable = false but nix.gc.automatic = true"
                log_info "  This may cause build failures"
            fi
        fi
    fi

    if [ "$conflicts_found" = "true" ]; then
        log_info "System file conflicts detected but will be handled automatically"
        log_info "Original files will be backed up with .before-nix-darwin suffix"

        # Automatically backup files if we have sudo access
        if [ "$SUDO_REQUIRED" = "true" ] && [ "$SUDO_SESSION_ACTIVE" = "true" ]; then
            log_info "Auto-backing up conflicting system files"

            if [ -f "/etc/bashrc" ] && [ ! -f "/etc/bashrc.before-nix-darwin" ]; then
                sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
                log_info "  Backed up /etc/bashrc"
            fi

            if [ -f "/etc/zshrc" ] && [ ! -f "/etc/zshrc.before-nix-darwin" ]; then
                sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
                log_info "  Backed up /etc/zshrc"
            fi

            log_success "System files backed up successfully"
        else
            log_warning "Cannot auto-backup files - manual intervention required"
        fi
    fi

    log_success "Prerequisites check completed"
}

# Execute nix build with parallelization
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

    # Pre-flight checks for Darwin
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        check_darwin_prerequisites
    fi

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
        JOBS=$(detect_optimal_jobs)
        log_info "Using ${JOBS} parallel jobs for build and switch"

        if [ "$VERBOSE" = "true" ]; then
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} \"\$@\"" || {
                    log_error "Build and switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" || {
                    log_error "Build and switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        else
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} \"\$@\"" >/dev/null || {
                    log_error "Build and switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            else
                ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE} "$@" >/dev/null 2>&1 || {
                    log_error "Build and switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi

        perf_end_phase "build"
        log_success "Build and switch completed"
    fi

    # Cleanup
    run_cleanup

    # Show performance summary
    perf_show_summary

    # Footer
    log_footer "success"

    # Cleanup handlers
    register_cleanup
    cleanup_sudo_session
}
