{ pkgs, ... }:
pkgs.runCommand "debian-remote-access-integration"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.sops
      pkgs.age
    ];
  }
  ''
    export PYTHONDONTWRITEBYTECODE=1
    python3 ${./debian-remote-access.py} ${../..}
    bash ${../..}/machines/debian/apply.sh --check
    touch "$out"
  ''
