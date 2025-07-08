#!/bin/sh
# Build Logic Module for Build Scripts
# Contains core build, switch, and orchestration functions
#
# Performance Optimizations (TDD Cycle 1.1):
# - Integrated optimization module for dynamic flag management
# - Added eval-cache support for faster evaluation
# - Modularized optimization settings for better maintainability
#
# Unified Build Logic (TDD Cycle 1.3):
# - Platform-agnostic error handling
# - Consistent build steps across all platforms
# - Enhanced failure recovery mechanisms

# Setup build environment and monitoring
setup_build_monitoring() {
    log_debug "Initializing build monitoring and progress systems"

    # Start performance monitoring
    perf_start_total || {
        log_error "Failed to initialize performance monitoring"
        return 1
    }

    # Initialize progress system
    progress_init || {
        log_error "Failed to initialize progress system"
        return 1
    }

    # Show header
    log_header

    log_debug "Build monitoring setup completed successfully"
    return 0
}

# Prepare build environment and validate requirements
prepare_build_environment() {
    log_debug "Preparing build environment and validating requirements"

    # Check if sudo will be needed and acquire it
    if ! check_sudo_requirement; then
        log_error "Cannot proceed without administrator privileges"
        log_error "Please ensure you have the necessary permissions to perform system changes"
        return 1
    fi

    # Validate essential build components
    if ! validate_build_environment; then
        log_error "Build environment validation failed"
        return 1
    fi

    log_debug "Build environment preparation completed successfully"
    return 0
}

# Validate essential build environment components
validate_build_environment() {
    log_debug "Validating build environment components"

    # Check if required variables are set
    if [ -z "$SYSTEM_TYPE" ]; then
        log_error "SYSTEM_TYPE is not set"
        return 1
    fi

    if [ -z "$PLATFORM_TYPE" ]; then
        log_error "PLATFORM_TYPE is not set"
        return 1
    fi

    # Check if rebuild command exists for Linux
    if [ "$PLATFORM_TYPE" != "darwin" ] && [ -z "$REBUILD_COMMAND_PATH" ]; then
        log_error "REBUILD_COMMAND_PATH is not set for Linux build"
        return 1
    fi

    log_debug "Build environment validation completed successfully"
    return 0
}

# Execute platform-specific build operations
execute_platform_build() {
    log_debug "Starting platform-specific build operations for $PLATFORM_TYPE"

    case "$PLATFORM_TYPE" in
        "darwin")
            log_info "Executing Darwin build and switch phases"
            execute_darwin_build_switch "$@" || {
                log_error "Darwin build and switch failed"
                return 1
            }
            ;;
        *)
            log_info "Executing Linux build and switch phase"
            execute_linux_build_switch "$@" || {
                log_error "Linux build and switch failed"
                return 1
            }
            ;;
    esac

    log_debug "Platform-specific build operations completed successfully"
    return 0
}

# Execute Darwin-specific separate build and switch phases
execute_darwin_build_switch() {
    log_debug "Starting Darwin separate build and switch phases"

    # Darwin: separate build and switch phases for better error isolation
    if ! run_build "$@"; then
        log_error "Darwin build phase failed"
        return 1
    fi

    if ! run_switch "$@"; then
        log_error "Darwin switch phase failed"
        return 1
    fi

    log_debug "Darwin build and switch phases completed successfully"
    return 0
}

# Execute Linux-specific combined build and switch
execute_linux_build_switch() {
    perf_start_phase "build"
    log_step "Building and switching system configuration"
    log_info "Target: ${SYSTEM_TYPE}"

    # Log privilege and SSH information
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

    # Get build parameters
    local sudo_prefix=$(get_sudo_prefix)
    local jobs=$(detect_optimal_jobs)
    log_info "Using ${jobs} parallel jobs for build and switch"

    # Start progress indicator
    progress_start "시스템 빌드 및 적용" "$(progress_estimate_time build)"

    # Record build start time
    BUILD_START_TIME=$(date +%s)

    # Execute the build and switch
    execute_linux_rebuild_command "$sudo_prefix" "$jobs" "$@" || {
        handle_linux_build_failure
        return 1
    }

    # Record completion and update stats
    BUILD_END_TIME=$(date +%s)
    update_post_build_stats "true" "$BUILD_START_TIME" "$BUILD_END_TIME"

    progress_stop
    perf_end_phase "build"
    progress_complete "빌드 및 적용" "$PERF_BUILD_DURATION"
    log_success "Build and switch completed"

    return 0
}

# Handle Linux build failure
handle_linux_build_failure() {
    progress_stop
    log_error "Build and switch failed"
    log_footer "failed"
}

# Execute the actual Linux rebuild command with proper error handling
execute_linux_rebuild_command() {
    local sudo_prefix="$1"
    local jobs="$2"
    shift 2  # Remove first two arguments, keep the rest

    # Get optimized rebuild command
    local base_rebuild_cmd="${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${jobs} --cores 0 --flake .#${SYSTEM_TYPE}"
    local optimized_rebuild_cmd=$(get_optimized_nix_command "$base_rebuild_cmd")

    # Execute with appropriate verbosity and privilege level
    if [ "$VERBOSE" = "true" ]; then
        execute_with_verbose_output "$sudo_prefix" "$optimized_rebuild_cmd" "$@"
    else
        execute_with_quiet_output "$sudo_prefix" "$optimized_rebuild_cmd" "$@"
    fi
}

