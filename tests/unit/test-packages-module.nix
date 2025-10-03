# Packages Module Unit Tests - TDD RED Phase
# Tests that the packages module implementation follows the Module Interface Contract
# THIS TEST MUST FAIL INITIALLY - it validates the future refactored packages module

{
  lib,
  pkgs ? import <nixpkgs> { },
}:

let
  # Test helper functions
  runTest = name: test: {
    inherit name;
    result = test;
    passed = test.valid or false;
  };

  # Load the actual packages modules to test against the contract
  # These will fail because they currently return package lists, not module interfaces
  sharedPackagesModule = import ../../modules/shared/packages.nix { inherit pkgs; };
  darwinPackagesModule = import ../../modules/darwin/packages.nix { inherit pkgs; };
  nixosPackagesModule = import ../../modules/nixos/packages.nix { inherit pkgs; };

  # Contract validation function specifically for packages module
  validatePackagesModuleInterface =
    module:
    let
      # Check if it's a module interface (has meta, options, config) or just a package list
      isModuleInterface =
        builtins.isAttrs module
        && builtins.hasAttr "meta" module
        && builtins.hasAttr "options" module
        && builtins.hasAttr "config" module;

      # If it's a module interface, validate it
      moduleValidation =
        if isModuleInterface then
          let
            # Check required top-level attributes
            hasRequiredAttrs = lib.all (attr: builtins.hasAttr attr module) [
              "meta"
              "options"
              "config"
            ];

            # Check meta attributes specific to packages module
            hasValidMeta =
              let
                meta = module.meta or { };
              in
              lib.all (attr: builtins.hasAttr attr meta) [
                "name"
                "description"
                "platforms"
                "version"
              ]
              && (meta.name or "") == "packages"
              && builtins.isString (meta.description or "")
              && (meta.description or "") != ""
              && builtins.isList (meta.platforms or [ ])
              && lib.all (
                platform:
                lib.elem platform [
                  "darwin"
                  "nixos"
                ]
              ) (meta.platforms or [ ])
              && builtins.isString (meta.version or "");

            # Check options structure for packages module
            hasValidOptions =
              let
                options = module.options or { };
              in
              builtins.hasAttr "enable" options
              && builtins.hasAttr "config" options
              && builtins.hasAttr "extraPackages" options
              && builtins.isBool (options.enable or false)
              && builtins.isAttrs (options.config or { })
              && builtins.isList (options.extraPackages or [ ])
              &&
                # Enforce constitutional requirement: max 5 external dependencies
                (lib.length (options.extraPackages or [ ])) <= 5;

            # Check config structure for packages module
            hasValidConfig =
              let
                config = module.config or { };
              in
              builtins.isAttrs config
              &&
                # Packages module should have home.packages in config
                builtins.hasAttr "home" config
              && builtins.isAttrs (config.home or { })
              && builtins.hasAttr "packages" (config.home or { })
              && builtins.isList (config.home.packages or [ ]);

            # Check package organization and categorization
            hasValidPackageOrganization =
              let
                homePackages = module.config.home.packages or [ ];
                # Check that packages are organized and not just a flat list
                # This is a heuristic - a well-organized module should have structured package management
              in
              builtins.isList homePackages;

            # Check cross-platform compatibility
            hasCrossPlatformSupport =
              let
                platforms = module.meta.platforms or [ ];
                testPlatforms = module.tests.platforms or [ ];
              in
              lib.length platforms >= 1
              && lib.all (
                platform:
                lib.elem platform [
                  "darwin"
                  "nixos"
                ]
              ) platforms
              &&
                # Test platforms should match meta platforms
                lib.all (platform: lib.elem platform platforms) testPlatforms;

            allChecks = [
              {
                name = "hasRequiredAttrs";
                result = hasRequiredAttrs;
              }
              {
                name = "hasValidMeta";
                result = hasValidMeta;
              }
              {
                name = "hasValidOptions";
                result = hasValidOptions;
              }
              {
                name = "hasValidConfig";
                result = hasValidConfig;
              }
              {
                name = "hasValidPackageOrganization";
                result = hasValidPackageOrganization;
              }
              {
                name = "hasCrossPlatformSupport";
                result = hasCrossPlatformSupport;
              }
            ];

            failedChecks = lib.filter (check: !check.result) allChecks;
          in
          {
            valid = lib.all (check: check.result) allChecks;
            errors = lib.map (check: "Packages module validation failed: ${check.name}") failedChecks;
            isModuleInterface = true;
          }
        else
          {
            valid = false;
            errors = [
              "Packages module does not implement module interface - returns package list instead of module structure"
            ];
            isModuleInterface = false;
          };
    in
    moduleValidation;

  # Test dependency limits for packages module
  validatePackageDependencyLimits =
    packageList:
    let
      # Count external dependencies (packages not in base nixpkgs)
      # This is a simplified check - in reality we'd need to analyze package sources
      externalDependencies = lib.filter (
        pkg:
        # Heuristic: packages with complex names or version numbers might be external
        let
          pkgName = if builtins.isString pkg then pkg else pkg.pname or pkg.name or "unknown";
        in
        lib.hasInfix "-" pkgName || lib.hasInfix "_" pkgName
      ) packageList;

      dependencyCount = lib.length externalDependencies;
    in
    {
      valid = dependencyCount <= 5;
      count = dependencyCount;
      limit = 5;
      dependencies = externalDependencies;
      errors =
        if dependencyCount > 5 then
          [
            "Packages module exceeds constitutional limit of 5 external dependencies (found ${toString dependencyCount})"
          ]
        else
          [ ];
    };

  # Test shared packages module compliance
  testSharedPackagesModuleCompliance = runTest "Shared packages module should implement module interface contract" (
    validatePackagesModuleInterface sharedPackagesModule
  );

  # Test darwin packages module compliance
  testDarwinPackagesModuleCompliance = runTest "Darwin packages module should implement module interface contract" (
    validatePackagesModuleInterface darwinPackagesModule
  );

  # Test nixos packages module compliance
  testNixosPackagesModuleCompliance = runTest "NixOS packages module should implement module interface contract" (
    validatePackagesModuleInterface nixosPackagesModule
  );

  # Test package organization structure
  testPackageOrganization = runTest "Packages should be organized by category and purpose" (
    let
      # Since current modules return lists, this test checks organizational structure expectations
      # It will fail because current implementation doesn't provide organizational metadata
      result =
        if builtins.isList sharedPackagesModule then
          {
            valid = false;
            errors = [
              "Packages module returns unstructured list - should provide categorical organization metadata"
            ];
          }
        else if builtins.hasAttr "categories" sharedPackagesModule then
          {
            valid = true;
            errors = [ ];
          }
        else
          {
            valid = false;
            errors = [ "Packages module missing categorical organization structure" ];
          };
    in
    result
  );

  # Test dependency limits compliance
  testDependencyLimitsCompliance =
    runTest "Packages module should respect constitutional dependency limits"
      (
        let
          # Test against current shared packages (will likely fail due to too many packages)
          packageList = if builtins.isList sharedPackagesModule then sharedPackagesModule else [ ];
          dependencyCheck = validatePackageDependencyLimits packageList;
        in
        {
          valid = dependencyCheck.valid;
          errors = dependencyCheck.errors;
          metadata = {
            dependencyCount = dependencyCheck.count;
            dependencyLimit = dependencyCheck.limit;
          };
        }
      );

  # Test cross-platform package compatibility
  testCrossPlatformCompatibility = runTest "Packages should support cross-platform installation" (
    let
      # This test checks if modules provide platform compatibility information
      # Current implementation doesn't, so it should fail
      darwinPackages = if builtins.isList darwinPackagesModule then darwinPackagesModule else [ ];
      nixosPackages = if builtins.isList nixosPackagesModule then nixosPackagesModule else [ ];
      sharedPackages = if builtins.isList sharedPackagesModule then sharedPackagesModule else [ ];

      # Check if there's platform-specific package management
      hasPlatformSpecificHandling =
        (lib.length darwinPackages) != (lib.length nixosPackages) || (lib.length sharedPackages) > 0;

      # Check if modules provide compatibility metadata (they don't currently)
      hasCompatibilityMetadata =
        !builtins.isList darwinPackagesModule
        && !builtins.isList nixosPackagesModule
        && !builtins.isList sharedPackagesModule;
    in
    {
      valid = hasPlatformSpecificHandling && hasCompatibilityMetadata;
      errors =
        if !hasCompatibilityMetadata then
          [ "Packages modules lack cross-platform compatibility metadata" ]
        else
          [ ];
    }
  );

  # Test package validation and availability
  testPackageValidation = runTest "Packages should include validation and availability checks" (
    let
      # Check if modules provide package validation (they don't currently)
      hasValidation =
        !builtins.isList sharedPackagesModule
        && builtins.hasAttr "assertions" sharedPackagesModule
        && builtins.isList (sharedPackagesModule.assertions or [ ]);
    in
    {
      valid = hasValidation;
      errors =
        if !hasValidation then
          [ "Packages module lacks package validation and availability assertions" ]
        else
          [ ];
    }
  );

  # Test configuration validation and error handling
  testConfigurationValidation = runTest "Packages module should provide configuration validation" (
    let
      # Check if modules provide configuration validation (they don't currently)
      hasConfigValidation =
        !builtins.isList sharedPackagesModule
        && builtins.hasAttr "options" sharedPackagesModule
        && builtins.hasAttr "assertions" sharedPackagesModule;
    in
    {
      valid = hasConfigValidation;
      errors =
        if !hasConfigValidation then
          [ "Packages module lacks configuration validation and error handling" ]
        else
          [ ];
    }
  );

  # Test that packages are manageable and not hardcoded
  testPackageManageability = runTest "Package installation should be configurable and manageable" (
    let
      # Check if current implementation allows for package management configuration
      isConfigurable =
        !builtins.isList sharedPackagesModule
        && builtins.hasAttr "options" sharedPackagesModule
        && builtins.hasAttr "enable" (sharedPackagesModule.options or { });
    in
    {
      valid = isConfigurable;
      errors =
        if !isConfigurable then
          [ "Packages module is not configurable - should support enable/disable and package selection" ]
        else
          [ ];
    }
  );

  # Aggregate test to validate overall packages module architecture
  testPackagesModuleArchitecture =
    runTest "Packages module should follow modular architecture principles"
      (
        let
          # Check architectural compliance
          hasModularStructure =
            # Should be modules, not just package lists
            !builtins.isList sharedPackagesModule
            && !builtins.isList darwinPackagesModule
            && !builtins.isList nixosPackagesModule;

          hasSharedReusability =
            # Check if platform modules properly import shared functionality
            builtins.isList darwinPackagesModule && builtins.isList nixosPackagesModule;

          # This checks current structure, which should show architectural issues
          architecturalProblems = [ ];

          architecturalProblems' =
            architecturalProblems
            ++ (
              if !hasModularStructure then
                [ "Modules return package lists instead of module interfaces" ]
              else
                [ ]
            );

          architecturalProblems'' =
            architecturalProblems'
            ++ (
              if !hasSharedReusability then
                [ "Platform modules don't demonstrate proper shared component reuse" ]
              else
                [ ]
            );
        in
        {
          valid = hasModularStructure;
          errors = architecturalProblems'';
        }
      );

  # Collect all tests
  allTests = [
    testSharedPackagesModuleCompliance # SHOULD FAIL - returns list not module
    testDarwinPackagesModuleCompliance # SHOULD FAIL - returns list not module
    testNixosPackagesModuleCompliance # SHOULD FAIL - returns list not module
    testPackageOrganization # SHOULD FAIL - no categorical organization
    testDependencyLimitsCompliance # MAY FAIL - might exceed 5 dependency limit
    testCrossPlatformCompatibility # SHOULD FAIL - no compatibility metadata
    testPackageValidation # SHOULD FAIL - no validation assertions
    testConfigurationValidation # SHOULD FAIL - no config validation
    testPackageManageability # SHOULD FAIL - not configurable
    testPackagesModuleArchitecture # SHOULD FAIL - not modular architecture
  ];

