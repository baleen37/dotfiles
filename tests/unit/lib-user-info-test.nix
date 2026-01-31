# User Info Test
#
# Unit tests for lib/user-info.nix centralized user information
# Tests user identity consistency across all configurations
{
  inputs,
  system,
  nixtest ? { },
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;

in
{
  platforms = ["any"];
  value = helpers.testSuite "user-info" [
    # ===== 구조 검증 =====

    # 필수 속성 존재 확인 (common-assertions 사용)
    (assertions.assertAttrsExist "user-info-has-required-attributes" userInfo ["name" "email"] null)

    # ===== 타입 검증 =====

    # 이름 타입 검증
    (assertions.assertType "user-info-name-type" userInfo.name "string" null)
    (assertions.assertType "user-info-email-type" userInfo.email "string" null)

    # ===== 값 검증 =====

    # 이름이 비어있지 않은지 확인
    (helpers.assertTest "user-info-name-non-empty" (
      builtins.stringLength userInfo.name > 0
    ) "userInfo.name should be non-empty")

    # 이메일이 비어있지 않은지 확인
    (helpers.assertTest "user-info-email-non-empty" (
      builtins.stringLength userInfo.email > 0
    ) "userInfo.email should be non-empty")

    # ===== 이메일 형식 검증 =====

    # 이메일 기본 형식 검증 (@ 및 . 포함)
    (assertions.assertStringContains "user-info-email-has-at" userInfo.email "@" null)
    (assertions.assertStringContains "user-info-email-has-dot" userInfo.email "." null)

    # 이메일 형식 검증 (정규식)
    (assertions.assertStringMatches "user-info-email-format" userInfo.email "^[^@]+@[^@]+\\.[^@]+$" null)

    # 이메일 로컬 파트 검증 (@ 앞부분)
    (helpers.assertTest "user-info-email-local-part-non-empty" (
      let
        parts = builtins.split "@" userInfo.email;
        localPart = builtins.elemAt parts 0;
      in
      builtins.isString localPart && builtins.stringLength localPart > 0
    ) "userInfo.email local part should be non-empty")

    # 이메일 도메인 파트 검증 (@ 뒷부분)
    (helpers.assertTest "user-info-email-domain-non-empty" (
      let
        parts = builtins.split "@" userInfo.email;
        domainPart = if builtins.length parts >= 3 then builtins.elemAt parts 2 else "";
      in
      builtins.isString domainPart && builtins.stringLength domainPart > 0
    ) "userInfo.email domain part should be non-empty")

    # 이메일 도메인에 점이 있는지 확인
    (helpers.assertTest "user-info-email-domain-has-dot" (
      let
        parts = builtins.split "@" userInfo.email;
        domainPart = if builtins.length parts >= 3 then builtins.elemAt parts 2 else "";
      in
      builtins.isString domainPart && lib.hasInfix "." domainPart
    ) "userInfo.email domain should contain a dot")

    # 이메일에 @ 기호가 정확히 하나 있는지 확인
    (helpers.assertTest "user-info-email-single-at-sign" (
      let
        parts = builtins.split "@" userInfo.email;
        atCount = (builtins.length parts - 1) / 2;
      in
      atCount == 1
    ) "userInfo.email should contain exactly one @ symbol")

    # ===== 널 검증 =====

    # 속성이 null이 아닌지 확인
    (assertions.assertNotNull "user-info-name-not-null" userInfo.name null)
    (assertions.assertNotNull "user-info-email-not-null" userInfo.email null)

    # ===== 공백 검증 =====

    # 이름에 공백만 있는 것이 아닌지 확인
    (helpers.assertTest "user-info-name-not-whitespace-only" (
      let
        hasNonWhitespace = builtins.any (c: !lib.elem c [" " "\t" "\n" "\r"])
          (lib.stringToCharacters userInfo.name);
      in
      hasNonWhitespace
    ) "userInfo.name should not be whitespace only")

    # 이름 앞뒤 공백 검증
    (helpers.assertTest "user-info-name-no-leading-trailing-spaces" (
      let
        firstChar = builtins.substring 0 1 userInfo.name;
        lastChar = builtins.substring (builtins.stringLength userInfo.name - 1) 1 userInfo.name;
      in
      firstChar != " " && lastChar != " "
    ) "userInfo.name should not have leading or trailing spaces")

    # ===== 구체적인 값 검증 =====

    # 사용자 이름 검증
    (assertions.assertAttrEquals "user-info-name-correct" userInfo "name" "Jiho Lee" null)

    # 이메일 주소 검증
    (assertions.assertAttrEquals "user-info-email-correct" userInfo "email" "baleen37@gmail.com" null)

    # ===== 속성 완전성 검증 =====

    # userInfo에 예상되는 속성만 있는지 확인
    (helpers.assertTest "user-info-only-expected-attrs" (
      let
        attrs = builtins.attrNames userInfo;
        expectedAttrs = [ "name" "email" ];
        unexpectedAttrs = builtins.filter (attr: !builtins.elem attr expectedAttrs) attrs;
      in
      builtins.length unexpectedAttrs == 0
    ) "userInfo should only contain name and email attributes")
  ];
}
