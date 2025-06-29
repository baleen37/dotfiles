# Test for portable path utilities functionality
{ pkgs }:

let
  portablePaths = import ../lib/portable-paths.nix { inherit pkgs; };
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in

pkgs.runCommand "portable-paths-test" { } ''
  echo "🧪 Portable Paths Utilities Test"
  echo "================================"

  # Test 1: Verify portable temp directory creation
  ${testHelpers.testSubsection "Portable Temp Directory"}

  ${portablePaths.getTempDir}

  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} TEST_TEMP_DIR created: $TEST_TEMP_DIR"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failed to create TEST_TEMP_DIR"
    exit 1
  fi

  # Test that the temp directory is writable
  TEST_FILE="$TEST_TEMP_DIR/test-write-check"
  if echo "test content" > "$TEST_FILE" 2>/dev/null; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Temp directory is writable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Temp directory is not writable"
    exit 1
  fi

  # Test 2: Verify portable test home creation
  ${testHelpers.testSubsection "Portable Test Home"}

  ${portablePaths.getTestHome}

  if [ -n "$HOME" ] && [ -d "$HOME" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} HOME directory created: $HOME"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failed to create HOME directory"
    exit 1
  fi

  # Test that home directory is different from temp directory
  if [ "$HOME" != "$TEST_TEMP_DIR" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} HOME and TEMP directories are separate"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} HOME and TEMP directories should be separate"
    exit 1
  fi

  # Test 3: Verify system binary resolution
  ${testHelpers.testSubsection "System Binary Resolution"}

  # Test common system binaries
  BINARIES=(
    "echo"
    "cat"
    "touch"
    "rm"
    "mkdir"
    "find"
  )

  for binary in "''${BINARIES[@]}"; do
    BINARY_PATH="${portablePaths.getSystemBinary binary}"
    if [ -x "$BINARY_PATH" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Binary '$binary' resolved to: $BINARY_PATH"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Binary '$binary' not found or not executable: $BINARY_PATH"
      exit 1
    fi
  done

  # Test 4: Verify mock system file creation
  ${testHelpers.testSubsection "Mock System File Creation"}

  ${portablePaths.createMockSystemFile "test user:x:1000:1000:Test User:/home/test:/bin/bash"}

  if [ -n "$MOCK_SYSTEM_FILE" ] && [ -f "$MOCK_SYSTEM_FILE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock system file created: $MOCK_SYSTEM_FILE"

    # Verify content
    if grep -q "test user" "$MOCK_SYSTEM_FILE"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock system file has correct content"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock system file content incorrect"
      exit 1
    fi
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failed to create mock system file"
    exit 1
  fi

  # Test 5: Verify platform detection
  ${testHelpers.testSubsection "Platform Detection"}

  ${portablePaths.getPlatformInfo}

  if [ -n "$PLATFORM" ] && [ -n "$HOME_PREFIX" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform detected: $PLATFORM"
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Home prefix: $HOME_PREFIX"

    # Verify platform makes sense
    case "$PLATFORM" in
      "macos"|"linux")
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform value is valid"
        ;;
      *)
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Unknown platform: $PLATFORM"
        exit 1
        ;;
    esac
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failed to detect platform information"
    exit 1
  fi

  # Test 6: Verify cleanup works properly
  ${testHelpers.testSubsection "Cleanup Verification"}

  # Create some test files to be cleaned up
  TEST_CLEANUP_FILE="$TEST_TEMP_DIR/cleanup-test"
  echo "cleanup test" > "$TEST_CLEANUP_FILE"

  if [ -f "$TEST_CLEANUP_FILE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Test cleanup file created"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failed to create test cleanup file"
    exit 1
  fi

  # Note: Actual cleanup verification happens when the script exits
  # due to the trap handlers set up by the portable paths functions

  echo ""
  echo "${testHelpers.colors.green}🎉 All Portable Paths Tests Passed!${testHelpers.colors.reset}"
  echo ""
  echo "Summary:"
  echo "- Portable temp directory: ✅"
  echo "- Portable test home: ✅"
  echo "- System binary resolution: ✅"
  echo "- Mock system file creation: ✅"
  echo "- Platform detection: ✅"
  echo "- Cleanup preparation: ✅"

  touch $out
''
