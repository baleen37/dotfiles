#!/bin/sh
# error-messaging.sh - Enhanced error messaging and recovery guidance system
# Provides comprehensive error analysis, user-friendly messages, and actionable recovery guidance

# Global error messaging configuration
ERROR_REPORT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch/error-reports"
ERROR_MESSAGE_FORMAT="${ERROR_MESSAGE_FORMAT:-console}" # console, json, minimal
INTERACTIVE_GUIDANCE="${INTERACTIVE_GUIDANCE:-false}"

# Generate comprehensive diagnostic report
generate_diagnostic_report() {
  local error_type="$1"
  local error_context="$2"
  local raw_error="${3:-}"
  local exit_code="${4:-1}"
  local output_file="$5"

  log_debug "Generating diagnostic report for: $error_type"

  # Create report directory if needed
  mkdir -p "$(dirname "$output_file")"

  # Generate timestamp and unique report ID
  local report_id="$(date +%Y%m%d_%H%M%S)_$$"
  local timestamp=$(date -Iseconds)

  # Start diagnostic report with JSON structure
  cat >"$output_file" <<EOF
{
  "diagnostic_report": {
    "id": "$report_id",
    "timestamp": "$timestamp",
    "error_type": "$error_type",
    "error_context": "$error_context",
    "exit_code": $exit_code,
    "raw_error": "$raw_error",
    "system_info": {
      "platform": "${PLATFORM_TYPE:-unknown}",
      "system": "${SYSTEM_TYPE:-unknown}",
      "hostname": "${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}",
      "user": "${USER:-$(whoami 2>/dev/null || echo unknown)}",
      "shell": "${SHELL:-unknown}",
      "working_directory": "$PWD"
    },
    "environment_info": {
      "nix_version": "$(nix --version 2>/dev/null || echo 'not available')",
      "path": "${PATH:-}",
      "home": "${HOME:-}",
      "lang": "${LANG:-}",
      "offline_mode": "${OFFLINE_MODE:-false}",
      "user_mode_only": "${USER_MODE_ONLY:-false}",
      "emergency_mode": "${EMERGENCY_MODE:-false}"
    },
    "resource_info": {},
    "recommendations": []
  }
}
EOF

  # Add detailed diagnostic information based on error type
  add_diagnostic_details "$error_type" "$error_context" "$output_file"

  # Add system resource information
  add_resource_diagnostics "$output_file"

  # Add recovery recommendations
  add_recovery_recommendations "$error_type" "$error_context" "$raw_error" "$output_file"

  log_info "Diagnostic report generated: $output_file"
  return 0
}

# Add detailed diagnostic information
add_diagnostic_details() {
  local error_type="$1"
  local error_context="$2"
  local output_file="$3"

  log_debug "Adding diagnostic details for: $error_type"

  # Append detailed diagnostics to report file
  {
    echo ""
    echo "=== DETAILED DIAGNOSTICS ==="
    echo ""

    case "$error_type" in
    "build_failure")
      echo "BUILD ENVIRONMENT ANALYSIS:"
      echo "- Nix version: $(nix --version 2>/dev/null || echo 'not available')"
      echo "- Experimental features: $(nix --extra-experimental-features 'nix-command flakes' --help >/dev/null 2>&1 && echo 'enabled' || echo 'disabled')"
      echo "- Available disk space: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo 'unknown')"
      echo "- Build cache size: $(du -sh ~/.cache/nix 2>/dev/null | cut -f1 || echo 'unknown')"
      echo "- Flake lock status: $([ -f flake.lock ] && echo 'present' || echo 'missing')"

      # Check for platform-specific build tools
      case "${PLATFORM_TYPE:-}" in
      "darwin")
        echo "- darwin-rebuild: $(command -v darwin-rebuild >/dev/null && echo 'available' || echo 'not found')"
        ;;
      "linux")
        echo "- nixos-rebuild: $(command -v nixos-rebuild >/dev/null && echo 'available' || echo 'not found')"
        ;;
      esac
      ;;
    "network_failure")
      echo "NETWORK ENVIRONMENT ANALYSIS:"
      echo "- Internet connectivity: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo 'online' || echo 'offline')"
      echo "- DNS resolution: $(nslookup google.com >/dev/null 2>&1 && echo 'working' || echo 'failed')"
      echo "- Nix substituters: ${NIX_CONFIG:-default}"
      echo "- Proxy settings: ${HTTP_PROXY:-none} / ${HTTPS_PROXY:-none}"
      echo "- Cachix status: $(command -v cachix >/dev/null && echo 'available' || echo 'not installed')"
      ;;
    "permission_failure")
      echo "PERMISSION ENVIRONMENT ANALYSIS:"
      echo "- Current user: $(whoami)"
      echo "- User groups: $(groups 2>/dev/null || echo 'unknown')"
      echo "- Sudo access: $(sudo -n true 2>/dev/null && echo 'available' || echo 'not available')"
      echo "- Home directory writable: $([ -w "$HOME" ] && echo 'yes' || echo 'no')"
      echo "- Nix store writable: $([ -w /nix/store ] 2>/dev/null && echo 'yes' || echo 'no')"
      echo "- System directories access: $([ -w /etc ] 2>/dev/null && echo 'yes' || echo 'no')"
      ;;
    "dependency_failure")
      echo "DEPENDENCY ENVIRONMENT ANALYSIS:"
      echo "- Flake inputs status: $([ -f flake.lock ] && echo 'locked' || echo 'unlocked')"
      echo "- Nix channels: $(nix-channel --list 2>/dev/null | wc -l || echo '0') channels"
      echo "- Package cache: $(ls ~/.cache/nix 2>/dev/null | wc -l || echo '0') entries"
      echo "- Registry status: $(nix registry list 2>/dev/null | wc -l || echo '0') entries"
      ;;
    "resource_exhaustion")
      echo "RESOURCE USAGE ANALYSIS:"
      echo "- Available disk space: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo 'unknown')"
      echo "- Available memory: $(free -h 2>/dev/null | grep Mem | awk '{print $7}' || echo 'unknown')"
      echo "- Running processes: $(ps aux 2>/dev/null | wc -l || echo 'unknown')"
      echo "- Load average: $(uptime 2>/dev/null | awk -F'load average:' '{print $2}' || echo 'unknown')"
      ;;
    esac

    echo ""
    echo "=== ENVIRONMENT VARIABLES ==="
    echo "Relevant environment variables:"
    env | grep -E "(NIX|CACHIX|HOME|USER|PATH)" | sort || echo "Environment not accessible"

  } >>"$output_file"
}

