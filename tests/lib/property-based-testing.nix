# Property-Based Testing Framework for Nix Configurations
#
# A comprehensive framework for testing configuration invariants across
# multiple scenarios, inspired by Haskell's QuickCheck and ScalaCheck.
#
# Core Concepts:
#   - Properties: Invariants that must hold true across all inputs
#   - Generators: Functions that produce test data
#   - Scenarios: Predefined test cases for deterministic testing
#
# VERSION: 2.0.0
# LAST UPDATED: 2025-01-31

{
  lib,
  pkgs,
}:

let
  inherit (builtins)
    any
    attrNames
    elemAt
    genList
    head
    isFunction
    length
    map
    tail
    tryEval
    typeOf
    ;

  inherit (lib)
    all
    concatMapStringsSep
    filter
    foldl'
    imap0
    mapAttrsToList
    range
    unique
    zipLists
    ;

  # Import base test helpers
  helpers = import ./test-helpers.nix { inherit pkgs lib; };

in

rec {
  # Re-export core helpers
  inherit (helpers) assertTest testSuite;

  # ============================================================
  # Core Property Types
  # ============================================================

  # Property: Configuration round-trip (parse -> modify -> parse -> equals)
  # Validates that parsing and re-parsing produces consistent results
  roundtripProperty =
    {
      parser,
      modifier,
      validator,
      name ? "roundtrip",
    }:
    config:
    let
      identifier = config.identifier or "unknown";
      original = parser config;
      modified = modifier original;
      reparsed = parser modified;
      isValid = validator original reparsed;
    in
    {
      property = name;
      config = identifier;
      result = isValid;
      details = {
        original = typeOf original;
        modified = typeOf modified;
        reparsed = typeOf reparsed;
      };
    };

  # Property: Configuration invariants (always true regardless of input)
  # Tests that certain conditions always hold for valid inputs
  invariantProperty =
    {
      invariant,
      name ? "invariant",
    }:
    config:
    let
      identifier = config.identifier or "unknown";
      result = invariant config;
    in
    {
      property = name;
      config = identifier;
      inherit result;
    };

  # Property: Configuration idempotence (applying twice = same as once)
  # Tests that repeated transformations stabilize
  idempotenceProperty =
    {
      transformer,
      name ? "idempotence",
    }:
    config:
    let
      identifier = config.identifier or "unknown";
      once = transformer config;
      twice = transformer once;
      result = once == twice;
    in
    {
      property = name;
      config = identifier;
      inherit result;
      details = {
        once = typeOf once;
        twice = typeOf twice;
      };
    };

  # Property: Configuration composition (f ∘ g = h)
  # Tests that function composition behaves as expected
  compositionProperty =
    {
      f,
      g,
      expected,
      name ? "composition",
    }:
    config:
    let
      identifier = config.identifier or "unknown";
      composed = f (g config);
      direct = expected config;
      result = composed == direct;
    in
    {
      property = name;
      config = identifier;
      inherit result;
      details = {
        composed = typeOf composed;
        direct = typeOf direct;
      };
    };

  # Property: Configuration monotonicity (adding options doesn't remove existing ones)
  # Tests that enrichment operations are non-destructive
  monotonicityProperty =
    {
      enricher,
      checker,
      name ? "monotonicity",
    }:
    config:
    let
      identifier = config.identifier or "unknown";
      enriched = enricher config;
      result = checker enriched config;
    in
    {
      property = name;
      config = identifier;
      inherit result;
      details = {
        enriched = typeOf enriched;
        original = typeOf config;
      };
    };

  # Property: Reflexivity (x == x)
  # Tests that values equal themselves
  reflexivityProperty =
    {
      extractor,
      name ? "reflexivity",
    }:
    config:
    let
      identifier = config.identifier or "unknown";
      value = extractor config;
      result = value == value;
    in
    {
      property = name;
      config = identifier;
      inherit result;
    };

  # Property: Symmetry (f(x, y) == f(y, x))
  # Tests that operations are order-independent
  symmetryProperty =
    {
      operation,
      extractor,
      name ? "symmetry",
    }:
    config1: config2:
    let
      id1 = config1.identifier or "unknown1";
      id2 = config2.identifier or "unknown2";
      result1 = operation config1 config2;
      result2 = operation config2 config1;
      value1 = extractor result1;
      value2 = extractor result2;
      result = value1 == value2;
    in
    {
      property = name;
      config = "${id1}-${id2}";
      inherit result;
      details = {
        forward = typeOf result1;
        backward = typeOf result2;
      };
    };

  # Property: Transitivity (if a==b and b==c, then a==c)
  # Tests that equivalence chains are consistent
  transitivityProperty =
    {
      comparator,
      name ? "transitivity",
    }:
    config1: config2: config3:
    let
      id1 = config1.identifier or "unknown1";
      id2 = config2.identifier or "unknown2";
      id3 = config3.identifier or "unknown3";
      ab = comparator config1 config2;
      bc = comparator config2 config3;
      ac = comparator config1 config3;
      # If a==b and b==c, then a must equal c
      result = if ab && bc then ac else true;
    in
    {
      property = name;
      config = "${id1}-${id2}-${id3}";
      inherit result;
      details = {
        ab = ab;
        bc = bc;
        ac = ac;
      };
    };

  # Property: Associativity (f(f(x, y), z) == f(x, f(y, z)))
  # Tests that grouping doesn't affect results
  associativityProperty =
    {
      operation,
      extractor,
      name ? "associativity",
    }:
    config1: config2: config3:
    let
      id1 = config1.identifier or "unknown1";
      id2 = config2.identifier or "unknown2";
      id3 = config3.identifier or "unknown3";
      left = operation (operation config1 config2) config3;
      right = operation config1 (operation config2 config3);
      valueLeft = extractor left;
      valueRight = extractor right;
      result = valueLeft == valueRight;
    in
    {
      property = name;
      config = "${id1}-${id2}-${id3}";
      inherit result;
      details = {
        leftGrouped = typeOf left;
        rightGrouped = typeOf right;
      };
    };

  # ============================================================
  # Test Data Generators
  # ============================================================

  # Generate valid usernames (alphanumeric, underscore, hyphen)
  generateUsername =
    i:
    let
      letters = "abcdefghijklmnopqrstuvwxyz";
      chars = letters + "0123456789_-";
      base = elemAt letters (lib.mod i 26);
      num = lib.mod i 100;
      suffix = if num < 10 then "0${toString num}" else toString num;
    in
    "${base}${suffix}";

  # Generate valid email addresses
  generateEmail =
    username:
    let
      domains = [
        "gmail.com"
        "yahoo.com"
        "outlook.com"
        "protonmail.com"
        "example.com"
        "test.org"
        "dev.io"
      ];
      domainIdx = lib.mod (stringLength username) (length domains);
      domain = elemAt domains domainIdx;
    in
    "${username}@${domain}";

  # Generate full names
  generateFullName =
    i:
    let
      firstNames = [
        "Alice"
        "Bob"
        "Charlie"
        "Diana"
        "Eve"
        "Frank"
        "Grace"
        "Henry"
      ];
      lastNames = [
        "Smith"
        "Johnson"
        "Williams"
        "Brown"
        "Jones"
        "Garcia"
        "Miller"
        "Davis"
      ];
      firstIdx = lib.mod i (length firstNames);
      lastIdx = lib.mod (i + 3) (length lastNames);
    in
    "${elemAt firstNames firstIdx} ${elemAt lastNames lastIdx}";

  # Generate system identifiers
  generateSystemName =
    i:
    let
      prefixes = [
        "macbook"
        "desktop"
        "server"
        "vm"
        "laptop"
      ];
      suffixes = [
        "pro"
        "air"
        "mini"
        "studio"
        "testing"
      ];
      prefixIdx = lib.mod i (length prefixes);
      suffixIdx = lib.mod (i + 1) (length suffixes);
    in
    "${elemAt prefixes prefixIdx}-${elemAt suffixes suffixIdx}";

  # Generate architecture strings
  generateArchitecture =
    i:
    let
      archs = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-w64-mingw32"
      ];
    in
    elemAt archs (lib.mod i (length archs));

  # Generate package lists
  generatePackageList =
    seed:
    let
      basePackages = [
        "git"
        "vim"
        "curl"
        "wget"
        "tree"
        "jq"
        "ripgrep"
        "fzf"
      ];
      devPackages = [
        "nodejs"
        "python3"
        "go"
        "rustc"
        "docker"
        "gh"
      ];
      count = (lib.mod seed 5) + 3;
      useDev = (lib.mod seed 2) == 0;
      packages = if useDev then basePackages ++ devPackages else basePackages;
    in
    genList (i: elemAt packages (lib.mod i (length packages))) count;

  # Generate scenario variations
  generateVariations =
    baseConfig: variations: map (v: baseConfig // v) variations;

  # ============================================================
  # Scenario Generators
  # ============================================================

  scenarios = {
    # User configuration scenarios
    users =
      let
        baseUsers = builtins.genList (i: {
          identifier = "user-${toString i}";
          name = generateFullName i;
          email = generateEmail (generateUsername i);
          username = generateUsername i;
        }) 5;
      in
      baseUsers;

    # System configuration scenarios
    systems =
      let
        baseSystems = builtins.genList (i: {
          identifier = "system-${toString i}";
          name = generateSystemName i;
          system = generateArchitecture i;
          user = generateUsername i;
          darwin = lib.mod i 2 == 0;
          wsl = lib.mod i 3 == 0;
        }) 8;
      in
      baseSystems;

    # Git configuration scenarios
    gitConfigs =
      let
        baseGitConfigs = [
          {
            identifier = "basic-git";
            enable = true;
            userName = "Test User";
            userEmail = "test@example.com";
          }
          {
            identifier = "git-with-aliases";
            enable = true;
            userName = "Alias User";
            userEmail = "alias@example.com";
            aliases = {
              st = "status";
              co = "checkout";
              br = "branch";
            };
          }
          {
            identifier = "git-with-lfs";
            enable = true;
            userName = "LFS User";
            userEmail = "lfs@example.com";
            lfs = true;
          }
        ];
      in
      baseGitConfigs;

    # Platform scenarios
    platforms = [
      {
        identifier = "darwin-arm64";
        isDarwin = true;
        isLinux = false;
        system = "aarch64-darwin";
        homePrefix = "/Users";
      }
      {
        identifier = "darwin-x64";
        isDarwin = true;
        isLinux = false;
        system = "x86_64-darwin";
        homePrefix = "/Users";
      }
      {
        identifier = "linux-arm64";
        isDarwin = false;
        isLinux = true;
        system = "aarch64-linux";
        homePrefix = "/home";
      }
      {
        identifier = "linux-x64";
        isDarwin = false;
        isLinux = true;
        system = "x86_64-linux";
        homePrefix = "/home";
      }
    ];

    # Edge case scenarios
    edgeCases = [
      { identifier = "empty-config"; }
      {
        identifier = "minimal-user";
        username = "x";
        name = "X";
        email = "x@x.x";
      }
      {
        identifier = "maximal-user";
        username = "very-long-username-123";
        name = "Very Long Name With Spaces";
        email = "very.long.email+tag@example.com";
      }
      {
        identifier = "special-chars";
        username = "user_123-test";
        name = "Test User";
        email = "user_123@test.example.com";
      }
    ];
  };

  # ============================================================
  # Property Test Runners
  # ============================================================

  # Run a single property test against multiple scenarios
  runPropertyTest =
    propertyFn: scenarioList:
    let
      testResults = map propertyFn scenarioList;
      passed = filter (t: t.result) testResults;
      failed = filter (t: !t.result) testResults;
      totalTests = length testResults;
      passedCount = length passed;
      failedCount = length failed;
    in
    {
      inherit testResults passed failed totalTests passedCount failedCount;
      allPassed = failedCount == 0;
      successRate = if totalTests > 0 then passedCount / totalTests else 0;
    };

  # Run a suite of property tests
  runPropertySuite =
    propertySuite: scenarios:
    let
      suiteResults = mapAttrsToList (
        propName: propertyFn: {
          name = propName;
          result = runPropertyTest propertyFn scenarios;
        }
      ) propertySuite;

      allResults = map (r: r.result) suiteResults;
      totalSuites = length suiteResults;
      passedSuites = length (filter (r: r.result.allPassed) suiteResults);

      failedTests = foldl' (
        acc: r:
        acc
        ++ map (
          t: {
            property = r.name;
            config = t.config;
            inherit (t) result;
            inherit (t.details) details;
          }
        ) r.result.failed
      ) [ ] suiteResults;
    in
    {
      inherit suiteResults failedTests totalSuites passedSuites;
      allPassed = length failedTests == 0;
      summary = {
        totalProperties = totalSuites;
        passedProperties = passedSuites;
        totalTests = foldl' (acc: r: acc + r.result.totalTests) 0 allResults;
        passedTests = foldl' (acc: r: acc + r.result.passedCount) 0 allResults;
      };
    };

  # Create a test derivation from property test results
  mkPropertyTest =
    name: propertyFn: scenarioList:
    let
      results = runPropertyTest propertyFn scenarioList;
    in
    if results.allPassed then
      pkgs.runCommand "property-test-${name}-pass" { } ''
        echo "Property Test: ${name}"
        echo "Status: PASS"
        echo "Scenarios tested: ${toString results.totalTests}"
        echo ""
        echo "All scenarios passed successfully"
        touch $out
      ''
    else
      pkgs.runCommand "property-test-${name}-fail" { } ''
        echo "Property Test: ${name}"
        echo "Status: FAIL"
        echo "Scenarios tested: ${toString results.totalTests}"
        echo "Passed: ${toString results.passedCount}"
        echo "Failed: ${toString results.failedCount}"
        echo ""
        echo "Failed scenarios:"
        ${concatMapStringsSep "\n" (
          t: ''
            echo "  - ${t.property} (${t.config})"
            ${if t ? details then ''
              echo "    Details: ${toString t.details}"
            '' else ""}
          ''
        ) results.failed}
        exit 1
      '';

  # Create a test suite derivation from property suite results
  mkPropertySuite =
    name: propertySuite: scenarioList:
    let
      results = runPropertySuite propertySuite scenarioList;
      summary = results.summary;
    in
    if results.allPassed then
      pkgs.runCommand "property-suite-${name}-pass" { } ''
        echo "Property Test Suite: ${name}"
        echo "Status: PASS"
        echo ""
        echo "Summary:"
        echo "  Properties tested: ${toString summary.totalProperties}"
        echo "  Properties passed: ${toString summary.passedProperties}"
        echo "  Total test cases: ${toString summary.totalTests}"
        echo "  Tests passed: ${toString summary.passedTests}"
        echo ""
        echo "All property tests passed successfully"
        touch $out
      ''
    else
      pkgs.runCommand "property-suite-${name}-fail" { } ''
        echo "Property Test Suite: ${name}"
        echo "Status: FAIL"
        echo ""
        echo "Summary:"
        echo "  Properties tested: ${toString summary.totalProperties}"
        echo "  Properties passed: ${toString summary.passedProperties}"
        echo "  Total test cases: ${toString summary.totalTests}"
        echo "  Tests passed: ${toString summary.passedTests}"
        echo ""
        echo "Failed tests:"
        ${concatMapStringsSep "\n" (
          t: ''
            echo "  - ${t.property} (${t.config})"
          ''
        ) results.failedTests}
        exit 1
      '';

  # ============================================================
  # Helper Functions for Creating Custom Properties
  # ============================================================

  # Create a custom property with type dispatch
  mkProperty =
    { type, ... }@args:
    if type == "roundtrip" then
      roundtripProperty args
    else if type == "invariant" then
      invariantProperty args
    else if type == "idempotence" then
      idempotenceProperty args
    else if type == "composition" then
      compositionProperty args
    else if type == "monotonicity" then
      monotonicityProperty args
    else if type == "reflexivity" then
      reflexivityProperty args
    else if type == "symmetry" then
      symmetryProperty args
    else if type == "transitivity" then
      transitivityProperty args
    else if type == "associativity" then
      associativityProperty args
    else
      throw "Unknown property type: ${type}";

  # Create custom scenario generators
  mkScenarios = baseConfig: variations: generateVariations baseConfig variations;

  # ============================================================
  # Exports
  # ============================================================

  inherit
    # Core property types
    roundtripProperty
    invariantProperty
    idempotenceProperty
    compositionProperty
    monotonicityProperty
    reflexivityProperty
    symmetryProperty
    transitivityProperty
    associativityProperty
    ;

  inherit
    # Generators
    generateUsername
    generateEmail
    generateFullName
    generateSystemName
    generateArchitecture
    generatePackageList
    generateVariations
    ;

  inherit
    # Scenario collections
    scenarios
    ;

  inherit
    # Test runners
    runPropertyTest
    runPropertySuite
    ;

  inherit
    # Test creators
    mkProperty
    mkScenarios
    mkPropertyTest
    mkPropertySuite
    ;
}
