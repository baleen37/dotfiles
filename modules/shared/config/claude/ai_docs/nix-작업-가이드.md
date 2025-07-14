# Nix 작업 가이드

## 기본 원칙

### Nix Flake 기반 시스템
- **flake.nix**: 전체 시스템 설정의 중심
- **모듈 시스템**: 기능별 모듈로 구성된 계층적 구조
- **순수함수적 접근**: 모든 설정은 재현 가능하고 예측 가능해야 함

### 설정 검증 프로세스
```bash
# 1. 문법 검증
nix flake check --show-trace

# 2. 빌드 검증
nix build .#darwinConfigurations.aarch64-darwin.system --show-trace

# 3. 사전 검증 스크립트
./scripts/check-config
```

## 작업 단계별 가이드

### 1. 설정 변경 전 준비
```bash
# 현재 설정 상태 확인
nix flake show

# 기존 설정 백업
git stash push -m "backup before changes"

# 의존성 확인
nix flake metadata
```

### 2. 모듈 구조 이해
```
modules/
├── shared/           # 공통 설정
│   ├── config/      # 애플리케이션 설정
│   ├── packages/    # 패키지 목록
│   └── services/    # 서비스 설정
├── darwin/          # macOS 특화 설정
│   ├── system/      # 시스템 레벨 설정
│   └── homebrew/    # Homebrew 관리
└── linux/           # Linux 특화 설정
    ├── system/      # 시스템 레벨 설정
    └── services/    # 서비스 설정
```

### 3. 설정 변경 패턴

#### 새 패키지 추가
```nix
# modules/shared/packages/development.nix
{
  # 기존 패키지 목록 확인
  environment.systemPackages = with pkgs; [
    # 기존 패키지들...
    new-package  # 새 패키지 추가
  ];
}
```

#### 서비스 설정 변경
```nix
# modules/shared/services/example.nix
{
  # 기존 서비스 설정 확인
  services.example = {
    enable = true;
    # 기존 설정 유지하면서 새 설정 추가
    newOption = "value";
  };
}
```

## 플랫폼별 특화 설정

### macOS/Darwin 설정
```nix
# modules/darwin/system/defaults.nix
{
  system.defaults = {
    # macOS 시스템 기본값 설정
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;

    # 기존 설정 패턴 유지
    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = false;
    };
  };
}
```

### Linux 설정
```nix
# modules/linux/system/core.nix
{
  # Linux 특화 시스템 설정
  boot.loader.systemd-boot.enable = true;

  # 네트워크 설정
  networking.networkmanager.enable = true;
}
```

## 빌드 및 적용 프로세스

### 1. 안전한 빌드 프로세스
```bash
# Phase 1: 설정 검증
nix flake check --show-trace

# Phase 2: 빌드 테스트
nix build .#darwinConfigurations.aarch64-darwin.system --show-trace

# Phase 3: 설정 적용 (권한 주의)
nix run #build-switch
```

### 2. 빌드 실패 시 대응
```bash
# 상세 에러 확인
nix build .#target --show-trace --verbose

# 의존성 문제 확인
nix flake lock --update-input nixpkgs

# 캐시 문제 해결
nix store gc
```

## 패키지 관리

### 1. 패키지 검색
```bash
# 사용 가능한 패키지 검색
nix search nixpkgs package-name

# 특정 버전 확인
nix search nixpkgs --exact package-name
```

### 2. 패키지 추가 패턴
```nix
# 조건부 패키지 추가
environment.systemPackages = with pkgs; [
  # 기본 패키지
  git
  vim
] ++ lib.optionals stdenv.isDarwin [
  # macOS 전용 패키지
  mas
] ++ lib.optionals stdenv.isLinux [
  # Linux 전용 패키지
  systemd
];
```

### 3. 커스텀 패키지 정의
```nix
# packages/custom-package.nix
{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "custom-package";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = "sha256-hash";
  };

  # 빌드 과정 정의
  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp binary $out/bin/
  '';
}
```

## 설정 모듈화 전략

### 1. 기능별 모듈 분리
```nix
# modules/shared/config/development.nix
{ config, pkgs, ... }:

{
  # 개발 환경 설정만 포함
  environment.systemPackages = with pkgs; [
    # 개발 도구들
  ];

  # 개발 관련 서비스
  services.development = {
    enable = true;
  };
}
```

### 2. 조건부 설정 활용
```nix
# modules/shared/config/optional.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.development;
in {
  options.custom.development = {
    enable = lib.mkEnableOption "development tools";
  };

  config = lib.mkIf cfg.enable {
    # 개발 도구 설정
    environment.systemPackages = with pkgs; [
      # 개발 도구들
    ];
  };
}
```

## 트러블슈팅

### 1. 일반적인 빌드 오류
```bash
# 문법 오류 확인
nix flake check --show-trace

# 순환 의존성 확인
nix show-derivation .#target

# 의존성 업데이트
nix flake update
```

### 2. 권한 관련 오류
```bash
# Darwin 권한 문제
# - darwin-rebuild는 항상 sudo 필요
# - 시스템 활성화 단계에서 권한 요구

# 해결 방법: 사용자 수동 실행 가이드 제공
echo "다음 명령을 터미널에서 실행해주세요:"
echo "sudo nix run #build-switch"
```

### 3. 의존성 문제
```bash
# 의존성 트리 확인
nix why-depends .#target dependency

# 의존성 업데이트
nix flake lock --update-input input-name

# 의존성 충돌 해결
nix flake lock --override-input input-name github:owner/repo
```

## 성능 최적화

### 1. 빌드 캐시 활용
```nix
# nix.settings in flake.nix
{
  nix.settings = {
    # 바이너리 캐시 설정
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
```

### 2. 병렬 빌드 설정
```nix
{
  nix.settings = {
    # 병렬 빌드 활성화
    max-jobs = "auto";
    cores = 0;  # 모든 코어 사용

    # 빌드 성능 최적화
    build-cores = 0;
    max-silent-time = 3600;  # 1시간
  };
}
```

## 모범 사례

### 1. 설정 관리
- **작은 변경 단위**: 한 번에 하나의 기능만 변경
- **테스트 우선**: 빌드 성공 확인 후 적용
- **백업 유지**: 변경 전 현재 설정 백업
- **문서화**: 변경 사항과 이유 문서화

### 2. 모듈 설계
- **단일 책임**: 각 모듈은 하나의 기능만 담당
- **재사용성**: 플랫폼 간 공통 설정 분리
- **조건부 활성화**: 선택적 기능은 enable 옵션 제공
- **네이밍 일관성**: 기존 네이밍 패턴 유지

### 3. 성능 고려사항
- **빌드 시간**: 불필요한 의존성 추가 금지
- **메모리 사용량**: 대용량 패키지는 조건부 설치
- **네트워크 사용량**: 바이너리 캐시 적극 활용
- **디스크 사용량**: 정기적인 가비지 컬렉션

---

*Nix 시스템의 강력함과 복잡성을 고려하여 신중하게 접근하세요.*
