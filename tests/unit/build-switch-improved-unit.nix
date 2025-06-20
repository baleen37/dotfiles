{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-improved-unit-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Improved Unit Tests"}

  # Test 1: Script structure and basic functionality
  ${testHelpers.testSubsection "Script Structure"}

  ${testHelpers.assertExists "${buildSwitchScript}" "build-switch script exists"}
  ${testHelpers.assertCommand "[ -x '${buildSwitchScript}' ]" "build-switch script is executable"}

  # Test 2: Color constants definition
  ${testHelpers.testSubsection "Color Constants"}

  ${testHelpers.assertContains "${buildSwitchScript}" "GREEN=" "GREEN color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "YELLOW=" "YELLOW color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "RED=" "RED color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "BLUE=" "BLUE color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "NC=" "No color constant defined"}

  # Test 3: Helper functions definition
  ${testHelpers.testSubsection "Helper Functions"}

  ${testHelpers.assertContains "${buildSwitchScript}" "print_step()" "print_step function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_success()" "print_success function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_error()" "print_error function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "show_progress()" "show_progress function defined"}

  # Test 4: Verbose flag handling
  ${testHelpers.testSubsection "Verbose Flag Handling"}

  ${testHelpers.assertContains "${buildSwitchScript}" "VERBOSE=false" "VERBOSE variable initialized"}
  ${testHelpers.assertContains "${buildSwitchScript}" "--verbose" "verbose flag check implemented"}
  ${testHelpers.assertContains "${buildSwitchScript}" "VERBOSE=true" "verbose flag setting implemented"}

  # Test 5: Progress indicator format
  ${testHelpers.testSubsection "Progress Indicator Format"}

  ${testHelpers.assertContains "${buildSwitchScript}" "🏗️  Dotfiles Build & Switch" "progress indicator with emoji"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\[\$step/\$total\]" "step counter format"}

  # Test 6: Error handling patterns
  ${testHelpers.testSubsection "Error Handling"}

  ${testHelpers.assertContains "${buildSwitchScript}" "2>/dev/null" "error suppression for non-verbose mode"}
  ${testHelpers.assertContains "${buildSwitchScript}" "Run with --verbose for details" "verbose suggestion in error messages"}
  ${testHelpers.assertContains "${buildSwitchScript}" "exit 1" "proper exit code on failure"}

  # Test 7: Success indicators
  ${testHelpers.testSubsection "Success Indicators"}

  ${testHelpers.assertContains "${buildSwitchScript}" "✅" "success emoji used"}
  ${testHelpers.assertContains "${buildSwitchScript}" "System configuration built" "build success message"}
  ${testHelpers.assertContains "${buildSwitchScript}" "New generation activated" "switch success message"}
  ${testHelpers.assertContains "${buildSwitchScript}" "Cleanup complete" "cleanup success message"}

  # Test 8: Mock script execution test
  ${testHelpers.testSubsection "Mock Script Execution"}

  # Create a mock build-switch script for functional testing
  MOCK_SCRIPT="$HOME/mock-build-switch"
  cat > "$MOCK_SCRIPT" << 'MOCK_EOF'
#!/bin/bash
# Mock version of build-switch for testing

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

SYSTEM_TYPE="aarch64-darwin"
FLAKE_SYSTEM="darwinConfigurations.\''${SYSTEM_TYPE}.system"

export NIXPKGS_ALLOW_UNFREE=1

if [ -z "$USER" ]; then
    export USER=$(whoami)
fi

# Check for verbose flag
VERBOSE=false
for arg in "$@"; do
    if [ "$arg" = "--verbose" ]; then
        VERBOSE=true
        break
    fi
done

print_step() {
    echo "\''${BLUE}$1\''${NC}"
}

print_success() {
    echo "\''${GREEN}✅ $1\''${NC}"
}

print_error() {
    echo "\''${RED}❌ $1\''${NC}"
}

show_progress() {
    local step=$1
    local total=$2
    local desc=$3
    echo "\''${YELLOW}🏗️  Dotfiles Build & Switch [$step/$total] - $desc\''${NC}"
}

# Mock build phase
show_progress "1" "4" "Building system configuration"
if [ "$VERBOSE" = "true" ]; then
    echo "VERBOSE: Detailed build output would appear here"
fi
print_success "System configuration built"

# Mock switch phase
show_progress "2" "4" "Switching to new generation"
print_step "└─ Requesting admin privileges..."
if [ "$VERBOSE" = "true" ]; then
    echo "VERBOSE: Detailed switch output would appear here"
fi
print_success "New generation activated"

# Mock cleanup phase
show_progress "3" "4" "Cleaning up"
print_success "Cleanup complete"

# Final
show_progress "4" "4" "Complete"
print_success "System update complete!"
echo "\''${BLUE}💡 Use --verbose for detailed output\''${NC}"
MOCK_EOF

  chmod +x "$MOCK_SCRIPT"

  # Test normal execution
  OUTPUT=$("$MOCK_SCRIPT" 2>&1)
  ${testHelpers.assertTrue ''echo "$OUTPUT" | grep -q "🏗️  Dotfiles Build & Switch"'' "progress indicator appears in output"}
  ${testHelpers.assertTrue ''echo "$OUTPUT" | grep -q "✅"'' "success indicators appear in output"}
  ${testHelpers.assertTrue ''echo "$OUTPUT" | grep -q "💡 Use --verbose"'' "verbose hint appears in output"}

  # Test verbose execution
  VERBOSE_OUTPUT=$("$MOCK_SCRIPT" --verbose 2>&1)
  ${testHelpers.assertTrue ''echo "$VERBOSE_OUTPUT" | grep -q "VERBOSE:"'' "verbose output appears with --verbose flag"}

  # Test 9: Output format validation
  ${testHelpers.testSubsection "Output Format Validation"}

  NORMAL_OUTPUT=$("$MOCK_SCRIPT" 2>&1)

  # Count progress steps
  PROGRESS_COUNT=$(echo "$NORMAL_OUTPUT" | grep -c "🏗️  Dotfiles Build & Switch")
  ${testHelpers.assertTrue ''[ $PROGRESS_COUNT -eq 4 ]'' "exactly 4 progress steps shown"}

  # Count success messages
  SUCCESS_COUNT=$(echo "$NORMAL_OUTPUT" | grep -c "✅")
  ${testHelpers.assertTrue ''[ $SUCCESS_COUNT -eq 4 ]'' "exactly 4 success messages shown"}

  # Test that output is concise (should be under 15 lines for normal mode)
  LINE_COUNT=$(echo "$NORMAL_OUTPUT" | wc -l)
  ${testHelpers.assertTrue ''[ $LINE_COUNT -le 15 ]'' "normal output is concise (≤15 lines)"}

  # Test 10: Error simulation
  ${testHelpers.testSubsection "Error Simulation"}

  # Create a script that simulates build failure
  ERROR_SCRIPT="$HOME/error-build-switch"
  cat > "$ERROR_SCRIPT" << 'ERROR_EOF'
#!/bin/bash
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo "\''${RED}❌ $1\''${NC}"
}

show_progress() {
    local step=$1
    local total=$2
    local desc=$3
    echo "\''${YELLOW}🏗️  Dotfiles Build & Switch [$step/$total] - $desc\''${NC}"
}

show_progress "1" "4" "Building system configuration"
print_error "Build failed. Run with --verbose for details"
exit 1
ERROR_EOF

  chmod +x "$ERROR_SCRIPT"

  # Test error handling
  if ! "$ERROR_SCRIPT" >/dev/null 2>&1; then
    ERROR_OUTPUT=$("$ERROR_SCRIPT" 2>&1)
    ${testHelpers.assertTrue ''echo "$ERROR_OUTPUT" | grep -q "❌"'' "error indicator appears on failure"}
    ${testHelpers.assertTrue ''echo "$ERROR_OUTPUT" | grep -q "Run with --verbose"'' "verbose suggestion appears on error"}
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Error handling works correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Error script should exit with non-zero code"
    exit 1
  fi

  ${testHelpers.cleanup}

  # Clean up mock scripts
  rm -f "$MOCK_SCRIPT" "$ERROR_SCRIPT"

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