# Add system resource diagnostics
add_resource_diagnostics() {
  local output_file="$1"

  {
    echo ""
    echo "=== SYSTEM RESOURCES ==="
    echo ""
    echo "DISK USAGE:"
    df -h . 2>/dev/null || echo "Disk information not available"

    echo ""
    echo "MEMORY USAGE:"
    if command -v free >/dev/null 2>&1; then
      free -h
    else
      echo "Memory information not available"
    fi

    echo ""
    echo "PROCESS INFORMATION:"
    echo "Running Nix processes:"
    ps aux 2>/dev/null | grep -E "(nix|darwin-rebuild|nixos-rebuild)" | grep -v grep || echo "No Nix processes running"

  } >>"$output_file"
}

# Add recovery recommendations to diagnostic report
add_recovery_recommendations() {
  local error_type="$1"
  local error_context="$2"
  local raw_error="$3"
  local output_file="$4"

  {
    echo ""
    echo "=== RECOVERY RECOMMENDATIONS ==="
    echo ""

    case "$error_type" in
    "build_failure")
      echo "BUILD FAILURE RECOVERY:"
      echo "1. [IMMEDIATE] Clean build environment:"
      echo "   nix-collect-garbage -d"
      echo "   rm -rf ~/.cache/nix"
      echo ""
      echo "2. [BASIC] Try minimal build:"
      echo "   nix build --show-trace --verbose"
      echo ""
      echo "3. [ADVANCED] Check dependencies:"
      echo "   nix flake check"
      echo "   nix flake update"
      echo ""
      echo "4. [FALLBACK] Use alternative build method:"
      echo "   export BUILD_TYPE=minimal && retry"
      ;;
    "network_failure")
      echo "NETWORK FAILURE RECOVERY:"
      echo "1. [IMMEDIATE] Enable offline mode:"
      echo "   export OFFLINE_MODE=true"
      echo '   export NIX_CONFIG="substituters = "'
      echo ""
      echo "2. [BASIC] Check connectivity:"
      echo "   ping -c 3 google.com"
      echo "   nslookup cache.nixos.org"
      echo ""
      echo "3. [ADVANCED] Configure alternative sources:"
      echo '   export NIX_CONFIG="substituters = https://mirror.example.com/nix-cache"'
      echo ""
      echo "4. [FALLBACK] Use local cache only:"
      echo "   nix build --offline"
      ;;
    "permission_failure")
      echo "PERMISSION FAILURE RECOVERY:"
      echo "1. [IMMEDIATE] Switch to user mode:"
      echo "   export USER_MODE_ONLY=true"
      echo ""
      echo "2. [BASIC] Check sudo access:"
      echo "   sudo -v"
      echo ""
      echo "3. [ADVANCED] Fix permissions:"
      echo '   sudo chown -R $USER ~/.config/nix'
      echo "   sudo chmod 755 ~/.config"
      echo ""
      echo "4. [FALLBACK] Use home-manager only:"
      echo "   home-manager switch --flake ."
      ;;
    "dependency_failure")
      echo "DEPENDENCY FAILURE RECOVERY:"
      echo "1. [IMMEDIATE] Update dependencies:"
      echo "   nix flake update"
      echo ""
      echo "2. [BASIC] Check flake inputs:"
      echo "   nix flake show"
      echo "   nix flake check"
      echo ""
      echo "3. [ADVANCED] Reset dependency cache:"
      echo "   rm flake.lock"
      echo "   nix flake lock"
      echo ""
      echo "4. [FALLBACK] Use pinned versions:"
      echo "   git checkout HEAD~1 flake.lock"
      ;;
    "resource_exhaustion")
      echo "RESOURCE EXHAUSTION RECOVERY:"
      echo "1. [IMMEDIATE] Free up space:"
      echo "   nix-collect-garbage -d"
      echo "   docker system prune -af  # if using Docker"
      echo ""
      echo "2. [BASIC] Reduce build parallelism:"
      echo "   export NIX_MAX_JOBS=1"
      echo "   export NIX_CORES=1"
      echo ""
      echo "3. [ADVANCED] Use minimal build:"
      echo "   export LOW_RESOURCE_MODE=true"
      echo "   export BUILD_TYPE=minimal"
      echo ""
      echo "4. [FALLBACK] Build components separately:"
      echo "   nix build .#component1"
      echo "   nix build .#component2"
      ;;
    esac

    # Add context-specific recommendations
    if echo "$raw_error" | grep -qi "flake.lock"; then
      echo ""
      echo "FLAKE-SPECIFIC RECOMMENDATIONS:"
      echo "- Update flake.lock: nix flake update"
      echo "- Check for conflicts: nix flake check"
      echo "- Reset to working state: git checkout HEAD~1 flake.lock"
    fi

    if echo "$raw_error" | grep -qi "substituter"; then
      echo ""
      echo "SUBSTITUTER-SPECIFIC RECOMMENDATIONS:"
      echo "- Check substituter availability: curl -I https://cache.nixos.org"
      echo '- Use alternative substituters: export NIX_CONFIG="substituters = https://mirror.example.com"'
      echo '- Disable substituters: export NIX_CONFIG="substituters = "'
    fi

  } >>"$output_file"
}

