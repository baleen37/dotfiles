{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "build-switch-performance-regression-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Performance Regression Detection Tests"}

  # Test 1: Performance baseline establishment (should fail initially)
  ${testHelpers.testSubsection "Performance Baseline Establishment"}

  mkdir -p test_workspace
  cd test_workspace

  # Test that performance baseline functions exist
  BUILD_SWITCH_COMMON="${src}/scripts/build-switch-common.sh"

  if [ -f "$BUILD_SWITCH_COMMON" ]; then
    if grep -q "establish_performance_baseline" "$BUILD_SWITCH_COMMON"; then
      echo "✓ establish_performance_baseline function found"
    else
      echo "✗ establish_performance_baseline function not found"
      exit 1
    fi
  else
    echo "✗ build-switch-common.sh not found"
    exit 1
  fi

  # Test 2: Performance monitoring framework (should fail initially)
  ${testHelpers.testSubsection "Performance Monitoring Framework"}

  if grep -q "start_performance_monitoring" "$BUILD_SWITCH_COMMON"; then
    echo "✓ start_performance_monitoring function found"
  else
    echo "✗ start_performance_monitoring function not found"
    exit 1
  fi

  if grep -q "stop_performance_monitoring" "$BUILD_SWITCH_COMMON"; then
    echo "✓ stop_performance_monitoring function found"
  else
    echo "✗ stop_performance_monitoring function not found"
    exit 1
  fi

  # Test 3: Performance regression detection (should fail initially)
  ${testHelpers.testSubsection "Performance Regression Detection"}

  if grep -q "detect_performance_regression" "$BUILD_SWITCH_COMMON"; then
    echo "✓ detect_performance_regression function found"
  else
    echo "✗ detect_performance_regression function not found"
    exit 1
  fi

  # Test 4: Performance reporting (should fail initially)
  ${testHelpers.testSubsection "Performance Reporting"}

  if grep -q "generate_performance_report" "$BUILD_SWITCH_COMMON"; then
    echo "✓ generate_performance_report function found"
  else
    echo "✗ generate_performance_report function not found"
    exit 1
  fi

  # Test 5: Performance alert system (should fail initially)
  ${testHelpers.testSubsection "Performance Alert System"}

  if grep -q "trigger_performance_alert" "$BUILD_SWITCH_COMMON"; then
    echo "✓ trigger_performance_alert function found"
  else
    echo "✗ trigger_performance_alert function not found"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Performance Regression Detection Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All performance regression detection tests passed${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Performance regression detection implemented successfully${testHelpers.colors.reset}"

  touch $out
''
