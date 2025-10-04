#!/bin/sh
# pre-validation.sh - Pre-execution validation system
# Comprehensive environment, prerequisites, and dependency validation

# Validate essential environment variables and settings
validate_environment() {
  local validation_errors=""
  local validation_warnings=""

  log_debug "Validating environment configuration"

  # Check essential environment variables
  local essential_vars="HOME USER PATH SHELL"
  for var in $essential_vars; do
    eval "local var_value=\${$var:-}"
    if [ -z "$var_value" ]; then
      validation_errors="$validation_errors missing_${var}"
      log_error "Essential environment variable $var is not set"
    fi
  done

  # Check platform type detection
  if [ -z "${PLATFORM_TYPE:-}" ]; then
    validation_errors="$validation_errors missing_platform_type"
    log_error "Platform type not detected"
  else
    log_debug "Platform type detected: $PLATFORM_TYPE"
  fi

  # Check system type detection
  if [ -z "${SYSTEM_TYPE:-}" ]; then
    validation_warnings="$validation_warnings missing_system_type"
    log_warning "System type not detected"
  else
    log_debug "System type detected: $SYSTEM_TYPE"
  fi

  # Validate PATH contents for platform appropriateness
  case "${PLATFORM_TYPE:-}" in
  "darwin")
    if ! echo "$PATH" | grep -q "/usr/bin"; then
      validation_warnings="$validation_warnings path_missing_usr_bin"
      log_warning "PATH may be missing standard Darwin paths"
    fi
    ;;
  "linux")
    if ! echo "$PATH" | grep -q "/bin"; then
      validation_warnings="$validation_warnings path_missing_bin"
      log_warning "PATH may be missing standard Linux paths"
    fi
    ;;
  esac

  # Check locale settings
  if [ -z "${LANG:-}" ] && [ -z "${LC_ALL:-}" ]; then
    validation_warnings="$validation_warnings missing_locale"
    log_warning "Locale settings not configured"
  fi

  # Check write permissions in key directories
  for dir in "$HOME" "${XDG_STATE_HOME:-$HOME/.local/state}" "${XDG_CACHE_HOME:-$HOME/.cache}"; do
    if [ ! -w "$dir" ]; then
      validation_errors="$validation_errors write_permission_${dir##*/}"
      log_error "No write permission in $dir"
    fi
  done

  # Report validation results
  if [ -n "$validation_errors" ]; then
    log_error "Environment validation failed with errors: $validation_errors"
    return 1
  elif [ -n "$validation_warnings" ]; then
    log_warning "Environment validation completed with warnings: $validation_warnings"
    return 0
  else
    log_success "Environment validation passed"
    return 0
  fi
}

# Check for required commands and tools
check_prerequisites() {
  local missing_commands=""
  local missing_optional=""
  local platform_missing=""

  log_debug "Checking system prerequisites"

  # Essential commands required for operation
  local essential_commands="sh bash nix"
  for cmd in $essential_commands; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_commands="$missing_commands $cmd"
      log_error "Essential command not found: $cmd"
    fi
  done

  # Optional but recommended commands
  local optional_commands="jq curl wget git"
  for cmd in $optional_commands; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_optional="$missing_optional $cmd"
      log_warning "Optional command not found: $cmd"
    fi
  done

  # Platform-specific rebuild commands
  case "${PLATFORM_TYPE:-}" in
  "darwin")
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
      platform_missing="$platform_missing darwin-rebuild"
      log_error "Platform-specific command not found: darwin-rebuild"
    fi
    ;;
  "linux")
    if ! command -v nixos-rebuild >/dev/null 2>&1; then
      platform_missing="$platform_missing nixos-rebuild"
      log_error "Platform-specific command not found: nixos-rebuild"
    fi
    ;;
  esac

  # Check Nix experimental features support
  if command -v nix >/dev/null 2>&1; then
    if ! nix --extra-experimental-features 'nix-command flakes' --help >/dev/null 2>&1; then
      missing_commands="$missing_commands nix-experimental-features"
      log_error "Nix experimental features (flakes) not supported"
    fi
  fi

  # Check sudo availability if required
  if [ "${SUDO_REQUIRED:-false}" = "true" ]; then
    if ! command -v sudo >/dev/null 2>&1; then
      missing_commands="$missing_commands sudo"
      log_error "sudo required but not available"
    fi
  fi

  # Report prerequisite check results
  if [ -n "$missing_commands" ] || [ -n "$platform_missing" ]; then
    log_error "Prerequisites check failed. Missing essential commands:$missing_commands$platform_missing"
    return 1
  elif [ -n "$missing_optional" ]; then
    log_warning "Prerequisites check completed with warnings. Missing optional commands:$missing_optional"
    return 0
  else
    log_success "Prerequisites check passed"
    return 0
  fi
}