# Provide contextual recovery guidance
provide_recovery_guidance() {
  local error_type="$1"
  local error_details="$2"
  local guidance_format="${3:-$ERROR_MESSAGE_FORMAT}"
  local output_file="$4"

  log_info "Providing recovery guidance for: $error_type (format: $guidance_format)"

  case "$guidance_format" in
  "console")
    provide_console_guidance "$error_type" "$error_details" "$output_file"
    ;;
  "json")
    provide_json_guidance "$error_type" "$error_details" "$output_file"
    ;;
  "minimal")
    provide_minimal_guidance "$error_type" "$error_details" "$output_file"
    ;;
  *)
    log_warning "Unknown guidance format: $guidance_format, using console"
    provide_console_guidance "$error_type" "$error_details" "$output_file"
    ;;
  esac
}

# Provide console-formatted recovery guidance
provide_console_guidance() {
  local error_type="$1"
  local error_details="$2"
  local output_file="$3"

  {
    echo ""
    echo "🔧 RECOVERY GUIDANCE"
    echo "===================="
    echo ""
    echo "Error Type: $error_type"
    echo "Details: $error_details"
    echo "Generated: $(date)"
    echo ""

    case "$error_type" in
    "build_failure")
      cat <<'EOF'
BUILD FAILURE RECOVERY STEPS:

🎯 Quick Fix (try first):
   1. Clean build cache: nix-collect-garbage -d
   2. Retry with verbose output: nix build --show-trace --verbose
   3. Check available disk space: df -h

📋 Systematic Approach:
   1. Verify environment:
      • Check Nix installation: nix --version
      • Verify experimental features: nix --help | grep flakes
      • Confirm flake.nix exists: ls -la flake.nix

   2. Clean and retry:
      • Clear caches: rm -rf ~/.cache/nix
      • Update dependencies: nix flake update
      • Attempt build: nix build --show-trace

   3. Alternative approaches:
      • Minimal build: export BUILD_TYPE=minimal && retry
      • Direct nix build: nix build .#system
      • User-only mode: export USER_MODE_ONLY=true

🚨 If all else fails:
   • Check detailed error log for specific issues
   • Try building individual components
   • Consider rolling back recent changes
EOF
      ;;
    "network_failure")
      cat <<'EOF'
