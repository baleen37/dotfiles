# Common Utilities Library
# Reusable functions for system detection, package filtering, and configuration operations

{ pkgs ? import <nixpkgs> {} }:

{
  # System detection utilities
  
  # Check if current system matches target system
  isSystem = currentSystem: targetSystem: currentSystem == targetSystem;
  
  # Check if system is Darwin (macOS)
  isDarwin = system: builtins.match ".*-darwin" system != null;
  
  # Check if system is Linux
  isLinux = system: builtins.match ".*-linux" system != null;
  
  # Package filtering utilities
  
  # Filter out packages that don't exist in nixpkgs
  filterValidPackages = packageList: nixpkgs:
    builtins.filter (pkg: 
      if builtins.isString pkg 
      then builtins.hasAttr pkg nixpkgs
      else true  # Allow package derivations to pass through
    ) packageList;
  
  # Configuration merging utilities
  
  # Deep merge two attribute sets (configs)
  mergeConfigs = config1: config2:
    let
      mergeAttr = name: value:
        if builtins.hasAttr name config1
        then
          let existing = config1.${name}; in
          if builtins.isAttrs existing && builtins.isAttrs value
          then existing // value  # Merge nested attributes
          else value              # Override with new value
        else value;              # Add new attribute
    in
    config1 // (builtins.mapAttrs mergeAttr config2);
  
  # List manipulation utilities
  
  # Remove duplicate elements from a list
  unique = list:
    let
      addUnique = acc: item:
        if builtins.elem item acc
        then acc
        else acc ++ [item];
    in
    builtins.foldl' addUnique [] list;
  
  # Flatten nested lists into a single list
  flatten = nestedList:
    let
      flattenItem = item:
        if builtins.isList item
        then builtins.concatLists (map flattenItem item)
        else [item];
    in
    builtins.concatLists (map flattenItem nestedList);
  
  # String utilities
  
  # Join list of strings with separator
  joinStrings = separator: stringList:
    builtins.concatStringsSep separator stringList;
  
  # Check if string starts with prefix
  hasPrefix = prefix: string:
    let
      prefixLen = builtins.stringLength prefix;
      stringLen = builtins.stringLength string;
    in
    if prefixLen > stringLen 
    then false
    else builtins.substring 0 prefixLen string == prefix;
}