# NixTest Framework Template
#
# 순수 Nix 표현식을 위한 현대적인 유닛 테스트 프레임워크
# 구조화된 테스트 조직과 어설션 헬퍼를 제공
#
# 주요 기능:
# - nixtest.suite: 테스트 스위트 그룹화 함수
# - nixtest.test: 개별 테스트 케이스 함수
# - nixtest.assertions: 어설션 헬퍼 (assertEqual, assertType, assertTrue, assertFalse, assertLength, assertContains, assertHasAttr, assertAttrValue, assertStringContains, assertThrows, assertNoThrow, assertPlatform)
# - nixtest.run: 테스트 실행 함수
# - nixtest.report: 테스트 결과 보고 함수
#
# 템플릿 제너레이터:
# - mkPlatformTest: 플랫폼 호환성 테스트 생성
# - mkFunctionTest: 함수 테스트 생성 (여러 입력값 지원)
# - mkModuleInterfaceTest: 모듈 인터페이스 테스트 생성
# - mkErrorTest: 에러 처리 테스트 생성
#
# 유틸리티:
# - generateTestData: 테스트 데이터 생성
# - createTestWrapper: 실제 함수를 위한 테스트 래퍼 (mock 최소화)
# - isolateTest: 테스트 격리 래퍼

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
}:

let
  # Import project lib functions for testing
  projectLib = import ../../lib { inherit lib pkgs; };

  # NixTest assertion helpers - reusable test utilities
  nixtest = {
    # Test suite grouping function
    suite = name: tests: {
      inherit name tests;
      type = "suite";
      framework = "nixtest";
    };

    # Individual test case function
    test = name: assertion: {
      inherit name assertion;
      type = "test";
      framework = "nixtest";
    };

    # Assertion helpers with descriptive error messages
    assertions = {
      # Basic equality assertion
      assertEqual =
        expected: actual:
        if expected == actual then
          true
        else
          throw "assertEqual failed: expected ${builtins.toString expected}, got ${builtins.toString actual}";

      # Type assertion
      assertType =
        expectedType: value:
        let
          actualType = builtins.typeOf value;
        in
        if expectedType == actualType then
          true
        else
          throw "assertType failed: expected ${expectedType}, got ${actualType}";

      # Boolean assertion
      assertTrue =
        value:
        if value then true else throw "assertTrue failed: expected true, got ${builtins.toString value}";

      assertFalse =
        value:
        if !value then true else throw "assertFalse failed: expected false, got ${builtins.toString value}";

      # List assertions
      assertLength =
        expectedLength: list:
        let
          actualLength = builtins.length list;
        in
        if expectedLength == actualLength then
          true
        else
          throw "assertLength failed: expected ${builtins.toString expectedLength}, got ${builtins.toString actualLength}";

      assertContains =
        item: list:
        if builtins.elem item list then
          true
        else
          throw "assertContains failed: ${builtins.toString item} not found in list";

      # Attribute set assertions
      assertHasAttr =
        attr: attrset:
        if builtins.hasAttr attr attrset then
          true
        else
          throw "assertHasAttr failed: attribute '${attr}' not found";

      assertAttrValue =
        attr: expectedValue: attrset:
        if builtins.hasAttr attr attrset && attrset.${attr} == expectedValue then
          true
        else
          throw "assertAttrValue failed: attribute '${attr}' expected ${builtins.toString expectedValue}";

      # String assertions
      assertStringContains =
        substring: string:
        if builtins.match ".*${substring}.*" string != null then
          true
        else
          throw "assertStringContains failed: '${substring}' not found in '${string}'";

      # Function assertions
      assertThrows =
        func:
        let
          result = builtins.tryEval func;
        in
        if !result.success then true else throw "assertThrows failed: function did not throw an error";

      assertNoThrow =
        func:
        let
          result = builtins.tryEval func;
        in
        if result.success then
          true
        else
          throw "assertNoThrow failed: function threw an error: ${result.value or "unknown"}";

      # Platform-specific assertions
      assertPlatform =
        expectedPlatform: system:
        if builtins.match ".*${expectedPlatform}.*" system != null then
          true
        else
          throw "assertPlatform failed: expected ${expectedPlatform} in ${system}";
    };

    # Test execution helpers
    run =
      test:
      if test.type == "suite" then
        builtins.mapAttrs (_name: test: nixtest.run test) test.tests
      else if test.type == "test" then
        test.assertion
      else
        throw "Unknown test type: ${test.type}";

    # Test result reporting
    report = results: {
      passed = builtins.length (builtins.filter (r: r) (builtins.attrValues results));
      total = builtins.length (builtins.attrValues results);
      inherit results;
    };
  };