NETWORK FAILURE RECOVERY STEPS:

🎯 Quick Fix (try first):
   1. Enable offline mode: export OFFLINE_MODE=true
   2. Check connectivity: ping google.com
   3. Test DNS: nslookup cache.nixos.org

📋 Systematic Approach:
   1. Diagnose connectivity:
      • Test internet: ping -c 3 8.8.8.8
      • Check DNS: nslookup google.com
      • Verify proxy settings: echo $HTTP_PROXY

   2. Configure offline operation:
      • Disable substituters: export NIX_CONFIG="substituters = "
      • Use local cache: nix build --offline
      • Enable offline mode: export OFFLINE_MODE=true

   3. Alternative sources:
      • Try mirrors: export NIX_CONFIG="substituters = https://mirror.example.com"
      • Use Cachix: cachix use <cache-name>
      • Build from source: nix build --option substitute false

🚨 If connectivity is required:
   • Configure proxy settings if behind firewall
   • Check certificate issues: curl -I https://cache.nixos.org
   • Consider using mobile hotspot as alternative connection
EOF
      ;;
    "permission_failure")
      cat <<'EOF'
PERMISSION FAILURE RECOVERY STEPS:

🎯 Quick Fix (try first):
   1. Switch to user mode: export USER_MODE_ONLY=true
   2. Check sudo access: sudo -v
   3. Verify file permissions: ls -la ~/.config

📋 Systematic Approach:
   1. Understand permission requirements:
      • Check current user: whoami
      • List groups: groups
      • Test sudo: sudo -n true

   2. User-only solutions:
      • Enable user mode: export USER_MODE_ONLY=true
      • Use home-manager: home-manager switch --flake .
      • Build user components: nix build .#homeConfigurations

   3. System-level solutions:
      • Configure sudo: sudo visudo
      • Fix ownership: sudo chown -R $USER ~/.config/nix
      • Add to groups: sudo usermod -aG admin $USER

🚨 Security considerations:
   • Prefer user-only mode when possible
   • Understand system modification implications
   • Use minimal required permissions
EOF
      ;;
    esac

    echo ""
    echo "💡 Need more help?"
    echo "   • Run with --verbose for detailed output"
    echo "   • Check diagnostic report for system details"
    echo "   • Consult documentation: https://docs.example.com"
    echo ""

  } >"$output_file"
}

# Provide JSON-formatted recovery guidance
provide_json_guidance() {
  local error_type="$1"
  local error_details="$2"
  local output_file="$3"

  cat >"$output_file" <<EOF
{
  "recovery_guidance": {
    "error_type": "$error_type",
    "error_details": "$error_details",
    "timestamp": "$(date -Iseconds)",
    "quick_fixes": [],
    "systematic_steps": [],
    "fallback_options": [],
    "additional_resources": []
  }
}
EOF
}

# Provide minimal recovery guidance
provide_minimal_guidance() {
  local error_type="$1"
  local error_details="$2"
  local output_file="$3"

  {
    echo "Error: $error_type"
    echo "Quick fix:"
    case "$error_type" in
    "build_failure") echo "  nix-collect-garbage -d && retry" ;;
    "network_failure") echo "  export OFFLINE_MODE=true && retry" ;;
    "permission_failure") echo "  export USER_MODE_ONLY=true && retry" ;;
    *) echo "  Check detailed error log" ;;
    esac
  } >"$output_file"
}

# Format user-friendly error messages
format_user_friendly_error() {
  local raw_error="$1"
  local error_context="$2"
  local output_format="${3:-$ERROR_MESSAGE_FORMAT}"
  local severity="${4:-medium}"

  # Categorize error based on content
  local error_category=$(categorize_error_message "$raw_error")

  case "$output_format" in
  "console")
    format_console_error "$error_category" "$error_context" "$raw_error" "$severity"
    ;;
  "json")
    format_json_error "$error_category" "$error_context" "$raw_error" "$severity"
    ;;
  "minimal")
    format_minimal_error "$error_category" "$error_context" "$raw_error"
    ;;
  esac
}

