{ pkgs, ... }:
pkgs.runCommand "just-command-contract"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.just
      pkgs.bash
      pkgs.git
      pkgs.jq
    ];
  }
  ''
    export PYTHONDONTWRITEBYTECODE=1
    python3 ${./just-commands.py} ${../..}
    touch "$out"
  ''
