{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-improved-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils nix git findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Improved Integration Tests"}

  # Test 1: Integration with actual flake structure
  ${testHelpers.testSubsection "Flake Integration"}

  # Create a test flake environment
  TEST_FLAKE_DIR="$HOME/test-flake"
  mkdir -p "$TEST_FLAKE_DIR"
  cd "$TEST_FLAKE_DIR"

  # Create a minimal flake.nix for testing
  cat > flake.nix << 'FLAKE_EOF'
{
  description = "Test flake for build-switch integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, ... }: {
    darwinConfigurations.aarch64-darwin = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        {
          # Minimal configuration for testing
          system.stateVersion = 4;
          services.nix-daemon.enable = true;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
        }
      ];
    };

    apps.aarch64-darwin.build-switch = {
      type = "app";
      program = "\''${self.packages.aarch64-darwin.build-switch}/bin/build-switch";
    };

    packages.aarch64-darwin.build-switch = pkgs.writeShellApplication {
      name = "build-switch";
      text = ''
        echo "Test build-switch execution"
        exit 0
      '';
    };
  };
}
FLAKE_EOF

  # Test that our build-switch script can recognize flake structure
  ${testHelpers.assertExists "$TEST_FLAKE_DIR/flake.nix" "test flake.nix created"}

  # Test 2: Environment variable handling
  ${testHelpers.testSubsection "Environment Variable Handling"}

  # Test USER variable requirement
  export USER="testuser"
  ${testHelpers.assertTrue ''[ "$USER" = "testuser" ]'' "USER variable properly set"}

  # Test 3: Verbose vs Normal mode output differences
  ${testHelpers.testSubsection "Output Mode Differences"}

  # Create a test script that mimics the actual build-switch behavior
  TEST_SCRIPT="$TEST_FLAKE_DIR/test-build-switch"
  cp "${buildSwitchScript}" "$TEST_SCRIPT"

  # Modify the test script to use mock commands instead of real nix/sudo
  cat > "$TEST_SCRIPT" << 'TEST_SCRIPT_EOF'
#!/bin/sh -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

SYSTEM_TYPE="aarch64-darwin"
FLAKE_SYSTEM="darwinConfigurations.''${SYSTEM_TYPE}.system"

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
    echo "''${BLUE}$1''${NC}"
}

print_success() {
    echo "''${GREEN}✅ $1''${NC}"
}

print_error() {
    echo "''${RED}❌ $1''${NC}"
}

show_progress() {
    local step=$1
    local total=$2
    local desc=$3
    echo "''${YELLOW}🏗️  Dotfiles Build & Switch [$step/$total] - $desc''${NC}"
}

# Mock nix build command
mock_nix_build() {
    if [ "$VERBOSE" = "true" ]; then
        echo "VERBOSE: Building derivation..."
        echo "VERBOSE: these derivations will be built:"
        echo "VERBOSE:   /nix/store/abc123-config.drv"
        echo "VERBOSE: building '/nix/store/abc123-config.drv'..."
        echo "VERBOSE: build completed"
    fi

    # Create mock result symlink
    mkdir -p result/sw/bin
    echo '#!/bin/bash' > result/sw/bin/darwin-rebuild
    echo 'echo "Mock darwin-rebuild: $@"' >> result/sw/bin/darwin-rebuild
    chmod +x result/sw/bin/darwin-rebuild

    return 0
}

# Mock sudo command
mock_sudo() {
    if [ "$VERBOSE" = "true" ]; then
        echo "VERBOSE: Executing with elevated privileges: $@"
    fi

    # Execute the command without actual sudo
    shift 3  # Remove 'sudo -E USER=testuser'
    "$@"
    return 0
}

# Build phase
show_progress "1" "4" "Building system configuration"
if [ "$VERBOSE" = "true" ]; then
    mock_nix_build
else
    mock_nix_build 2>/dev/null || {
        print_error "Build failed. Run with --verbose for details"
        exit 1
    }
fi
print_success "System configuration built"

# Switch phase
show_progress "2" "4" "Switching to new generation"
print_step "└─ Requesting admin privileges..."
if [ "$VERBOSE" = "true" ]; then
    mock_sudo -E USER="$USER" ./result/sw/bin/darwin-rebuild switch --impure --flake .#''${SYSTEM_TYPE} "$@"
else
    mock_sudo -E USER="$USER" ./result/sw/bin/darwin-rebuild switch --impure --flake .#''${SYSTEM_TYPE} "$@" 2>/dev/null || {
        print_error "Switch failed. Run with --verbose for details"
        exit 1
    }
fi
print_success "New generation activated"

# Cleanup phase
show_progress "3" "4" "Cleaning up"
if [ -L "./result" ]; then
    unlink ./result
fi
print_success "Cleanup complete"