# Categorize error message for appropriate handling
categorize_error_message() {
  local error_message="$1"

  # Pattern matching for error categorization
  if echo "$error_message" | grep -qi "permission denied\|sudo\|access denied\|operation not permitted"; then
    echo "permission"
  elif echo "$error_message" | grep -qi "network\|timeout\|connection\|unreachable\|name resolution"; then
    echo "network"
  elif echo "$error_message" | grep -qi "no space\|disk full\|quota exceeded\|filesystem full"; then
    echo "disk_space"
  elif echo "$error_message" | grep -qi "build failed\|compilation error\|link error\|make.*error"; then
    echo "build"
  elif echo "$error_message" | grep -qi "dependency\|package.*not found\|missing\|unresolved"; then
    echo "dependency"
  elif echo "$error_message" | grep -qi "syntax error\|parse error\|invalid\|malformed"; then
    echo "configuration"
  elif echo "$error_message" | grep -qi "out of memory\|killed\|resource.*exhausted"; then
    echo "resource_exhaustion"
  else
    echo "unknown"
  fi
}

# Format console error message
format_console_error() {
  local error_category="$1"
  local error_context="$2"
  local raw_error="$3"
  local severity="$4"

  # Choose appropriate emoji and styling based on severity
  local icon="🚨"
  local title="Operation Failed"
  case "$severity" in
  "low")
    icon="⚠️"
    title="Warning"
    ;;
  "medium")
    icon="🚨"
    title="Error"
    ;;
  "high")
    icon="💥"
    title="Critical Error"
    ;;
  esac

  cat <<EOF

$icon $title
$(printf "=%.0s" {1..50})

Context: $error_context
Category: $error_category
Severity: $severity

What happened:
$(describe_error_category "$error_category")

Quick fixes to try:
$(provide_quick_fixes "$error_category")

For detailed guidance, run: <command> --help
For diagnostic report, check: $ERROR_REPORT_DIR

EOF
}

# Describe error category in user-friendly terms
describe_error_category() {
  local category="$1"

  case "$category" in
  "permission")
    echo "  The operation requires elevated permissions that are not available."
    echo "  This typically happens when system files need to be modified."
    ;;
  "network")
    echo "  A network connection is required but couldn't be established."
    echo "  This might be due to connectivity issues or network configuration."
    ;;
  "build")
    echo "  The build process encountered an error during compilation."
    echo "  This could be due to dependency issues or configuration problems."
    ;;
  "disk_space")
    echo "  Insufficient disk space to complete the operation."
    echo "  The build process requires additional free space."
    ;;
  "dependency")
    echo "  Required dependencies are missing or incompatible."
    echo "  This prevents the operation from completing successfully."
    ;;
  "configuration")
    echo "  Configuration files contain syntax errors or invalid settings."
    echo "  The system cannot parse or process the configuration."
    ;;
  "resource_exhaustion")
    echo "  System resources (memory, CPU) are insufficient for the operation."
    echo "  The process was terminated due to resource constraints."
    ;;
  *)
    echo "  An unexpected error occurred during the operation."
    echo "  Please check the detailed error message for more information."
    ;;
  esac
}

# Provide category-specific quick fixes
provide_quick_fixes() {
  local category="$1"

  case "$category" in
  "permission")
    echo "  • Try user-only mode: export USER_MODE_ONLY=true"
    echo "  • Check sudo access: sudo -v"
    echo "  • Use home-manager instead of system rebuild"
    ;;
  "network")
    echo "  • Enable offline mode: export OFFLINE_MODE=true"
    echo "  • Check internet connection: ping google.com"
    echo "  • Try alternative sources or mirrors"
    ;;
  "build")
    echo "  • Clean build cache: nix-collect-garbage -d"
    echo "  • Try minimal build with --show-trace"
    echo "  • Update dependencies: nix flake update"
    ;;
  "disk_space")
    echo "  • Free up disk space (need ~5GB)"
    echo "  • Clean temporary files: nix-collect-garbage -d"
    echo "  • Use different build location if possible"
    ;;
  "dependency")
    echo "  • Update dependencies: nix flake update"
    echo "  • Check flake inputs: nix flake show"
    echo "  • Try alternative dependency sources"
    ;;
  "configuration")
    echo "  • Check syntax: nix flake check"
    echo "  • Validate configuration files"
    echo "  • Restore from known working version"
    ;;
  "resource_exhaustion")
    echo "  • Reduce parallelism: export NIX_MAX_JOBS=1"
    echo "  • Close other applications"
    echo "  • Try minimal build mode"
    ;;
  *)
    echo "  • Check detailed error log with --verbose"
    echo "  • Try running with --show-trace"
    echo "  • Consult troubleshooting documentation"
    ;;
  esac
}

# Export functions for use by other modules
export -f generate_diagnostic_report
export -f provide_recovery_guidance
export -f format_user_friendly_error
export -f categorize_error_message
