#!/bin/sh
# Performance Monitoring Module for Build Scripts
# Contains performance measurement and monitoring functions

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

# CPU core detection for parallel builds
detect_optimal_jobs() {
    local CORES

    if command -v nproc >/dev/null 2>&1; then
        # Linux
        CORES=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        # macOS
        CORES=$(sysctl -n hw.ncpu)
    else
        # Fallback
        CORES=2
    fi

    # Check if we're in CI environment
    if [ -n "$CI" ]; then
        # CI: Use fewer cores to avoid overwhelming runners
        CORES=$([ "$CORES" -gt 4 ] && echo 4 || echo "$CORES")
    else
        # Local development: Use more cores but cap at 8 for safety
        CORES=$([ "$CORES" -gt 8 ] && echo 8 || echo "$CORES")
    fi

    # Return cores (minimum 1)
    echo "$([ "$CORES" -gt 0 ] && echo "$CORES" || echo 1)"
}
