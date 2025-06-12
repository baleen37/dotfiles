{ pkgs }:
let
  # Test get-user function with current environment
  getUserLib = import ../lib/get-user.nix;
  currentUser = getUserLib {};
  defaultUser = getUserLib { default = "fallback"; };
in
pkgs.runCommand "get-user-test" {} ''
  # Test that get-user returns a non-empty value
  current_result="${currentUser}"
  if [ -z "$current_result" ]; then
    echo "get-user returned empty string"
    exit 1
  fi

  # Test that get-user returns same value with default (should use env var)
  default_result="${defaultUser}"
  if [ "$current_result" != "$default_result" ]; then
    echo "get-user inconsistent: '$current_result' vs '$default_result'"
    exit 1
  fi

  echo "get-user test passed: returns '$current_result'"
  touch $out
''
