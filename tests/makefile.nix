{ pkgs, flake ? null, src ? ../.. }:
pkgs.runCommand "makefile-test" { nativeBuildInputs = [ pkgs.gnumake ]; } ''
  set -e
  outText=$(make -f ${../Makefile} help)
  echo "$outText" | grep -q "Available targets"
  touch $out
''