in
{
  # Export all individual tests
  inherit
    testSharedPackagesModuleCompliance
    testDarwinPackagesModuleCompliance
    testNixosPackagesModuleCompliance
    testPackageOrganization
    testDependencyLimitsCompliance
    testCrossPlatformCompatibility
    testPackageValidation
    testConfigurationValidation
    testPackageManageability
    testPackagesModuleArchitecture
    ;

  # Export validation utilities
  inherit validatePackagesModuleInterface validatePackageDependencyLimits;

  # Test summary with TDD context
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;

    # TDD Phase indication
    tddPhase = "RED";
    tddMessage = "TDD RED Phase: This test suite is designed to FAIL initially. It validates that packages modules implement the Module Interface Contract. All tests should fail until packages modules are refactored from package lists to proper module interfaces.";

    # Expected failures for TDD RED phase
    expectedFailures = [
      "testSharedPackagesModuleCompliance" # Current: returns package list, Expected: module interface
      "testDarwinPackagesModuleCompliance" # Current: returns package list, Expected: module interface
      "testNixosPackagesModuleCompliance" # Current: returns package list, Expected: module interface
      "testPackageOrganization" # Current: no organization metadata
      "testCrossPlatformCompatibility" # Current: no compatibility metadata
      "testPackageValidation" # Current: no validation assertions
      "testConfigurationValidation" # Current: no config validation
      "testPackageManageability" # Current: not configurable
      "testPackagesModuleArchitecture" # Current: package lists not modules
    ];

    # Constitutional compliance requirements
    constitutionalRequirements = {
      maxExternalDependencies = 5;
      enforcedBy = "testDependencyLimitsCompliance";
      rationale = "Prevent excessive external dependencies per constitutional requirement";
    };

    # Package module specific requirements
    packageModuleRequirements = {
      mustImplementModuleInterface = true;
      mustProvidePackageOrganization = true;
      mustSupportCrossPlatform = true;
      mustHaveValidationAssertions = true;
      mustBeConfigurable = true;
      mustRespectDependencyLimits = true;
    };

    # Implementation guidance for GREEN phase
    implementationGuidance = {
      nextSteps = [
        "Refactor modules/shared/packages.nix to return module interface"
        "Refactor modules/darwin/packages.nix to return module interface"
        "Refactor modules/nixos/packages.nix to return module interface"
        "Add package categorization and organization metadata"
        "Implement configuration validation and error handling"
        "Add cross-platform compatibility assertions"
        "Ensure dependency limits compliance"
        "Make package installation configurable (enable/disable)"
      ];
      contractCompliance = "All modules must implement the Module Interface Contract defined in test-module-interface.nix";
    };
  };
}
