{ pkgs }:
let
  flakeFile = builtins.toString ../../flake.nix;
in pkgs.runCommand "flake-smoke" {} ''
  echo "Running smoke test"
  if [ ! -f ${flakeFile} ]; then
    echo "flake.nix missing"
    exit 1
  fi
  grep -q "description" ${flakeFile}
  touch $out
''

