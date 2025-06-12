{ pkgs, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "user-resolution-unit-test" { } ''
  export SRC_PATH="${src}"
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "User Resolution Unit Tests"}

  # Test 1: Basic user resolution with USER env var
  export USER=testuser
  USER_RESULT=$(nix-instantiate --eval --expr "let getUser = import $SRC_PATH/lib/get-user.nix {}; in getUser" 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ "$USER_RESULT" = "testuser" ]'' "User resolution works with USER environment variable"}

  # Test 2: Fallback behavior when USER is empty
  unset USER
  export USER=""
  USER_RESULT=$(nix-instantiate --eval --expr "let getUser = import $SRC_PATH/lib/get-user.nix {}; in getUser" 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ -n "$USER_RESULT" ]'' "User resolution provides fallback when USER is empty"}

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
