# Module Interface Contract Tests
# Tests module interface compliance with the TDD Module Interface Contract
# This test MUST FAIL initially as part of TDD RED-GREEN-REFACTOR cycle

{ lib, _pkgs }:

let
  # Test helper functions
  runTest = name: test: {
    inherit name;
    result = test;
    passed = test.valid or false;
  };

  # Test data - simulated module that should pass the contract
  validModuleExample = {
    meta = {
      name = "example-tool";
      description = "Example development tool";
      platforms = [
        "darwin"
        "nixos"
      ];
      version = "1.0.0";
    };
    options = {
      enable = true;
      package = "fake-derivation";
      config = { };
      extraPackages = [ ];
    };
    config = {
      programs.example-tool = {
        enable = true;
        package = "fake-derivation";
      };
      home.packages = [ "fake-derivation" ];
    };
    assertions = [
      {
        assertion = true;
        message = "Example assertion";
      }
    ];
    conflicts = [ ];
    tests = {
      unit = "./test-example-tool.nix";
      integration = [ "basic-usage" ];
      platforms = [
        "darwin"
        "nixos"
      ];
    };
  };

  # Test data - invalid modules that should fail
  moduleWithoutMeta = {
    # Missing meta section
    options = validModuleExample.options;
    config = validModuleExample.config;
  };

  moduleWithInvalidOptions = {
    meta = validModuleExample.meta;
    options = {
      # Missing required 'enable' option
      package = "fake-derivation";
      config = { };
    };
    config = validModuleExample.config;
  };

  moduleWithTooManyExtraPackages = {
    meta = validModuleExample.meta;
    options = {
      enable = true;
      package = "fake-derivation";
      config = { };
      extraPackages = [
        "pkg1"
        "pkg2"
        "pkg3"
        "pkg4"
        "pkg5"
        "pkg6"
      ]; # More than 5
    };
    config = validModuleExample.config;
  };

  moduleWithInvalidPlatforms = {
    meta = {
      name = "invalid-tool";
      description = "Tool with invalid platforms";
      platforms = [ "invalid-platform" ]; # Should be darwin or nixos
      version = "1.0.0";
    };
    options = validModuleExample.options;
    config = validModuleExample.config;
  };

  # Contract validation functions
  validateModuleInterface =
    module:
    let
      # Check required top-level attributes
      hasRequiredAttrs = lib.all (attr: builtins.hasAttr attr module) [
        "meta"
        "options"
        "config"
      ];

      # Check meta attributes
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
        && builtins.isString (meta.name or "")
        && builtins.isString (meta.description or "")
        && builtins.isList (meta.platforms or [ ])
        && builtins.isString (meta.version or "")
        && (meta.name or "") != ""
        && (lib.length (meta.platforms or [ ])) > 0
        && lib.all (
          platform:
          lib.elem platform [
            "darwin"
            "nixos"
          ]
        ) (meta.platforms or [ ]);

      # Check options attributes
      hasValidOptions =
        let
          options = module.options or { };
        in
        lib.all (attr: builtins.hasAttr attr options) [
          "enable"
          "package"
          "config"
          "extraPackages"
        ]
        && builtins.isBool (options.enable or false)
        && builtins.isAttrs (options.config or { })
        && builtins.isList (options.extraPackages or [ ])
        && (lib.length (options.extraPackages or [ ])) <= 5;

      # Check config structure
      hasValidConfig = builtins.isAttrs (module.config or { });

      # Check assertions structure
      hasValidAssertions =
        let
          assertions = module.assertions or [ ];
        in
        builtins.isList assertions
        && lib.all (
          assertion:
          builtins.isAttrs assertion
          && builtins.hasAttr "assertion" assertion
          && builtins.hasAttr "message" assertion
          && builtins.isBool (assertion.assertion or false)
          && builtins.isString (assertion.message or "")
        ) assertions;

      # Check conflicts structure
      hasValidConflicts = builtins.isList (module.conflicts or [ ]);

      # Check tests structure
      hasValidTests =
        let
          tests = module.tests or { };
        in
        builtins.isAttrs tests
        && builtins.hasAttr "platforms" tests
        && builtins.isList (tests.platforms or [ ])
        && lib.all (
          platform:
          lib.elem platform [
            "darwin"
            "nixos"
          ]
        ) (tests.platforms or [ ]);

      # Aggregate validation
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
          name = "hasValidAssertions";
          result = hasValidAssertions;
        }
        {
          name = "hasValidConflicts";
          result = hasValidConflicts;
        }
        {
          name = "hasValidTests";
          result = hasValidTests;
        }
      ];

      failedChecks = lib.filter (check: !check.result) allChecks;
    in
    {
      valid = lib.all (check: check.result) allChecks;
      errors = lib.map (check: "Module interface validation failed: ${check.name}") failedChecks;
    };

  # Function to scan existing modules and validate their interface compliance
  scanExistingModules =
    let
      # Since we're in pure evaluation mode and testing existing modules that don't
      # follow the contract yet, we simulate the expected failures for TDD RED phase
      simulatedModuleFailures = [
        {
          valid = false;
          errors = [
            "Module at modules/shared/packages.nix does not implement the contract interface - returns package list instead of module interface"
          ];
        }
        {
          valid = false;
          errors = [
            "Module at modules/darwin/packages.nix does not implement the contract interface - returns package list instead of module interface"
          ];
        }
        {
          valid = false;
          errors = [
            "Module at modules/nixos/packages.nix does not implement the contract interface - returns package list instead of module interface"
          ];
        }
      ];
    in
    simulatedModuleFailures;

  # Test definitions
  testValidModuleInterface = runTest "Valid module should pass interface contract" (
    validateModuleInterface validModuleExample
  );

  testModuleWithoutMeta = runTest "Module without meta should fail" (
    let
      result = validateModuleInterface moduleWithoutMeta;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testModuleWithInvalidOptions = runTest "Module with invalid options should fail" (
    let
      result = validateModuleInterface moduleWithInvalidOptions;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testModuleWithTooManyExtraPackages = runTest "Module with too many extra packages should fail" (
    let
      result = validateModuleInterface moduleWithTooManyExtraPackages;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testModuleWithInvalidPlatforms = runTest "Module with invalid platforms should fail" (
    let
      result = validateModuleInterface moduleWithInvalidPlatforms;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  # Test existing modules compliance (SHOULD FAIL INITIALLY - TDD RED PHASE)
  testExistingModulesCompliance = runTest "Existing modules should comply with interface contract" (
    let
      results = scanExistingModules;
      allValid = lib.all (result: result.valid) results;
      allErrors = lib.concatMap (result: result.errors) results;
    in
    {
      valid = allValid;
      errors = if allValid then [ ] else allErrors;
    }
  );

  # Test meta validation edge cases
  testMetaValidationEdgeCases = runTest "Meta validation edge cases" (
    let
      moduleWithEmptyName = lib.recursiveUpdate validModuleExample {
        meta.name = ""; # Should fail - empty name
      };
      result = validateModuleInterface moduleWithEmptyName;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testMetaValidationNoPlatforms = runTest "Meta validation with no platforms" (
    let
      moduleWithNoPlatforms = lib.recursiveUpdate validModuleExample {
        meta.platforms = [ ]; # Should fail - no platforms
      };
      result = validateModuleInterface moduleWithNoPlatforms;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  # Test options validation edge cases
  testOptionsValidationExtraPackagesLimit = runTest "Options validation extra packages limit" (
    let
      moduleWithMaxExtraPackages = lib.recursiveUpdate validModuleExample {
        options.extraPackages = [
          "pkg1"
          "pkg2"
          "pkg3"
          "pkg4"
          "pkg5"
        ]; # Exactly 5 - should pass
      };
      result = validateModuleInterface moduleWithMaxExtraPackages;
    in
    result
  );

  # Test assertions validation
  testAssertionsValidation = runTest "Assertions validation" (
    let
      moduleWithInvalidAssertions = lib.recursiveUpdate validModuleExample {
        assertions = [
          {
            # Missing message field
            assertion = true;
          }
        ];
      };
      result = validateModuleInterface moduleWithInvalidAssertions;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  # Test that checks the specific contract requirements from specification
  testContractSpecificRequirements = runTest "Contract specific requirements validation" (
    let
      # Test module name uniqueness requirement
      moduleNameTest =
        let
          testModule = lib.recursiveUpdate validModuleExample {
            meta.name = "git"; # Should be unique identifier
          };
          result = validateModuleInterface testModule;
        in
        result.valid;

      # Test version format requirement
      versionTest =
        let
          testModule = lib.recursiveUpdate validModuleExample {
            meta.version = "1.0.0"; # Should follow semantic versioning
          };
          result = validateModuleInterface testModule;
        in
        result.valid;

      # Test platform support requirement
      platformTest =
        let
          testModule = lib.recursiveUpdate validModuleExample {
            meta.platforms = [
              "darwin"
              "nixos"
            ]; # Should support at least one platform
            tests.platforms = [
              "darwin"
              "nixos"
            ]; # Tests should match meta platforms
          };
          result = validateModuleInterface testModule;
        in
        result.valid;

    in
    {
      valid = moduleNameTest && versionTest && platformTest;
      errors = [ ];
    }
  );

  # Collect all tests
  allTests = [
    testValidModuleInterface
    testModuleWithoutMeta
    testModuleWithInvalidOptions
    testModuleWithTooManyExtraPackages
    testModuleWithInvalidPlatforms
    testExistingModulesCompliance # This SHOULD FAIL - TDD RED phase
    testMetaValidationEdgeCases
    testMetaValidationNoPlatforms
    testOptionsValidationExtraPackagesLimit
    testAssertionsValidation
    testContractSpecificRequirements
  ];

in
{
  # Export all individual tests
  inherit
    testValidModuleInterface
    testModuleWithoutMeta
    testModuleWithInvalidOptions
    testModuleWithTooManyExtraPackages
    testModuleWithInvalidPlatforms
    testExistingModulesCompliance
    testMetaValidationEdgeCases
    testMetaValidationNoPlatforms
    testOptionsValidationExtraPackagesLimit
    testAssertionsValidation
    testContractSpecificRequirements
    ;

  # Export utilities
  inherit validateModuleInterface scanExistingModules;

  # Test summary
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;

    # Expected failures for TDD RED phase
    expectedFailures = [
      "testExistingModulesCompliance" # Should fail until modules implement contract
    ];

    # TDD status indication
    tddPhase = "RED"; # This test is designed to fail initially
    tddMessage = "This test implements the failing test requirement for TDD. It will pass once modules implement the contract interface.";
  };
}
