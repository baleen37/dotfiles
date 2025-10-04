#!/bin/sh
# unified-colors.sh - Centralized color definitions for all scripts
# Provides consistent color scheme across the entire build system

# Core color definitions with standardized ANSI escape codes
export ERROR_COLOR='\033[1;31m'     # Bright Red - for errors
export WARNING_COLOR='\033[1;33m'   # Bright Yellow - for warnings
export SUCCESS_COLOR='\033[1;32m'   # Bright Green - for success messages
export INFO_COLOR='\033[1;34m'      # Bright Blue - for info messages
export DEBUG_COLOR='\033[2m'        # Dim - for debug messages
export HIGHLIGHT_COLOR='\033[1;36m' # Bright Cyan - for highlights
export NC='\033[0m'                 # No Color - reset

# Legacy color aliases for backwards compatibility
export RED="$ERROR_COLOR"
export YELLOW="$WARNING_COLOR"
export GREEN="$SUCCESS_COLOR"
export BLUE="$INFO_COLOR"
export DIM="$DEBUG_COLOR"

# Additional semantic colors
export HEADER_COLOR='\033[1;34m' # Bright Blue - for headers
export STEP_COLOR='\033[1;33m'   # Bright Yellow - for steps
export FOOTER_COLOR='\033[1;34m' # Bright Blue - for footers

# Status-specific colors
export PENDING_COLOR='\033[0;33m'   # Yellow - for pending operations
export RUNNING_COLOR='\033[0;36m'   # Cyan - for running operations
export COMPLETED_COLOR='\033[1;32m' # Bright Green - for completed operations
export FAILED_COLOR='\033[1;31m'    # Bright Red - for failed operations
export SKIPPED_COLOR='\033[2;37m'   # Dim White - for skipped operations

# Context-specific color mappings
export BUILD_COLOR="$INFO_COLOR"          # Blue for build contexts
export TEST_COLOR="$WARNING_COLOR"        # Yellow for test contexts
export NETWORK_COLOR="$HIGHLIGHT_COLOR"   # Cyan for network contexts
export UPDATE_COLOR="$SUCCESS_COLOR"      # Green for update contexts
export ERROR_CONTEXT_COLOR="$ERROR_COLOR" # Red for error contexts

# Terminal capability detection
detect_color_support() {
  # Check if stdout is a terminal
  if [ ! -t 1 ]; then
    return 1
  fi

  # Check TERM variable
  case "${TERM:-}" in
  *color* | xterm* | screen* | tmux* | alacritty | kitty | iterm*) return 0 ;;
  dumb | "") return 1 ;;
  *)
    # Check if terminal supports colors by testing capability
    if command -v tput >/dev/null 2>&1; then
      colors=$(tput colors 2>/dev/null || echo 0)
      [ "$colors" -ge 8 ]
    else
      return 1
    fi
    ;;
  esac
}

# Initialize color system based on environment
init_colors() {
  local force_colors="${FORCE_COLORS:-}"
  local no_color="${NO_COLOR:-}"

  # Handle NO_COLOR environment variable (https://no-color.org/)
  if [ -n "$no_color" ]; then
    disable_colors
    return
  fi

  # Force colors if requested
  if [ "$force_colors" = "true" ] || [ "$force_colors" = "1" ]; then
    enable_colors
    return
  fi

  # Auto-detect color support
  if detect_color_support; then
    enable_colors
  else
    disable_colors
  fi
}

# Enable color output
enable_colors() {
  export COLOR_ENABLED=true
  # Colors are already defined above, nothing more needed
}

