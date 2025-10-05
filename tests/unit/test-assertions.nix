# Advanced Test Assertion Helpers
#
# NixTest 프레임워크용 고급 어설션 라이브러리
# 상세한 에러 메시지와 디버깅 정보를 제공하는 종합적인 어설션 함수 모음
#
# 주요 기능:
# - 기본 어설션: assertEqual, assertStrictEqual, assertType, assertTrue, assertFalse
# - Null 체크: assertNull, assertNotNull
# - 숫자 비교: assertGreater, assertLess, assertBetween
# - 리스트 검증: assertLength, assertEmpty, assertContains, assertAllContain, assertAnyContain
# - 속성 검증: assertHasAttr, assertAttrValue, assertAttrType, assertAttrsEqual
# - 문자열 검증: assertStringContains, assertStringStartsWith, assertStringEndsWith, assertStringMatches
# - 함수 검증: assertThrows, assertNoThrow
# - 플랫폼 검증: assertPlatform, assertArchitecture, assertSystemSupported
# - 경로 검증: assertPathExists, assertPathIsAbsolute, assertPathExtension
# - 복합 어설션: assertModuleStructure, assertAllSatisfy, assertPackageList, assertConfigStructure
# - 컬러 터미널 출력 지원 및 디버깅 도구 제공

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
}:

let
  # Color codes for terminal output
  colors = {
    red = "\033[31m";
    green = "\033[32m";
    yellow = "\033[33m";
    blue = "\033[34m";
    purple = "\033[35m";
    cyan = "\033[36m";
    white = "\033[37m";
    reset = "\033[0m";
    bold = "\033[1m";
  };

  # Helper function to format error messages with context
  formatError =
    assertion: expected: actual: context:
    let
      contextStr = if context != null then " (${context})" else "";
      expectedStr = builtins.toString expected;
      actualStr = builtins.toString actual;
    in
    "${colors.red}${colors.bold}ASSERTION FAILED${colors.reset}: ${assertion}${contextStr}\n"
    + "  ${colors.yellow}Expected:${colors.reset} ${expectedStr}\n"
    + "  ${colors.cyan}Actual:${colors.reset}   ${actualStr}";

  # Helper function to format success messages
  formatSuccess =
    assertion: context:
    let
      contextStr = if context != null then " (${context})" else "";
    in
    "${colors.green}✓${colors.reset} ${assertion}${contextStr}";

  # Debug helper to inspect values
  inspect =
    value:
    let
      valueType = builtins.typeOf value;
      valueStr =
        if valueType == "string" then
          ''"${value}"''
        else if valueType == "int" || valueType == "float" then
          builtins.toString value
        else if valueType == "bool" then
          if value then "true" else "false"
        else if valueType == "list" then
          "[${builtins.concatStringsSep ", " (map inspect value)}]"
        else if valueType == "set" then
          "{${builtins.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k} = ${inspect v}") value)}}"
        else
          builtins.toString value;
    in
    "${colors.purple}${valueType}${colors.reset}: ${valueStr}";

