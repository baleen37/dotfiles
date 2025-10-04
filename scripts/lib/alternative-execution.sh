#!/bin/sh
# alternative-execution.sh - Alternative execution paths and fallback mechanisms
# Provides robust fallback strategies when primary execution paths fail

# Global state for execution tracking
EXECUTION_ATTEMPTS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/execution_attempts.json"
EXECUTION_MAX_ATTEMPTS=5
EXECUTION_CURRENT_PATH=""

# Execute with fallback mechanism
fallback_execution() {
  local primary_command="$1"
  local fallback_command="$2"
  local execution_context="${3:-general}"
  local attempt_id="$(date +%s)_$$"

  log_debug "Starting fallback execution (context: $execution_context, id: $attempt_id)"
  log_debug "Primary command: $primary_command"
  log_debug "Fallback command: $fallback_command"

  # Track execution attempt
  track_execution_attempt "$attempt_id" "primary" "$primary_command" "$execution_context"

  # Try primary command first
  log_info "Attempting primary execution: $execution_context"
  if eval "$primary_command"; then
    log_success "Primary execution successful"
    track_execution_result "$attempt_id" "primary" "success"
    return 0
  else
    local primary_exit_code=$?
    log_warning "Primary execution failed (exit code: $primary_exit_code)"
    track_execution_result "$attempt_id" "primary" "failed:$primary_exit_code"

    # Try fallback command
    log_info "Attempting fallback execution"
    track_execution_attempt "$attempt_id" "fallback" "$fallback_command" "$execution_context"

    if eval "$fallback_command"; then
      log_success "Fallback execution successful"
      track_execution_result "$attempt_id" "fallback" "success"
      return 0
    else
      local fallback_exit_code=$?
      log_error "Both primary and fallback execution failed (fallback exit code: $fallback_exit_code)"
      track_execution_result "$attempt_id" "fallback" "failed:$fallback_exit_code"
      return 1
    fi
  fi
}

# Select alternative build method based on failure context
alternative_build_method() {
  local build_type="$1"
  local platform_type="$2"
  local failure_context="${3:-unknown}"

  log_debug "Selecting alternative build method (type: $build_type, platform: $platform_type, context: $failure_context)"

  case "$build_type" in
  "direct")
    log_info "Using direct nix build approach"
    if command -v nix >/dev/null 2>&1; then
      # Direct nix build without platform-specific rebuild tools
      case "$platform_type" in
      "darwin")
        nix build --extra-experimental-features 'nix-command flakes' '.#darwinConfigurations.'"${HOSTNAME:-$(hostname)}"'.system'
        ;;
      "linux")
        nix build --extra-experimental-features 'nix-command flakes' '.#nixosConfigurations.'"${HOSTNAME:-$(hostname)}"'.config.system.build.toplevel'
        ;;
      *)
        log_error "Unsupported platform for direct build: $platform_type"
        return 1
        ;;
      esac
    else
      log_error "Nix command not available for direct build method"
      return 1
    fi
    ;;
  "legacy")
    log_info "Using legacy build approach"
    # Attempt to use older, more compatible build methods
    case "$platform_type" in
    "darwin")
      # Try legacy darwin-rebuild if available
      if command -v darwin-rebuild >/dev/null 2>&1; then
        darwin-rebuild switch --flake .
      else
        log_error "Legacy darwin-rebuild not available"
        return 1
      fi
      ;;
    "linux")
      # Try legacy nixos-rebuild
      if command -v nixos-rebuild >/dev/null 2>&1; then
        nixos-rebuild switch --flake .
      else
        log_error "Legacy nixos-rebuild not available"
        return 1
      fi
      ;;
    *)
      log_error "Unsupported platform for legacy build: $platform_type"
      return 1
      ;;
    esac
    ;;
  "minimal")
    log_info "Using minimal build approach"
    # Build only essential components
    if command -v nix >/dev/null 2>&1; then
      # Build minimal configuration
      nix build --extra-experimental-features 'nix-command flakes' --show-trace '.#minimal' 2>/dev/null ||
        nix build --extra-experimental-features 'nix-command flakes' '.#packages.'"$platform_type"'.minimal' 2>/dev/null ||
        nix build --extra-experimental-features 'nix-command flakes' '.#devShells.'"$platform_type"'.default'
    else
      log_error "Nix not available for minimal build"
      return 1
    fi
    ;;
  "user-only")
    log_info "Using user-only build approach (no system changes)"
    # Build and activate only user configuration
    if command -v home-manager >/dev/null 2>&1; then
      home-manager switch --flake .
    elif command -v nix >/dev/null 2>&1; then
      nix build --extra-experimental-features 'nix-command flakes' '.#homeConfigurations.'"${USER:-$(whoami)}"'.activationPackage'
      if [ -f ./result/activate ]; then
        ./result/activate
      fi
    else
      log_error "No user-only build method available"
      return 1
    fi
    ;;
  *)
    log_error "Unknown build method: $build_type"
    return 1
    ;;
  esac
}

