{ pkgs }:
let
  overlay = import ../overlays/10-feather-font.nix;
  pkg = (overlay pkgs pkgs).feather-font;
in
pkgs.runCommand "feather-font-test" { buildInputs = [ pkgs.coreutils ]; } ''
  test -f ${pkg}/share/fonts/truetype/feather.ttf
  touch $out
''
