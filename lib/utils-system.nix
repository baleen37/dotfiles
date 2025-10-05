# Unified Utilities System - Backwards Compatibility Layer
#
# Purpose: Consolidates common-utils.nix and package-utils.nix into a single unified system
# Provides comprehensive utility functions for system operations
#
# Why This File Exists:
# - Backwards compatibility: Existing tests reference these specific utility functions
# - Test stability: Changing test dependencies would require extensive test rewrites
# - Migration path: New code should use nixpkgs.lib or platform-system.nix instead
#
# Duplicate Utilities Explanation:
# String/list/path utilities duplicate nixpkgs.lib functionality (e.g., hasPrefix, splitString).
#
# Rationale for Maintaining Duplication:
# 1. Test Dependency: 20+ test files in tests/{unit,integration,e2e}/ import these functions
# 2. API Compatibility: Test assertions verify specific function signatures (3-parameter formatError, etc.)
# 3. Migration Cost: Refactoring all tests to use nixpkgs.lib would require rewriting ~5,000 LOC
# 4. Risk/Reward: Tests are stable and passing; refactor provides no functional benefit
#
# For New Code (IMPORTANT):
# - String operations: Use nixpkgs.lib.strings (lib.hasPrefix, lib.splitString, lib.concatStrings)
# - List operations: Use nixpkgs.lib.lists (lib.unique, lib.flatten, lib.filter)
# - Platform detection: Use ./platform-system.nix (standardized isDarwin/isLinux interface)
#
# Example Migration:
# OLD: utils.formatError "test" expected actual context
# NEW: Use nixpkgs.lib.trivial.warn or custom formatter with lib.concatStringsSep
# - For EXISTING tests: Continue using this file until test refactoring
# - Future: Consolidate all utilities into platform-system.nix after test migration
#
# Specific Duplicates to Avoid in New Code:
#   - stringUtils.hasPrefix     → Use actualLib.hasPrefix
#   - stringUtils.splitString   → Use actualLib.splitString
#   - listUtils.unique          → Use actualLib.unique
#   - listUtils.flatten         → Use actualLib.flatten
#   - systemUtils.isDarwin      → Use (import ./platform-system.nix).isDarwin
#   - systemUtils.isLinux       → Use (import ./platform-system.nix).isLinux

{
  pkgs ? null,
  lib ? null,
}:

let
  # Determine pkgs and lib
  actualPkgs = if pkgs != null then pkgs else (import <nixpkgs> { });
  actualLib = if lib != null then lib else actualPkgs.lib;

  # Import error system for error handling
  errorSystem = import ./error-system.nix {
    pkgs = actualPkgs;
    lib = actualLib;
  };

  # Import optimized platform detection utilities
  platformDetection = import ./platform-detection.nix {
    pkgs = actualPkgs;
    lib = actualLib;
  };

  # System detection utilities (now using optimized platform detection)
  systemUtils = {
    # Check if current system matches target system
    isSystem = currentSystem: targetSystem: currentSystem == targetSystem;

    # Use optimized platform detection functions (cached results)
    inherit (platformDetection)
      isDarwin
      isLinux
      isX86_64
      isAarch64
      ;
    inherit (platformDetection) getPlatform getArch validateSystem;
  };

  # Package utilities
  packageUtils = {
    # Filter out packages that don't exist in nixpkgs
    filterValidPackages =
      packageList: nixpkgs:
      builtins.filter (
        pkg: if builtins.isString pkg then builtins.hasAttr pkg nixpkgs else true # Allow package derivations to pass through
      ) packageList;

    # Merge shared packages with platform-specific packages
    # This function standardizes the pattern used across platform modules
    mergePackageLists =
      {
        pkgs,
        sharedPackagesPath,
        platformPackages ? [ ],
      }:
      let
        # Import shared packages
        sharedPackages = import sharedPackagesPath { inherit pkgs; };

        # Validate that shared packages is a list
        validSharedPackages =
          if builtins.isList sharedPackages then
            sharedPackages
          else
            errorSystem.throwValidationError "Shared packages must be a list, got: ${builtins.typeOf sharedPackages}";

        # Validate that platform packages is a list
        validPlatformPackages =
          if builtins.isList platformPackages then
            platformPackages
          else
            errorSystem.throwValidationError "Platform packages must be a list, got: ${builtins.typeOf platformPackages}";
      in
      # Merge shared and platform-specific packages
      validSharedPackages ++ validPlatformPackages;

    # Helper function to get package names for debugging/testing
    getPackageNames = packages: map (pkg: pkg.name or pkg.pname or "unknown") packages;

    # Validation function to ensure packages are valid derivations
    validatePackages =
      packages:
      let
        invalidPackages = builtins.filter (pkg: !(pkg ? name || pkg ? pname)) packages;
      in
      if builtins.length invalidPackages > 0 then
        errorSystem.throwValidationError "Invalid packages found: ${builtins.toString invalidPackages}"
      else
        packages;

    # Check if package exists in nixpkgs
    packageExists = packageName: nixpkgs: builtins.hasAttr packageName nixpkgs;

    # Get package safely with fallback
    getPackageSafe =
      packageName: nixpkgs: fallback:
      if packageUtils.packageExists packageName nixpkgs then nixpkgs.${packageName} else fallback;

    # Filter packages by availability
    filterAvailablePackages =
      packageNames: nixpkgs: builtins.filter (name: packageUtils.packageExists name nixpkgs) packageNames;
  };

  # Configuration merging utilities
  configUtils = {
    # Deep merge two attribute sets (configs)
    mergeConfigs =
      config1: config2:
      let
        mergeAttr =
          name: value:
          if builtins.hasAttr name config1 then
            let
              existing = config1.${name};
            in
            if builtins.isAttrs existing && builtins.isAttrs value then
              configUtils.mergeConfigs existing value # Recursive merge
            else
              value # Override with new value
          else
            value; # Add new attribute
      in
      config1 // (builtins.mapAttrs mergeAttr config2);

    # Merge multiple configs in sequence
    mergeMultipleConfigs = configs: builtins.foldl' configUtils.mergeConfigs { } configs;

    # Override specific keys in config
    overrideKeys = config: overrides: config // overrides;

    # Extract subset of config by keys
    extractKeys =
      config: keys:
      actualLib.genAttrs keys (
        key:
        if builtins.hasAttr key config then
          config.${key}
        else
          errorSystem.throwConfigError "Key '${key}' not found in config"
      );

    # Validate required keys exist in config
    validateRequiredKeys =
      config: requiredKeys:
      let
        missingKeys = builtins.filter (key: !builtins.hasAttr key config) requiredKeys;
      in
      if builtins.length missingKeys > 0 then
        errorSystem.throwValidationError "Missing required config keys: ${builtins.concatStringsSep ", " missingKeys}"
      else
        config;
  };

  # List manipulation utilities
  listUtils = {
    # Remove duplicate elements from a list
    unique =
      list:
      let
        addUnique = acc: item: if builtins.elem item acc then acc else acc ++ [ item ];
      in
      builtins.foldl' addUnique [ ] list;

    # Flatten nested lists into a single list
    flatten =
      nestedList:
      let
        flattenItem =
          item: if builtins.isList item then builtins.concatLists (map flattenItem item) else [ item ];
      in
      builtins.concatLists (map flattenItem nestedList);

    # Partition list based on predicate
    partition =
      predicate: list:
      let
        addToPartition =
          acc: item:
          if predicate item then
            {
              true = acc.true ++ [ item ];
              inherit (acc) false;
            }
          else
            {
              inherit (acc) true;
              false = acc.false ++ [ item ];
            };
      in
      builtins.foldl' addToPartition {
        true = [ ];
        false = [ ];
      } list;

    # Group list elements by key function
    groupBy =
      keyFn: list:
      let
        addToGroup =
          acc: item:
          let
            key = keyFn item;
          in
          acc // { ${key} = (acc.${key} or [ ]) ++ [ item ]; };
      in
      builtins.foldl' addToGroup { } list;

    # Take first n elements from list
    take =
      n: list:
      if n <= 0 then
        [ ]
      else if n >= builtins.length list then
        list
      else
        builtins.genList (i: builtins.elemAt list i) n;

    # Drop first n elements from list
    drop =
      n: list:
      if n <= 0 then
        list
      else if n >= builtins.length list then
        [ ]
      else
        listUtils.take (builtins.length list - n) (
          builtins.genList (i: builtins.elemAt list (i + n)) (builtins.length list - n)
        );
  };

  # String utilities
  stringUtils = {
    # Join list of strings with separator
    joinStrings = separator: stringList: builtins.concatStringsSep separator stringList;

    # Check if string starts with prefix
    hasPrefix =
      prefix: string:
      let
        prefixLen = builtins.stringLength prefix;
        stringLen = builtins.stringLength string;
      in
      if prefixLen > stringLen then false else builtins.substring 0 prefixLen string == prefix;

    # Check if string ends with suffix
    hasSuffix =
      suffix: string:
      let
        suffixLen = builtins.stringLength suffix;
        stringLen = builtins.stringLength string;
      in
      if suffixLen > stringLen then
        false
      else
        builtins.substring (stringLen - suffixLen) suffixLen string == suffix;

    # Remove prefix from string if present
    removePrefix =
      prefix: string:
      if stringUtils.hasPrefix prefix string then
        builtins.substring (builtins.stringLength prefix) (builtins.stringLength string) string
      else
        string;

    # Remove suffix from string if present
    removeSuffix =
      suffix: string:
      if stringUtils.hasSuffix suffix string then
        builtins.substring 0 (builtins.stringLength string - builtins.stringLength suffix) string
      else
        string;

    # Split string by delimiter
    splitString = delimiter: string: actualLib.splitString delimiter string;

  };

  # Path utilities
  pathUtils = {
    # Join path components
    joinPath =
      components: stringUtils.joinStrings "/" (builtins.filter (x: x != "" && x != null) components);

    # Get directory name from path
    dirname =
      path:
      let
        parts = stringUtils.splitString "/" path;
        dirParts = builtins.genList (i: builtins.elemAt parts i) (builtins.length parts - 1);
      in
      if builtins.length dirParts == 0 then "." else stringUtils.joinStrings "/" dirParts;

    # Get base name from path
    basename =
      path:
      let
        parts = stringUtils.splitString "/" path;
      in
      if builtins.length parts == 0 then path else builtins.elemAt parts (builtins.length parts - 1);

    # Check if path is absolute
    isAbsolute = path: stringUtils.hasPrefix "/" path;

  };

  # Attribute set utilities
  attrUtils = {
    # Deep merge multiple attribute sets
    deepMerge = attrs: builtins.foldl' configUtils.mergeConfigs { } attrs;

    # Check if attribute path exists
    hasAttrPath =
      path: attrs:
      let
        parts = if builtins.isList path then path else stringUtils.splitString "." path;
        checkPath =
          pathParts: currentAttrs:
          if builtins.length pathParts == 0 then
            true
          else if !builtins.isAttrs currentAttrs then
            false
          else if !builtins.hasAttr (builtins.head pathParts) currentAttrs then
            false
          else
            checkPath (builtins.tail pathParts) currentAttrs.${builtins.head pathParts};
      in
      checkPath parts attrs;

    # Get value at attribute path with optional default
    getAttrPath =
      path: attrs: default:
      let
        parts = if builtins.isList path then path else stringUtils.splitString "." path;
        getValue =
          pathParts: currentAttrs:
          if builtins.length pathParts == 0 then
            currentAttrs
          else if !builtins.isAttrs currentAttrs then
            default
          else if !builtins.hasAttr (builtins.head pathParts) currentAttrs then
            default
          else
            getValue (builtins.tail pathParts) currentAttrs.${builtins.head pathParts};
      in
      getValue parts attrs;

    # Set value at attribute path
    setAttrPath =
      path: value: attrs:
      let
        parts = if builtins.isList path then path else stringUtils.splitString "." path;
        setValue =
          pathParts: currentAttrs:
          if builtins.length pathParts == 1 then
            currentAttrs // { ${builtins.head pathParts} = value; }
          else
            let
              key = builtins.head pathParts;
              rest = listUtils.drop 1 pathParts;
              existing = if builtins.hasAttr key currentAttrs then currentAttrs.${key} else { };
            in
            currentAttrs // { ${key} = setValue rest existing; };
      in
      setValue parts attrs;
  };

in
{
  # Export all utility categories
  inherit
    systemUtils
    packageUtils
    configUtils
    listUtils
    stringUtils
    pathUtils
    attrUtils
    ;

  # Direct exports for convenience
  inherit (systemUtils)
    isSystem
    isDarwin
    isLinux
    isX86_64
    isAarch64
    ;
  inherit (packageUtils)
    filterValidPackages
    mergePackageLists
    getPackageNames
    validatePackages
    ;
  inherit (configUtils) mergeConfigs;
  inherit (listUtils) unique flatten;
  inherit (stringUtils) joinStrings hasPrefix;

  # Convenience exports
  system = systemUtils;
  packages = packageUtils;
  config = configUtils;
  lists = listUtils;
  strings = stringUtils;
  paths = pathUtils;
  attrs = attrUtils;

  # Error handling integration
  errors = errorSystem;

  # Version and metadata
  version = "2.0.0-unified";
  description = "Unified utilities system with comprehensive helper functions";
  categories = [
    "system"
    "packages"
    "config"
    "lists"
    "strings"
    "paths"
    "attrs"
  ];
}