# Execute command with verbose output
execute_with_verbose_output() {
    local sudo_prefix="$1"
    local command="$2"
    shift 2

    if [ -n "$sudo_prefix" ]; then
        eval "${sudo_prefix} ${command} \"\$@\"" || return 1
    else
        eval "${command} \"\$@\"" || return 1
    fi
}

# Execute command with quiet output
execute_with_quiet_output() {
    local sudo_prefix="$1"
    local command="$2"
    shift 2

    if [ -n "$sudo_prefix" ]; then
        eval "${sudo_prefix} ${command} \"\$@\"" >/dev/null || {
            log_error "Build and switch failed. Run with --verbose for details"
            return 1
        }
    else
        eval "${command} \"\$@\"" >/dev/null 2>&1 || {
            log_error "Build and switch failed. Run with --verbose for details"
            return 1
        }
    fi
}

# Handle build completion tasks
handle_build_completion() {
    log_debug "Starting build completion tasks"

    # Run system cleanup
    if ! run_cleanup; then
        log_warn "System cleanup encountered issues but continuing"
    fi

    # Show performance summary
    if ! perf_show_summary; then
        log_warn "Performance summary display failed but continuing"
    fi

    # Log success footer
    log_footer "success"

    # Register and execute cleanup handlers
    if ! register_cleanup; then
        log_warn "Cleanup handler registration failed but continuing"
    fi

    if ! cleanup_sudo_session; then
        log_warn "Sudo session cleanup failed but continuing"
    fi

    # Cleanup progress system
    if ! progress_cleanup; then
        log_warn "Progress system cleanup failed but continuing"
    fi

    log_debug "Build completion tasks finished"
    return 0
}

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
            handle_build_error $? "build"
            exit $?
        }
    else
        eval "$OPTIMIZED_NIX_CMD .#$FLAKE_SYSTEM \"\$@\"" 2>/dev/null || {
            handle_build_error $? "build"
            exit $?
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
# Main build and switch orchestrator (simplified with decomposed functions)
execute_build_switch() {
    log_debug "Starting build and switch orchestration"

    # Setup and prepare
    setup_build_monitoring || { log_error "Failed to setup build monitoring"; exit 1; }
    prepare_build_environment || { log_error "Failed to prepare build environment"; handle_build_failure; exit 1; }

    # Execute and complete
    execute_platform_build "$@" || { log_error "Platform-specific build operations failed"; handle_build_failure; exit 1; }
    handle_build_completion || { log_error "Failed to handle build completion"; exit 1; }

    log_debug "Build and switch orchestration completed successfully"
}

# Handle build failure cleanup
handle_build_failure() {
    log_debug "Handling build failure cleanup"

    # Stop any running progress indicators
    progress_stop 2>/dev/null || true

    # Log failure footer
    log_footer "failed"

    # Cleanup any partial state
    cleanup_sudo_session 2>/dev/null || true
    progress_cleanup 2>/dev/null || true

    log_debug "Build failure cleanup completed"
}

# Unified error handling for build failures
handle_build_error() {
    local exit_code="${1:-1}"
    local operation="${2:-build}"

    progress_stop 2>/dev/null || true

    if command -v log_error >/dev/null 2>&1; then
        log_error "$operation failed (exit code: $exit_code)"

        # Provide helpful debugging information based on exit code
        case "$exit_code" in
            1)
                log_info "General build failure - check build dependencies"
                log_info "Common causes: missing packages, network issues, or configuration errors"
                ;;
            2)
                log_info "Permission error - check sudo requirements"
                log_info "Run with administrator privileges if needed"
                ;;
            130)
                log_info "Build interrupted by user (Ctrl+C)"
                ;;
            *)
                log_info "Unexpected error - run with --verbose for detailed output"
                if [ "$VERBOSE" != "true" ]; then
                    log_info "Retry with: $0 --verbose"
                fi
                ;;
        esac

        # Footer with failure status
        log_footer "failed"
    else
        echo "ERROR: $operation failed (exit code: $exit_code)" >&2
    fi

    # Cleanup on failure
    cleanup_on_failure

    return "$exit_code"
}

# Cleanup operations when build fails
cleanup_on_failure() {
    # Stop any background processes
    if command -v stop_sudo_refresh_daemon >/dev/null 2>&1; then
        stop_sudo_refresh_daemon 2>/dev/null || true
    fi

    # Clean up temporary files
    if [ -n "${BUILD_TEMP_DIR:-}" ] && [ -d "$BUILD_TEMP_DIR" ]; then
        rm -rf "$BUILD_TEMP_DIR" 2>/dev/null || true
    fi

    # Reset performance monitoring
    if command -v perf_cleanup >/dev/null 2>&1; then
        perf_cleanup 2>/dev/null || true
    fi

    if command -v log_info >/dev/null 2>&1; then
        log_info "Cleanup completed"
    fi
}
