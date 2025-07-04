#!/bin/sh
# Logging Module for Build Scripts
# Contains all logging functions and color constants

# Color constants
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
DIM='\033[2m'
NC='\033[0m'

# Logging functions
log_header() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}  ${PLATFORM_NAME} Build & Switch${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_step() {
    echo "${YELLOW}▶${NC} $1"
}

log_info() {
    echo "${DIM}  $1${NC}"
}

log_warning() {
    echo "${YELLOW}⚠️  $1${NC}"
}

log_success() {
    echo "${GREEN}✅ $1${NC}"
}

log_error() {
    echo "${RED}❌ $1${NC}"
}

log_footer() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ "$VERBOSE" = "true" ]; then
        echo "${DIM}  ℹ️  Verbose mode enabled${NC}"
        echo "${DIM}  📁 Working directory: $(pwd)${NC}"
        echo "${DIM}  👤 User: ${USER:-unknown}${NC}"
        echo "${DIM}  💻 Platform: ${PLATFORM_NAME}${NC}"
    fi
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}
