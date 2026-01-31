# tests/lib/common-assertions.nix
#
# 자주 사용하는 assertion 패턴 표준화
#
# 이 파일은 다음과 같은 일반적인 assertion 패턴을 제공합니다:
# - 속성 존재 검증
# - 리스트 포함 검증
# - 문자열 포함 검증
# - 타입 검증
# - 값 범위 검증
# - 설정 완전성 검증
#
# 사용 예시:
#   assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
#   assertions.assertAttrExists "has-git" config "programs.git"
#   assertions.assertListContains "has-vim" packages "vim"

{
  pkgs,
  lib,
}:

rec {
  # ===== 기본 assertion 함수 =====

  # 조건 검증 (기본 assertion)
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - condition: 검증할 조건
  #   - message: 실패 시 메시지
  #
  # Example:
  #   assertCondition "test-name" true "Should pass"
  assertCondition =
    name: condition: message:
    let
      displayMessage = if message != null then message else "Assertion failed: ${name}";
    in
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "PASS: ${name}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "FAIL: ${name}"
        echo "  ${displayMessage}"
        exit 1
      '';

  # ===== 속성 관련 assertions =====

  # 속성 존재 검증
  #
  # 객체에 특정 속성이 존재하는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - obj: 검사할 객체
  #   - attrName: 검증할 속성 이름
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertAttrExists "has-git" config "programs.git"
  #   assertAttrExists "has-home" hmConfig "home" "home attribute should exist"
  assertAttrExists =
    name: obj: attrName: message:
    assertCondition name (builtins.hasAttr attrName obj) (message);

  # 속성 경로 존재 검증
  #
  # 점으로 구분된 경로의 속성이 존재하는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - obj: 검사할 객체
  #   - attrPath: 속성 경로 (예: "programs.git.enable")
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertAttrPathExists "git-enabled" config "programs.git.enable"
  assertAttrPathExists =
    name: obj: attrPath: message:
    let
      pathParts = builtins.split "\\." attrPath;
      hasPath = builtins.foldl' (
        acc: part:
        if !acc then
          false
        else if builtins.isString part then
          builtins.hasAttr part obj
        else
          acc
      ) true pathParts;
    in
    assertCondition name (hasPath) (message);

  # 다중 속성 존재 검증
  #
  # 여러 속성이 모두 존재하는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - obj: 검사할 객체
  #   - attrNames: 검증할 속성 이름 목록
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertAttrsExist "git-settings" gitConfig ["userName" "userEmail" "aliases"]
  assertAttrsExist =
    name: obj: attrNames: message:
    let
      allExist = builtins.all (n: builtins.hasAttr n obj) attrNames;
      missing = builtins.filter (n: !builtins.hasAttr n obj) attrNames;
      defaultMsg = "Missing attributes: ${lib.concatStringsSep ", " missing}";
      errorMessage = if message != null then message else defaultMsg;
    in
    assertCondition name allExist errorMessage;

  # 속성 값 검증
  #
  # 속성이 존재하고 특정 값을 가지는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - obj: 검사할 객체
  #   - attrName: 속성 이름
  #   - expectedValue: 예상값
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertAttrEquals "git-enabled" gitConfig "enable" true
  assertAttrEquals =
    name: obj: attrName: expectedValue: message:
    let
      actualValue = if builtins.hasAttr attrName obj then obj.${attrName} else null;
      isEqual = actualValue == expectedValue;
      errorMessage =
        if message != null then
          message
        else
          "Attribute '${attrName}' should be ${toString expectedValue}, got ${toString actualValue}";
    in
    assertCondition name isEqual errorMessage;

  # ===== 리스트 관련 assertions =====

  # 리스트 포함 검증
  #
  # 리스트에 특정 요소가 포함되어 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - list: 검사할 리스트
  #   - element: 검증할 요소
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertListContains "has-vim" packages "vim"
  assertListContains =
    name: list: element: message:
    let
      isContained = builtins.any (e: e == element) list;
      errorMessage = if message != null then message else "List should contain '${toString element}'";
    in
    assertCondition name isContained errorMessage;

  # 다중 요소 포함 검증
  #
  # 리스트에 여러 요소가 모두 포함되어 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - list: 검사할 리스트
  #   - elements: 검증할 요소 목록
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertListContainsAll "has-dev-tools" packages ["git" "vim" "tmux"]
  assertListContainsAll =
    name: list: elements: message:
    let
      allContained = builtins.all (e: builtins.any (l: l == e) list) elements;
      missing = builtins.filter (e: !builtins.any (l: l == e) list) elements;
      errorMessage =
        if message != null then
          message
        else
          "Missing elements: ${lib.concatStringsSep ", " (map toString missing)}";
    in
    assertCondition name allContained errorMessage;

  # 리스트가 비어있지 않은지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - list: 검사할 리스트
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertListNotEmpty "has-packages" config.packages
  assertListNotEmpty =
    name: list: message:
    assertCondition name (builtins.length list > 0) (message);

  # 리스트 길이 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - list: 검사할 리스트
  #   - expectedLength: 예상 길이
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertListLength "aliases-count" gitAliases 5
  assertListLength =
    name: list: expectedLength: message:
    let
      actualLength = builtins.length list;
      isEqual = actualLength == expectedLength;
      errorMessage =
        if message != null then
          message
        else
          "List length should be ${toString expectedLength}, got ${toString actualLength}";
    in
    assertCondition name isEqual errorMessage;

  # ===== 문자열 관련 assertions =====

  # 문자열 포함 검증
  #
  # 문자열에 특정 부분 문자열이 포함되어 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - str: 검사할 문자열
  #   - substring: 검증할 부분 문자열
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertStringContains "has-email" userInfo.email "@"
  assertStringContains =
    name: str: substring: message:
    assertCondition name (lib.hasInfix substring str) (message);

  # 문자열 접두사 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - str: 검사할 문자열
  #   - prefix: 예상 접두사
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertStringStartsWith "home-dir-darwin" homeDir "/Users/"
  assertStringStartsWith =
    name: str: prefix: message:
    assertCondition name (lib.hasPrefix prefix str) (message);

  # 문자열 접미사 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - str: 검사할 문자열
  #   - suffix: 예상 접미사
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertStringEndsWith "config-file" file ".nix"
  assertStringEndsWith =
    name: str: suffix: message:
    assertCondition name (lib.hasSuffix suffix str) (message);

  # 문자열 정규식 매칭 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - str: 검사할 문자열
  #   - pattern: 정규식 패턴
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertStringMatches "email-format" email "^[^@]+@[^@]+\\.[^@]+$"
  assertStringMatches =
    name: str: pattern: message:
    assertCondition name (builtins.match pattern str != null) (message);

  # ===== 타입 관련 assertions =====

  # 타입 검증
  #
  # 값의 타입이 예상 타입과 일치하는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - value: 검사할 값
  #   - expectedType: 예상 타입 ("string", "int", "bool", "list", "set", "lambda")
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertType "username-type" userInfo.name "string"
  assertType =
    name: value: expectedType: message:
    let
      actualType = builtins.typeOf value;
      isEqual = actualType == expectedType;
      errorMessage =
        if message != null then message else "Type should be ${expectedType}, got ${actualType}";
    in
    assertCondition name isEqual errorMessage;

  # 널이 아닌 값 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - value: 검사할 값
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertNotNull "username-not-null" userInfo.userName
  assertNotNull =
    name: value: message:
    assertCondition name (value != null) (message);

  # ===== 값 범위 assertions =====

  # 숫자 범위 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - value: 검사할 숫자
  #   - min: 최소값 (포함)
  #   - max: 최대값 (포함)
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertInRange "port-number" port 1024 65535
  assertInRange =
    name: value: min: max: message:
    assertCondition name (value >= min && value <= max) (message);

  # 양수 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - value: 검사할 값
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertPositive "package-count" packagesCount
  assertPositive =
    name: value: message:
    assertCondition name (value > 0) (message);

  # 음수가 아닌 값 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - value: 검사할 값
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertNonNegative "file-size" fileSize
  assertNonNegative =
    name: value: message:
    assertCondition name (value >= 0) (message);

  # ===== 설정 완전성 assertions =====

  # 필수 속성 검증
  #
  # 객체가 필수 속성들을 모두 가지고 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - obj: 검사할 객체
  #   - requiredAttrs: 필수 속성 목록
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertRequiredAttrs "user-info-complete" userInfo ["name" "email"]
  assertRequiredAttrs =
    name: obj: requiredAttrs: message:
    let
      missing = builtins.filter (attr: !builtins.hasAttr attr obj) requiredAttrs;
      allPresent = builtins.length missing == 0;
      errorMessage =
        if message != null then
          message
        else
          "Missing required attributes: ${lib.concatStringsSep ", " missing}";
    in
    assertCondition name allPresent errorMessage;

  # 설정 객체 검증
  #
  # 설정 객체가 최소한의 구조를 가지고 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - config: 검사할 설정
  #   - requiredSections: 필수 섹션 목록
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertConfigStructure "home-manager-valid" hmConfig ["home" "xdg" "programs"]
  assertConfigStructure =
    name: config: requiredSections: message:
    let
      missing = builtins.filter (section: !builtins.hasAttr section config) requiredSections;
      allPresent = builtins.length missing == 0;
      errorMessage =
        if message != null then
          message
        else
          "Missing required config sections: ${lib.concatStringsSep ", " missing}";
    in
    assertCondition name allPresent errorMessage;

  # ===== 논리 assertions =====

  # AND 조건 검증
  #
  # 모든 조건이 참인지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - conditions: 조건 목록
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertAll "user-valid" [
  #     (userInfo.name != null)
  #     (userInfo.email != null)
  #     (lib.hasInfix "@" userInfo.email)
  #   ]
  assertAll =
    name: conditions: message:
    let
      allTrue = builtins.all (c: c) conditions;
    in
    assertCondition name allTrue (message);

  # OR 조건 검증
  #
  # 적어도 하나의 조건이 참인지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - conditions: 조건 목록
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertAny "editor-installed" [
  #     (hasPackage "vim")
  #     (hasPackage "neovim")
  #     (hasPackage "emacs")
  #   ]
  assertAny =
    name: conditions: message:
    let
      anyTrue = builtins.any (c: c) conditions;
    in
    assertCondition name anyTrue (message);

  # ===== 특수 목적 assertions =====

  # 이메일 형식 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - email: 검사할 이메일 주소
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertEmailFormat "user-email" userInfo.email
  assertEmailFormat =
    name: email: message:
    let
      # 기본 이메일 형식 검증 (간단한 정규식)
      emailPattern = "^[^@]+@[^@]+\\.[^@]+$";
      isValid = builtins.match emailPattern email != null;
      errorMessage = if message != null then message else "Email '${email}' has invalid format";
    in
    assertCondition name isValid errorMessage;

  # 경로 존재 검증 (문자열 패턴)
  #
  # 경로가 유효한 형식인지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - path: 검사할 경로
  #   - message: 실패 시 메시지 (선택적)
  #
  # Example:
  #   assertPathValid "home-dir" homeDir
  assertPathValid =
    name: path: message:
    let
      # 절대 경로인지 확인
      isAbsolute = lib.hasPrefix "/" path;
      # 빈 경로가 아닌지 확인
      notEmpty = builtins.stringLength path > 0;
      isValid = isAbsolute && notEmpty;
      errorMessage = if message != null then message else "Path '${path}' is not a valid absolute path";
    in
    assertCondition name isValid errorMessage;
}
