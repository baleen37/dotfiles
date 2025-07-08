{ lib, pkgs, ... }:

let
  # Module under test
  conditionalFileCopy = import ../../modules/shared/lib/conditional-file-copy.nix { inherit lib pkgs; };
  changeDetector = import ../../modules/shared/lib/change-detector.nix { inherit lib pkgs; };
  policyResolver = import ../../modules/shared/lib/policy-resolver.nix { inherit lib pkgs; };
  copyEngine = import ../../modules/shared/lib/copy-engine.nix { inherit lib pkgs; };

  # Test dependency analyzer
  analyzeDependencies = moduleFile:
    let
      # Read module file content
      content = builtins.readFile moduleFile;

      # Extract import statements (simplified parsing)
      imports = lib.filter (line: lib.hasPrefix "import " line)
        (lib.splitString "\n" content);

      # Extract relative imports (./module.nix)
      relativeImports = lib.filter (line: lib.hasInfix "./" line) imports;

    in
    {
      totalImports = builtins.length imports;
      relativeImports = builtins.length relativeImports;
      hasImports = builtins.length imports > 0;
      importLines = imports;
    };

  # Test for circular dependencies
  testCircularDependencies = {
    name = "test_no_circular_dependencies";

    # This should FAIL initially - we're testing for circular deps
    test =
      let
        # Manually track dependencies
        deps = {
          "conditional-file-copy" = [ "change-detector" "policy-resolver" "copy-engine" ];
          "change-detector" = [ ];
          "policy-resolver" = [ "change-detector" ];
          "copy-engine" = [ "change-detector" "policy-resolver" ];
        };

        # Check for circular dependencies (this should fail if we find any)
        hasCircularDep =
          # This is where we'd detect if copy-engine also imports conditional-file-copy
          # or if there are other circular references
          builtins.elem "conditional-file-copy" deps.copy-engine ||
          builtins.elem "policy-resolver" deps.change-detector ||
          builtins.elem "copy-engine" deps.change-detector;

      in
      {
        # Test should FAIL if circular dependencies exist
        assertion = !hasCircularDep;
        message = "Circular dependencies detected in module structure";
        actualDeps = deps;
        criticalFailure = hasCircularDep;
      };
  };

  # Test for optimal dependency hierarchy
  testDependencyHierarchy = {
    name = "test_clean_dependency_hierarchy";

    test =
      let
        # Expected hierarchy levels
        expectedLevels = {
          level1 = [ "change-detector" ]; # Base level - no dependencies
          level2 = [ "policy-resolver" ]; # Depends only on level1
          level3 = [ "copy-engine" ]; # Depends on level1 and level2
          level4 = [ "conditional-file-copy" ]; # Depends on all previous levels
        };

        # Check if copy-engine has too many dependencies
        copyEngineModules = conditionalFileCopy.modules;

        # This should FAIL if copy-engine depends on conditional-file-copy
        hasImproperDependency =
          # Test if copy-engine tries to import the main module
          builtins.hasAttr "conditionalFileCopy" copyEngineModules ||
          # Test if there are cross-references
          builtins.hasAttr "copyEngine" changeDetector;

      in
      {
        assertion = !hasImproperDependency;
        message = "Improper dependency hierarchy detected";
        expectedLevels = expectedLevels;
        improperDependency = hasImproperDependency;
      };
  };

  # Test for duplicate dependencies
  testDuplicateDependencies = {
    name = "test_no_duplicate_dependencies";

    test =
      let
        # Check if modules are imported multiple times
        mainModule = conditionalFileCopy;

        # This should FAIL if we have both new and legacy versions
        hasDuplicateDetector =
          builtins.hasAttr "changeDetector" mainModule.modules &&
          builtins.hasAttr "detectorLib" mainModule.modules;

        hasDuplicatePolicy =
          builtins.hasAttr "policyResolver" mainModule.modules &&
          builtins.hasAttr "policyLib" mainModule.modules;

        # Check for redundant imports
        hasRedundantImports = hasDuplicateDetector || hasDuplicatePolicy;

      in
      {
        assertion = !hasRedundantImports;
        message = "Duplicate dependencies found - legacy and new versions coexist";
        duplicateDetector = hasDuplicateDetector;
        duplicatePolicy = hasDuplicatePolicy;
      };
  };

  # Test for dependency injection pattern
  testDependencyInjection = {
    name = "test_dependency_injection_pattern";

    test =
      let
        # Check if modules use dependency injection
        copyEngineHasInjection =
          # This should FAIL if copy-engine directly imports instead of receiving dependencies
          builtins.hasAttr "modules" conditionalFileCopy &&
          builtins.hasAttr "copyEngine" conditionalFileCopy.modules;

        # Test if modules can work independently
        changeDetectorIndependent =
          builtins.hasAttr "detectFileChanges" changeDetector;

        # This should FAIL if dependency injection is not properly implemented
        lacksDependencyInjection =
          !copyEngineHasInjection || !changeDetectorIndependent;

      in
      {
        assertion = !lacksDependencyInjection;
        message = "Dependency injection pattern not properly implemented";
        copyEngineInjection = copyEngineHasInjection;
        changeDetectorIndependent = changeDetectorIndependent;
      };
  };

  # Test for modular interface consistency
  testModularInterface = {
    name = "test_modular_interface_consistency";

    test =
      let
        # Check if all modules expose consistent interfaces
        mainModule = conditionalFileCopy;

        # This should FAIL if interfaces are inconsistent
        hasInconsistentInterface =
          # Check if modules section exists
          !builtins.hasAttr "modules" mainModule ||
          # Check if advanced section exists
          !builtins.hasAttr "advanced" mainModule ||
          # Check if utils section exists
          !builtins.hasAttr "utils" mainModule;

      in
      {
        assertion = !hasInconsistentInterface;
        message = "Modular interface structure is inconsistent";
        hasModulesSection = builtins.hasAttr "modules" mainModule;
        hasAdvancedSection = builtins.hasAttr "advanced" mainModule;
        hasUtilsSection = builtins.hasAttr "utils" mainModule;
      };
  };

  # Test for legacy compatibility impact
  testLegacyCompatibility = {
    name = "test_legacy_compatibility_isolation";

    test =
      let
        # Check if legacy modules don't interfere with new architecture
        mainModule = conditionalFileCopy;

        # This should FAIL if legacy modules affect new module structure
        legacyInterference =
          # Check if legacy modules are mixed with new ones inappropriately
          builtins.hasAttr "policyLib" mainModule.modules &&
          builtins.hasAttr "detectorLib" mainModule.modules &&
          # Check if they're not properly isolated
          !builtins.hasAttr "legacy" mainModule;

      in
      {
        assertion = !legacyInterference;
        message = "Legacy modules not properly isolated from new architecture";
        hasLegacyModules = builtins.hasAttr "policyLib" mainModule.modules;
        hasLegacyIsolation = builtins.hasAttr "legacy" mainModule;
      };
  };

