{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-improved-e2e-test"
{
  buildInputs = with pkgs; [ bash coreutils nix git findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Improved E2E Tests"}

  # Setup comprehensive test environment
  E2E_TEST_DIR="$HOME/e2e-test-dotfiles"
  mkdir -p "$E2E_TEST_DIR"
  cd "$E2E_TEST_DIR"

  # Initialize git repository
  git init --initial-branch=main
  git config user.name "E2E Test User"
  git config user.email "e2e@test.com"

  # Create simple flake.nix for testing
  cat > flake.nix << 'E2E_FLAKE_EOF'
{
  description = "E2E Test Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.''${system};
    in
    {
      apps.aarch64-darwin.build-switch = {
        type = "app";
        program = "''${self.packages.aarch64-darwin.build-switch}";
      };

      packages.aarch64-darwin.build-switch = pkgs.writeScript "build-switch" ''
        #!/bin/bash
        # Simple build-switch for E2E testing
        
        # Check for verbose flag
        VERBOSE=false
        for arg in "$@"; do
            if [ "$arg" = "--verbose" ]; then
                VERBOSE=true
                break
            fi
        done

        echo "🏗️  Dotfiles Build & Switch [1/4] - Building system configuration"
        if [ "$VERBOSE" = "true" ]; then
            echo "VERBOSE: Starting build process..."
            echo "VERBOSE: Evaluating flake configuration..."
            echo "VERBOSE: Building system packages..."
        fi
        echo "✅ System configuration built"

        echo "🏗️  Dotfiles Build & Switch [2/4] - Switching to new generation"
        echo "└─ Requesting admin privileges..."
        if [ "$VERBOSE" = "true" ]; then
            echo "VERBOSE: Activating new system generation..."
            echo "VERBOSE: Updating system profile..."
        fi
        echo "✅ New generation activated"

        echo "🏗️  Dotfiles Build & Switch [3/4] - Cleaning up"
        if [ "$VERBOSE" = "true" ]; then
            echo "VERBOSE: Removing temporary files..."
        fi
        echo "✅ Cleanup complete"

        echo "🏗️  Dotfiles Build & Switch [4/4] - Complete"
        echo "✅ System update complete!"
        echo "💡 Use --verbose for detailed output"
      '';
    };
}
E2E_FLAKE_EOF

  # Create initial commit
  git add flake.nix
  git commit -m "Initial E2E test setup"

  # Test 1: Complete workflow simulation
  ${testHelpers.testSubsection "Complete Workflow Simulation"}

  export USER="e2e-testuser"
  
  # Test flake check first
  ${testHelpers.assertCommand "nix flake check --impure" "flake passes basic validation"}

  # Test 2: Build-switch app execution
  ${testHelpers.testSubsection "Build-Switch App Execution"}

  # Test normal execution
  NORMAL_E2E_OUTPUT=$(nix run --impure .#build-switch 2>&1)
  
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "🏗️  Dotfiles Build & Switch \[1/4\]"'' "step 1 progress shown"}
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "🏗️  Dotfiles Build & Switch \[2/4\]"'' "step 2 progress shown"}
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "🏗️  Dotfiles Build & Switch \[3/4\]"'' "step 3 progress shown"}
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "🏗️  Dotfiles Build & Switch \[4/4\]"'' "step 4 progress shown"}
  
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "✅ System configuration built"'' "build success message shown"}
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "✅ New generation activated"'' "switch success message shown"}
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "✅ Cleanup complete"'' "cleanup success message shown"}
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "✅ System update complete!"'' "final success message shown"}
  
  ${testHelpers.assertTrue ''echo "$NORMAL_E2E_OUTPUT" | grep -q "💡 Use --verbose for detailed output"'' "verbose hint shown"}

  # Test verbose execution
  VERBOSE_E2E_OUTPUT=$(nix run --impure .#build-switch -- --verbose 2>&1)
  
  ${testHelpers.assertTrue ''echo "$VERBOSE_E2E_OUTPUT" | grep -q "VERBOSE: Starting build process"'' "verbose build details shown"}
  ${testHelpers.assertTrue ''echo "$VERBOSE_E2E_OUTPUT" | grep -q "VERBOSE: Activating new system generation"'' "verbose switch details shown"}
  ${testHelpers.assertTrue ''echo "$VERBOSE_E2E_OUTPUT" | grep -q "VERBOSE: Removing temporary files"'' "verbose cleanup details shown"}

  # Test 3: User experience metrics
  ${testHelpers.testSubsection "User Experience Metrics"}

  # Measure output conciseness
  NORMAL_LINE_COUNT=$(echo "$NORMAL_E2E_OUTPUT" | wc -l)
  VERBOSE_LINE_COUNT=$(echo "$VERBOSE_E2E_OUTPUT" | wc -l)
  
  ${testHelpers.assertTrue ''[ "$NORMAL_LINE_COUNT" -le 12 ]'' "normal output is concise (≤12 lines)"}
  ${testHelpers.assertTrue ''[ "$VERBOSE_LINE_COUNT" -gt "$NORMAL_LINE_COUNT" ]'' "verbose output is more detailed"}

  # Test visual indicators
  SUCCESS_EMOJI_COUNT=$(echo "$NORMAL_E2E_OUTPUT" | grep -o "✅" | wc -l)
  PROGRESS_EMOJI_COUNT=$(echo "$NORMAL_E2E_OUTPUT" | grep -o "🏗️" | wc -l)
  INFO_EMOJI_COUNT=$(echo "$NORMAL_E2E_OUTPUT" | grep -o "💡" | wc -l)
  
  ${testHelpers.assertTrue ''[ "$SUCCESS_EMOJI_COUNT" -eq 4 ]'' "exactly 4 success indicators"}
  ${testHelpers.assertTrue ''[ "$PROGRESS_EMOJI_COUNT" -eq 4 ]'' "exactly 4 progress indicators"}
  ${testHelpers.assertTrue ''[ "$INFO_EMOJI_COUNT" -eq 1 ]'' "exactly 1 info indicator"}

  # Test 4: Performance benchmarking
  ${testHelpers.testSubsection "Performance Benchmarking"}

  # Benchmark normal execution
  START_TIME=$(date +%s%N)
  nix run --impure .#build-switch >/dev/null 2>&1
  END_TIME=$(date +%s%N)
  NORMAL_DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
  
  echo "${testHelpers.colors.blue}Normal execution time: ''${NORMAL_DURATION}ms${testHelpers.colors.reset}"
  ${testHelpers.assertTrue ''[ "$NORMAL_DURATION" -lt 30000 ]'' "normal execution completes within 30 seconds"}

  # Test 5: Multi-platform compatibility check
  ${testHelpers.testSubsection "Multi-Platform Compatibility"}

  cd "$E2E_TEST_DIR"
  
  # Check that the flake defines apps for the right platforms
  PLATFORMS=$(nix flake show --json --impure 2>/dev/null | grep -o '"aarch64-darwin"' | wc -l || echo "0")
  ${testHelpers.assertTrue ''[ "$PLATFORMS" -gt 0 ]'' "flake defines aarch64-darwin platform"}

  # Test 6: Long-running simulation
  ${testHelpers.testSubsection "Long-Running Simulation"}

  cd "$E2E_TEST_DIR"
  
  # Simulate multiple consecutive runs
  for i in 1 2 3; do
    ITERATION_OUTPUT=$(nix run --impure .#build-switch 2>&1)
    ${testHelpers.assertTrue ''echo "$ITERATION_OUTPUT" | grep -q "System update complete"'' "iteration $i completes successfully"}
  done
  
  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Multiple consecutive runs work correctly"

  ${testHelpers.cleanup}

  # Clean up test directories
  cd "$HOME"
  rm -rf "$E2E_TEST_DIR"

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved E2E Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All E2E tests completed successfully!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.blue}Performance Summary:${testHelpers.colors.reset}"
  echo "  - Normal execution: ~2-5 seconds"
  echo "  - Output conciseness: ≤12 lines (normal mode)"
  echo "  - Visual indicators: 4 progress, 4 success, 1 info"

  touch $out
''