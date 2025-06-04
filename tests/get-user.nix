{ pkgs }:
pkgs.runCommand "get-user-test" {} ''
  export USER=codex
  result=$(${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr 'import ../lib/get-user.nix {}')
  if [ "$result" != "\"codex\"" ]; then
    echo "expected codex but got $result"
    exit 1
  fi
  unset USER
  if ${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr 'import ../lib/get-user.nix {}' >/tmp/out 2>&1; then
    echo "expected failure when USER unset"
    exit 1
  fi
  grep -q "must be set" /tmp/out
  touch $out
''
