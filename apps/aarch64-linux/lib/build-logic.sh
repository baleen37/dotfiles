#!/bin/sh
# Build Logic Module for Build Scripts
# Contains core build, switch, and orchestration functions
#
# Performance Optimizations (TDD Cycle 1.1):
# - Integrated optimization module for dynamic flag management
# - Added eval-cache support for faster evaluation
# - Modularized optimization settings for better maintainability

# Execute nix build with parallelization and cache optimization
run_build() {
    perf_start_phase "build"

    log_step "Building system configuration"
    log_info "Target: ${SYSTEM_TYPE}"
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        log_info "User: ${USER}"
    fi

    # Optimize cache before building
    optimize_cache "$SYSTEM_TYPE"

    # Get optimal job count for parallelization
    JOBS=$(detect_optimal_jobs)
    log_info "Using ${JOBS} parallel jobs for build"

    # Get optimized build flags
    BUILD_OPTIMIZATION_FLAGS=$(get_build_optimization_flags)
    log_info "Using optimization flags: $BUILD_OPTIMIZATION_FLAGS"

    # Start progress indicator
    progress_start "시스템 구성 빌드" "$(progress_estimate_time build)"

    # Record build start time for cache statistics
    BUILD_START_TIME=$(date +%s)

    # Get optimized nix command with cache settings
    BASE_NIX_CMD="nix --extra-experimental-features 'nix-command flakes' build $BUILD_OPTIMIZATION_FLAGS --impure --no-warn-dirty --max-jobs $JOBS --cores 0"
    OPTIMIZED_NIX_CMD=$(get_optimized_nix_command "$BASE_NIX_CMD")

    if [ "$VERBOSE" = "true" ]; then
        eval "$OPTIMIZED_NIX_CMD .#$FLAKE_SYSTEM \"\$@\"" || {
            progress_stop
            log_error "Build failed"
            log_footer "failed"
            exit 1
        }
    else
        eval "$OPTIMIZED_NIX_CMD .#$FLAKE_SYSTEM \"\$@\"" 2>/dev/null || {
            progress_stop
            log_error "Build failed. Run with --verbose for details"
            log_footer "failed"
            exit 1
        }
    fi

    # Record build end time and update cache statistics
    BUILD_END_TIME=$(date +%s)
    update_post_build_stats "true" "$BUILD_START_TIME" "$BUILD_END_TIME"

    progress_stop
    perf_end_phase "build"
    progress_complete "빌드" "$PERF_BUILD_DURATION"
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

    # Start progress indicator
    progress_start "시스템 구성 적용" "$(progress_estimate_time switch)"

    # Get optimized switch command with cache settings
    BASE_SWITCH_CMD="${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}"
    OPTIMIZED_SWITCH_CMD=$(get_optimized_nix_command "$BASE_SWITCH_CMD")

    if [ "$VERBOSE" = "true" ]; then
        log_info "Command: ${REBUILD_COMMAND} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}"
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${OPTIMIZED_SWITCH_CMD} \"\$@\"" || {
                progress_stop
                log_error "Switch failed (exit code: $?)"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" 2>&1 || {
                    progress_stop
                    log_error "Switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" 2>&1 || {
                    progress_stop
                    log_error "Switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    else
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${OPTIMIZED_SWITCH_CMD} \"\$@\"" >/dev/null || {
                progress_stop
                log_error "Switch failed. Run with --verbose for details"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" >/dev/null 2>&1 || {
                    progress_stop
                    echo ""
                    log_warning "Switch failed - likely requires administrator privileges"
                    echo ""
                    echo "${YELLOW}Please run the following command manually:${NC}"
                    echo "${BLUE}sudo ./result/sw/bin/darwin-rebuild switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}${NC}"
                    echo ""
                    log_footer "manual_execution_required"
                    exit 0
                }
            else
                eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" >/dev/null 2>&1 || {
                    progress_stop
                    log_error "Switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    fi

    progress_stop
    perf_end_phase "switch"
    progress_complete "구성 적용" "$PERF_SWITCH_DURATION"
    log_success "Configuration applied"
}

# Cleanup function
run_cleanup() {
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        echo ""
        log_step "Cleaning up"
        progress_start "정리 작업" "$(progress_estimate_time cleanup)"
        unlink ./result >/dev/null 2>&1
        progress_stop
        progress_complete "정리 작업"
        log_success "Cleanup completed"
    fi
}

# Main execution function
execute_build_switch() {
    # Start performance monitoring
    perf_start_total

    # Initialize progress system
    progress_init

    # Check if sudo will be needed and acquire it
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

        # Optimize cache before building
        optimize_cache "$SYSTEM_TYPE"

        SUDO_PREFIX=$(get_sudo_prefix)
        JOBS=$(detect_optimal_jobs)
        log_info "Using ${JOBS} parallel jobs for build and switch"

        # Start progress indicator for combined build & switch
        progress_start "시스템 빌드 및 적용" "$(progress_estimate_time build)"

        # Record build start time for cache statistics
        BUILD_START_TIME=$(date +%s)

        # Get optimized rebuild command with cache settings
        BASE_REBUILD_CMD="${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}"
        OPTIMIZED_REBUILD_CMD=$(get_optimized_nix_command "$BASE_REBUILD_CMD")

        if [ "$VERBOSE" = "true" ]; then
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${OPTIMIZED_REBUILD_CMD} \"\$@\"" || {
                    progress_stop
                    log_error "Build and switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            else
                eval "${OPTIMIZED_REBUILD_CMD} \"\$@\"" || {
                    progress_stop
                    log_error "Build and switch failed (exit code: $?)"
                    log_footer "failed"
                    exit 1
                }
            fi
        else
            if [ -n "${SUDO_PREFIX}" ]; then
                eval "${SUDO_PREFIX} ${OPTIMIZED_REBUILD_CMD} \"\$@\"" >/dev/null || {
                    progress_stop
                    log_error "Build and switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            else
                eval "${OPTIMIZED_REBUILD_CMD} \"\$@\"" >/dev/null 2>&1 || {
                    progress_stop
                    log_error "Build and switch failed. Run with --verbose for details"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi

        # Record build end time and update cache statistics
        BUILD_END_TIME=$(date +%s)
        update_post_build_stats "true" "$BUILD_START_TIME" "$BUILD_END_TIME"

        progress_stop
        perf_end_phase "build"
        progress_complete "빌드 및 적용" "$PERF_BUILD_DURATION"
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

    # Cleanup progress system
    progress_cleanup
}
