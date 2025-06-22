{ pkgs }:

let
  inherit (pkgs.lib)
    attrNames
    filterAttrs
    mapAttrs
    foldl'
    any
    elem
    removeAttrs
    intersectLists
    subtractLists
    hasAttr
    getAttr
    isAttrs
    isList
    isString
    concatStringsSep
    optionalString;

  # Helper function to normalize package names by removing version suffixes
  normalizePackageName = name:
    let
      parts = pkgs.lib.splitString "-" name;
      # Keep everything except the last part if it looks like a version
      withoutVersion = if (builtins.length parts > 1) &&
                         (builtins.match "^[0-9].*" (builtins.elemAt parts ((builtins.length parts) - 1)) != null)
                      then builtins.concatStringsSep "-" (pkgs.lib.take ((builtins.length parts) - 1) parts)
                      else name;
    in withoutVersion;

  # Extract package names from a package list
  extractPackageNames = packages:
    if isList packages then
      map (pkg:
        if isString pkg then normalizePackageName pkg
        else if isAttrs pkg && hasAttr "name" pkg then normalizePackageName pkg.name
        else "unknown-package"
      ) packages
    else [];

  # Compare two lists of packages and return differences
  comparePackageLists = oldPackages: newPackages:
    let
      oldNames = extractPackageNames oldPackages;
      newNames = extractPackageNames newPackages;
      added = subtractLists oldNames newNames;
      removed = subtractLists newNames oldNames;
      common = intersectLists oldNames newNames;
    in {
      added = added;
      removed = removed;
      unchanged = common;
      total_changes = (builtins.length added) + (builtins.length removed);
    };

  # Compare system settings between configurations
  compareSystemSettings = oldSettings: newSettings:
    let
      allKeys = attrNames (oldSettings // newSettings);

      # Helper to compare individual values
      compareValue = key:
        let
          oldVal = getAttr key oldSettings null;
          newVal = getAttr key newSettings null;
        in
          if oldVal == newVal then { status = "unchanged"; old = oldVal; new = newVal; }
          else if oldVal == null then { status = "added"; old = null; new = newVal; }
          else if newVal == null then { status = "removed"; old = oldVal; new = null; }
          else { status = "changed"; old = oldVal; new = newVal; };

      # Compare all settings
      comparisons = mapAttrs (key: _: compareValue key) (builtins.listToAttrs (map (k: { name = k; value = null; }) allKeys));

      # Count changes
      countByStatus = status: builtins.length (builtins.filter (comp: comp.status == status) (attrNames comparisons));

    in {
      comparisons = comparisons;
      summary = {
        total_settings = builtins.length allKeys;
        unchanged = countByStatus "unchanged";
        added = countByStatus "added";
        removed = countByStatus "removed";
        changed = countByStatus "changed";
      };
    };

  # Compare home-manager configurations
  compareHomeManagerConfigs = oldHM: newHM:
    let
      # Extract user configurations
      oldUsers = if hasAttr "users" oldHM then oldHM.users else {};
      newUsers = if hasAttr "users" newHM then newHM.users else {};

      # Get all user names
      allUsers = attrNames (oldUsers // newUsers);

      # Compare each user
      compareUser = username:
        let
          oldUser = getAttr username oldUsers {};
          newUser = getAttr username newUsers {};
        in {
          shell_changed = (getAttr "shell" oldUser null) != (getAttr "shell" newUser null);
          dotfiles_changed = (getAttr "dotfiles" oldUser []) != (getAttr "dotfiles" newUser []);
          settings_changed = (removeAttrs oldUser ["shell" "dotfiles"]) != (removeAttrs newUser ["shell" "dotfiles"]);
        };

      userComparisons = mapAttrs (user: _: compareUser user) (builtins.listToAttrs (map (u: { name = u; value = null; }) allUsers));

    in {
      version_changed = (getAttr "version" oldHM null) != (getAttr "version" newHM null);
      users = userComparisons;
      user_count = builtins.length allUsers;
    };

  # Apply ignore patterns to filter out expected differences
  applyIgnorePatterns = ignorePatterns: config:
    let
      shouldIgnore = key: any (pattern:
        if pattern == "timestamps" then
          elem key ["timestamp" "build_time" "generation_time"]
        else if pattern == "version-info" then
          elem key ["version" "build_version" "nix_version"]
        else if pattern == "build-paths" then
          elem key ["build_path" "store_path" "derivation"]
        else
          key == pattern
      ) ignorePatterns;

      filterConfig = cfg:
        if isAttrs cfg then
          mapAttrs (key: value:
            if shouldIgnore key then null
            else if isAttrs value then filterConfig value
            else value
          ) (filterAttrs (key: value: !(shouldIgnore key)) cfg)
        else cfg;
    in
      filterConfig config;

  # Perform full configuration equivalence check
  checkConfigEquivalence = oldConfig: newConfig:
    let
      # Extract different aspects of the configuration
      oldPackages = getAttr "packages" oldConfig [];
      newPackages = getAttr "packages" newConfig [];

      oldSystem = getAttr "system_settings" oldConfig {};
      newSystem = getAttr "system_settings" newConfig {};

      oldHM = getAttr "home_manager" oldConfig {};
      newHM = getAttr "home_manager" newConfig {};

      # Perform comparisons
      packageDiff = comparePackageLists oldPackages newPackages;
      systemDiff = compareSystemSettings oldSystem newSystem;
      hmDiff = compareHomeManagerConfigs oldHM newHM;

      # Determine overall equivalence
      isEquivalent =
        packageDiff.total_changes == 0 &&
        systemDiff.summary.added == 0 && systemDiff.summary.removed == 0 && systemDiff.summary.changed == 0 &&
        !hmDiff.version_changed &&
        !(any (user: user.shell_changed || user.dotfiles_changed || user.settings_changed) (attrNames hmDiff.users));

    in {
      equivalent = isEquivalent;
      packages = packageDiff;
      system_settings = systemDiff;
      home_manager = hmDiff;
    };

  # Generate a comprehensive difference report
  generateDifferenceReport = oldConfig: newConfig:
    let
      equivalenceCheck = checkConfigEquivalence oldConfig newConfig;

      formatPackageChanges = packageDiff:
        optionalString (packageDiff.total_changes > 0) ''
          Package Changes:
          ${optionalString (builtins.length packageDiff.added > 0) "  Added: ${concatStringsSep ", " packageDiff.added}"}
          ${optionalString (builtins.length packageDiff.removed > 0) "  Removed: ${concatStringsSep ", " packageDiff.removed}"}
          Total Changes: ${toString packageDiff.total_changes}
        '';

      formatSystemChanges = systemDiff:
        optionalString (systemDiff.summary.added + systemDiff.summary.removed + systemDiff.summary.changed > 0) ''
          System Settings Changes:
          ${optionalString (systemDiff.summary.added > 0) "  Added: ${toString systemDiff.summary.added} settings"}
          ${optionalString (systemDiff.summary.removed > 0) "  Removed: ${toString systemDiff.summary.removed} settings"}
          ${optionalString (systemDiff.summary.changed > 0) "  Changed: ${toString systemDiff.summary.changed} settings"}
        '';

      formatHMChanges = hmDiff:
        optionalString (hmDiff.version_changed || hmDiff.user_count > 0) ''
          Home Manager Changes:
          ${optionalString hmDiff.version_changed "  Version changed"}
          ${optionalString (hmDiff.user_count > 0) "  Users affected: ${toString hmDiff.user_count}"}
        '';

    in {
      summary = {
        equivalent = equivalenceCheck.equivalent;
        total_changes = equivalenceCheck.packages.total_changes +
                       equivalenceCheck.system_settings.summary.added +
                       equivalenceCheck.system_settings.summary.removed +
                       equivalenceCheck.system_settings.summary.changed;
      };
      details = equivalenceCheck;
      formatted_report = ''
        Configuration Comparison Report
        ==============================

        Overall Status: ${if equivalenceCheck.equivalent then "EQUIVALENT" else "DIFFERENT"}

        ${formatPackageChanges equivalenceCheck.packages}
        ${formatSystemChanges equivalenceCheck.system_settings}
        ${formatHMChanges equivalenceCheck.home_manager}
      '';
    };

  # Compare configurations with platform-specific handling
  comparePlatformConfigs = platform: oldConfig: newConfig:
    let
      # Platform-specific ignore patterns
      platformIgnores =
        if platform == "darwin" then ["system.apple.*" "homebrew.*"]
        else if platform == "nixos" then ["boot.*" "systemd.*"]
        else [];

      # Apply platform-specific filtering
      filterForPlatform = config: applyIgnorePatterns platformIgnores config;

      filteredOld = filterForPlatform oldConfig;
      filteredNew = filterForPlatform newConfig;

    in
      checkConfigEquivalence filteredOld filteredNew;

in
{
  # Export all functions
  inherit comparePackageLists;
  inherit compareSystemSettings;
  inherit compareHomeManagerConfigs;
  inherit checkConfigEquivalence;
  inherit generateDifferenceReport;
  inherit applyIgnorePatterns;
  inherit comparePlatformConfigs;

  # Helper functions
  inherit extractPackageNames;
  inherit normalizePackageName;
}
