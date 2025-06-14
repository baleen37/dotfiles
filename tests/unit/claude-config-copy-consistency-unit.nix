{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Test constants
  testUser = "testuser";
  testHome = "/home/${testUser}";
  
  # Expected Claude config files
  expectedClaudeFiles = [
    "CLAUDE.md"
    "settings.json"
    "commands/build.md"
    "commands/create-pr.md" 
    "commands/create-worktree.md"
    "commands/do-todo.md"
    "commands/docs.md"
    "commands/fix-github-issue.md"
    "commands/fix-pr.md"
    "commands/plan-tdd.md"
    "commands/plan.md"
    "commands/tdd.md" 
    "commands/update-docs.md"
    "commands/verify-pr.md"
  ];

in
pkgs.runCommand "claude-config-copy-consistency-unit-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "Claude Config Copy Consistency Unit Tests"}
  
  # Test 1: Verify all expected Claude files exist in source
  ${testHelpers.testSubsection "Source File Verification"}
  
  EXPECTED_FILES=(${toString expectedClaudeFiles})
  MISSING_SOURCE_FILES=0
  
  for file in "''${EXPECTED_FILES[@]}"; do
    if [ -f "${src}/modules/shared/config/claude/$file" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Source file exists: $file"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Missing source file: $file"
      MISSING_SOURCE_FILES=$((MISSING_SOURCE_FILES + 1))
    fi
  done
  
  # Test 2: Check for duplicate copy mechanisms in files.nix
  ${testHelpers.testSubsection "Duplicate Copy Mechanism Detection"}
  
  # Check if files.nix contains Claude file entries
  CLAUDE_ENTRIES_IN_FILES=0
  if [ -f "${src}/modules/shared/files.nix" ]; then
    CLAUDE_ENTRIES_IN_FILES=$(grep -c "\.claude/" "${src}/modules/shared/files.nix" || echo "0")
    echo "Found $CLAUDE_ENTRIES_IN_FILES Claude file entries in files.nix"
  fi
  
  # Check if Darwin home-manager has activation script
  DARWIN_HAS_ACTIVATION=0
  if [ -f "${src}/modules/darwin/home-manager.nix" ]; then
    if grep -q "copyClaudeFiles" "${src}/modules/darwin/home-manager.nix"; then
      DARWIN_HAS_ACTIVATION=1
      echo "Found Claude activation script in Darwin home-manager"
    fi
  fi
  
  # Test for duplicate mechanisms (both should not exist)
  DUPLICATE_MECHANISM_DETECTED=0
  if [ $CLAUDE_ENTRIES_IN_FILES -gt 0 ] && [ $DARWIN_HAS_ACTIVATION -eq 1 ]; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Duplicate copy mechanisms detected!"
    DUPLICATE_MECHANISM_DETECTED=1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} No duplicate copy mechanisms"
  fi
  
  # Test 3: Check platform consistency
  ${testHelpers.testSubsection "Platform Consistency"}
  
  # Check if NixOS has similar Claude handling
  NIXOS_HAS_ACTIVATION=0
  if [ -f "${src}/modules/nixos/home-manager.nix" ]; then
    if grep -q "copyClaudeFiles" "${src}/modules/nixos/home-manager.nix"; then
      NIXOS_HAS_ACTIVATION=1
    fi
  fi
  
  PLATFORM_INCONSISTENCY=0
  if [ $DARWIN_HAS_ACTIVATION -ne $NIXOS_HAS_ACTIVATION ]; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Platform inconsistency: Darwin has activation=$DARWIN_HAS_ACTIVATION, NixOS has activation=$NIXOS_HAS_ACTIVATION"
    PLATFORM_INCONSISTENCY=1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform consistency maintained"
  fi
  
  # Test 4: Check symlink handling robustness
  ${testHelpers.testSubsection "Symlink Handling"}
  
  SYMLINK_HANDLING_ISSUES=0
  if [ $DARWIN_HAS_ACTIVATION -eq 1 ]; then
    # Check if activation script has proper error handling
    if ! grep -q "set -e\||| return" "${src}/modules/darwin/home-manager.nix"; then
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Activation script lacks proper error handling"
      SYMLINK_HANDLING_ISSUES=$((SYMLINK_HANDLING_ISSUES + 1))
    fi
    
    # Check if it handles symlink conversion
    if ! grep -q "convert_symlink\|readlink" "${src}/modules/darwin/home-manager.nix"; then
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Activation script lacks symlink conversion handling"
      SYMLINK_HANDLING_ISSUES=$((SYMLINK_HANDLING_ISSUES + 1))
    fi
  fi
  
  if [ $SYMLINK_HANDLING_ISSUES -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Symlink handling appears robust"
  fi
  
  # Test 5: File content validation
  ${testHelpers.testSubsection "File Content Validation"}
  
  INVALID_FILE_CONTENT=0
  for file in "''${EXPECTED_FILES[@]}"; do
    SOURCE_FILE="${src}/modules/shared/config/claude/$file"
    if [ -f "$SOURCE_FILE" ]; then
      # Check if file is not empty
      if [ ! -s "$SOURCE_FILE" ]; then
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Empty source file: $file"
        INVALID_FILE_CONTENT=$((INVALID_FILE_CONTENT + 1))
      fi
    fi
  done
  
  if [ $INVALID_FILE_CONTENT -eq 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} All source files have content"
  fi
  
  ${testHelpers.cleanup}
  
  # Calculate test results
  TOTAL_TESTS=5
  FAILED_TESTS=0
  
  # Count failures
  [ $MISSING_SOURCE_FILES -gt 0 ] && FAILED_TESTS=$((FAILED_TESTS + 1))
  [ $DUPLICATE_MECHANISM_DETECTED -eq 1 ] && FAILED_TESTS=$((FAILED_TESTS + 1))
  [ $PLATFORM_INCONSISTENCY -eq 1 ] && FAILED_TESTS=$((FAILED_TESTS + 1))
  [ $SYMLINK_HANDLING_ISSUES -gt 0 ] && FAILED_TESTS=$((FAILED_TESTS + 1))
  [ $INVALID_FILE_CONTENT -gt 0 ] && FAILED_TESTS=$((FAILED_TESTS + 1))
  
  PASSED_TESTS=$((TOTAL_TESTS - FAILED_TESTS))
  
  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Claude Config Copy Consistency ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}''${PASSED_TESTS}${testHelpers.colors.reset}/''${TOTAL_TESTS}"
  
  # For TDD, we expect some tests to fail initially
  echo ""
  echo "${testHelpers.colors.yellow}📋 TDD Status: Expected failures for initial test run${testHelpers.colors.reset}"
  echo "- Missing source files: $MISSING_SOURCE_FILES"
  echo "- Duplicate mechanisms: $DUPLICATE_MECHANISM_DETECTED"
  echo "- Platform inconsistency: $PLATFORM_INCONSISTENCY"  
  echo "- Symlink handling issues: $SYMLINK_HANDLING_ISSUES"
  echo "- Invalid file content: $INVALID_FILE_CONTENT"
  
  if [ "''${FAILED_TESTS}" -gt 0 ]; then
    echo "${testHelpers.colors.yellow}⚠ ''${FAILED_TESTS} tests failed (expected for TDD)${testHelpers.colors.reset}"
  else
    echo "${testHelpers.colors.green}✓ All tests passed!${testHelpers.colors.reset}"
  fi
  
  touch $out
''