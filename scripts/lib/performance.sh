#!/bin/sh
# Performance Monitoring Module for Build Scripts
# Contains performance measurement, monitoring, and parallel optimization functions
#
# Performance Optimizations (TDD Cycle 1.2):
# - Intelligent CPU core detection with platform-specific optimization
# - Dynamic scaling based on system resources and environment
# - Apple Silicon P-core/E-core optimization support
# - Multiple performance modes (default, conservative, aggressive)
# - CI environment resource conservation

# Performance monitoring variables
PERF_START_TIME=""
PERF_BUILD_START_TIME=""
PERF_SWITCH_START_TIME=""
PERF_BUILD_DURATION=""
PERF_SWITCH_DURATION=""

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
                if command -v log_info >/dev/null 2>&1; then
                    log_info "Build phase completed in ${PERF_BUILD_DURATION}s"
                fi
            fi
            ;;
        "switch")
            if [ -n "$PERF_SWITCH_START_TIME" ]; then
                PERF_SWITCH_DURATION=$((end_time - PERF_SWITCH_START_TIME))
                if command -v log_info >/dev/null 2>&1; then
                    log_info "Switch phase completed in ${PERF_SWITCH_DURATION}s"
                fi
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

# CPU core detection for parallel builds with intelligent scaling
detect_optimal_jobs() {
    local CORES
    local PLATFORM=$(uname -s)

    # Step 1: Detect system cores
    if command -v nproc >/dev/null 2>&1; then
        # Linux
        CORES=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        # macOS - get total logical cores
        CORES=$(sysctl -n hw.ncpu)
    else
        # Fallback
        CORES=4
    fi

    # Step 2: Platform-specific optimizations
    if [ "$PLATFORM" = "Darwin" ]; then
        # macOS: Check for Apple Silicon optimization
        P_CORES=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo "0")
        E_CORES=$(sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo "0")

        if [ "$P_CORES" -gt 0 ] && [ "$E_CORES" -gt 0 ]; then
            # Apple Silicon: Focus on P-cores for compute-intensive tasks
            # Use P-cores + some E-cores for optimal performance
            CORES=$(( P_CORES + (E_CORES / 2) ))
            if command -v log_info >/dev/null 2>&1; then
                log_info "Apple Silicon detected: P-cores=$P_CORES, E-cores=$E_CORES, using $CORES cores"
            fi
        fi
    fi

    # Step 3: Environment-based scaling
    if [ -n "$CI" ]; then
        # CI: Conservative approach to avoid overwhelming runners
        CORES=$([ "$CORES" -gt 4 ] && echo 4 || echo "$CORES")
    elif [ "${PERFORMANCE_MODE:-}" = "conservative" ]; then
        # Conservative mode: Use 75% of cores
        CORES=$(echo "scale=0; $CORES * 3 / 4" | bc 2>/dev/null || echo $(( CORES * 3 / 4 )))
    elif [ "${PERFORMANCE_MODE:-}" = "aggressive" ]; then
        # Aggressive mode: Use all cores up to reasonable limit
        CORES=$([ "$CORES" -gt 32 ] && echo 32 || echo "$CORES")
    else
        # Default mode: Dynamic scaling based on core count
        if [ "$CORES" -le 4 ]; then
            # Low core systems: use all cores
            CORES="$CORES"
        elif [ "$CORES" -le 8 ]; then
            # Medium core systems: use all cores
            CORES="$CORES"
        elif [ "$CORES" -le 16 ]; then
            # High core systems: use most cores
            CORES=$(( CORES - 1 ))
        else
            # Very high core systems: use 75% to leave room for system
            CORES=$(echo "scale=0; $CORES * 3 / 4" | bc 2>/dev/null || echo $(( CORES * 3 / 4 )))
        fi
    fi

    # Step 4: Safety bounds
    CORES=$([ "$CORES" -lt 1 ] && echo 1 || echo "$CORES")
    CORES=$([ "$CORES" -gt 64 ] && echo 64 || echo "$CORES")

    echo "$CORES"
}
