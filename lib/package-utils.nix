{ lib }:

{
  # Merge shared packages with platform-specific packages
  # This function standardizes the pattern used across platform modules
  mergePackageLists = { pkgs, sharedPackagesPath, platformPackages ? [] }:
    let
      # Import shared packages
      sharedPackages = import sharedPackagesPath { inherit pkgs; };

      # Validate that shared packages is a list
      validSharedPackages = if builtins.isList sharedPackages
        then sharedPackages
        else throw "Shared packages must be a list, got: ${builtins.typeOf sharedPackages}";

      # Validate that platform packages is a list
      validPlatformPackages = if builtins.isList platformPackages
        then platformPackages
        else throw "Platform packages must be a list, got: ${builtins.typeOf platformPackages}";
    in
    # Merge shared and platform-specific packages
    validSharedPackages ++ validPlatformPackages;

  # Helper function to get package names for debugging/testing
  getPackageNames = packages: map (pkg: pkg.name or pkg.pname or "unknown") packages;

  # Validation function to ensure packages are valid derivations
  validatePackages = packages:
    let
      invalidPackages = builtins.filter (pkg: !(pkg ? name || pkg ? pname)) packages;
    in
    if builtins.length invalidPackages > 0
    then throw "Invalid packages found: ${builtins.toString invalidPackages}"
    else packages;
}
