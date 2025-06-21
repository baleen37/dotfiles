{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "mock-file-system-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Enhanced Mock File System Unit Tests"}

  # Test 1: Basic mock file system functionality
  ${testHelpers.testSubsection "Basic Mock File System Operations"}

  # Now that we've implemented createMockFileSystem, test it works
  eval $(${testHelpers.createMockFileSystem})

  if [ -n "$MOCK_FS_STATE" ] && [ -f "$MOCK_FS_STATE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock file system initialized successfully"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock file system initialization failed"
    exit 1
  fi

  # Test 2: Mock file operations tracking
  ${testHelpers.testSubsection "File Operations Tracking"}

  # Test file creation
  TEST_FILE="$MOCK_FS_DIR/test.txt"
  ${testHelpers.mockFileCreate "$TEST_FILE" "test content"}

  if [ -f "$TEST_FILE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock file creation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock file creation failed"
    exit 1
  fi

  # Test file reading
  CONTENT=$(${testHelpers.mockFileRead "$TEST_FILE"})
  if [ "$CONTENT" = "test content" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock file reading works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock file reading failed"
    exit 1
  fi

  # Test operation counting
  OP_COUNT=$(${testHelpers.getMockOperationCount})
  if [ "$OP_COUNT" = "2" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Operation counting works (2 operations)"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Operation counting failed (expected 2, got $OP_COUNT)"
    exit 1
  fi

  # Test 3: Permission error simulation
  ${testHelpers.testSubsection "Permission Error Simulation"}

  # Test permission error simulation (check for error message)
  PERM_OUTPUT=$(${testHelpers.mockPermissionError "/restricted/file" "write"} 2>&1)

  if echo "$PERM_OUTPUT" | grep -q "PERMISSION_ERROR_OCCURRED"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Permission error simulation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Permission error simulation failed"
    echo "Expected PERMISSION_ERROR_OCCURRED, got: $PERM_OUTPUT"
    exit 1
  fi

  # Test 4: File content verification
  ${testHelpers.testSubsection "File Content Verification"}

  # Test file content verification
  ${testHelpers.mockFileVerify "$TEST_FILE" "test content"}
  VERIFY_RESULT=$?

  if [ "$VERIFY_RESULT" = "0" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} File content verification works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} File content verification failed"
    exit 1
  fi

  # Test 5: Directory operations
  ${testHelpers.testSubsection "Directory Operations"}

  # Test directory creation
  TEST_DIR="$MOCK_FS_DIR/testdir"
  ${testHelpers.mockDirCreate "$TEST_DIR"}

  if [ -d "$TEST_DIR" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock directory creation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock directory creation failed"
    exit 1
  fi

  # Test 6: Operation history
  ${testHelpers.testSubsection "Operation History"}

  HISTORY=$(${testHelpers.getMockOperationHistory})
  if echo "$HISTORY" | grep -q "CREATE:$TEST_FILE"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Operation history tracking works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Operation history tracking failed"
    exit 1
  fi

  echo ""
  echo "${testHelpers.colors.blue}=== TDD Green Phase Complete ===${testHelpers.colors.reset}"
  echo "All basic mock file system functions implemented and tested"

  touch $out
''
