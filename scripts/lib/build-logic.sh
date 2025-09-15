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

# Import unified error handling system
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$(dirname "$0")")}"
. "${SCRIPTS_DIR}/lib/unified-error-handling.sh"

# Enhanced cleanup function with progress cleanup
cleanup_build_environment() {
    log_debug "Starting enhanced cleanup process"

    # Stop progress system first
    if command -v progress_cleanup >/dev/null 2>&1; then
        progress_cleanup 2>/dev/null || true
    fi

    # Call original cleanup
    cleanup_on_failure
}

# Set up signal handlers for graceful shutdown
setup_signal_handlers() {
    trap 'cleanup_build_environment; exit 130' INT
    trap 'cleanup_build_environment; exit 143' TERM
    trap 'cleanup_build_environment' EXIT
}

# Setup build environment and monitoring
setup_build_monitoring() {
    log_debug "Initializing build monitoring and progress systems"

    # Set up signal handlers for graceful shutdown
    setup_signal_handlers

    # Start performance monitoring
    perf_start_total || {
        unified_unified_log_error "Failed to initialize performance monitoring" "BUILD" "medium"
        return 1
    }

    # Initialize progress system
    progress_init || {
        unified_unified_log_error "Failed to initialize progress system" "BUILD" "medium"
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

    # Initialize state persistence system
    init_state_persistence || {
        log_warning "State persistence initialization failed - continuing without state management"
    }

    # Create pre-build snapshot
    create_pre_build_snapshot || {
        log_warning "Failed to create pre-build snapshot - continuing without backup"
    }

    # Configure network mode based on connectivity
    configure_network_mode || {
        log_warning "Network mode configuration encountered issues"
        if is_offline_mode; then
            get_offline_mode_message >&2
        fi
    }

    # Check if sudo will be needed and acquire it
    if ! check_sudo_requirement; then
        # For Darwin, try to provide helpful guidance
        if [ "${PLATFORM_TYPE:-}" = "darwin" ]; then
            log_info "Administrator privileges are required for system configuration changes."
            log_info "This is normal for nix-darwin system activation."

            # Try to acquire sudo with user-friendly prompts
            if command -v setup_sudo_session >/dev/null 2>&1; then
                if ! setup_sudo_session; then
                    unified_unified_log_error "Unable to acquire administrator privileges" "BUILD" "high"
                    return 1
                fi
            else
                unified_unified_log_error "Please ensure you have administrator access" "BUILD" "high"
                return 1
            fi
        else
            unified_unified_log_error "Cannot proceed without administrator privileges" "BUILD" "high"
            unified_unified_log_error "Please ensure you have the necessary permissions to perform system changes" "BUILD" "high"
            return 1
        fi
    fi

    # Validate essential build components
    if ! validate_build_environment; then
        unified_unified_log_error "Build environment validation failed" "BUILD" "high"
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
        unified_unified_log_error "SYSTEM_TYPE is not set" "BUILD" "high"
        return 1
    fi

    if [ -z "$PLATFORM_TYPE" ]; then
        unified_unified_log_error "PLATFORM_TYPE is not set" "BUILD" "high"
        return 1
    fi

    # Check if rebuild command exists for Linux
    if [ "$PLATFORM_TYPE" != "darwin" ] && [ -z "$REBUILD_COMMAND_PATH" ]; then
        unified_unified_log_error "REBUILD_COMMAND_PATH is not set for Linux build" "NIXOS_BUILD" "high"
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
                unified_unified_log_error "Darwin build and switch failed" "DARWIN_BUILD" "high"
                return 1
            }
            ;;
        *)
            log_info "Executing Linux build and switch phase"
            execute_linux_build_switch "$@" || {
                unified_unified_log_error "Linux build and switch failed" "NIXOS_BUILD" "high"
                return 1
            }
            ;;
    esac

    log_debug "Platform-specific build operations completed successfully"
    return 0
}