# Disable color output
disable_colors() {
  export COLOR_ENABLED=false

  # Override all color variables with empty strings
  export ERROR_COLOR=''
  export WARNING_COLOR=''
  export SUCCESS_COLOR=''
  export INFO_COLOR=''
  export DEBUG_COLOR=''
  export HIGHLIGHT_COLOR=''
  export NC=''

  # Legacy aliases
  export RED=''
  export YELLOW=''
  export GREEN=''
  export BLUE=''
  export DIM=''

  # Additional colors
  export HEADER_COLOR=''
  export STEP_COLOR=''
  export FOOTER_COLOR=''
  export PENDING_COLOR=''
  export RUNNING_COLOR=''
  export COMPLETED_COLOR=''
  export FAILED_COLOR=''
  export SKIPPED_COLOR=''

  # Context colors
  export BUILD_COLOR=''
  export TEST_COLOR=''
  export NETWORK_COLOR=''
  export UPDATE_COLOR=''
  export ERROR_CONTEXT_COLOR=''
}

# Colorize text with specified color
colorize() {
  local color="$1"
  local text="$2"
  local reset="${3:-true}"

  if [ "$COLOR_ENABLED" = "false" ]; then
    echo "$text"
    return
  fi

  if [ "$reset" = "true" ]; then
    echo "${color}${text}${NC}"
  else
    echo "${color}${text}"
  fi
}

# Semantic colorization functions
colorize_error() {
  colorize "$ERROR_COLOR" "$1"
}

colorize_warning() {
  colorize "$WARNING_COLOR" "$1"
}

colorize_success() {
  colorize "$SUCCESS_COLOR" "$1"
}

colorize_info() {
  colorize "$INFO_COLOR" "$1"
}

colorize_debug() {
  colorize "$DEBUG_COLOR" "$1"
}

colorize_highlight() {
  colorize "$HIGHLIGHT_COLOR" "$1"
}

# Context-specific colorization
colorize_context() {
  local context="$1"
  local text="$2"

  case "$context" in
  "BUILD" | "DARWIN_BUILD" | "NIXOS_BUILD")
    colorize "$BUILD_COLOR" "$text"
    ;;
  "TEST" | "UNIT_TEST" | "INTEGRATION_TEST" | "E2E_TEST")
    colorize "$TEST_COLOR" "$text"
    ;;
  "NETWORK" | "CACHE" | "SUBSTITUTER")
    colorize "$NETWORK_COLOR" "$text"
    ;;
  "UPDATE" | "AUTO_UPDATE" | "FLAKE_UPDATE")
    colorize "$UPDATE_COLOR" "$text"
    ;;
  "ERROR" | "FAILURE")
    colorize "$ERROR_CONTEXT_COLOR" "$text"
    ;;
  *)
    colorize "$INFO_COLOR" "$text"
    ;;
  esac
}

# Status colorization
colorize_status() {
  local status="$1"
  local text="$2"

  case "$status" in
  "pending" | "waiting" | "queued")
    colorize "$PENDING_COLOR" "$text"
    ;;
  "running" | "executing" | "processing")
    colorize "$RUNNING_COLOR" "$text"
    ;;
  "completed" | "success" | "done" | "passed")
    colorize "$COMPLETED_COLOR" "$text"
    ;;
  "failed" | "error" | "failed")
    colorize "$FAILED_COLOR" "$text"
    ;;
  "skipped" | "ignored" | "disabled")
    colorize "$SKIPPED_COLOR" "$text"
    ;;
  *)
    colorize "$INFO_COLOR" "$text"
    ;;
  esac
}

# Progress bar colorization
colorize_progress() {
  local percentage="$1"
  local text="$2"

  if [ "$percentage" -ge 100 ]; then
    colorize "$SUCCESS_COLOR" "$text"
  elif [ "$percentage" -ge 75 ]; then
    colorize "$INFO_COLOR" "$text"
  elif [ "$percentage" -ge 50 ]; then
    colorize "$WARNING_COLOR" "$text"
  else
    colorize "$ERROR_COLOR" "$text"
  fi
}

# Export colorization functions
export -f colorize
export -f colorize_error
export -f colorize_warning
export -f colorize_success
export -f colorize_info
export -f colorize_debug
export -f colorize_highlight
export -f colorize_context
export -f colorize_status
export -f colorize_progress
export -f enable_colors
export -f disable_colors
export -f detect_color_support
export -f init_colors

# Initialize colors when this script is sourced
init_colors
