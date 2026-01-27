# Package Test Helpers
#
# Provides reusable assertion helpers for testing package installations.
# Reduces duplication of package existence checks across test files.

{
  pkgs,
  lib,
  helpers,
}:

rec {
  # Assert that a package is in the Home Manager packages list
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   packageName: The package name to check for (e.g., "git")
  #   testSuffix: Optional suffix for test name (defaults to package name)
  #
  # Returns: An assertion that passes if the package is in the list
  assertPackageInstalled = config: packageName: testSuffix:
    let
      suffix = if testSuffix == null then packageName else testSuffix;
    in
    helpers.assertTest "package-${suffix}-installed" (
      lib.any (p: p.name == "${packageName}" || p.pname == packageName || lib.hasInfix packageName (lib.getName p)) config.home.packages
    ) "Package ${packageName} should be installed";

  # Assert that multiple packages are installed
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   packageNames: List of package names to check for
  #
  # Returns: A list of assertions for all packages
  assertPackagesInstalled = config: packageNames:
    map (name: assertPackageInstalled config name null) packageNames;

  # Assert that a package is NOT in the Home Manager packages list
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   packageName: The package name to check for
  #
  # Returns: An assertion that passes if the package is NOT in the list
  assertPackageNotInstalled = config: packageName:
    helpers.assertTest "package-${packageName}-not-installed" (
      !lib.any (p: p.name == "${packageName}" || p.pname == packageName || lib.hasInfix packageName (lib.getName p)) config.home.packages
    ) "Package ${packageName} should NOT be installed";

  # Assert that a package exists in pkgs (is available)
  #
  # Parameters:
  #   packageName: The package name to check for
  #
  # Returns: An assertion that passes if the package exists in pkgs
  assertPackageExists = packageName:
    helpers.assertTest "package-${packageName}-exists" (
      pkgs ? ${packageName}
    ) "Package ${packageName} should exist in pkgs";

  # Assert that multiple packages exist in pkgs
  #
  # Parameters:
  #   packageNames: List of package names to check for
  #
  # Returns: A list of assertions for all packages
  assertPackagesExist = packageNames:
    map assertPackageExists packageNames;

  # Assert that a package is enabled in a specific program configuration
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   programName: The program name (e.g., "git", "vim")
  #
  # Returns: An assertion that passes if the program is enabled
  assertProgramEnabled = config: programName:
    helpers.assertTest "program-${programName}-enabled" (
      config.programs.${programName}.enable == true
    ) "Program ${programName} should be enabled";

  # Assert that a program is disabled
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   programName: The program name (e.g., "git", "vim")
  #
  # Returns: An assertion that passes if the program is disabled
  assertProgramDisabled = config: programName:
    helpers.assertTest "program-${programName}-disabled" (
      config.programs.${programName}.enable == false
    ) "Program ${programName} should be disabled";

  # Assert that a Homebrew cask is in the casks list
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   caskName: The cask name to check for
  #
  # Returns: An assertion that passes if the cask is in the list
  assertHomebrewCaskInstalled = config: caskName:
    helpers.assertTest "homebrew-cask-${caskName}-installed" (
      lib.elem caskName config.homebrew.casks
    ) "Homebrew cask ${caskName} should be installed";

  # Assert that a Mac App Store app is in the masApps list
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   appName: The app name to check for
  #
  # Returns: An assertion that passes if the app is in the list
  assertMasAppInstalled = config: appName:
    helpers.assertTest "mas-app-${appName}-installed" (
      config.masApps ? ${appName}
    ) "Mac App Store app ${appName} should be installed";

  # Count the number of installed packages
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #
  # Returns: The count of packages in the packages list
  countPackages = config:
    builtins.length config.home.packages;

  # Assert that the package count meets a minimum threshold
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   minCount: Minimum expected package count
  #
  # Returns: An assertion that passes if package count >= minCount
  assertMinPackageCount = config: minCount:
    helpers.assertTest "package-count-min-${toString minCount}" (
      countPackages config >= minCount
    ) "Should have at least ${toString minCount} packages installed";

  # Assert that the package count does not exceed a maximum threshold
  #
  # Parameters:
  #   config: The Home Manager configuration to test
  #   maxCount: Maximum expected package count
  #
  # Returns: An assertion that passes if package count <= maxCount
  assertMaxPackageCount = config: maxCount:
    helpers.assertTest "package-count-max-${toString maxCount}" (
      countPackages config <= maxCount
    ) "Should have no more than ${toString maxCount} packages installed";
}
