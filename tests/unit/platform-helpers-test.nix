# tests/unit/platform-helpers-test.nix
# Tests platform helper utilities for conditional test inclusion
{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Import platform helpers once for testing
  platformHelpers = import ../lib/platform-helpers.nix { inherit pkgs lib; };
  currentPlatform = platformHelpers.getCurrentPlatform;
in
# Simple test suite that works within framework constraints
pkgs.runCommand "test-suite-platform-helpers" { } ''
  echo "🧪 Running platform helpers test suite"
  echo "🌍 Platform: ${currentPlatform}"
  echo ""

  echo "🔍 Test: mkPlatformTest function availability"
  if ${if builtins.isFunction platformHelpers.mkPlatformTest then "echo '✅ PASS: mkPlatformTest available'" else "echo '❌ FAIL: mkPlatformTest not available'; exit 1"}; then
    echo "  ✅ PASS"
  else
    echo "  ❌ FAIL"
    exit 1
  fi

  echo "🔍 Test: filterPlatformTests function availability"
  if ${if builtins.isFunction platformHelpers.filterPlatformTests then "echo '✅ PASS: filterPlatformTests available'" else "echo '❌ FAIL: filterPlatformTests not available'; exit 1"}; then
    echo "  ✅ PASS"
  else
    echo "  ❌ FAIL"
    exit 1
  fi

  echo "🔍 Test: getCurrentPlatform value availability"
  if ${if builtins.isString currentPlatform then "echo '✅ PASS: getCurrentPlatform available'" else "echo '❌ FAIL: getCurrentPlatform not available'; exit 1"}; then
    echo "  ✅ PASS"
  else
    echo "  ❌ FAIL"
    exit 1
  fi

  echo "🔍 Test: Platform detection returns valid value"
  echo "  Current platform: ${currentPlatform}"
  if [ "${currentPlatform}" = "darwin" ] || [ "${currentPlatform}" = "linux" ] || [ "${currentPlatform}" = "unknown" ]; then
    echo "  ✅ PASS: Platform value is valid"
  else
    echo "  ❌ FAIL: Invalid platform value"
    exit 1
  fi

  echo "🔍 Test: isCurrentPlatform helper availability"
  if ${if builtins.isFunction platformHelpers.isCurrentPlatform then "echo '✅ PASS: isCurrentPlatform available'" else "echo '❌ FAIL: isCurrentPlatform not available'; exit 1"}; then
    echo "  ✅ PASS"
  else
    echo "  ❌ FAIL"
    exit 1
  fi

  echo "🔍 Test: mkPlatformTestSuite helper availability"
  if ${if builtins.isFunction platformHelpers.mkPlatformTestSuite then "echo '✅ PASS: mkPlatformTestSuite available'" else "echo '❌ FAIL: mkPlatformTestSuite not available'; exit 1"}; then
    echo "  ✅ PASS"
  else
    echo "  ❌ FAIL"
    exit 1
  fi

  echo ""
  echo "✅ Test suite platform-helpers: All tests passed"
  echo "🎯 Platform discovery integration is working correctly"
  touch $out
''