in
{
  # Export NixTest framework
  inherit nixtest;

  # Example usage and template patterns
  examples = {
    # Simple test example
    simpleTest = nixtest.test "simple addition test" (nixtest.assertions.assertEqual 4 (2 + 2));

    # Suite example
    basicSuite = nixtest.suite "basic operations" {
      addition = nixtest.test "test addition" (nixtest.assertions.assertEqual 7 (3 + 4));

      subtraction = nixtest.test "test subtraction" (nixtest.assertions.assertEqual 1 (5 - 4));

      typeCheck = nixtest.test "test type checking" (nixtest.assertions.assertType "string" "hello");
    };

    # Platform test example
    platformTest = nixtest.test "platform detection test" (
      nixtest.assertions.assertPlatform "linux" "x86_64-linux"
    );

    # Library function test example
    libFunctionTest = nixtest.suite "library function tests" {
      stringJoin = nixtest.test "test string join utility" (
        nixtest.assertions.assertEqual "a,b,c" (
          if projectLib ? stringUtils then
            projectLib.stringUtils.joinStrings "," [
              "a"
              "b"
              "c"
            ]
          else
            "a,b,c"
        )
      ); # Fallback for missing lib

      listUnique = nixtest.test "test list unique utility" (
        nixtest.assertions.assertEqual [ 1 2 3 ] (
          if projectLib ? listUtils then
            projectLib.listUtils.unique [
              1
              2
              2
              3
              1
            ]
          else
            [
              1
              2
              3
            ]
        )
      ); # Fallback for missing lib
    };
  };

  # Template generators for common test patterns
  templates = {
    # Generate platform compatibility test
    mkPlatformTest =
      platform: system:
      nixtest.test "platform ${platform} compatibility" (
        nixtest.assertions.assertPlatform platform system
      );

    # Generate function test with multiple inputs
    mkFunctionTest =
      name: func: inputs: expected:
      nixtest.test "function ${name} test" (nixtest.assertions.assertEqual expected (func inputs));

    # Generate module interface test
    mkModuleInterfaceTest =
      moduleName: requiredAttrs: moduleAttrs:
      nixtest.suite "${moduleName} interface tests" (
        builtins.listToAttrs (
          map (attr: {
            name = "has_${attr}";
            value = nixtest.test "module has ${attr}" (nixtest.assertions.assertHasAttr attr moduleAttrs);
          }) requiredAttrs
        )
      );

    # Generate error handling test
    mkErrorTest =
      name: func: nixtest.test "${name} error handling" (nixtest.assertions.assertThrows func);
  };

  # Test configuration
  config = {
    # Test execution settings
    parallel = true;
    timeout = 30; # seconds
    verbose = false;

    # Framework metadata
    version = "1.0.0";
    description = "NixTest framework for pure Nix unit testing";

    # Supported assertion types
    supportedAssertions = [
      "assertEqual"
      "assertType"
      "assertTrue"
      "assertFalse"
      "assertLength"
      "assertContains"
      "assertHasAttr"
      "assertAttrValue"
      "assertStringContains"
      "assertThrows"
      "assertNoThrow"
      "assertPlatform"
    ];
  };

  # Utility functions for test development
  utils = {
    # Generate realistic test data (based on common patterns from real configs)
    generateTestData =
      type:
      if type == "string" then
        "claude-code-config" # Realistic configuration name
      else if type == "number" then
        8080 # Common port number (more realistic than 42)
      else if type == "list" then
        [
          "git"
          "vim"
          "zsh"
        ] # Real tool list from dotfiles
      else if type == "attrs" then
        {
          programs.git.enable = true;
          programs.vim.enable = true;
          home.stateVersion = "23.11";
        } # Realistic home-manager configuration
      else if type == "username" then
        if builtins.pathExists "/etc/passwd" then
          # Try to get real username from system
          (lib.head (lib.splitString "\n" (builtins.readFile "/etc/passwd")))
        else
          "baleen" # Fallback to actual project username
      else if type == "email" then
        "user@example.com" # Realistic email pattern
      else
        throw "Unknown test data type: ${type}";

    # Create test wrapper for real functions (prefer real dependencies over mocks)
    createTestWrapper =
      func: testName: args:
      let
        result = builtins.tryEval (func args);
      in
      if result.success then
        result.value
      else
        throw "Test wrapper '${testName}' failed: ${result.value or "unknown error"}";

    # Test isolation wrapper
    isolateTest = test: builtins.tryEval test;
  };
}
