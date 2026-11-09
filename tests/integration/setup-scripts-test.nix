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
      pkgs.python3
    ];
  }
  ''
    shellcheck --severity=warning -e SC1091,SC1090 ${../../bootstrap.sh} ${../../switch.sh} ${../../scripts/lib/setup.sh} ${../../scripts/lib/flake-source.sh} ${../../machines/debian/apply.sh}
    bash ${./setup-scripts.sh} ${../..}
    DOTFILES_TEST_REPO=${../..} python3 ${./debian-setup.py}
    touch "$out"
  ''
