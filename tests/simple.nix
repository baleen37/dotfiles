{ pkgs }:
pkgs.runCommand "simple-test" {} ''
  echo "Running simple test"
  if [ $((1 + 1)) -ne 2 ]; then
    echo "math is broken"
    exit 1
  fi
  touch $out
''

