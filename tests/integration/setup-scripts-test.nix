{ pkgs, ... }:
pkgs.runCommand "setup-script-scenarios"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.age
      pkgs.sops
      pkgs.jq
      pkgs.git
      pkgs.shellcheck
    ];
  }
  ''
    shellcheck --severity=warning -e SC1091,SC1090 ${../../bootstrap.sh} ${../../switch.sh} ${../../scripts/lib/setup.sh}
    bash ${./setup-scripts.sh} ${../..}
    touch "$out"
  ''
