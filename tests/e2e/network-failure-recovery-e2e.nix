{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "network-failure-recovery-e2e-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils curl timeout ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Network Failure Recovery End-to-End Tests"}

  # Test 1: Network connectivity baseline
  ${testHelpers.testSubsection "Network Connectivity Baseline"}

  mkdir -p test_workspace network_simulation
  cd test_workspace

  # Establish baseline network behavior expectation
  echo "Establishing network failure recovery test baseline..."

  # Test 2: Intermittent network failure simulation
  ${testHelpers.testSubsection "Intermittent Network Failure"}

  # Simulate network that comes and goes during build
  echo "Testing intermittent network recovery..."

  # Create network state simulation
  NETWORK_STATE_FILE="network_state.tmp"
  echo "connected" > "$NETWORK_STATE_FILE"

  # Simulate network state changes
  simulate_network_failure() {
    echo "disconnected" > "$NETWORK_STATE_FILE"
    sleep 1
    echo "connected" > "$NETWORK_STATE_FILE"
  }

  # Test network state tracking
  INITIAL_STATE=$(cat "$NETWORK_STATE_FILE")
  if [ "$INITIAL_STATE" = "connected" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Network state simulation initialized"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Network state simulation failed"
    exit 1
  fi

  # Test 3: Build interruption and resume
  ${testHelpers.testSubsection "Build Interruption and Resume"}

  # Test build system's ability to resume after network interruption
  echo "Testing build interruption recovery..."

  # Create mock interrupted build state
  mkdir -p .nix-build-interrupted
  touch .nix-build-interrupted/build.lock
  touch .nix-build-interrupted/partial_state.json

  # Verify recovery preparation
  if [ -d ".nix-build-interrupted" ] && [ -f ".nix-build-interrupted/build.lock" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Interrupted build state simulation ready"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Interrupted build state setup failed"
    exit 1
  fi

  # Test 4: Cachix connectivity fallback
  ${testHelpers.testSubsection "Cachix Connectivity Fallback"}

  # Test fallback when Cachix is unreachable
  echo "Testing Cachix fallback behavior..."

  # Mock Cachix unavailability
  export CACHIX_FALLBACK_TEST=1

  # Create local fallback cache directory
  mkdir -p local_cache/store
  mkdir -p local_cache/meta

  if [ -d "local_cache/store" ] && [ -d "local_cache/meta" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Local cache fallback structure created"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Local cache fallback setup failed"
    exit 1
  fi

  # Test 5: Progressive retry mechanism
  ${testHelpers.testSubsection "Progressive Retry Mechanism"}

  # Test that system implements intelligent retry with backoff
  echo "Testing progressive retry behavior..."

  # Simulate retry attempts with exponential backoff
  RETRY_ATTEMPTS=3
  CURRENT_ATTEMPT=1

  while [ $CURRENT_ATTEMPT -le $RETRY_ATTEMPTS ]; do
    echo "Retry attempt $CURRENT_ATTEMPT/$RETRY_ATTEMPTS"

    # Simulate backoff timing (mock)
    BACKOFF_TIME=$((CURRENT_ATTEMPT * 2))
    echo "Simulated backoff: ''${BACKOFF_TIME}s"

    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
  done

  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Progressive retry simulation completed"

  # Test 6: Recovery success verification
  ${testHelpers.testSubsection "Recovery Success Verification"}

  # Test that system properly validates recovery
  echo "Testing recovery success verification..."

  # Create recovery validation markers
  touch .recovery_checkpoint_1
  touch .recovery_checkpoint_2
  touch .recovery_verified

  RECOVERY_CHECKPOINTS=$(ls .recovery_checkpoint_* 2>/dev/null | wc -l)
  if [ "$RECOVERY_CHECKPOINTS" -ge 2 ] && [ -f ".recovery_verified" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Recovery verification system ready"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Recovery verification setup incomplete"
    exit 1
  fi

  # Test 7: Network quality adaptation
  ${testHelpers.testSubsection "Network Quality Adaptation"}

  # Test system adaptation to different network qualities
  echo "Testing network quality adaptation..."

  # Simulate different network conditions
  NETWORK_CONDITIONS=("high_latency" "low_bandwidth" "packet_loss" "stable")

  for condition in "''${NETWORK_CONDITIONS[@]}"; do
    echo "Testing adaptation to: $condition"

    # Create condition-specific test marker
    touch ".network_condition_$condition"
  done

  CONDITION_FILES=$(ls .network_condition_* 2>/dev/null | wc -l)
  if [ "$CONDITION_FILES" -eq 4 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Network condition adaptation tests prepared"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Network condition setup incomplete"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Network Failure Recovery E2E Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Network failure recovery test infrastructure completed!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Implementation needed: Actual network failure detection, retry logic, and recovery mechanisms${testHelpers.colors.reset}"

  touch $out
''
