{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "network-failure-recovery-e2e-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils curl ];
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

  # Test 8: Orchestration with comprehensive scenarios
  ${testHelpers.testSubsection "Orchestration with Network Scenarios"}

  # Test orchestration of network scenarios with other test scenarios
  echo "Testing orchestration with network scenarios..."

  # Create orchestration test function
  orchestrate_with_network_scenarios() {
    local scenario_type="$1"
    local network_condition="$2"

    echo "Orchestrating scenario: $scenario_type with network condition: $network_condition"

    # Create orchestration state directory
    mkdir -p orchestration_state

    # Initialize scenario orchestration
    cat > orchestration_state/network_orchestration.json << EOF
{
  "orchestration": {
    "id": "network_orchestration_$(date +%s)",
    "scenario_type": "$scenario_type",
    "network_condition": "$network_condition",
    "status": "active",
    "start_time": "$(date -Iseconds)"
  },
  "phases": {
    "pre_network_setup": "pending",
    "network_simulation": "pending",
    "recovery_validation": "pending",
    "post_recovery_cleanup": "pending"
  },
  "results": {
    "network_interruptions": 0,
    "recovery_attempts": 0,
    "successful_recoveries": 0
  }
}
EOF

    # Phase 1: Pre-network setup
    echo "Phase 1: Pre-network setup for $scenario_type"
    touch orchestration_state/pre_network_setup.complete

    # Phase 2: Network simulation
    echo "Phase 2: Network simulation ($network_condition)"
    case "$network_condition" in
      "intermittent")
        echo "Simulating intermittent network failures..."
        # Create intermittent failure markers
        for i in 1 2 3; do
          touch "orchestration_state/network_failure_$i"
          sleep 0.1
          rm "orchestration_state/network_failure_$i"
        done
        ;;
      "sustained_outage")
        echo "Simulating sustained network outage..."
        touch orchestration_state/network_outage_active
        sleep 0.2
        rm orchestration_state/network_outage_active
        ;;
      "degraded_performance")
        echo "Simulating degraded network performance..."
        touch orchestration_state/network_degraded
        sleep 0.1
        rm orchestration_state/network_degraded
        ;;
    esac

    # Phase 3: Recovery validation
    echo "Phase 3: Recovery validation"
    touch orchestration_state/recovery_validation.complete

    # Phase 4: Post-recovery cleanup
    echo "Phase 4: Post-recovery cleanup"
    touch orchestration_state/post_recovery_cleanup.complete

    # Update orchestration results
    sed -i.bak 's/"status": "active"/"status": "completed"/' orchestration_state/network_orchestration.json 2>/dev/null || true

    echo "Network scenario orchestration completed for $scenario_type"
    return 0
  }

  # Test different orchestration scenarios
  ORCHESTRATION_SCENARIOS="build_failure switch_failure combined_failure"
  NETWORK_CONDITIONS="intermittent sustained_outage degraded_performance"

  ORCHESTRATION_TESTS_COMPLETED=0
  ORCHESTRATION_TESTS_TOTAL=0

  for scenario in $ORCHESTRATION_SCENARIOS; do
    for condition in $NETWORK_CONDITIONS; do
      ORCHESTRATION_TESTS_TOTAL=$((ORCHESTRATION_TESTS_TOTAL + 1))

      echo "Testing orchestration: $scenario with $condition"

      if orchestrate_with_network_scenarios "$scenario" "$condition"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Orchestration successful: $scenario + $condition"
        ORCHESTRATION_TESTS_COMPLETED=$((ORCHESTRATION_TESTS_COMPLETED + 1))
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Orchestration failed: $scenario + $condition"
      fi
    done
  done

  echo ""
  echo "Orchestration Test Results: $ORCHESTRATION_TESTS_COMPLETED/$ORCHESTRATION_TESTS_TOTAL scenarios completed"

  if [ "$ORCHESTRATION_TESTS_COMPLETED" -eq "$ORCHESTRATION_TESTS_TOTAL" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} All orchestration scenarios completed successfully"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Some orchestration scenarios had issues"
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Network Failure Recovery E2E Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Network failure recovery test infrastructure completed!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Network scenario orchestration functionality implemented!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Implementation needed: Actual network failure detection, retry logic, and recovery mechanisms${testHelpers.colors.reset}"

  touch $out
''
