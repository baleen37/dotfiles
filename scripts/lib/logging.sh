#!/bin/bash
# Common logging utilities for all platform scripts
# Provides standardized logging functions with different log levels

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Log with timestamp
log_with_timestamp() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            log_info "[$timestamp] $message"
            ;;
        "SUCCESS")
            log_success "[$timestamp] $message"
            ;;
        "WARNING")
            log_warning "[$timestamp] $message"
            ;;
        "ERROR")
            log_error "[$timestamp] $message"
            ;;
        "DEBUG")
            log_debug "[$timestamp] $message"
            ;;
        *)
            echo "[$timestamp] [$level] $message" >&2
            ;;
    esac
}

# Progress indicator
show_progress() {
    local message="$1"
    local duration="${2:-3}"
    
    for i in $(seq 1 "$duration"); do
        echo -n "${message}..."
        sleep 1
        echo -ne "\r"
    done
    echo "${message} ✓"
}