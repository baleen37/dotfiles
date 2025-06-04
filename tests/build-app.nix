{ pkgs }:
pkgs.runCommand "build-app-test" {} ''
  export USER=baleen
  if ! ${pkgs.nix}/bin/nix eval --impure --extra-experimental-features nix-command --expr ".#apps.${pkgs.system}.build.program" >/dev/null; then
    echo "build app not found for ${pkgs.system}"
    exit 1
  fi
  touch $out
''
