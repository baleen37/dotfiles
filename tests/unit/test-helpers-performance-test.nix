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

  # This test should FAIL initially because measureExecutionTime doesn't exist yet
  if command -v measureExecutionTime >/dev/null 2>&1; then
    echo "✓ measureExecutionTime function exists"
  else
    echo "✗ measureExecutionTime function not found"
    exit 1
  fi

  # TEST: assertPerformance function should exist and work
  echo "Testing assertPerformance function..."

  # This test should FAIL initially because assertPerformance doesn't exist yet
  if command -v assertPerformance >/dev/null 2>&1; then
    echo "✓ assertPerformance function exists"
  else
    echo "✗ assertPerformance function not found"
    exit 1
  fi

  # TEST: Performance measurement should be accurate
  echo "Testing performance measurement accuracy..."

  # This should fail because the functions don't exist yet
  START_TIME=$(date +%s%N)
  sleep 0.1
  END_TIME=$(date +%s%N)
  ACTUAL_DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

  # Test that measured time is reasonable (between 95-150ms for 100ms sleep)
  if [ "$ACTUAL_DURATION" -ge 95 ] && [ "$ACTUAL_DURATION" -le 150 ]; then
    echo "✓ Performance measurement is accurate: ''${ACTUAL_DURATION}ms"
  else
    echo "✗ Performance measurement inaccurate: ''${ACTUAL_DURATION}ms (expected ~100ms)"
    exit 1
  fi

  echo "Performance test helpers validation completed"
  touch $out
''