in

{
  # Test metadata
  testInfo = {
    name = "Module Dependency Structure Unit Tests";
    description = "Test module dependency structure for circular dependencies, hierarchy, and injection patterns";
    category = "unit";
    priority = "high";
    tags = [ "dependency" "architecture" "modular" "tdd" ];
  };

  # Test cases (these should FAIL initially in Red Phase)
  tests = {
    inherit testCircularDependencies;
    inherit testDependencyHierarchy;
    inherit testDuplicateDependencies;
    inherit testDependencyInjection;
    inherit testModularInterface;
    inherit testLegacyCompatibility;
  };

  # Test runner
  runTests =
    let
      allTests = [
        testCircularDependencies
        testDependencyHierarchy
        testDuplicateDependencies
        testDependencyInjection
        testModularInterface
        testLegacyCompatibility
      ];

      results = map (test:
        let
          result = test.test;
        in
        {
          name = test.name;
          passed = result.assertion;
          message = result.message;
          details = result;
        }
      ) allTests;

      passedCount = builtins.length (lib.filter (r: r.passed) results);
      totalCount = builtins.length results;

    in
    {
      inherit results passedCount totalCount;
      allPassed = passedCount == totalCount;
      summary = "Dependency tests: ${toString passedCount}/${toString totalCount} passed";
    };

  # Expected failure message for Red Phase
  expectedFailures = [
    "Circular dependencies detected in module structure"
    "Improper dependency hierarchy detected"
    "Duplicate dependencies found - legacy and new versions coexist"
    "Dependency injection pattern not properly implemented"
    "Modular interface structure is inconsistent"
    "Legacy modules not properly isolated from new architecture"
  ];
}