# Enter emergency mode with specific recovery actions
emergency_mode() {
  local emergency_type="$1"
  local recovery_action="${2:-auto}"

  log_warning "Entering emergency mode (type: $emergency_type, action: $recovery_action)"

  # Set emergency mode flag
  export EMERGENCY_MODE=true
  export EMERGENCY_TYPE="$emergency_type"

  case "$emergency_type" in
  "network_failure")
    log_info "Network failure detected - enabling offline mode"
    export OFFLINE_MODE=true
    export NIX_CONFIG="substituters = "

    case "$recovery_action" in
    "auto" | "offline")
      log_info "Emergency action: switching to offline operations"
      # Disable all network-dependent operations
      export NIX_REMOTE=""
      export CACHIX_AUTH_TOKEN=""
      ;;
    "local-cache")
      log_info "Emergency action: using local cache only"
      # Use only local nix store
      export NIX_CONFIG="substituters = "
      ;;
    esac
    ;;
  "build_failure")
    log_info "Build failure detected - attempting recovery"
    case "$recovery_action" in
    "auto" | "cleanup")
      log_info "Emergency action: cleaning build environment"
      # Clean nix store and caches
      nix-collect-garbage -d >/dev/null 2>&1 || true
      rm -rf ~/.cache/nix 2>/dev/null || true
      ;;
    "rollback")
      log_info "Emergency action: rolling back to previous generation"
      case "${PLATFORM_TYPE:-}" in
      "darwin")
        darwin-rebuild rollback 2>/dev/null || true
        ;;
      "linux")
        nixos-rebuild rollback 2>/dev/null || true
        ;;
      esac
      ;;
    "minimal")
      log_info "Emergency action: switching to minimal build"
      export BUILD_TYPE="minimal"
      export SKIP_HEAVY_PACKAGES=true
      ;;
    esac
    ;;
  "dependency_failure")
    log_info "Dependency failure detected - using alternative dependencies"
    export USE_ALTERNATIVE_DEPS=true

    case "$recovery_action" in
    "auto" | "fallback")
      log_info "Emergency action: switching to fallback dependency sources"
      # Use alternative package sources
      export NIXPKGS_ALLOW_UNFREE=1
      export NIXPKGS_ALLOW_BROKEN=1
      ;;
    "minimal-deps")
      log_info "Emergency action: using minimal dependency set"
      export MINIMAL_DEPENDENCIES=true
      ;;
    esac
    ;;
  "permission_failure")
    log_info "Permission failure detected - switching to user mode"
    export USER_MODE_ONLY=true
    export SUDO_REQUIRED=false

    case "$recovery_action" in
    "auto" | "user-mode")
      log_info "Emergency action: switching to user-only operations"
      # Disable all system-level operations
      unset SUDO_PASSWORD
      ;;
    esac
    ;;
  "resource_exhaustion")
    log_info "Resource exhaustion detected - reducing resource usage"
    export LOW_RESOURCE_MODE=true

    case "$recovery_action" in
    "auto" | "reduce")
      log_info "Emergency action: reducing resource consumption"
      export NIX_MAX_JOBS=1
      export NIX_CORES=1
      ;;
    esac
    ;;
  *)
    log_error "Unknown emergency type: $emergency_type"
    return 1
    ;;
  esac

  log_warning "Emergency mode activated successfully"
  return 0
}

# Select optimal execution path based on failure context
select_execution_path() {
  local failure_context="$1"
  local available_methods="$2"
  local platform_type="${3:-${PLATFORM_TYPE:-unknown}}"

  log_debug "Selecting execution path for failure: $failure_context"
  log_debug "Available methods: $available_methods"
  log_debug "Platform type: $platform_type"

  case "$failure_context" in
  "network_timeout" | "network_unreachable" | "network_failure")
    if echo "$available_methods" | grep -q "offline_mode"; then
      echo "offline_mode"
      log_info "Selected offline mode for network failure"
    elif echo "$available_methods" | grep -q "local_cache"; then
      echo "local_cache"
      log_info "Selected local cache mode for network failure"
    else
      echo "emergency_mode"
      log_warning "No network-specific recovery available, using emergency mode"
    fi
    ;;
  "build_dependency_missing" | "dependency_resolution_failed")
    if echo "$available_methods" | grep -q "alternative_dependencies"; then
      echo "alternative_dependencies"
      log_info "Selected alternative dependencies for dependency failure"
    elif echo "$available_methods" | grep -q "minimal_build"; then
      echo "minimal_build"
      log_info "Selected minimal build for dependency failure"
    else
      echo "emergency_mode"
      log_warning "No dependency-specific recovery available, using emergency mode"
    fi
    ;;
  "insufficient_permissions" | "sudo_failed" | "permission_denied")
    if echo "$available_methods" | grep -q "user_mode_build"; then
      echo "user_mode_build"
      log_info "Selected user mode build for permission failure"
    elif echo "$available_methods" | grep -q "minimal_build"; then
      echo "minimal_build"
      log_info "Selected minimal build for permission failure"
    else
      echo "emergency_mode"
      log_warning "No permission-specific recovery available, using emergency mode"
    fi
    ;;
  "resource_exhaustion" | "out_of_memory" | "disk_full")
    if echo "$available_methods" | grep -q "minimal_build"; then
      echo "minimal_build"
      log_info "Selected minimal build for resource exhaustion"
    elif echo "$available_methods" | grep -q "cleanup_first"; then
      echo "cleanup_first"
      log_info "Selected cleanup approach for resource exhaustion"
    else
      echo "emergency_mode"
      log_warning "No resource-specific recovery available, using emergency mode"
    fi
    ;;
  "build_timeout" | "build_hung")
    if echo "$available_methods" | grep -q "alternative_build"; then
      echo "alternative_build"
      log_info "Selected alternative build method for build timeout"
    elif echo "$available_methods" | grep -q "direct_nix"; then
      echo "direct_nix"
      log_info "Selected direct nix build for build timeout"
    else
      echo "emergency_mode"
      log_warning "No timeout-specific recovery available, using emergency mode"
    fi
    ;;
  *)
    echo "emergency_mode"
    log_warning "Unknown failure context '$failure_context', defaulting to emergency mode"
    ;;
  esac
}