# Execute Darwin-specific optimized build and switch
execute_darwin_build_switch() {
    log_debug "Starting Darwin optimized build and switch"

    # Check if DARWIN_USE_COMBINED_MODE is set to false for legacy behavior
    if [ "${DARWIN_USE_COMBINED_MODE:-true}" = "false" ]; then
        log_info "Using legacy separate build and switch phases"

        # Legacy: separate build and switch phases for better error isolation
        if ! run_build "$@"; then
            unified_unified_log_error "Darwin build phase failed" "DARWIN_BUILD" "high"
            return 1
        fi

        if ! run_switch "$@"; then
            unified_unified_log_error "Darwin switch phase failed" "DARWIN_BUILD" "high"
            return 1
        fi
    else
        log_info "Using optimized combined build and switch"

        # Optimized: combined build and switch similar to Linux
        if ! run_darwin_combined_build_switch "$@"; then
            unified_unified_log_error "Darwin combined build and switch failed" "DARWIN_BUILD" "high"
            return 1
        fi
    fi

    log_debug "Darwin build and switch completed successfully"
    return 0
}

# Execute Darwin-specific combined build and switch (optimized)
run_darwin_combined_build_switch() {
    perf_start_phase "build"
    log_step "Building and applying system configuration"
    log_info "Target: ${SYSTEM_TYPE}"
    log_info "User: ${USER}"

    # Log privilege information
    if [ "$SUDO_REQUIRED" = "true" ]; then
        log_info "Administrator privileges will be requested for system changes"
    else
        log_info "Running with current privileges"
    fi

    # Optimize cache before building
    optimize_cache "$SYSTEM_TYPE"

    # Get build parameters
    local sudo_prefix=$(get_sudo_prefix)
    local jobs=$(detect_optimal_jobs)
    log_info "Using ${jobs} parallel jobs for combined build and switch"

    # Start progress indicator
    progress_start "시스템 빌드 및 적용" "$(progress_estimate_time build)"

    # Record build start time
    BUILD_START_TIME=$(date +%s)

    # Execute the combined build and switch
    execute_darwin_combined_command "$sudo_prefix" "$jobs" "$@" || {
        handle_darwin_build_failure
        return 1
    }

    # Record completion and update stats
    BUILD_END_TIME=$(date +%s)
    update_post_build_stats "true" "$BUILD_START_TIME" "$BUILD_END_TIME"

    progress_stop
    perf_end_phase "build"
    progress_complete "빌드 및 적용" "$PERF_BUILD_DURATION"
    log_success "Combined build and switch completed"

    return 0
}

# Handle Darwin build failure
handle_darwin_build_failure() {
    progress_stop
    unified_unified_log_error "Combined build and switch failed" "BUILD" "high"
    log_footer "failed"
}

# Execute the actual Darwin combined rebuild command with proper error handling
execute_darwin_combined_command() {
    local sudo_prefix="$1"
    local jobs="$2"
    shift 2  # Remove first two arguments, keep the rest

    # Get optimized rebuild command - use darwin-rebuild switch directly
    local base_rebuild_cmd="${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${jobs} --cores 0 --flake .#${SYSTEM_TYPE}"
    local optimized_rebuild_cmd=$(get_optimized_nix_command "$base_rebuild_cmd")

    # Execute with appropriate verbosity and privilege level
    local build_result=0
    if [ "$VERBOSE" = "true" ]; then
        execute_darwin_with_verbose_output "$sudo_prefix" "$optimized_rebuild_cmd" "$@"
        build_result=$?
    else
        execute_darwin_with_quiet_output "$sudo_prefix" "$optimized_rebuild_cmd" "$@"
        build_result=$?
    fi

    # Detect and handle build failures
    if detect_build_failure "$build_result" "darwin_combined_rebuild"; then
        local recovery_strategy=$(decide_recovery_strategy)
        log_warning "Build failure detected - suggested recovery: $recovery_strategy"

        case "$recovery_strategy" in
            "rollback")
                log_info "Attempting automatic rollback..."
                get_recovery_recommendations "$recovery_strategy" >&2
                execute_rollback
                ;;
            "retry"|"manual_review"|*)
                get_recovery_recommendations "$recovery_strategy" >&2
                ;;
        esac
    fi

    return $build_result
}

# Execute Darwin command with verbose output
execute_darwin_with_verbose_output() {
    local sudo_prefix="$1"
    local command="$2"
    shift 2

    # Try with network retry if network connectivity is uncertain
    if is_offline_mode; then
        log_info "Executing in offline mode with local cache only"
        if [ -n "$sudo_prefix" ]; then
            ${sudo_prefix} ${command} || return 1
        else
            USER="$USER" ${command} || return 1
        fi
    else
        # Use retry mechanism for online builds
        if [ -n "$sudo_prefix" ]; then
            ${sudo_prefix} ${command} || return 1
        else
            USER="$USER" ${command} || return 1
        fi
    fi
}

