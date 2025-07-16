{ pkgs }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "test-helpers-performance-test" { } ''
  set -e
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Performance Test Helpers Validation"}

  # TEST: measureExecutionTime function should exist and work
  echo "Testing measureExecutionTime function..."

  # Test that measureExecutionTime function works with a simple command
  MEASURED_TIME=$(${testHelpers.measureExecutionTime "sleep 0.1"})
  if [ "$MEASURED_TIME" -ge 80 ] && [ "$MEASURED_TIME" -le 300 ]; then
    echo "✓ measureExecutionTime function works correctly: ''${MEASURED_TIME}ms"
  else
    echo "✗ measureExecutionTime function failed: ''${MEASURED_TIME}ms (expected ~100ms)"
    exit 1
  fi

  # TEST: assertPerformance function should exist and work
  echo "Testing assertPerformance function..."

  # Test that assertPerformance function works with a reasonable duration
  ${testHelpers.assertPerformance {
    command = "sleep 0.05";
    maxDuration = 100;
    message = "Short sleep test";
  }}

  # TEST: Performance measurement should be accurate
  echo "Testing performance measurement accuracy..."

  # Test direct timing accuracy as well
  START_TIME=$(date +%s%N)
  sleep 0.1
  END_TIME=$(date +%s%N)
  ACTUAL_DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

  # Test that measured time is reasonable (between 80-300ms for 100ms sleep)
  if [ "$ACTUAL_DURATION" -ge 80 ] && [ "$ACTUAL_DURATION" -le 300 ]; then
    echo "✓ Performance measurement is accurate: ''${ACTUAL_DURATION}ms"
  else
    echo "✗ Performance measurement inaccurate: ''${ACTUAL_DURATION}ms (expected ~100ms)"
    exit 1
  fi

  echo "Performance test helpers validation completed"
  touch $out
''
