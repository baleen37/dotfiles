{ pkgs }:
let
  hasFeather = pkgs ? feather-font;
  checkCmd = if hasFeather then "test -f ${pkgs.feather-font}/share/fonts/truetype/feather.ttf" else "echo 'feather-font not available for ${pkgs.system}'";
in pkgs.runCommand "e2e-overlay-test" { } ''
  # Verify overlay package builds on supported platforms
  ${checkCmd}
  touch $out
''