# Execute Darwin command with quiet output
execute_darwin_with_quiet_output() {
    local sudo_prefix="$1"
    local command="$2"
    shift 2

    # Try with network retry if network connectivity is uncertain
    if is_offline_mode; then
        log_info "Executing in offline mode with local cache only"
        if [ -n "$sudo_prefix" ]; then
            ${sudo_prefix} ${command} >/dev/null || {
                unified_log_error "Combined build and switch failed. Run with --verbose for details" "BUILD" "high"
                return 1
            }
        else
            USER="$USER" ${command} >/dev/null 2>&1 || {
                progress_stop
                echo ""
                log_warning "Combined build and switch failed - likely requires administrator privileges"
                echo ""
                echo "${YELLOW}Please run the following command manually:${NC}"
                echo "${BLUE}sudo ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${jobs} --cores 0 --flake .#${SYSTEM_TYPE}${NC}"
                echo ""
                log_footer "manual_execution_required"
                return 1
            }
        fi
    else
        # Use retry mechanism for online builds with quiet output
        if [ -n "$sudo_prefix" ]; then
            ${sudo_prefix} ${command} >/dev/null || {
                unified_log_error "Combined build and switch failed. Run with --verbose for details" "BUILD" "high"
                return 1
            }
        else
            USER="$USER" ${command} >/dev/null 2>&1 || {
                progress_stop
                echo ""
                log_warning "Combined build and switch failed - likely requires administrator privileges"
                echo ""
                echo "${YELLOW}Please run the following command manually:${NC}"
                echo "${BLUE}sudo ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${jobs} --cores 0 --flake .#${SYSTEM_TYPE}${NC}"
                echo ""
                log_footer "manual_execution_required"
                return 1
            }
        fi
    fi
}

