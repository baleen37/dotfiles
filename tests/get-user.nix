{ pkgs }:
let
  getUserLib = import ../lib/get-user.nix;
in
pkgs.runCommand "get-user-test" {} ''
  export USER=codex
  # Test that get-user returns the correct user when USER is set
  result="${getUserLib {}}"
  if [ "$result" != "codex" ]; then
    echo "expected codex but got $result"
    exit 1
  fi
  
  # Test without USER environment variable would fail during evaluation
  # so we just test the successful case
  echo "get-user test passed"
  touch $out
''