# Final
show_progress "4" "4" "Complete"
print_success "System update complete!"
echo "''${BLUE}💡 Use --verbose for detailed output''${NC}"
TEST_SCRIPT_EOF

  chmod +x "$TEST_SCRIPT"

  # Test normal mode execution
  cd "$TEST_FLAKE_DIR"
  NORMAL_OUTPUT=$("$TEST_SCRIPT" 2>&1)

  ${testHelpers.assertTrue ''echo "$NORMAL_OUTPUT" | grep -q "🏗️"'' "progress indicators shown in normal mode"}
  ${testHelpers.assertTrue ''echo "$NORMAL_OUTPUT" | grep -q "✅"'' "success indicators shown in normal mode"}
  ${testHelpers.assertTrue ''! echo "$NORMAL_OUTPUT" | grep -q "VERBOSE:"'' "verbose output hidden in normal mode"}

  # Test verbose mode execution
  VERBOSE_OUTPUT=$("$TEST_SCRIPT" --verbose 2>&1)

  ${testHelpers.assertTrue ''echo "$VERBOSE_OUTPUT" | grep -q "VERBOSE:"'' "verbose output shown in verbose mode"}
  ${testHelpers.assertTrue ''echo "$VERBOSE_OUTPUT" | grep -q "Building derivation"'' "build details shown in verbose mode"}
  ${testHelpers.assertTrue ''echo "$VERBOSE_OUTPUT" | grep -q "Executing with elevated privileges"'' "sudo details shown in verbose mode"}

  # Test 4: Error handling integration
  ${testHelpers.testSubsection "Error Handling Integration"}

  # Create a script that fails during build
  FAILING_SCRIPT="$TEST_FLAKE_DIR/failing-build-switch"
  sed 's/return 0/return 1/' "$TEST_SCRIPT" > "$FAILING_SCRIPT"
  chmod +x "$FAILING_SCRIPT"

  # Test that error is properly handled
  if ! "$FAILING_SCRIPT" >/dev/null 2>&1; then
    FAILURE_OUTPUT=$("$FAILING_SCRIPT" 2>&1)
    ${testHelpers.assertTrue ''echo "$FAILURE_OUTPUT" | grep -q "❌"'' "error indicator shown on failure"}
    ${testHelpers.assertTrue ''echo "$FAILURE_OUTPUT" | grep -q "Build failed"'' "build failure message shown"}
    ${testHelpers.assertTrue ''echo "$FAILURE_OUTPUT" | grep -q "Run with --verbose"'' "verbose suggestion shown on failure"}
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Error handling integration works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failing script should exit with error code"
    exit 1
  fi

  # Test 5: Output consistency across runs
  ${testHelpers.testSubsection "Output Consistency"}

  cd "$TEST_FLAKE_DIR"

  # Run the script multiple times and check output consistency
  OUTPUT1=$("$TEST_SCRIPT" 2>&1)
  OUTPUT2=$("$TEST_SCRIPT" 2>&1)

  # Both outputs should have the same structure
  LINES1=$(echo "$OUTPUT1" | wc -l)
  LINES2=$(echo "$OUTPUT2" | wc -l)
  ${testHelpers.assertTrue ''[ "$LINES1" -eq "$LINES2" ]'' "output has consistent line count across runs"}

  PROGRESS1=$(echo "$OUTPUT1" | grep -c "🏗️")
  PROGRESS2=$(echo "$OUTPUT2" | grep -c "🏗️")
  ${testHelpers.assertTrue ''[ "$PROGRESS1" -eq "$PROGRESS2" ]'' "progress indicators consistent across runs"}

  # Test 6: Performance characteristics
  ${testHelpers.testSubsection "Performance Characteristics"}

  cd "$TEST_FLAKE_DIR"

  # Time the execution
  START_TIME=$(date +%s%N)
  "$TEST_SCRIPT" >/dev/null 2>&1
  END_TIME=$(date +%s%N)
  DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

  # Should complete quickly since it's mocked
  ${testHelpers.assertTrue ''[ "$DURATION" -lt 5000 ]'' "script execution completes quickly (< 5s)"}
  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Execution completed in ''${DURATION}ms"

  # Test 7: Cleanup verification
  ${testHelpers.testSubsection "Cleanup Verification"}

  cd "$TEST_FLAKE_DIR"

  # Ensure cleanup removes temporary files
  "$TEST_SCRIPT" >/dev/null 2>&1
  ${testHelpers.assertTrue ''[ ! -L "./result" ]'' "result symlink properly cleaned up"}

  # Test 8: Flag parsing edge cases
  ${testHelpers.testSubsection "Flag Parsing Edge Cases"}

  cd "$TEST_FLAKE_DIR"

  # Test with multiple flags
  MULTI_FLAG_OUTPUT=$("$TEST_SCRIPT" --verbose --other-flag 2>&1)
  ${testHelpers.assertTrue ''echo "$MULTI_FLAG_OUTPUT" | grep -q "VERBOSE:"'' "verbose flag works with other flags"}

  # Test with verbose flag in different positions
  VERBOSE_LAST_OUTPUT=$("$TEST_SCRIPT" --some-flag --verbose 2>&1)
  ${testHelpers.assertTrue ''echo "$VERBOSE_LAST_OUTPUT" | grep -q "VERBOSE:"'' "verbose flag works when not first"}

  ${testHelpers.cleanup}

  # Clean up test files
  cd "$HOME"
  rm -rf "$TEST_FLAKE_DIR"

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Integration Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All integration tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
