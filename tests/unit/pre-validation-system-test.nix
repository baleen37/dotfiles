{ pkgs, lib ? pkgs.lib }:

let
  # Import test utilities
  testLib = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Pre-validation system test module
  preValidationSystemTest = testLib.createTestScript {
    name = "pre-validation-system-test";

    script = ''
      echo "=== Testing Pre-validation System ==="

      # Test 1: Environment validation function
      echo "--- Test 1: Environment validation function ---"

      # Mock validate_environment function
      validate_environment() {
        # Check essential environment variables
        if [ -z "$HOME" ] || [ -z "$USER" ] || [ -z "$PATH" ]; then
          echo "Missing essential environment variables"
          return 1
        fi

        # Check platform detection
        if [ -z "$PLATFORM_TYPE" ]; then
          echo "Platform type not detected"
          return 1
        fi

        echo "Environment validation passed"
        return 0
      }

      # Set test environment
      export HOME=/tmp/test-home
      export USER=testuser
      export PATH=/usr/bin:/bin
      export PLATFORM_TYPE=darwin

      if validate_environment; then
        echo "✓ Environment validation test passed"
      else
        echo "✗ Environment validation test failed"
        exit 1
      fi

      # Test 2: Prerequisites check function
      echo "--- Test 2: Prerequisites check function ---"

      check_prerequisites() {
        # Check for required commands
        local missing_commands=""
        local required_commands="sh bash"

        for cmd in $required_commands; do
          if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands="$missing_commands $cmd"
          fi
        done

        if [ -n "$missing_commands" ]; then
          echo "Missing required commands:$missing_commands"
          return 1
        fi

        echo "Prerequisites check passed"
        return 0
      }

      if check_prerequisites; then
        echo "✓ Prerequisites check test passed"
      else
        echo "✗ Prerequisites check test failed"
        exit 1
      fi

      # Test 3: Dependency verification function
      echo "--- Test 3: Dependency verification function ---"

      verify_dependencies() {
        local dependency_errors=""

        # Check flake.nix existence (use parent directory)
        if [ ! -f "${../..}/flake.nix" ]; then
          dependency_errors="$dependency_errors missing_flake"
        fi

        # Check build-switch script existence
        if [ ! -f "${../..}/scripts/build-switch-common.sh" ]; then
          dependency_errors="$dependency_errors missing_build_script"
        fi

        # Check lib directory structure
        if [ ! -d "${../..}/scripts/lib" ]; then
          dependency_errors="$dependency_errors missing_lib_dir"
        fi

        if [ -n "$dependency_errors" ]; then
          echo "Dependency verification failed:$dependency_errors"
          return 1
        fi

        echo "Dependency verification passed"
        return 0
      }

      if verify_dependencies; then
        echo "✓ Dependency verification test passed"
      else
        echo "✗ Dependency verification test failed"
        exit 1
      fi

      # Test 4: Integrated pre-validation check
      echo "--- Test 4: Integrated pre-validation check ---"

      pre_validation_check() {
        local validation_mode="''${1:-standard}"
        local strict_mode="''${2:-false}"

        echo "Running pre-validation check (mode: $validation_mode, strict: $strict_mode)"

        # Environment validation
        if ! validate_environment; then
          echo "Pre-validation failed: environment validation"
          return 1
        fi

        # Prerequisites check
        if ! check_prerequisites; then
          echo "Pre-validation failed: prerequisites check"
          return 1
        fi

        # Dependencies verification
        if ! verify_dependencies; then
          echo "Pre-validation failed: dependencies verification"
          return 1
        fi

        echo "Pre-validation check completed successfully"
        return 0
      }

      if pre_validation_check "standard" "false"; then
        echo "✓ Integrated pre-validation check test passed"
      else
        echo "✗ Integrated pre-validation check test failed"
        exit 1
      fi

      # Test 5: Error handling and recovery suggestions
      echo "--- Test 5: Error handling and recovery suggestions ---"

      generate_validation_report() {
        local validation_errors="$1"
        local report_file="$2"

        cat > "$report_file" << EOF
{
  "validation_report": {
    "timestamp": "$(date -Iseconds)",
    "errors": "$validation_errors",
    "recovery_suggestions": []
  }
}
EOF

        # Add recovery suggestions based on errors
        if echo "$validation_errors" | grep -q "missing_flake"; then
          echo "Recovery: Check if you're in the correct dotfiles directory" >> "$report_file"
        fi

        if echo "$validation_errors" | grep -q "missing_build_script"; then
          echo "Recovery: Ensure build-switch-common.sh exists in scripts/ directory" >> "$report_file"
        fi

        echo "Validation report generated: $report_file"
      }

      # Test report generation
      temp_report="$(mktemp)"
      generate_validation_report "missing_flake missing_build_script" "$temp_report"

      if [ -f "$temp_report" ] && grep -q "validation_report" "$temp_report"; then
        echo "✓ Report generation test passed"
      else
        echo "✗ Report generation test failed"
        exit 1
      fi

      rm -f "$temp_report"

      echo "=== All pre-validation system tests passed! ==="
    '';
  };

in preValidationSystemTest