# Verify project dependencies and file structure
verify_dependencies() {
  local dependency_errors=""
  local dependency_warnings=""

  log_debug "Verifying project dependencies and structure"

  # Determine project root
  local project_root="${PROJECT_ROOT:-}"
  if [ -z "$project_root" ]; then
    # Try to detect project root from script location
    if [ -n "${SCRIPT_DIR:-}" ]; then
      project_root=$(dirname "$SCRIPT_DIR")
    else
      project_root="$PWD"
    fi
  fi

  log_debug "Using project root: $project_root"

  # Check essential project files
  local essential_files="flake.nix flake.lock"
  for file in $essential_files; do
    if [ ! -f "$project_root/$file" ]; then
      dependency_errors="$dependency_errors missing_$file"
      log_error "Essential project file not found: $file"
    fi
  done

  # Check essential directories
  local essential_dirs="scripts scripts/lib modules"
  for dir in $essential_dirs; do
    if [ ! -d "$project_root/$dir" ]; then
      dependency_errors="$dependency_errors missing_${dir##*/}_dir"
      log_error "Essential directory not found: $dir"
    fi
  done

  # Check essential script files
  local essential_scripts="scripts/build-switch-common.sh"
  for script in $essential_scripts; do
    if [ ! -f "$project_root/$script" ]; then
      dependency_errors="$dependency_errors missing_${script##*/}"
      log_error "Essential script not found: $script"
    elif [ ! -x "$project_root/$script" ]; then
      dependency_warnings="$dependency_warnings non_executable_${script##*/}"
      log_warning "Script exists but is not executable: $script"
    fi
  done

  # Check essential lib modules
  local essential_modules="logging.sh performance.sh build-logic.sh sudo-management.sh"
  for module in $essential_modules; do
    if [ ! -f "$project_root/scripts/lib/$module" ]; then
      dependency_errors="$dependency_errors missing_$module"
      log_error "Essential lib module not found: $module"
    fi
  done

  # Check platform-specific modules if available
  local platform_dir="$project_root/modules/${PLATFORM_TYPE:-unknown}"
  if [ ! -d "$platform_dir" ]; then
    dependency_warnings="$dependency_warnings missing_platform_modules"
    log_warning "Platform-specific modules directory not found: $platform_dir"
  fi

  # Check configuration files
  local config_dir="$project_root/config"
  if [ -d "$config_dir" ]; then
    local important_configs="paths.yaml platforms.yaml"
    for config in $important_configs; do
      if [ ! -f "$config_dir/$config" ]; then
        dependency_warnings="$dependency_warnings missing_$config"
        log_warning "Important configuration file not found: $config"
      fi
    done
  else
    dependency_warnings="$dependency_warnings missing_config_dir"
    log_warning "Configuration directory not found"
  fi

  # Report dependency verification results
  if [ -n "$dependency_errors" ]; then
    log_error "Dependency verification failed with errors: $dependency_errors"
    return 1
  elif [ -n "$dependency_warnings" ]; then
    log_warning "Dependency verification completed with warnings: $dependency_warnings"
    return 0
  else
    log_success "Dependency verification passed"
    return 0
  fi
}

