# Testing Guide

이 가이드는 dotfiles 프로젝트에서 테스트를 작성하고 실행하는 방법을 설명합니다.

## 목차

1. [테스트 개요](#테스트-개요)
2. [테스트 헬퍼 함수](#테스트-헬퍼-함수)
3. [테스트 작성 가이드라인](#테스트-작성-가이드라인)
4. [공통 테스트 패턴](#공통-테스트-패턴)
5. [테스트 실행](#테스트-실행)
6. [모범 사례](#모범-사례)
7. [Troubleshooting](#troubleshooting)

---

## 테스트 개요

이 프로젝트는 TDD (Test-Driven Development) 방식을 따르며, 다음과 같은 테스트 유형을 지원합니다:

### 테스트 유형

- **Unit Tests** (`tests/unit/*-test.nix`): 빠른 단위 테스트 (2-5초)
- **Integration Tests** (`tests/integration/*-test.nix`): 통합 테스트
- **Container Tests** (`tests/containers/*.nix`): Linux 전용 NixOS 컨테이너 테스트
- **E2E Tests** (`tests/e2e/*.nix`): 엔드 투 엔드 테스트 (수동, 무거움)

### 테스트 자동 발견

`*-test.nix` 패턴을 따르는 모든 파일은 자동으로 발견되어 실행됩니다.

```bash
tests/
├── unit/
│   └── *-test.nix       # 자동 발견
├── integration/
│   └── *-test.nix       # 자동 발견
└── containers/
    └── *.nix            # 수동 포함 필요
```

---

## 테스트 헬퍼 함수

### 기본 헬퍼 (`tests/lib/test-helpers.nix`)

가장 기본이 되는 헬퍼 함수들을 제공합니다.

```nix
{ pkgs, lib, ... }:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  # 기본 assertion
  (helpers.assertTest "test-name" condition "failure message")

  # 속성 존재 확인
  (helpers.assertHasAttr "has-git" config "programs.git")

  # 파일 존재 확인
  (helpers.assertFileExists "vimrc" derivation ".vimrc")

  # 문자열 포함 확인
  (helpers.assertContains "has-email" email "@")
}
```

### 공통 Assertion (`tests/lib/common-assertions.nix`)

자주 사용하는 assertion 패턴을 표준화한 헬퍼입니다.

```nix
let
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
in
{
  # 속성 관련
  (assertions.assertAttrExists "has-git" config "programs.git")
  (assertions.assertAttrPathExists "git-enabled" config "programs.git.enable")
  (assertions.assertAttrsExist "git-settings" gitConfig ["userName" "userEmail"])
  (assertions.assertAttrEquals "git-enabled" gitConfig "enable" true)

  # 리스트 관련
  (assertions.assertListContains "has-vim" packages "vim")
  (assertions.assertListContainsAll "has-dev-tools" packages ["git" "vim" "tmux"])
  (assertions.assertListNotEmpty "has-packages" config.packages)
  (assertions.assertListLength "aliases-count" gitAliases 5)

  # 문자열 관련
  (assertions.assertStringContains "has-email" email "@")
  (assertions.assertStringStartsWith "home-dir" homeDir "/Users/")
  (assertions.assertStringEndsWith "config-file" file ".nix")
  (assertions.assertStringMatches "email-format" email "^[^@]+@[^@]+\\.[^@]+$")

  # 타입 관련
  (assertions.assertType "username-type" userInfo.name "string")
  (assertions.assertNotNull "username-not-null" userInfo.userName)

  # 값 범위
  (assertions.assertInRange "port-number" port 1024 65535)
  (assertions.assertPositive "package-count" packagesCount)
  (assertions.assertNonNegative "file-size" fileSize)

  # 설정 완전성
  (assertions.assertRequiredAttrs "user-info-complete" userInfo ["name" "email"])
  (assertions.assertConfigStructure "home-manager-valid" hmConfig ["home" "xdg" "programs"])

  # 논리
  (assertions.assertAll "user-valid" [
    (userInfo.name != null)
    (userInfo.email != null)
    (lib.hasInfix "@" userInfo.email)
  ])
  (assertions.assertAny "editor-installed" [
    (hasPackage "vim")
    (hasPackage "neovim")
  ])

  # 특수 목적
  (assertions.assertEmailFormat "user-email" userInfo.email)
  (assertions.assertPathValid "home-dir" homeDir)
}
```

### 테스트 패턴 (`tests/lib/patterns.nix`)

공통 테스트 패턴을 제공하는 헬퍼입니다.

```nix
let
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };
in
{
  # 파일 설정 테스트
  (patterns.testHomeFileConfig "vim-files" hmConfig {
    ".vimrc" = true;
    ".vim/plugin/statusline.vim" = true;
  })

  # 패키지 설치 테스트
  (patterns.testPackagesInstalled "dev-tools" hmConfig ["git" "vim" "tmux"])
  (patterns.testPackagesNotInstalled "no-heavy-packages" hmConfig ["emacs" "nano"])

  # 사용자 설정 테스트
  (patterns.testUsername "default-user" hmConfig "baleen")
  (patterns.testHomeDirectory "darwin-home" hmConfig "/Users/baleen")
  (patterns.testXDGEnabled "xdg-enabled" hmConfig true)

  # 시스템 설정 테스트
  (patterns.testDarwinDefaults "dock-settings" darwinConfig "dock" {
    autohide = true;
    tilesize = 48;
  })

  # 모듈 임포트 테스트
  (patterns.testModuleImports "tool-modules" hmConfig [
    "./git.nix"
    "./vim.nix"
    "./zsh.nix"
  ])

  # 프로그램 활성화 테스트
  (patterns.testProgramEnabled "git-enabled" hmConfig "git" true)

  # 설정 속성 테스트
  (patterns.testConfigAttr "git-enabled" config "programs.git.enable" true)

  # 복합 테스트
  (patterns.testBasicHomeConfig "hm-basic" hmConfig {
    checkPackages = true;
  })
  (patterns.testBasicGitConfig "git-basic" gitConfig {})
}
```

### 전문 헬퍼

- **Git** (`tests/lib/git-test-helpers.nix`): Git 설정 테스트 전용
- **Darwin** (`tests/lib/darwin-test-helpers.nix`): macOS 설정 테스트 전용
- **Mock Config** (`tests/lib/mock-config.nix`): 테스트용 Mock 설정 생성
- **Platform** (`tests/lib/platform-helpers.nix`): 플랫폼별 테스트 필터링

---

## 테스트 작성 가이드라인

### 기본 테스트 파일 구조

```nix
# tests/unit/my-feature-test.nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };

  # 테스트 대상 설정 로드
  myConfig = import ../../users/shared/my-feature.nix {
    inherit pkgs lib;
    config = { };
  };
in
{
  platforms = ["any"];  # 또는 ["darwin"], ["linux"]
  value = helpers.testSuite "my-feature" [
    # 여기에 테스트 작성
    (helpers.assertTest "basic-check" true "Should pass")
  ];
}
```

### 테스트 네이밍 규칙

- 파일명: `*-test.nix` 패턴 따르기
- 테스트 이름: `kebab-case` 사용
- 설명적이고 명확한 이름 사용

**좋은 예:**
```nix
"git-user-info-correct"
"vim-plugins-installed"
"home-directory-darwin"
```

**나쁜 예:**
```nix
"test1"
"check"
"t"
```

### 플랫폼별 테스트

플랫폼 속성을 사용하여 테스트가 실행될 플랫폼을 지정하세요:

```nix
{
  # 모든 플랫폼에서 실행
  platforms = ["any"];
  value = testSuite "cross-platform" [...];
}

{
  # macOS에서만 실행
  platforms = ["darwin"];
  value = testSuite "darwin-only" [...];
}

{
  # Linux에서만 실행
  platforms = ["linux"];
  value = testSuite "linux-only" [...];
}

{
  # macOS와 Linux에서 실행
  platforms = ["darwin" "linux"];
  value = testSuite "multi-platform" [...];
}
```

---

## 공통 테스트 패턴

### 1. 파일 설정 테스트

```nix
# Home Manager 파일이 올바르게 설정되었는지 확인
let
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };
in
patterns.testHomeFileConfig "vim-config" hmConfig {
  ".vimrc" = true;
  ".vim/plugin/statusline.vim" = true;
  ".vim/colors/mytheme.vim" = true;
}
```

### 2. 패키지 설치 테스트

```nix
# 필수 패키지가 설치되었는지 확인
let
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };
in
patterns.testPackagesInstalled "essential-tools" hmConfig [
  "git"
  "vim"
  "tmux"
  "zsh"
]

# 특정 패키지가 설치되지 않았는지 확인
patterns.testPackagesNotInstalled "no-conflicting-packages" hmConfig [
  "emacs"
  "nano"
]
```

### 3. 설정 값 검증

```nix
# 설정 속성이 올바른 값을 가지는지 확인
let
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
in
[
  (assertions.assertAttrEquals "git-enabled" gitConfig "enable" true)
  (assertions.assertAttrEquals "git-editor" gitSettings "core.editor" "vim")
  (assertions.assertAttrEquals "git-branch" gitSettings "init.defaultBranch" "main")
]
```

### 4. 사용자 정보 검증

```nix
# 사용자 정보가 올바르게 설정되었는지 확인
let
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;
in
[
  (assertions.assertRequiredAttrs "user-info-complete" userInfo ["name" "email"])
  (assertions.assertEmailFormat "email-valid" userInfo.email)
  (assertions.assertType "name-type" userInfo.name "string")
]
```

### 5. 모듈 임포트 테스트

```nix
# Home Manager가 올바른 모듈들을 임포트하는지 확인
let
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };
in
patterns.testModuleImports "tool-modules" hmConfig [
  "./git.nix"
  "./vim.nix"
  "./zsh.nix"
  "./tmux.nix"
  "./starship.nix"
]
```

### 6. 속성셋 비교 테스트

```nix
# 두 속성셋이 일치하는지 확인
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
helpers.assertAttrsEqual "git-aliases" expectedAliases actualAliases
  "Git aliases should match expected values"
```

---

## 테스트 실행

### 빠른 테스트 (기본)

```bash
# 모든 테스트 실행 (Linux: 컨테이너, macOS: 검증 모드)
make test

# 단위 테스트만 실행
make test-unit

# 통합 테스트만 실행
make test-integration

# 컨테이너 테스트 실행 (Linux 전용)
make test-containers
```

### 전체 테스트

```bash
# 전체 테스트 스위트 실행
make test-all
```

### 특정 테스트 실행

```bash
# 특정 테스트만 빌드
nix build '.#checks.aarch64-darwin.my-test-name' --impure

# 특정 플랫폼용 테스트
nix build '.#checks.x86_64-linux.my-test-name' --impure
```

### CI에서 테스트 실행

```bash
# CI 환경 변수 설정
export USER=${USER:-ci}
export TEST_USER=${TEST_USER:-testuser}

# 테스트 실행
make test-all
```

---

## 모범 사례

### 1. 테스트의 독립성

각 테스트는 독립적으로 실행 가능해야 합니다:

```nix
# 좋은 예: 독립적인 테스트
[
  (helpers.assertTest "test-1" condition1 "message 1")
  (helpers.assertTest "test-2" condition2 "message 2")
  (helpers.assertTest "test-3" condition3 "message 3")
]

# 나쁜 예: 테스트 간 의존성
let
  result1 = helpers.assertTest "test-1" condition1 "message 1";
in
[
  result1
  (helpers.assertTest "test-2" (result1 == something) "message 2")
]
```

### 2. 명확한 실패 메시지

실패 메시지는 문제를 명확히 설명해야 합니다:

```nix
# 좋은 예: 명확한 메시지
(helpers.assertTest "git-enabled"
  gitConfig.programs.git.enable
  "Git should be enabled in the configuration")

# 나쁜 예: 모호한 메시지
(helpers.assertTest "test1"
  gitConfig.programs.git.enable
  "failed")
```

### 3. 헬퍼 함수 활용

반복적인 코드는 헬퍼 함수로 추출하세요:

```nix
# 나쁜 예: 반복 코드
[
  (helpers.assertTest "has-git" (hasPackage "git") "git should be installed")
  (helpers.assertTest "has-vim" (hasPackage "vim") "vim should be installed")
  (helpers.assertTest "has-tmux" (hasPackage "tmux") "tmux should be installed")
]

# 좋은 예: 헬퍼 함수 사용
let
  patterns = import ../lib/patterns.nix { inherit pkgs lib; };
in
patterns.testPackagesInstalled "dev-tools" hmConfig ["git" "vim" "tmux"]
```

### 4. 플랫폼 고려

플랫폼별 차이를 고려하세요:

```nix
{
  # 플랫폼 명시
  platforms = ["darwin"];
  value = helpers.testSuite "darwin-features" [
    # Darwin 전용 테스트
    (helpers.assertTest "dock-autohide" ...)
  ];
}
```

### 5. 테스트 커버리지

필수 기능을 테스트하고 경계 조건을 확인하세요:

```nix
helpers.testSuite "user-validation" [
  # 일반 케이스
  (assertions.assertType "name-type" userInfo.name "string")

  # 경계 조건
  (assertions.assertStringContains "email-has-at" userInfo.email "@")
  (assertions.assertNonNegative "path-length" (builtins.stringLength path))

  # 에러 케이스
  (assertions.assertEmailFormat "email-valid" userInfo.email)
]
```

### 6. 성능 고려

무거운 테스트는 통합 또는 E2E로 분리하세요:

```nix
# 단위 테스트: 빠름
tests/unit/git-config-test.nix

# 통합 테스트: 중간
tests/integration/git-configuration-test.nix

# E2E 테스트: 느림, CI에서만 실행
tests/e2e/complete-vm-bootstrap-test.nix
```

---

## Troubleshooting

### 테스트가 발견되지 않음

**문제:** 테스트 파일이 `*-test.nix` 패턴을 따르지 않음

**해결:** 파일 이름을 `my-test.nix` 형식으로 변경

### 플랫폼에서 테스트 스킵

**문제:** 잘못된 플랫폼 속성

**해결:**
```nix
{
  platforms = ["darwin"];  # macOS에서만 실행
  value = testSuite "my-test" [...];
}
```

### "infinite recursion" 에러

**문제:** 순환 참조 또는 잘못된 import

**해결:** import 경로 확인 및 순환 참조 제거

### 테스트가 너무 느림

**문제:** 무거운 테스트가 단위 테스트에 포함됨

**해결:** 통합 또는 E2E 테스트로 이동

### Mock 설정 필요

**해결:** `mock-config.nix` 헬퍼 사용

```nix
let
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };
  testConfig = mockConfig.mkEmptyConfig;
in
# testConfig 사용하여 테스트
```

---

## 추가 리소스

- [CLAUDE.md](../CLAUDE.md): 프로젝트 개요 및 구조
- [tests/lib/test-helpers.nix](./lib/test-helpers.nix): 기본 헬퍼 함수
- [tests/lib/common-assertions.nix](./lib/common-assertions.nix): 공통 assertion
- [tests/lib/patterns.nix](./lib/patterns.nix): 테스트 패턴
- [tests/default.nix](./default.nix): 테스트 발견 및 실행 로직

---

테스트 작성에 도움이 필요하면 기존 테스트 파일들을 참고하세요:
- [tests/unit/lib-user-info-test.nix](./unit/lib-user-info-test.nix): 속성 검증 예제
- [tests/integration/home-manager-test.nix](./integration/home-manager-test.nix): 모듈 테스트 예제
- [tests/integration/git-configuration-test.nix](./integration/git-configuration-test.nix): Git 테스트 예제
