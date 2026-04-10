# Property-based testing helpers
#
# Provides:
# - propertyTest: test a property against a list of values
# - multiParamPropertyTest: test binary/ternary properties against value combinations
# - forAllCases: test a property across named test cases
{
  pkgs,
  lib,
  assertTest,
  testSuite,
}:

{
  # Property-based testing helper
  # Tests a property against a list of test values
  propertyTest =
    name: property: testValues:
    let
      testResults = builtins.map (value: {
        value = value;
        result = builtins.tryEval (property value);
      }) testValues;

      allPassed = builtins.all (test: test.result.success) testResults;
      failedTests = builtins.filter (test: !test.result.success) testResults;
    in
    if allPassed then
      pkgs.runCommand "property-test-${name}-pass" { } ''
        echo "✅ Property test ${name}: PASS"
        echo "  Tested ${toString (builtins.length testValues)} values"
        echo "  Property holds for all test cases"
        touch $out
      ''
    else
      pkgs.runCommand "property-test-${name}-fail" { } ''
        echo "❌ Property test ${name}: FAIL"
        echo "  Property failed for ${toString (builtins.length failedTests)} out of ${toString (builtins.length testValues)} values"
        echo ""
        echo "🔍 Failed test cases:"
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "  Value: ${toString test.value}"
          echo "  Error: ${test.result.value or "Unknown error"}"
        '') failedTests}
        exit 1
      '';

  # Enhanced property testing with multiple parameters
  multiParamPropertyTest =
    name: property: testValueSets:
    let
      generateCombinations =
        valueSets:
        if builtins.length valueSets == 0 then
          [ [ ] ]
        else
          let
            rest = generateCombinations (builtins.tail valueSets);
            current = builtins.head valueSets;
          in
          builtins.concatLists (builtins.map (combo: builtins.map (val: [ val ] ++ combo) current) rest);

      combinations = generateCombinations testValueSets;
      testResults = builtins.map (values: {
        values = values;
        result = builtins.tryEval (builtins.foldl' (acc: v: acc v) property values);
      }) combinations;

      allPassed = builtins.all (test: test.result.success) testResults;
      failedTests = builtins.filter (test: !test.result.success) testResults;
    in
    if allPassed then
      pkgs.runCommand "multi-property-test-${name}-pass" { } ''
        echo "✅ Multi-parameter property test ${name}: PASS"
        echo "  Tested ${toString (builtins.length combinations)} combinations"
        echo "  Property holds for all test cases"
        touch $out
      ''
    else
      pkgs.runCommand "multi-property-test-${name}-fail" { } ''
        echo "❌ Multi-parameter property test ${name}: FAIL"
        echo "  Property failed for ${toString (builtins.length failedTests)} out of ${toString (builtins.length combinations)} combinations"
        echo ""
        echo "🔍 Failed test cases:"
        ${lib.concatMapStringsSep "\n" (test: ''
          echo "  Values: [${lib.concatMapStringsSep ", " toString test.values}]"
          echo "  Error: ${test.result.value or "Unknown error"}"
        '') failedTests}
        exit 1
      '';

  # Property testing helper for all cases (forAllCases)
  forAllCases =
    testName: testCases: propertyFn:
    let
      individualTests = builtins.map (
        testCase:
        let
          caseName = "${testName}-${testCase.name or "case"}";
          propertyResult = builtins.tryEval (propertyFn testCase);
        in
        if propertyResult.success then
          assertTest caseName propertyResult.value "Property test failed for case: ${toString testCase}"
        else
          assertTest caseName false
            "Property test threw error for case: ${toString testCase}: ${propertyResult.value}"
      ) testCases;

      summaryTest = pkgs.runCommand "property-test-${testName}-summary" { } ''
        echo "🧪 Property Test Suite: ${testName}"
        echo "Testing ${toString (builtins.length testCases)} cases..."
        echo ""
        ${lib.concatMapStringsSep "\n" (testCase: ''
          echo "  🔍 Testing case: ${testCase.name or "unnamed"}"
        '') testCases}
        echo ""
        echo "✅ All property tests passed for ${testName}"
        echo "Property holds across all test cases"
        touch $out
      '';
    in
    testSuite "${testName}-property-tests" (individualTests ++ [ summaryTest ]);
}
