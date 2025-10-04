# Test Helper Functions
#
# NixTest 프레임워크용 종합 어설션 및 유틸리티 라이브러리
# Nix 키워드 충돌을 피하고 깔끔한 API를 제공
#
# 주요 기능:
# - 핵심 어설션: assertEqual, assertType, assertTrue, assertFalse
# - 리스트 어설션: assertLength, assertContains
# - 속성 어설션: assertHasAttr, assertAttrValue
# - 문자열 어설션: assertStringContains
# - 함수 어설션: assertThrows, assertNoThrow
# - 플랫폼 어설션: assertPlatform
# - 유틸리티: inspect (값 검사), runAssertion (어설션 실행)
# - 컬러 터미널 출력: formatError를 통한 상세한 에러 메시지 (빨강, 노랑, 청록색)
#
# test-assertions.nix와의 차이점:
# - 더 간단하고 가벼운 API (핵심 어설션만 제공)
# - Nix 키워드 충돌 방지 최적화
# - 기본적인 테스트 실행 및 에러 포매팅 제공
#
# 사용 예시:
# assertEqual expected actual context
# assertTrue value context
# assertContains item list context

{ lib ? import <nixpkgs/lib>
, pkgs ? import <nixpkgs> { }
,
}:

let
  # Color codes for terminal output
  colors = {
    red = "\033[31m";
    green = "\033[32m";
    yellow = "\033[33m";
    blue = "\033[34m";
    cyan = "\033[36m";
    reset = "\033[0m";
    bold = "\033[1m";
  };

  # Helper function to format error messages
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

in
{
  # Core assertion functions
  assertEqual =
    expected: actual: context:
    if expected == actual then true else throw (formatError "assertEqual" expected actual context);

  assertType =
    expectedType: value: context:
    let
      actualType = builtins.typeOf value;
    in
    if expectedType == actualType then
      true
    else
      throw (formatError "assertType" expectedType actualType context);

  assertTrue =
    value: context: if value == true then true else throw (formatError "assertTrue" true value context);

  assertFalse =
    value: context:
    if value == false then true else throw (formatError "assertFalse" false value context);

  # List assertions
  assertLength =
    expectedLength: list: context:
    let
      actualLength = builtins.length list;
    in
    if expectedLength == actualLength then
      true
    else
      throw (formatError "assertLength" expectedLength actualLength context);

  assertContains =
    item: list: context:
    if builtins.elem item list then
      true
    else
      throw (formatError "assertContains" "item in list" "item not found" context);

  # Attribute assertions
  assertHasAttr =
    attr: attrset: context:
    if builtins.hasAttr attr attrset then
      true
    else
      throw (formatError "assertHasAttr" "attribute '${attr}'" "attribute not found" context);

  assertAttrValue =
    attr: expectedValue: attrset: context:
    if builtins.hasAttr attr attrset && attrset.${attr} == expectedValue then
      true
    else
      throw (
        formatError "assertAttrValue ('${attr}')" expectedValue
          (
            if builtins.hasAttr attr attrset then attrset.${attr} else "MISSING"
          )
          context
      );

  # String assertions
  assertStringContains =
    substring: string: context:
    if builtins.match ".*${substring}.*" string != null then
      true
    else
      throw (
        formatError "assertStringContains" "'${substring}' in string" "not found in '${string}'" context
      );

  # Function assertions
  assertThrows =
    func: context:
    let
      result = builtins.tryEval func;
    in
    if result.success == false then
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
    if result.success == true then
      true
    else
      throw (
        formatError "assertNoThrow" "function to complete successfully" "function threw error" context
      );

  # Platform assertions
  assertPlatform =
    expectedPlatform: system: context:
    if builtins.match ".*${expectedPlatform}.*" system != null then
      true
    else
      throw (formatError "assertPlatform" expectedPlatform system context);

  # Utility functions
  inspect =
    value:
    let
      valueType = builtins.typeOf value;
    in
    if valueType == "string" then ''"${value}"'' else builtins.toString value;

  # Test execution helpers
  runAssertion =
    name: assertion:
    let
      result = builtins.tryEval assertion;
    in
    {
      inherit name;
      success = result.success;
      error = if result.success then null else result.value;
    };

  # Version and metadata
  version = "1.0.0";
  description = "Test helper functions for NixTest framework";
  colors = colors;
}
