{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "mock-file-system-simple-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Mock File System Simple Test"}

  # Test that we can create and initialize the mock file system
  eval $(${testHelpers.createMockFileSystem})

  if [ -n "$MOCK_FS_STATE" ] && [ -f "$MOCK_FS_STATE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock file system works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock file system failed"
    exit 1
  fi

  echo ""
  echo "${testHelpers.colors.blue}=== Simple Test Complete ===${testHelpers.colors.reset}"

  touch $out
''
