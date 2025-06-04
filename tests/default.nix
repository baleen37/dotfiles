{ pkgs }:
let
  dir = ./.;
  files = builtins.filter (name: name != "default.nix" && builtins.match ".*\\.nix" name != null)
    (builtins.attrNames (builtins.readDir dir));
  tests = builtins.listToAttrs (map (file: {
    name = builtins.substring 0 ((builtins.stringLength file) - 4) file;
    value = import (dir + ("/" + file)) { inherit pkgs; };
  }) files);
in tests
