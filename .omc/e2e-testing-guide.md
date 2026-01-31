# E2E Testing Guide

## Overview

E2E (End-to-End) 테스트는 NixOS VM 또는 컨테이너에서 실행되는 전체 시스템 수준의 통합 테스트입니다. 이 가이드는 E2E 테스트 프레임워크의 구조, 실행 방법, 작성 방법을 설명합니다.

## 목차

1. [E2E 테스트 구조](#e2e-테스트-구조)
2. [테스트 실행 방법](#테스트-실행-방법)
3. [테스트 작성 방법](#테스트-작성-방법)
4. [테스트 헬퍼 함수](#테스트-헬퍼-함수)
5. [기존 E2E 테스트 목록](#기존-e2e-테스트-목록)
6. [CI/CD 통합](#cicd-통합)

---

## E2E 테스트 구조

```
tests/
├── e2e/                           # E2E 테스트 디렉토리
│   ├── default.nix                # E2E 테스트 진입점
│   ├── helpers.nix                # E2E 전용 헬퍼 함수
│   ├── complete-system-bootstrap-test.nix      # 전체 시스템 부트스트랩 테스트
│   ├── cross-platform-validation-test.nix      # 크로스 플랫폼 검증 테스트
│   ├── complete-vm-bootstrap-test.nix          # VM 부트스트랩 테스트
│   ├── cross-platform-build-test.nix           # 크로스 플랫폼 빌드 테스트
│   ├── fresh-machine-setup-test.nix            # 신규 머신 설정 테스트
│   └── ...                       # 기타 E2E 테스트들
└── lib/
    ├── e2e-helpers.nix            # E2E 테스트 공통 헬퍼 함수 (NEW)
    ├── test-helpers.nix           # 일반 테스트 헬퍼 함수
    └── platform-helpers.nix       # 플랫폼별 헬퍼 함수
```

### E2E 테스트의 특징

1. **VM 테스트**: `nixosTest`를 사용하여 실제 NixOS VM 환경에서 실행
2. **시간 소요**: 일반적으로 5-30분 소요 (컨테이너 테스트보다 느림)
3. **실제 환경 시뮬레이션**: 부팅, 서비스 시작, 사용자 로그인 등 실제 시나리오 검증
4. **Python 테스트 스크립트**: `testScript`는 Python 문법 사용

---

## 테스트 실행 방법

### 개별 E2E 테스트 실행

```bash
# 완전한 시스템 부트스트랩 테스트
nix build '.#e2e-tests.enhanced-e2e-tests.complete-system-bootstrap'

# 크로스 플랫폼 검증 테스트
nix build '.#e2e-tests.enhanced-e2e-tests.cross-platform-validation'

# 기존 VM 부트스트랩 테스트
nix build '.#e2e-tests.all.complete-vm-bootstrap'

# 크로스 플랫폼 빌드 테스트
nix build '.#e2e-tests.all.cross-platform-build'
```

### 모든 E2E 테스트 실행

```bash
# 모든 E2E 테스트 (주의: 매우 오래 걸림)
nix build '.#e2e-tests.all'
```

### 카테고리별 E2E 테스트 실행

```bash
# 크리티컬 기능 테스트만 (Priority 1)
nix build '.#e2e-tests.critical-features-only'

# 통합 테스트 (Priority 2)
nix build '.#e2e-tests.integration-tests'

# 운영 테스트 (Priority 3)
nix build '.#e2e-tests.operational-tests'

# 신규 E2E 테스트 (헬퍼 함수 사용)
nix build '.#e2e-tests.enhanced-e2e-tests'
```

### 테스트 결과 확인

```bash
# 테스트 실행 후 결과 확인
nix build '.#e2e-tests.enhanced-e2e-tests.complete-system-bootstrap' && \
  echo "Test passed!" || echo "Test failed!"

# 테스트 상세 로그 보기
nix build -v '.#e2e-tests.enhanced-e2e-tests.complete-system-bootstrap'

# 결과 symlink 확인
ls -l result
```

---

## 테스트 작성 방법

### 기본 E2E 테스트 템플릿

```nix
# tests/e2e/my-e2e-test.nix

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  lib ? pkgs.lib,
  system ? builtins.currentSystem or "x86_64-linux",
  self ? null,
  inputs ? { },
}:

let
  # nixosTest 가져오기
  nixosTest =
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });

  # E2E 헬퍼 함수 가져오기
  e2eHelpers = import ../lib/e2e-helpers.nix { inherit pkgs lib; };

in
nixosTest {
  name = "my-e2e-test";

  nodes = {
    # 테스트 머신 정의
    test-machine =
      { config, pkgs, ... }:
      {
        # 기본 설정
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "test-machine";
        networking.firewall.enable = false;

        virtualisation.cores = 2;
        virtualisation.memorySize = 2048;

        # Nix 설정
        nix.extraOptions = ''
          experimental-features = nix-command flakes
          accept-flake-config = true
        '';

        # 사용자 설정
        users.users.testuser = {
          isNormalUser = true;
          password = "test";
          extraGroups = [ "wheel" ];
        };

        # 시스템 패키지
        environment.systemPackages = with pkgs; [
          git
          vim
        ];

        security.sudo.wheelNeedsPassword = false;
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting My E2E Test...")

    # 테스트 케이스 1
    machine.succeed("""
      # 명령 실행
      git --version

      echo "✅ Test 1 passed"
    """)

    # 테스트 케이스 2: 파일 검증
    machine.succeed("""
      # 파일 생성
      echo "test content" > /tmp/test.txt

      # 파일 검증
      grep -q "test content" /tmp/test.txt

      echo "✅ Test 2 passed"
    """)

    # 테스트 케이스 3: 서비스 검증
    machine.succeed("""
      # 서비스 상태 확인
      systemctl status sshd | grep "active (running)"

      echo "✅ Test 3 passed"
    """)

    print("🎉 All tests passed!")
  '';
}
```

### 테스트 등록

`tests/e2e/default.nix`에 새 테스트를 등록합니다:

```nix
# tests/e2e/default.nix

{
  ...
  # 테스트 import
  myE2eTest = import ./my-e2e-test.nix {
    inherit lib pkgs system self;
  };

  ...
  # all 섹션에 추가
  all = {
    ...
    "my-e2e-test" = myE2eTest;
  };

  # 카테고리별로도 추가
  enhanced-e2e-tests = {
    ...
    "my-e2e-test" = myE2eTest;
  };
}
```

### 테스트 스크립트 작성 팁

1. **단계별 검증**: 각 테스트를 명확한 단계로 나누기
   ```python
   print("Phase 1: Installation")
   machine.succeed("...")
   print("Phase 2: Configuration")
   machine.succeed("...")
   ```

2. **명확한 성공/실패 메시지**
   ```python
   machine.succeed("""
     if [ condition ]; then
       echo "✅ Test passed"
     else
       echo "❌ Test failed"
       exit 1
     fi
   """)
   ```

3. **사용자 전환 명령어**
   ```python
   machine.succeed("""
     su - testuser -c '
       command here
     '
   """)
   ```

4. **파일 검증**
   ```python
   machine.succeed("""
     # 파일 존재 확인
     test -f /path/to/file

     # 내용 검증
     grep -q "pattern" /path/to/file
   """)
   ```

---

## 테스트 헬퍼 함수

### E2E 전용 헬퍼 (`tests/lib/e2e-helpers.nix`)

```nix
# E2E 헬퍼 import
e2eHelpers = import ../lib/e2e-helpers.nix { inherit pkgs lib; };

# 사용 가능한 함수
{
  # 기본 assertions
  assertTest = name: condition: message;
  assertFileExists = name: derivation: path;
  assertHasAttr = name: attrName: set;
  assertStringContains = name: needle: haystack;

  # 부트스트랩 워크플로우
  bootstrapWorkflow = { partitioning = ...; filesystems = ...; };
  validateBootstrapWorkflow = name;

  # 크로스 플랫폼 헬퍼
  getPlatformPath = darwinPath: linuxPath;
  getUserHomeDir = user;
  getPlatformConfigPath = configName: darwinSubPath: linuxSubPath;

  # Nix 관련
  assertNixBuilds = name: drvPath;
  assertFlakeEval = name: flakePath;
  assertNixosConfigEval = name: configPath;

  # 시스템 팩토리 검증
  validateMkSystemOutput = name: systemConfig: expectedType;
  validateSpecialArgs = name: specialArgs: requiredArgs;

  # 캐시 설정
  unifiedCacheSettings = { substituters = [...]; trusted-public-keys = [...]; };
  validateCacheSettings = name: cacheSettings;

  # Makefile 검증
  assertMakefileTarget = name: makefileContent: targetName;
  assertMakefileDependency = name: makefileContent: targetName: dependency;

  # 테스트 상수
  testUsers = ["baleen" "jito.hello" "testuser"];
  requiredBuildPackages = [git nix gnumake];
  stateVersion = "24.05";
}
```

### E2E 전용 헬퍼 (`tests/e2e/helpers.nix`)

```nix
# E2E 전용 헬퍼 import
e2eHelpers = import ./helpers.nix { inherit pkgs platformSystem; };

# 사용 가능한 함수
{
  # 모듈 import 검증
  canImport = path;
  canImportWith = path: args;

  # 플랫폼별 검증
  checkPlatformPath = darwinPath: linuxPath;
  checkPlatformScript = scriptBaseName;
  checkPlatformModule = darwinModule: linuxModule;

  # 패키지 검증
  allPackagesExist = packages;
  allPathsExist = paths;
  checkConfigStructure = basePath: requiredPaths;

  # 사용자 설정
  getUserHomeDir = user;

  # 테스트 상수
  constants = {
    testUsers = [...];
    requiredBuildPackages = [...];
    essentialDevTools = [...];
  };
}
```

---

## 기존 E2E 테스트 목록

### 새 E2E 테스트 (헬퍼 함수 활용)

| 테스트 | 파일 | 설명 | 카테고리 |
|--------|------|------|----------|
| Complete System Bootstrap | `complete-system-bootstrap-test.nix` | 전체 시스템 부트스트랩 과정 검증 | Priority 1 |
| Cross-Platform Validation | `cross-platform-validation-test.nix` | Darwin/NixOS 크로스 플랫폼 설정 검증 | Priority 1 |

### 기존 E2E 테스트

| 테스트 | 파일 | 설명 | 카테고리 |
|--------|------|------|----------|
| Fresh Machine Setup | `fresh-machine-setup-test.nix` | 신규 머신 설정 시나리오 | Real-world |
| Environment Replication | `environment-replication-test.nix` | 환경 복제 시나리오 | Real-world |
| Real Project Workflow | `real-project-workflow-test.nix` | 실제 프로젝트 워크플로우 | Real-world |
| Build Switch | `build-switch-test.nix` | 빌드 및 전환 검증 | Real-world |
| Multi-User Support | `multi-user-support-test.nix` | 멀티 유저 지원 검증 | Priority 1 |
| Cross-Platform Build | `cross-platform-build-test.nix` | 크로스 플랫폼 빌드 검증 | Priority 1 |
| System Factory Validation | `system-factory-validation-test.nix` | 시스템 팩토리 함수 검증 | Priority 1 |
| Cache Configuration | `cache-configuration-test.nix` | 캐시 설정 검증 | Priority 2 |
| Tool Integration | `tool-integration-test.nix` | 도구 통합 검증 | Priority 2 |
| Complete VM Bootstrap | `complete-vm-bootstrap-test.nix` | VM 부트스트랩 전체 과정 | Priority 2 |
| Service Management | `service-management-test.nix` | 서비스 관리 검증 | Priority 3 |
| Secret Management | `secret-management-test.nix` | 시크릿 관리 검증 | Priority 3 |
| Package Management | `package-management-test.nix` | 패키지 관리 검증 | Priority 3 |
| Machine Specific Config | `machine-specific-config-test.nix` | 머신별 설정 검증 | Priority 3 |
| Comprehensive Suite | `comprehensive-suite-validation-test.nix` | 종합 검증 모음 | All |

---

## CI/CD 통합

### GitHub Actions

E2E 테스트는 CI에서 Linux 환경에서만 실행됩니다:

```yaml
# .github/workflows/ci.yml

name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v25

      - name: Setup Cachix
        uses: cachix/cachix-action@v14
        with:
          name: baleen-nix
          authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}

      - name: Run E2E tests
        run: |
          export USER=${USER:-ci}
          nix build '.#e2e-tests.enhanced-e2e-tests' --impure
```

### 로컬에서 CI 테스트 실행

```bash
# CI와 동일한 환경에서 테스트
nix build '.#e2e-tests.enhanced-e2e-tests' --impure

# 특정 테스트만 실행
nix build '.#e2e-tests.enhanced-e2e-tests.complete-system-bootstrap' --impure
```

---

## 테스트 실행 시간

| 테스트 타입 | 예상 시간 | 비고 |
|-------------|-----------|------|
| 단위 테스트 (Unit) | 1-5초 | 가장 빠름 |
| 통합 테스트 (Integration) | 5-30초 | 중간 |
| E2E 테스트 | 5-30분 | 가장 느림 |
| 전체 테스트 스위트 | 30분-2시간 | 모든 테스트 |

### E2E 테스트 최적화 팁

1. **개별 테스트 실행**: 변경된 부분만 테스트
2. **병렬 실행**: 독립적인 테스트는 병렬로 실행 가능
3. **캐시 활용**: Cachix를 통해 빌드 결과 캐싱
4. **핵심 테스트 우선**: Priority 1 테스트 먼저 실행

---

## 디버깅

### 테스트 실패 시 디버깅

```bash
# 상세 로그 출력
nix build -v '.#e2e-tests.enhanced-e2e-tests.complete-system-bootstrap' --impure

# VM 상태 유지 (디버깅용)
# 테스트 코드에서 machine.wait_for_unit() 후 중단점 추가
```

### 일반적인 문제

1. **시간 초과**: VM 리소스 부족, `virtualisation.memorySize` 증가
2. **네트워크 오류**: `networking.firewall.enable = false` 확인
3. **권한 오류**: `security.sudo.wheelNeedsPassword = false` 확인
4. **파일 누락**: 경로 확인, `machine.succeed()` 내에서 검증

---

## 모범 사례

1. **테스트 독립성**: 각 테스트는 독립적으로 실행 가능해야 함
2. **명확한 이름**: 테스트 이름으로 목적을 바로 이해 가능해야 함
3. **적절한 그룹화**: 관련 테스트는 함께 그룹화
4. **문서화**: 복잡한 테스트는 주석 추가
5. **빠른 피드백**: 자주 실행되는 테스트는 빨리 끝나도록

---

## 추가 리소스

- [NixOS Testing](https://nixos.org/manual/nixos/stable/index.html#sec-testing)
- [Nixpkgs Tester Functions](https://nixos.org/manual/nixpkgs/stable/#ssec-meta-attributes)
- [Testing Python Tests](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
- [테스트 작성 가이드](./TESTING_GUIDE.md)
