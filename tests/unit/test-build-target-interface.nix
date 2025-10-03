# Unit Test for Build Target Interface Contract
# TDD RED Phase: Tests the build target contract validation
# This test MUST FAIL initially until build target implementations are created

{ lib }: # Removed unused pkgs parameter

let
  # Test helper functions
  runTest = name: test: {
    inherit name;
    result = test;
    passed = test.valid or false;
  };

  # Build target validator - currently doesn't exist (RED phase)
  # This should reference a non-existent module to ensure test fails
  buildTargetValidator =
    if builtins.pathExists ../../lib/build-target-validator.nix then
      import ../../lib/build-target-validator.nix { inherit lib; }
    else
      {
        validateBuildTarget = _: {
          valid = false;
          errors = [ "Build target validator not implemented" ];
        };
        validateAllTargets = _: {
          valid = false;
          errors = [ "Build target validator not implemented" ];
        };
      };

  # Valid build target test data (according to contract)
  validBuildTarget = {
    name = "test-unit";
    description = "Execute unit tests for all modules";
    dependencies = [ "format" ];
    operations = [
      {
        command = "nix flake check --all-systems";
        description = "Run comprehensive test suite";
        idempotent = true;
        timeout = 180;
      }
    ];
    sequential = false;
    platforms = [ "all" ];
    timeout = 300;
    success_criteria = [
      {
        condition = "exit_code == 0";
        description = "All tests pass with no failures";
      }
      {
        condition = "execution_time < 180";
        description = "Tests complete within time limit";
      }
    ];
  };

  # Invalid build target test data (violates contract)
  invalidBuildTargetMissingRequired = {
    # Missing required 'name' field
    description = "Invalid target missing name";
    # Missing other required fields: dependencies, operations, platforms
  };

  invalidBuildTargetWrongTypes = {
    name = 123; # Should be string
    description = true; # Should be string
    dependencies = "not-a-list"; # Should be array
    operations = "invalid"; # Should be array
    platforms = { }; # Should be array
    timeout = "not-a-number"; # Should be integer
  };

  invalidBuildTargetNamePattern = {
    name = "Test_Unit"; # Should be lowercase with hyphens only
    description = "Invalid name pattern";
    dependencies = [ ];
    operations = [
      {
        command = "echo test";
        description = "Test command";
      }
    ];
    platforms = [ "all" ];
  };

  invalidBuildTargetConstraints = {
    name = "test-invalid";
    description = "Invalid constraints";
    dependencies = [
      "dep1"
      "dep2"
      "dep3"
      "dep4"
      "dep5"
      "dep6"
      "dep7"
      "dep8"
      "dep9"
      "dep10"
      "dep11"
    ]; # More than 10 items
    operations = [
      {
        command = "sleep 1000";
        description = "Command with invalid timeout";
        timeout = 700; # Exceeds maximum of 600
      }
    ];
    platforms = [ ]; # Empty array, should have minItems: 1
    timeout = 400; # Exceeds maximum of 300
  };

  invalidBuildTargetPlatforms = {
    name = "test-platforms";
    description = "Invalid platform values";
    dependencies = [ ];
    operations = [
      {
        command = "echo test";
        description = "Test command";
      }
    ];
    platforms = [
      "windows"
      "android"
    ]; # Invalid platform values
  };

  # Test functions
  testValidBuildTarget = runTest "Valid build target should pass" (
    buildTargetValidator.validateBuildTarget validBuildTarget
  );

  testMissingRequiredFields = runTest "Build target missing required fields should fail" (
    let
      result = buildTargetValidator.validateBuildTarget invalidBuildTargetMissingRequired;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testWrongTypes = runTest "Build target with wrong types should fail" (
    let
      result = buildTargetValidator.validateBuildTarget invalidBuildTargetWrongTypes;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testNamePattern = runTest "Build target with invalid name pattern should fail" (
    let
      result = buildTargetValidator.validateBuildTarget invalidBuildTargetNamePattern;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testConstraintValidation = runTest "Build target violating constraints should fail" (
    let
      result = buildTargetValidator.validateBuildTarget invalidBuildTargetConstraints;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testPlatformValidation = runTest "Build target with invalid platforms should fail" (
    let
      result = buildTargetValidator.validateBuildTarget invalidBuildTargetPlatforms;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testRequiredAttributesExist = runTest "Build target must have all required attributes" (
    let
      requiredAttrs = [
        "name"
        "description"
        "operations"
        "platforms"
      ];
      hasAllRequired = lib.all (attr: builtins.hasAttr attr validBuildTarget) requiredAttrs;
    in
    {
      valid = hasAllRequired;
      errors = if hasAllRequired then [ ] else [ "Missing required attributes" ];
    }
  );

  testOperationsStructure = runTest "Operations must be array of objects with required fields" (
    let
      operations = validBuildTarget.operations;
      isArray = builtins.isList operations;
      hasRequiredFields = lib.all (
        op: builtins.hasAttr "command" op && builtins.hasAttr "description" op
      ) operations;
    in
    {
      valid = isArray && hasRequiredFields;
      errors = if isArray && hasRequiredFields then [ ] else [ "Invalid operations structure" ];
    }
  );

  testSuccessCriteriaStructure =
    runTest "Success criteria must be array of objects with condition and description"
      (
        let
          criteria = validBuildTarget.success_criteria;
          isArray = builtins.isList criteria;
          hasRequiredFields = lib.all (
            criterion: builtins.hasAttr "condition" criterion && builtins.hasAttr "description" criterion
          ) criteria;
        in
        {
          valid = isArray && hasRequiredFields;
          errors = if isArray && hasRequiredFields then [ ] else [ "Invalid success criteria structure" ];
        }
      );

  testPlatformCompatibility = runTest "Build target platforms must be valid enum values" (
    let
      validPlatforms = [
        "darwin"
        "nixos"
        "all"
      ];
      targetPlatforms = validBuildTarget.platforms;
      allValid = lib.all (platform: lib.elem platform validPlatforms) targetPlatforms;
    in
    {
      valid = allValid;
      errors = if allValid then [ ] else [ "Invalid platform values" ];
    }
  );

  testValidatorExists = runTest "Build target validator should exist" (
    let
      validatorPath = ../../lib/build-target-validator.nix;
      exists = builtins.pathExists validatorPath;
    in
    {
      valid = exists;
      errors = if exists then [ ] else [ "Build target validator not implemented yet" ];
    }
  );

  testValidateAllTargets = runTest "Validate multiple build targets" (
    let
      targets = {
        valid = validBuildTarget;
        invalid = invalidBuildTargetMissingRequired;
      };
      result = buildTargetValidator.validateAllTargets targets;
    in
    {
      valid = !result.valid; # Should fail because one target is invalid
      errors = result.errors;
    }
  );

  # Run all tests
  allTests = [
    testValidBuildTarget
    testMissingRequiredFields
    testWrongTypes
    testNamePattern
    testConstraintValidation
    testPlatformValidation
    testRequiredAttributesExist
    testOperationsStructure
    testSuccessCriteriaStructure
    testPlatformCompatibility
    testValidatorExists
    testValidateAllTargets
  ];

  # Test summary
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;

    # TDD status information
    tdd_phase = "RED";
    expected_failures = [
      "testValidBuildTarget"
      "testMissingRequiredFields"
      "testWrongTypes"
      "testNamePattern"
      "testConstraintValidation"
      "testPlatformValidation"
      "testValidatorExists"
      "testValidateAllTargets"
    ];
    note = "This test MUST fail initially - this is the TDD RED phase. Tests will pass once build target validator is implemented.";
  };

in
{
  # Expose all test results and summary
  inherit
    testValidBuildTarget
    testMissingRequiredFields
    testWrongTypes
    testNamePattern
    testConstraintValidation
    testPlatformValidation
    testRequiredAttributesExist
    testOperationsStructure
    testSuccessCriteriaStructure
    testPlatformCompatibility
    testValidatorExists
    testValidateAllTargets
    allTests
    testSummary
    ;
}