# Track execution attempts for analysis and recovery
track_execution_attempt() {
  local attempt_id="$1"
  local execution_type="$2" # primary, fallback, emergency, etc.
  local command="$3"
  local context="$4"

  # Ensure tracking directory exists
  mkdir -p "$(dirname "$EXECUTION_ATTEMPTS_FILE")"

  # Initialize tracking file if it doesn't exist
  if [ ! -f "$EXECUTION_ATTEMPTS_FILE" ]; then
    echo '{"attempts": []}' >"$EXECUTION_ATTEMPTS_FILE"
  fi

  # Add attempt record (simplified JSON append)
  local temp_file=$(mktemp)
  {
    echo "{"
    echo "  \"id\": \"$attempt_id\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"type\": \"$execution_type\","
    echo "  \"command\": \"$command\","
    echo "  \"context\": \"$context\","
    echo '  "status": "started"'
    echo "},"
  } >>"$temp_file"

  # Append to attempts file (simplified)
  cat "$temp_file" >>"${EXECUTION_ATTEMPTS_FILE}.log"
  rm -f "$temp_file"

  log_debug "Tracked execution attempt: $attempt_id ($execution_type)"
}

# Track execution result
track_execution_result() {
  local attempt_id="$1"
  local execution_type="$2"
  local result="$3" # success, failed:code, etc.

  # Log result (simplified tracking)
  {
    echo "{"
    echo "  \"id\": \"$attempt_id\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"type\": \"$execution_type\","
    echo "  \"result\": \"$result\""
    echo "},"
  } >>"${EXECUTION_ATTEMPTS_FILE}.results"

  log_debug "Tracked execution result: $attempt_id -> $result"
}

# Analyze execution attempts and determine if recovery is possible
recover_from_failure() {
  local max_attempts="${1:-$EXECUTION_MAX_ATTEMPTS}"
  local context="${2:-general}"

  log_debug "Analyzing execution attempts for recovery (max: $max_attempts, context: $context)"

  # Count recent attempts (last hour)
  local recent_attempts=0
  if [ -f "${EXECUTION_ATTEMPTS_FILE}.log" ]; then
    recent_attempts=$(wc -l <"${EXECUTION_ATTEMPTS_FILE}.log" 2>/dev/null || echo 0)
  fi

  log_debug "Found $recent_attempts recent execution attempts"

  if [ "$recent_attempts" -ge "$max_attempts" ]; then
    log_error "Maximum execution attempts exceeded ($recent_attempts >= $max_attempts)"
    log_error "Entering emergency mode to prevent infinite retry loops"
    emergency_mode "max_attempts_exceeded" "abort"
    return 1
  else
    local remaining_attempts=$((max_attempts - recent_attempts))
    log_info "Recovery possible - $remaining_attempts attempts remaining"
    return 0
  fi
}

# Clean up execution tracking data
cleanup_execution_tracking() {
  local retention_hours="${1:-24}"

  log_debug "Cleaning up execution tracking data (retention: ${retention_hours}h)"

  # Remove old tracking files
  find "$(dirname "$EXECUTION_ATTEMPTS_FILE")" -name "execution_attempts.*" -mtime "+${retention_hours}h" -delete 2>/dev/null || true

  # Clean up old log entries (keep only recent ones)
  if [ -f "${EXECUTION_ATTEMPTS_FILE}.log" ]; then
    local temp_file=$(mktemp)
    tail -n 100 "${EXECUTION_ATTEMPTS_FILE}.log" >"$temp_file"
    mv "$temp_file" "${EXECUTION_ATTEMPTS_FILE}.log"
  fi

  log_debug "Execution tracking cleanup completed"
}

# Export functions for use by other modules
export -f fallback_execution
export -f alternative_build_method
export -f emergency_mode
export -f select_execution_path
export -f track_execution_attempt
export -f track_execution_result
export -f recover_from_failure
export -f cleanup_execution_tracking