# Generate comprehensive validation report
generate_validation_report() {
  local validation_errors="$1"
  local validation_warnings="$2"
  local report_file="$3"

  log_debug "Generating validation report: $report_file"

  # Create report directory if needed
  mkdir -p "$(dirname "$report_file")"

  # Generate JSON validation report
  cat >"$report_file" <<EOF
{
  "validation_report": {
    "timestamp": "$(date -Iseconds)",
    "platform_type": "${PLATFORM_TYPE:-unknown}",
    "system_type": "${SYSTEM_TYPE:-unknown}",
    "project_root": "${PROJECT_ROOT:-$PWD}",
    "errors": "${validation_errors:-none}",
    "warnings": "${validation_warnings:-none}",
    "recovery_suggestions": []
  }
}
EOF

  # Add recovery suggestions based on specific errors
  if echo "$validation_errors" | grep -q "missing_flake"; then
    echo "  - Ensure you are in the correct dotfiles directory" >>"$report_file"
    echo "  - Check if flake.nix exists in the project root" >>"$report_file"
  fi

  if echo "$validation_errors" | grep -q "missing_build_script"; then
    echo "  - Verify build-switch-common.sh exists in scripts/ directory" >>"$report_file"
    echo "  - Check file permissions and make executable if needed" >>"$report_file"
  fi

  if echo "$validation_errors" | grep -q "missing_.*_dir"; then
    echo "  - Verify project structure is complete" >>"$report_file"
    echo "  - Consider running setup or initialization scripts" >>"$report_file"
  fi

  if echo "$validation_errors" | grep -q "missing_nix"; then
    echo "  - Install Nix package manager" >>"$report_file"
    echo "  - Enable experimental features (flakes, nix-command)" >>"$report_file"
  fi

  if echo "$validation_errors" | grep -q "missing_darwin-rebuild\|missing_nixos-rebuild"; then
    echo "  - Install platform-specific Nix tools" >>"$report_file"
    echo "  - Verify system configuration is complete" >>"$report_file"
  fi

  if echo "$validation_errors$validation_warnings" | grep -q "write_permission"; then
    echo "  - Check directory permissions" >>"$report_file"
    echo "  - Ensure user has appropriate access rights" >>"$report_file"
  fi

  log_debug "Validation report generated successfully"
}

# Main pre-validation check function
pre_validation_check() {
  local validation_mode="${1:-standard}"
  local strict_mode="${2:-false}"

  log_info "Running pre-validation check (mode: $validation_mode, strict: $strict_mode)"

  local all_errors=""
  local all_warnings=""
  local validation_failed=false

  # Create validation state directory
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/build-switch"
  mkdir -p "$state_dir"

  # Environment validation
  log_debug "Step 1/3: Environment validation"
  if ! validate_environment; then
    all_errors="$all_errors env_validation"
    validation_failed=true
  fi

  # Prerequisites check
  log_debug "Step 2/3: Prerequisites check"
  local prereq_result=0
  check_prerequisites || prereq_result=$?
  case $prereq_result in
  1)
    all_errors="$all_errors prerequisites"
    validation_failed=true
    ;;
  0)
    # Check for warnings (optional commands missing)
    if [ -n "$(check_prerequisites 2>&1 | grep -i warning || true)" ]; then
      all_warnings="$all_warnings optional_prerequisites"
    fi
    ;;
  esac

  # Dependencies verification
  log_debug "Step 3/3: Dependencies verification"
  local deps_result=0
  verify_dependencies || deps_result=$?
  case $deps_result in
  1)
    all_errors="$all_errors dependencies"
    validation_failed=true
    ;;
  0)
    # Check for warnings
    if [ -n "$(verify_dependencies 2>&1 | grep -i warning || true)" ]; then
      all_warnings="$all_warnings dependency_warnings"
    fi
    ;;
  esac

  # Generate validation report
  local report_file="$state_dir/pre_validation_$(date +%s).json"
  generate_validation_report "$all_errors" "$all_warnings" "$report_file"

  # Determine final result
  if [ "$validation_failed" = "true" ]; then
    log_error "Pre-validation check failed with errors: $all_errors"
    log_info "Validation report: $report_file"
    return 1
  elif [ -n "$all_warnings" ]; then
    log_warning "Pre-validation check completed with warnings: $all_warnings"
    log_info "Validation report: $report_file"

    if [ "$strict_mode" = "true" ]; then
      log_error "Strict mode enabled: treating warnings as errors"
      return 1
    else
      return 0
    fi
  else
    log_success "Pre-validation check completed successfully"
    return 0
  fi
}

# Export functions for use by other modules
export -f validate_environment
export -f check_prerequisites
export -f verify_dependencies
export -f generate_validation_report
export -f pre_validation_check
