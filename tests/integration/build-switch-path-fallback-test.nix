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
  # Source the script to get the pathResolutionWithFallback function
  . ./build-switch-test 2>/dev/null || true

  # Test the function directly
  if command -v pathResolutionWithFallback >/dev/null 2>&1; then
    RESOLVED_PATH=$(pathResolutionWithFallback "darwin-rebuild")
    if [ "$RESOLVED_PATH" = "./result/sw/bin/darwin-rebuild" ] && [ -x "./result/sw/bin/darwin-rebuild" ]; then
      echo "✓ Scenario 1: result symlink path correctly resolved"
    else
      echo "✗ Scenario 1: result symlink path resolution failed (got: $RESOLVED_PATH)"
      exit 1
    fi
  else
    echo "✗ Scenario 1: pathResolutionWithFallback function not available"
    exit 1
  fi

  # Scenario 2: result symlink broken, PATH available
  rm -f result
  mkdir -p mock_path_bin
  echo '#!/bin/bash' > mock_path_bin/darwin-rebuild
  echo 'echo "path darwin-rebuild: $@"' >> mock_path_bin/darwin-rebuild
  chmod +x mock_path_bin/darwin-rebuild
  export PATH="$(pwd)/mock_path_bin:$PATH"

  # Test path resolution for scenario 2
  if command -v pathResolutionWithFallback >/dev/null 2>&1; then
    RESOLVED_PATH=$(pathResolutionWithFallback "darwin-rebuild")
    if [ "$RESOLVED_PATH" = "darwin-rebuild" ] && command -v darwin-rebuild >/dev/null 2>&1; then
      echo "✓ Scenario 2: PATH fallback correctly resolved"
    else
      echo "✗ Scenario 2: PATH fallback resolution failed (got: $RESOLVED_PATH)"
      exit 1
    fi
  else
    echo "✗ Scenario 2: pathResolutionWithFallback function not available"
    exit 1
  fi

  # Scenario 3: system path fallback
  export PATH="/usr/bin:/bin"  # Remove our mock from PATH
  mkdir -p mock_system/run/current-system/sw/bin
  echo '#!/bin/bash' > mock_system/run/current-system/sw/bin/darwin-rebuild
  echo 'echo "system darwin-rebuild: $@"' >> mock_system/run/current-system/sw/bin/darwin-rebuild
  chmod +x mock_system/run/current-system/sw/bin/darwin-rebuild

  # Test path resolution for scenario 3
  # Create mock system path temporarily
  ORIGINAL_PATH="$PATH"
  export PATH="/usr/bin:/bin"

  if command -v pathResolutionWithFallback >/dev/null 2>&1; then
    # This should fallback to system path since no result link and no PATH
    RESOLVED_PATH=$(pathResolutionWithFallback "darwin-rebuild")
    if [ "$RESOLVED_PATH" = "/run/current-system/sw/bin/darwin-rebuild" ]; then
      echo "✓ Scenario 3: System fallback correctly resolved"
    else
      echo "✗ Scenario 3: System fallback resolution failed (got: $RESOLVED_PATH)"
      exit 1
    fi
  else
    echo "✗ Scenario 3: pathResolutionWithFallback function not available"
    exit 1
  fi

  # Restore PATH
  export PATH="$ORIGINAL_PATH"

  # Test 3: Broken symlink handling (should fail initially)
  ${testHelpers.testSubsection "Broken Symlink Handling"}

  # Create a broken symlink
  ln -sf nonexistent_target broken_result

  # Test that broken symlink detection works
  ln -sf broken_result result  # Point result to the broken symlink

  if command -v pathResolutionWithFallback >/dev/null 2>&1; then
    # This should skip the broken symlink and fallback to PATH/system
    RESOLVED_PATH=$(pathResolutionWithFallback "darwin-rebuild")
    if [ "$RESOLVED_PATH" != "./result/sw/bin/darwin-rebuild" ]; then
      echo "✓ Broken symlink correctly skipped (resolved to: $RESOLVED_PATH)"
    else
      echo "✗ Broken symlink was not skipped"
      exit 1
    fi
  else
    echo "✗ pathResolutionWithFallback function not available"
    exit 1
  fi

  # Test 4: Permission denied scenario (should fail initially)
  ${testHelpers.testSubsection "Permission Denied Scenario"}

  # Create a result with denied permissions
  mkdir -p denied_result/sw/bin
  echo '#!/bin/bash' > denied_result/sw/bin/darwin-rebuild
  chmod 000 denied_result/sw/bin/darwin-rebuild
  ln -sf denied_result result

  # Test permission handling
  if command -v pathResolutionWithFallback >/dev/null 2>&1; then
    # This should skip the non-executable file and fallback to PATH/system
    RESOLVED_PATH=$(pathResolutionWithFallback "darwin-rebuild")
    if [ "$RESOLVED_PATH" != "./result/sw/bin/darwin-rebuild" ]; then
      echo "✓ Permission denied file correctly skipped (resolved to: $RESOLVED_PATH)"
    else
      echo "✗ Permission denied file was not skipped"
      exit 1
    fi
  else
    echo "✗ pathResolutionWithFallback function not available"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Advanced Path Fallback Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All advanced path fallback tests passed${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ pathResolutionWithFallback function implemented successfully${testHelpers.colors.reset}"
  touch $out
''
