{ pkgs }:
let
  dir = ./.;
  files = builtins.filter (name: name != "default.nix" && builtins.match ".*\\.nix" name != null)
    (builtins.attrNames (builtins.readDir dir));
  
  # Convert filename to valid Nix attribute name
  sanitizeName = name: 
    let
      baseName = builtins.substring 0 ((builtins.stringLength name) - 4) name;
      # Replace hyphens with underscores for valid Nix attribute names
      sanitized = builtins.replaceStrings ["-"] ["_"] baseName;
    in sanitized;
  
  tests = builtins.listToAttrs (map (file: {
    name = sanitizeName file;
    value = import (dir + ("/" + file)) { inherit pkgs; };
  }) files);
in tests
