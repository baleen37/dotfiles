{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  getUserFn = import (src + "/lib/get-user.nix") { };
in
pkgs.runCommand "user-resolution-unit-test" { } ''
  export SRC_PATH="${src}"
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "User Resolution Unit Tests"}

  # Test 1: Basic user resolution with USER env var
  export USER=testuser
  USER_RESULT=$(nix-instantiate --eval --expr "let getUser = import $SRC_PATH/lib/get-user.nix {}; in getUser" 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ "$USER_RESULT" = "testuser" ]'' "User resolution works with USER environment variable"}

  # Test 2: Error handling when USER is empty
  unset USER
  export USER=""
  if nix-instantiate --eval --expr "let getUser = import $SRC_PATH/lib/get-user.nix {}; in getUser" 2>&1 | grep -q "Failed to detect valid user"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} User resolution correctly errors when USER is empty"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} User resolution should error when USER is empty"
    exit 1
  fi

  # Test 3: Function returns string type
  export USER=testuser
  TYPE_CHECK=$(nix-instantiate --eval --expr "let getUser = import $SRC_PATH/lib/get-user.nix {}; in builtins.typeOf getUser" 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ "$TYPE_CHECK" = "string" ]'' "User resolution returns string type"}

  # Test 4: No special characters injection
  export USER="test'user"
  SAFE_RESULT=$(nix-instantiate --eval --expr "let getUser = import $SRC_PATH/lib/get-user.nix {}; in getUser" 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ "$SAFE_RESULT" = "test'user" ]'' "User resolution handles special characters safely"}

  ${testHelpers.reportResults "User Resolution Unit Tests" 4 4}
  touch $out
''
