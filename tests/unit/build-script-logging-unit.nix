# Unit Tests for Build Script Logging Module
# Tests logging functions extracted from build-switch-common.sh

{ pkgs, ... }:

let
  # Import test helpers
  helpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Test that logging functions exist and work correctly
  testLoggingModule = pkgs.runCommand "test-logging-module" {
    buildInputs = [ pkgs.bash ];
  } ''
    # Test that we can source the logging module
    if [ -f ${../../scripts/lib/logging.sh} ]; then
      echo "✅ Logging module exists"

      # Source the module
      source ${../../scripts/lib/logging.sh}

      # Test that all expected functions exist
      if declare -f log_header > /dev/null; then
        echo "✅ log_header function exists"
      else
        echo "❌ log_header function missing"
        exit 1
      fi

      if declare -f log_step > /dev/null; then
        echo "✅ log_step function exists"
      else
        echo "❌ log_step function missing"
        exit 1
      fi

      if declare -f log_info > /dev/null; then
        echo "✅ log_info function exists"
      else
        echo "❌ log_info function missing"
        exit 1
      fi

      if declare -f log_warning > /dev/null; then
        echo "✅ log_warning function exists"
      else
        echo "❌ log_warning function missing"
        exit 1
      fi

      if declare -f log_success > /dev/null; then
        echo "✅ log_success function exists"
      else
        echo "❌ log_success function missing"
        exit 1
      fi

      if declare -f log_error > /dev/null; then
        echo "✅ log_error function exists"
      else
        echo "❌ log_error function missing"
        exit 1
      fi

      if declare -f log_footer > /dev/null; then
        echo "✅ log_footer function exists"
      else
        echo "❌ log_footer function missing"
        exit 1
      fi

      # Test that color constants are defined
      if [ -n "$GREEN" ] && [ -n "$YELLOW" ] && [ -n "$RED" ] && [ -n "$BLUE" ] && [ -n "$DIM" ] && [ -n "$NC" ]; then
        echo "✅ Color constants defined"
      else
        echo "❌ Color constants missing"
        exit 1
      fi

      # Test actual logging functions work
      echo "Testing logging functions..."
      log_info "Test message" > /dev/null 2>&1
      log_warning "Test warning" > /dev/null 2>&1
      log_success "Test success" > /dev/null 2>&1

      echo "✅ All logging tests passed"
    else
      echo "❌ Logging module does not exist yet - this test should fail initially"
      exit 1
    fi

    touch $out
  '';

in testLoggingModule
