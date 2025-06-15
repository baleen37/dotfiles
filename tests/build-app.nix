{ pkgs }:
let
  flake = builtins.getFlake (toString ../.);
  buildAppExists = builtins.hasAttr pkgs.system flake.outputs.apps &&
                   builtins.hasAttr "build" flake.outputs.apps.${pkgs.system};
in
pkgs.runCommand "build-app-test" {} ''
  export USER=baleen
  # Check if the build app exists for this system
  ${if buildAppExists then ''
    echo "build app found for ${pkgs.system}"
  '' else ''
    echo "build app not found for ${pkgs.system}"
    exit 1
  ''}
  touch $out
''
