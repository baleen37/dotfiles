{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-path-fallback-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Advanced Path Fallback Tests"}

  # Test 1: Test pathResolutionWithFallback function (should fail initially)
  ${testHelpers.testSubsection "Path Resolution Function Testing"}

  # Create test workspace
  mkdir -p test_workspace
  cd test_workspace

  # Copy and modify build-switch script
  cp "${buildSwitchScript}" ./build-switch-test
  chmod +x ./build-switch-test

  # Test if pathResolutionWithFallback function exists in script
  if grep -q "pathResolutionWithFallback" ./build-switch-test; then
    echo "✓ pathResolutionWithFallback function found in script"
  else
    echo "✗ pathResolutionWithFallback function not found in script"
    exit 1
  fi

  # Test 2: Multiple fallback scenarios (should fail initially)
  ${testHelpers.testSubsection "Multiple Fallback Scenarios"}

  # Scenario 1: result symlink exists and is valid
  mkdir -p mock_result/sw/bin
  echo '#!/bin/bash' > mock_result/sw/bin/darwin-rebuild
  echo 'echo "result-path darwin-rebuild: $@"' >> mock_result/sw/bin/darwin-rebuild
  chmod +x mock_result/sw/bin/darwin-rebuild
  ln -sf mock_result result

  # Test path resolution for scenario 1
  RESOLVED_PATH=$(grep 'REBUILD_COMMAND_PATH=' ./build-switch-test | head -1 | cut -d'"' -f2)
  if [ "$RESOLVED_PATH" = "./result/sw/bin/darwin-rebuild" ] && [ -x "./result/sw/bin/darwin-rebuild" ]; then
    echo "✓ Scenario 1: result symlink path correctly resolved"
  else
    echo "✗ Scenario 1: result symlink path resolution failed"
    exit 1
  fi

  # Scenario 2: result symlink broken, PATH available
  rm -f result
  mkdir -p mock_path_bin
  echo '#!/bin/bash' > mock_path_bin/darwin-rebuild
  echo 'echo "path darwin-rebuild: $@"' >> mock_path_bin/darwin-rebuild
  chmod +x mock_path_bin/darwin-rebuild
  export PATH="$(pwd)/mock_path_bin:$PATH"

  # Test path resolution for scenario 2 (should fail with current implementation)
  if command -v darwin-rebuild >/dev/null 2>&1; then
    # Current implementation should fail to detect this
    echo "✗ Scenario 2: Current implementation should fail to use PATH fallback"
    exit 1
  else
    echo "✓ Scenario 2: PATH fallback test setup correct"
  fi

  # Scenario 3: system path fallback
  export PATH="/usr/bin:/bin"  # Remove our mock from PATH
  mkdir -p mock_system/run/current-system/sw/bin
  echo '#!/bin/bash' > mock_system/run/current-system/sw/bin/darwin-rebuild
  echo 'echo "system darwin-rebuild: $@"' >> mock_system/run/current-system/sw/bin/darwin-rebuild
  chmod +x mock_system/run/current-system/sw/bin/darwin-rebuild

  # Test path resolution for scenario 3 (should fail with current implementation)
  if [ -x "mock_system/run/current-system/sw/bin/darwin-rebuild" ]; then
    echo "✗ Scenario 3: Current implementation should fail to use system fallback"
    exit 1
  else
    echo "✓ Scenario 3: System fallback test setup correct"
  fi

  # Test 3: Broken symlink handling (should fail initially)
  ${testHelpers.testSubsection "Broken Symlink Handling"}

  # Create a broken symlink
  ln -sf nonexistent_target broken_result

  # Test that broken symlink detection works (should fail with current implementation)
  if [ -L "broken_result" ] && [ ! -e "broken_result" ]; then
    echo "✗ Broken symlink detection: current implementation should fail"
    exit 1
  else
    echo "✓ Broken symlink test setup correct"
  fi

  # Test 4: Permission denied scenario (should fail initially)
  ${testHelpers.testSubsection "Permission Denied Scenario"}

  # Create a result with denied permissions
  mkdir -p denied_result/sw/bin
  echo '#!/bin/bash' > denied_result/sw/bin/darwin-rebuild
  chmod 000 denied_result/sw/bin/darwin-rebuild
  ln -sf denied_result result

  # Test permission handling (should fail with current implementation)
  if [ -x "./result/sw/bin/darwin-rebuild" ]; then
    echo "✗ Permission denied: current implementation should fail"
    exit 1
  else
    echo "✓ Permission denied test setup correct"
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Advanced Path Fallback Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.red}✗ All advanced path fallback tests failed as expected${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Implementation needed: pathResolutionWithFallback function${testHelpers.colors.reset}"

  # This test should fail until we implement the advanced path resolution
  touch $out
''