# Execute Linux-specific combined build and switch
execute_linux_build_switch() {
    perf_start_phase "build"
    log_step "Building and switching system configuration"
    log_info "Target: ${SYSTEM_TYPE}"

    # Check if we're on NixOS or regular Linux (Ubuntu, etc.)
    local is_nixos=false
    if [ -f /etc/NIXOS ]; then
        is_nixos=true
        log_info "Detected NixOS system"
    else
        log_info "Detected non-NixOS Linux system (Ubuntu, etc.)"
        log_info "Using Home Manager for user configuration"
    fi

    # Log privilege and SSH information
    if [ "$is_nixos" = "true" ] && [ "$SUDO_REQUIRED" = "true" ]; then
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
    local sudo_prefix=""
    if [ "$is_nixos" = "true" ]; then
        sudo_prefix=$(get_sudo_prefix)
    fi
    local jobs=$(detect_optimal_jobs)
    log_info "Using ${jobs} parallel jobs for build and switch"

    # Start progress indicator
    progress_start "시스템 빌드 및 적용" "$(progress_estimate_time build)"

    # Record build start time
    BUILD_START_TIME=$(date +%s)

    # Execute the build and switch
    if [ "$is_nixos" = "true" ]; then
        # NixOS - use nixos-rebuild
        execute_linux_rebuild_command "$sudo_prefix" "$jobs" "$@" || {
            handle_linux_build_failure
            return 1
        }
    else
        # Regular Linux (Ubuntu, etc.) - use Home Manager
        execute_home_manager_switch "$jobs" "$@" || {
            handle_linux_build_failure
            return 1
        }
    fi

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
    unified_unified_log_error "Build and switch failed" "BUILD" "high"
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

# Execute Home Manager switch for non-NixOS Linux systems
execute_home_manager_switch() {
    local jobs="$1"
    shift  # Remove first argument, keep the rest

    # Get current user
    local user="${USER:-$(whoami)}"

    # Get optimized Home Manager command
    local base_hm_cmd="nix run github:nix-community/home-manager/release-24.05 -- switch --flake .#${user} --impure"
    local optimized_hm_cmd=$(get_optimized_nix_command "$base_hm_cmd" 2>/dev/null || echo "$base_hm_cmd")

    # Execute with appropriate verbosity
    if [ "$VERBOSE" = "true" ]; then
        eval "${optimized_hm_cmd} \"\$@\"" || return 1
    else
        eval "${optimized_hm_cmd} \"\$@\"" >/dev/null 2>&1 || {
            unified_unified_log_error "Home Manager switch failed. Run with --verbose for details" "BUILD" "medium"
            return 1
        }
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
            unified_log_error "Build and switch failed. Run with --verbose for details" "BUILD" "high"
            return 1
        }
    else
        eval "${command} \"\$@\"" >/dev/null 2>&1 || {
            unified_log_error "Build and switch failed. Run with --verbose for details" "BUILD" "high"
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

    # Use optimized flake evaluation for better performance
    log_info "Using batched flake evaluation for improved performance"
    if ! replace_individual_evaluations "$SYSTEM_TYPE" "build"; then
        log_warn "Batched evaluation failed, falling back to individual evaluation"

        # Get optimized nix command with cache settings (fallback)
        BASE_NIX_CMD="nix --extra-experimental-features 'nix-command flakes' build $BUILD_OPTIMIZATION_FLAGS --impure --no-warn-dirty --max-jobs $JOBS --cores 0"
        OPTIMIZED_NIX_CMD=$(get_optimized_nix_command "$BASE_NIX_CMD")
    else
        # Use optimized flake build with batched evaluation
        log_info "Using optimized flake build with batched evaluation"
        if optimized_flake_build "$SYSTEM_TYPE" "system"; then
            # Record build completion
            BUILD_END_TIME=$(date +%s)
            update_post_build_stats "true" "$BUILD_START_TIME" "$BUILD_END_TIME"

            progress_stop
            perf_end_phase "build"
            progress_complete "빌드" "$PERF_BUILD_DURATION"
            log_success "Optimized build completed"
            return 0
        else
            log_warn "Optimized flake build failed, falling back to traditional build"

            # Fallback to traditional build
            BASE_NIX_CMD="nix --extra-experimental-features 'nix-command flakes' build $BUILD_OPTIMIZATION_FLAGS --impure --no-warn-dirty --max-jobs $JOBS --cores 0"
            OPTIMIZED_NIX_CMD=$(get_optimized_nix_command "$BASE_NIX_CMD")
        fi
    fi

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
                unified_log_error "Switch failed (exit code: $?)" "BUILD" "medium"
                log_footer "failed"
                exit 1
            }
        else
            if [ "$PLATFORM_TYPE" = "darwin" ]; then
                USER="$USER" eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" 2>&1 || {
                    progress_stop
                    unified_log_error "Switch failed (exit code: $?)" "BUILD" "medium" "BUILD" "medium"
                    log_footer "failed"
                    exit 1
                }
            else
                eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" 2>&1 || {
                    progress_stop
                    unified_log_error "Switch failed (exit code: $?)" "BUILD" "medium" "BUILD" "medium"
                    log_footer "failed"
                    exit 1
                }
            fi
        fi
    else
        if [ -n "${SUDO_PREFIX}" ]; then
            eval "${SUDO_PREFIX} ${OPTIMIZED_SWITCH_CMD} \"\$@\"" >/dev/null || {
                progress_stop
                unified_log_error "Switch failed. Run with --verbose for details" "BUILD" "medium"
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
                    echo "${BLUE}sudo ${REBUILD_COMMAND_PATH} switch --impure --max-jobs ${JOBS} --cores 0 --flake .#${SYSTEM_TYPE}${NC}"
                    echo ""
                    log_footer "manual_execution_required"
                    exit 0
                }
            else
                eval "${OPTIMIZED_SWITCH_CMD} \"\$@\"" >/dev/null 2>&1 || {
                    progress_stop
                    unified_log_error "Switch failed. Run with --verbose for details" "BUILD" "medium" "BUILD" "medium"
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
    setup_build_monitoring || { unified_unified_log_error "Failed to setup build monitoring" "BUILD" "high"; exit 1; }
    prepare_build_environment || { unified_unified_log_error "Failed to prepare build environment" "BUILD" "high"; handle_build_failure; exit 1; }

    # Execute and complete
    execute_platform_build "$@" || { unified_unified_log_error "Platform-specific build operations failed" "BUILD" "high"; handle_build_failure; exit 1; }
    handle_build_completion || { unified_unified_log_error "Failed to handle build completion" "BUILD" "medium"; exit 1; }

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

    if command -v unified_unified_log_error >/dev/null 2>&1; then
        unified_unified_log_error "$operation failed (exit code: $exit_code)" "BUILD" "medium"

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