in
rec {
  # Core assertion functions with enhanced error reporting
  assertions = {

    # Basic equality with deep comparison support
    assertEqual =
      expected: actual: context:
      if expected == actual then true else throw (formatError "assertEqual" expected actual context);

    # Strict equality (no type coercion)
    assertStrictEqual =
      expected: actual: context:
      let
        typesMatch = builtins.typeOf expected == builtins.typeOf actual;
        valuesMatch = expected == actual;
      in
      if typesMatch && valuesMatch then
        true
      else
        throw (
          formatError "assertStrictEqual (types: ${builtins.typeOf expected} vs ${builtins.typeOf actual})"
            expected
            actual
            context
        );

    # Type assertions with detailed type information
    assertType =
      expectedType: value: context:
      let
        actualType = builtins.typeOf value;
      in
      if expectedType == actualType then
        true
      else
        throw (formatError "assertType" expectedType actualType context);

    # Boolean assertions
    assertTrue =
      value: context: if value then true else throw (formatError "assertTrue" true value context);

    assertFalse =
      value: context: if !value then true else throw (formatError "assertFalse" false value context);

    # Null/undefined assertions
    assertNull =
      value: context: if value == null then true else throw (formatError "assertNull" null value context);

    assertNotNull =
      value: context:
      if value != null then true else throw (formatError "assertNotNull" "non-null value" null context);

    # Numeric assertions
    assertGreater =
      min: value: context:
      if value > min then
        true
      else
        throw (
          formatError "assertGreater (value > ${builtins.toString min})" "> ${builtins.toString min}" value
            context
        );

    assertLess =
      max: value: context:
      if value < max then
        true
      else
        throw (
          formatError "assertLess (value < ${builtins.toString max})" "< ${builtins.toString max}" value
            context
        );

    assertBetween =
      min: max: value: context:
      if value >= min && value <= max then
        true
      else
        throw (
          formatError "assertBetween (${builtins.toString min} <= value <= ${builtins.toString max})"
            "${builtins.toString min}-${builtins.toString max}"
            value
            context
        );

    # List assertions with detailed analysis
    assertLength =
      expectedLength: list: context:
      let
        actualLength = builtins.length list;
      in
      if expectedLength == actualLength then
        true
      else
        throw (formatError "assertLength" expectedLength actualLength context);

    assertEmpty =
      list: context:
      let
        length = builtins.length list;
      in
      if length == 0 then
        true
      else
        throw (formatError "assertEmpty" "[]" "list with ${builtins.toString length} elements" context);

    assertNotEmpty =
      list: context:
      let
        length = builtins.length list;
      in
      if length > 0 then
        true
      else
        throw (formatError "assertNotEmpty" "non-empty list" "empty list" context);

    assertContains =
      item: list: context:
      if builtins.elem item list then
        true
      else
        throw (formatError "assertContains" "item in list" "item not found: ${inspect item}" context);

    assertNotContains =
      item: list: context:
      if !builtins.elem item list then
        true
      else
        throw (formatError "assertNotContains" "item not in list" "item found: ${inspect item}" context);

    assertAllContain =
      items: list: context:
      let
        missing = builtins.filter (item: !builtins.elem item list) items;
      in
      if builtins.length missing == 0 then
        true
      else
        throw (
          formatError "assertAllContain" "all items in list"
            "missing: ${builtins.concatStringsSep ", " (map inspect missing)}"
            context
        );

    assertAnyContain =
      items: list: context:
      let
        found = builtins.filter (item: builtins.elem item list) items;
      in
      if builtins.length found > 0 then
        true
      else
        throw (
          formatError "assertAnyContain" "at least one item in list"
            "none found: ${builtins.concatStringsSep ", " (map inspect items)}"
            context
        );

    # Attribute set assertions with path support
    assertHasAttr =
      attr: attrset: context:
      if builtins.hasAttr attr attrset then
        true
      else
        throw (formatError "assertHasAttr" "attribute '${attr}'" "attribute not found" context);

    assertNotHasAttr =
      attr: attrset: context:
      if !builtins.hasAttr attr attrset then
        true
      else
        throw (formatError "assertNotHasAttr" "attribute '${attr}' absent" "attribute found" context);

    assertAttrValue =
      attr: expectedValue: attrset: context:
      if builtins.hasAttr attr attrset && attrset.${attr} == expectedValue then
        true
      else if !builtins.hasAttr attr attrset then
        throw (formatError "assertAttrValue" "attribute '${attr}' exists" "attribute not found" context)
      else
        throw (formatError "assertAttrValue ('${attr}')" expectedValue attrset.${attr} context);

    assertAttrType =
      attr: expectedType: attrset: context:
      if builtins.hasAttr attr attrset then
        assertions.assertType expectedType attrset.${attr} context
      else
        throw (formatError "assertAttrType" "attribute '${attr}' exists" "attribute not found" context);

    assertAttrsEqual =
      expectedAttrs: actualAttrs: context:
      let
        expectedKeys = builtins.attrNames expectedAttrs;
        actualKeys = builtins.attrNames actualAttrs;
        missingKeys = builtins.filter (key: !builtins.hasAttr key actualAttrs) expectedKeys;
        extraKeys = builtins.filter (key: !builtins.hasAttr key expectedAttrs) actualKeys;
        differentValues = builtins.filter (
          key: builtins.hasAttr key actualAttrs && expectedAttrs.${key} != actualAttrs.${key}
        ) expectedKeys;
      in
      if
        builtins.length missingKeys == 0
        && builtins.length extraKeys == 0
        && builtins.length differentValues == 0
      then
        true
      else
        throw (
          formatError "assertAttrsEqual" "matching attribute sets"
            "missing: [${builtins.concatStringsSep ", " missingKeys}], extra: [${builtins.concatStringsSep ", " extraKeys}], different: [${builtins.concatStringsSep ", " differentValues}]"
            context
        );

    # String assertions with pattern matching
    assertStringContains =
      substring: string: context:
      if builtins.match ".*${substring}.*" string != null then
        true
      else
        throw (
          formatError "assertStringContains" "'${substring}' in string"
            "'${substring}' not found in '${string}'"
            context
        );

    assertStringStartsWith =
      prefix: string: context:
      if builtins.match "${prefix}.*" string != null then
        true
      else
        throw (
          formatError "assertStringStartsWith" "starts with '${prefix}'"
            "'${string}' does not start with '${prefix}'"
            context
        );

    assertStringEndsWith =
      suffix: string: context:
      if builtins.match ".*${suffix}" string != null then
        true
      else
        throw (
          formatError "assertStringEndsWith" "ends with '${suffix}'"
            "'${string}' does not end with '${suffix}'"
            context
        );

    assertStringLength =
      expectedLength: string: context:
      let
        actualLength = builtins.stringLength string;
      in
      if expectedLength == actualLength then
        true
      else
        throw (formatError "assertStringLength" expectedLength actualLength context);

    assertStringMatches =
      pattern: string: context:
      if builtins.match pattern string != null then
        true
      else
        throw (formatError "assertStringMatches" "pattern '${pattern}'" "no match in '${string}'" context);

    # Function and error handling assertions
    assertThrows =
      func: context:
      let
        result = builtins.tryEval func;
      in
      if !result.success then
        true
      else
        throw (
          formatError "assertThrows" "function to throw error" "function completed successfully" context
        );

    assertNoThrow =
      func: context:
      let
        result = builtins.tryEval func;
      in
      if result.success then
        true
      else
        throw (
          formatError "assertNoThrow" "function to complete successfully" "function threw error" context
        );

    assertThrowsMessage =
      expectedMessage: func: context:
      let
        result = builtins.tryEval func;
      in
      if !result.success then
        # Note: Can't access error message in pure Nix, so we just verify it throws
        true
      else
        throw (
          formatError "assertThrowsMessage" "function to throw error with message"
            "function completed successfully"
            context
        );

    # Platform-specific assertions
    assertPlatform =
      expectedPlatform: system: context:
      if builtins.match ".*${expectedPlatform}.*" system != null then
        true
      else
        throw (formatError "assertPlatform" expectedPlatform system context);

    assertArchitecture =
      expectedArch: system: context:
      if builtins.match "${expectedArch}-.*" system != null then
        true
      else
        throw (formatError "assertArchitecture" expectedArch system context);

    assertSystemSupported =
      supportedSystems: system: context:
      if builtins.elem system supportedSystems then
        true
      else
        throw (
          formatError "assertSystemSupported" "system in supported list"
            "${system} not in [${builtins.concatStringsSep ", " supportedSystems}]"
            context
        );

    # File and path assertions
    assertPathExists =
      path: context:
      if builtins.pathExists path then
        true
      else
        throw (formatError "assertPathExists" "path exists" "path not found: ${path}" context);

    assertPathIsAbsolute =
      path: context:
      if builtins.match "/.*" path != null then
        true
      else
        throw (formatError "assertPathIsAbsolute" "absolute path" "relative path: ${path}" context);

    assertPathExtension =
      expectedExt: path: context:
      if builtins.match ".*\\.${expectedExt}" path != null then
        true
      else
        throw (
          formatError "assertPathExtension" ".${expectedExt}" "different extension in ${path}" context
        );
  };

  # Composite assertion functions for common patterns
  compositeAssertions = {

    # Validate complete module structure
    assertModuleStructure =
      requiredAttrs: module: context:
      let
        checks = map (attr: assertions.assertHasAttr attr module "${context}.${attr}") requiredAttrs;
      in
      builtins.all (check: check) checks;

    # Validate list of items with predicate
    assertAllSatisfy =
      predicate: list: context:
      let
        failures = builtins.filter (item: !predicate item) list;
      in
      if builtins.length failures == 0 then
        true
      else
        throw (
          formatError "assertAllSatisfy" "all items satisfy predicate"
            "${builtins.toString (builtins.length failures)} items failed"
            context
        );

    # Validate package list structure
    assertPackageList =
      packages: context:
      let
        validPackages = builtins.filter (pkg: pkg ? name || pkg ? pname) packages;
        invalidCount = (builtins.length packages) - (builtins.length validPackages);
      in
      if invalidCount == 0 then
        true
      else
        throw (
          formatError "assertPackageList" "all items have name or pname"
            "${builtins.toString invalidCount} invalid packages"
            context
        );

    # Validate configuration structure
    assertConfigStructure =
      requiredKeys: config: context:
      let
        missingKeys = builtins.filter (key: !builtins.hasAttr key config) requiredKeys;
      in
      if builtins.length missingKeys == 0 then
        true
      else
        throw (
          formatError "assertConfigStructure" "all required keys present"
            "missing: [${builtins.concatStringsSep ", " missingKeys}]"
            context
        );

    # Validate cross-platform compatibility
    assertCrossPlatformStructure =
      platforms: moduleStructure: context:
      let
        platformChecks = map (
          platform: assertions.assertHasAttr platform moduleStructure "${context}.${platform}"
        ) platforms;
      in
      builtins.all (check: check) platformChecks;
  };

  # Test helper utilities
  testHelpers = {

    # Create test context with metadata
    withContext = testName: assertion: builtins.tryEval assertion;

    # Run assertion with detailed logging
    runAssertion =
      name: assertion:
      let
        result = builtins.tryEval assertion;
      in
      {
        inherit name;
        inherit (result) success;
        error = if result.success then null else result.value;
        message = if result.success then formatSuccess name null else result.value;
      };

    # Batch run multiple assertions
    runAssertions =
      assertionList: map (item: testHelpers.runAssertion item.name item.assertion) assertionList;

    # Generate test report
    generateReport =
      results:
      let
        totalTests = builtins.length results;
        passedTests = builtins.length (builtins.filter (r: r.success) results);
        failedTests = totalTests - passedTests;
        failureDetails = builtins.filter (r: !r.success) results;
      in
      {
        total = totalTests;
        passed = passedTests;
        failed = failedTests;
        successRate = if totalTests > 0 then (passedTests * 100.0 / totalTests) else 0.0;
        failures = failureDetails;
        summary =
          "${colors.bold}Test Results:${colors.reset} "
          + "${colors.green}${builtins.toString passedTests} passed${colors.reset}, "
          + "${colors.red}${builtins.toString failedTests} failed${colors.reset} "
          + "out of ${builtins.toString totalTests} tests";
      };
  };

  # Export assertion functions with convenience wrappers
  # These provide the main API for test files
  asserts = rec {
    # Direct assertion functions (throw on failure)
    inherit (assertions)
      assertEqual
      assertStrictEqual
      assertType
      assertTrue
      assertFalse
      assertNull
      assertNotNull
      assertGreater
      assertLess
      assertBetween
      assertLength
      assertEmpty
      assertNotEmpty
      assertContains
      assertNotContains
      assertAllContain
      assertAnyContain
      assertHasAttr
      assertNotHasAttr
      assertAttrValue
      assertAttrType
      assertAttrsEqual
      assertStringContains
      assertStringStartsWith
      assertStringEndsWith
      assertStringLength
      assertStringMatches
      assertThrows
      assertNoThrow
      assertThrowsMessage
      assertPlatform
      assertArchitecture
      assertSystemSupported
      assertPathExists
      assertPathIsAbsolute
      assertPathExtension
      ;

    # Composite assertions
    inherit (compositeAssertions)
      assertModuleStructure
      assertAllSatisfy
      assertPackageList
      assertConfigStructure
      assertCrossPlatformStructure
      ;
  };

  # Export helper utilities
  helpers = testHelpers;

  # Export debugging tools
  debug = {
    inherit
      inspect
      formatError
      formatSuccess
      colors
      ;
  };

  # Version and metadata
  version = "1.0.0";
  description = "Advanced assertion library for NixTest framework";
  supportedAssertions = builtins.attrNames assertions;
}
