{ pkgs }:
pkgs.runCommand "get-user-test" {} ''
  export USER=codex
  result=$(${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr 'import ../lib/get-user.nix {}')
  if [ "$result" != "\"codex\"" ]; then
    echo "expected codex but got $result"
    exit 1
  fi
  unset USER
  export LOGNAME=codex
  result=$(${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr 'import ../lib/get-user.nix {}')
  if [ "$result" != "\"codex\"" ]; then
    echo "expected codex via LOGNAME but got $result"
    exit 1
  fi
  unset LOGNAME
  export SUDO_USER=codex
  export USER=root
  result=$(${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr 'import ../lib/get-user.nix {}')
  if [ "$result" != "\"codex\"" ]; then
    echo "expected codex via SUDO_USER but got $result"
    exit 1
  fi
  unset USER SUDO_USER
  if ${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr 'import ../lib/get-user.nix {}' >/dev/null 2>&1; then
    echo "expected failure when no user vars"
    exit 1
  fi
  touch $out
''


