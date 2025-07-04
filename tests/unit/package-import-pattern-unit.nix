{ pkgs, lib, ... }:

let
  # Test the current package import pattern behavior
  testDarwinPackages = import ../../modules/darwin/packages.nix { inherit pkgs; };
  testNixosPackages = import ../../modules/nixos/packages.nix { inherit pkgs; };
  testSharedPackages = import ../../modules/shared/packages.nix { inherit pkgs; };
  
  # Simple test functions
  isValidPackageList = packages: builtins.isList packages && builtins.all (pkg: pkg ? name || pkg ? pname) packages;
  
  containsSharedPackages = platformPackages: sharedPackages:
    let
      sharedNames = map (pkg: pkg.name or pkg.pname) sharedPackages;
      platformNames = map (pkg: pkg.name or pkg.pname) platformPackages;
    in
    builtins.all (name: builtins.elem name platformNames) sharedNames;

in {
  # Basic validation tests
  tests = {
    # Test that current Darwin packages are valid
    darwinPackagesValid = {
      assertion = isValidPackageList testDarwinPackages;
      description = "Darwin packages should be a valid list of packages";
    };
    
    # Test that current NixOS packages are valid
    nixosPackagesValid = {
      assertion = isValidPackageList testNixosPackages;
      description = "NixOS packages should be a valid list of packages";
    };
    
    # Test that shared packages are valid
    sharedPackagesValid = {
      assertion = isValidPackageList testSharedPackages;
      description = "Shared packages should be a valid list of packages";
    };
    
    # Test that Darwin includes shared packages
    darwinIncludesShared = {
      assertion = containsSharedPackages testDarwinPackages testSharedPackages;
      description = "Darwin packages should include all shared packages";
    };
    
    # Test that NixOS includes shared packages
    nixosIncludesShared = {
      assertion = containsSharedPackages testNixosPackages testSharedPackages;
      description = "NixOS packages should include all shared packages";
    };
    
    # Test that Darwin has platform-specific packages
    darwinHasSpecificPackages = {
      assertion = 
        let 
          darwinNames = map (pkg: pkg.name or pkg.pname) testDarwinPackages;
        in
        builtins.any (name: lib.hasPrefix "dockutil" name) darwinNames && 
        builtins.any (name: lib.hasPrefix "karabiner-elements" name) darwinNames;
      description = "Darwin should have platform-specific packages";
    };
    
    # Test that NixOS has platform-specific packages
    nixosHasSpecificPackages = {
      assertion = 
        let 
          nixosNames = map (pkg: pkg.name or pkg.pname) testNixosPackages;
        in
        builtins.any (name: lib.hasPrefix "appimage-run" name) nixosNames && 
        builtins.any (name: lib.hasPrefix "galculator" name) nixosNames;
      description = "NixOS should have platform-specific packages";
    };
  };
  
  # Export test data for use by utilities
  inherit testDarwinPackages testNixosPackages testSharedPackages;
}