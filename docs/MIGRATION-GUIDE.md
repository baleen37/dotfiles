# Migration Guide

> **Version**: 1.0  
> **Target**: Phase 4로 업그레이드하는 사용자  
> **Last Updated**: 2025-07-08

## Overview

이 가이드는 Phase 4의 주요 변경사항에 대한 마이그레이션 지침을 제공합니다. Phase 4는 **구조 최적화**를 중심으로 한 대규모 아키텍처 개선이 포함되어 있습니다.

## 🚀 Phase 4 주요 변경사항

### 1. 디렉토리 구조 개선

**Before (Phase 3)**:

```text
apps/
├── aarch64-darwin/
├── x86_64-darwin/
├── aarch64-linux/
└── x86_64-linux/
    └── apply  # 중복된 로직
```

**After (Phase 4)**:

```text
apps/
├── common/              # 공통 로직
│   ├── apply-core.sh
│   └── check-keys-core.sh
├── platforms/           # 플랫폼별 구현
│   ├── darwin.sh
│   └── linux.sh
└── targets/             # 아키텍처별 설정
    ├── aarch64-darwin.sh
    └── x86_64-linux.sh
```

### 2. 설정 외부화 시스템

**Before**: 하드코딩된 설정값

```bash
# 이전 방식
CACHE_SIZE=5
SSH_DIR="/Users/$USER/.ssh"
TIMEOUT=3600
```

**After**: YAML 기반 외부 설정

```yaml
# config/build-settings.yaml
build:
  timeout: 3600
  parallel_jobs: 4

# config/paths.yaml
ssh_directories:
  darwin: "/Users/${USER}/.ssh"
  linux: "/home/${USER}/.ssh"
```

### 3. 통합 설정 인터페이스

**Before**: 개별 환경변수 관리

```bash
export CACHE_SIZE=5
export SSH_DIR="/Users/$USER/.ssh"
```

**After**: 통합 설정 API

```bash
source scripts/utils/config-loader.sh
cache_size=$(get_unified_config "cache_max_size" "5")
ssh_dir=$(get_config "path" "ssh_dir_darwin")
```

## 📋 마이그레이션 체크리스트

### 즉시 실행 (Breaking Changes 없음)

✅ **자동 호환성**: 기존 스크립트는 즉시 작동  
✅ **설정 폴백**: 환경변수가 우선 적용  
✅ **레거시 지원**: 기존 경로와 명령어 유지

### 선택적 마이그레이션

#### 1. 외부 설정 활용 (권장)

기존 환경변수 대신 YAML 설정 사용:

```bash
# Before
export CACHE_MAX_SIZE_GB=10
export BUILD_TIMEOUT=7200

# After - config/build-settings.yaml 편집
build:
  timeout: 7200
cache:
  max_size_gb: 10
```

#### 2. 새로운 설정 API 활용

```bash
# Before
if [[ -z "$CACHE_SIZE" ]]; then
  CACHE_SIZE=5
fi

# After
source scripts/utils/config-loader.sh
cache_size=$(get_unified_config "cache_max_size" "5")
```

#### 3. 프로필 시스템 활용

```bash
# 개발 환경
export CONFIG_PROFILE="development"

# 프로덕션 환경
export CONFIG_PROFILE="production"
```

## 🛠️ 단계별 마이그레이션

### Step 1: 현재 설정 백업

```bash
# 현재 환경변수 백업
env | grep -E "(CACHE|BUILD|SSH)" > ~/.dotfiles-backup-env

# 기존 설정 파일 백업
cp -r ~/.config/dotfiles ~/.config/dotfiles.backup
```

### Step 2: Phase 4 업그레이드

```bash
# 최신 코드 가져오기
git pull origin main

# 설정 검증
./scripts/check-config

# 빌드 및 적용
nix run #build-switch
```

### Step 3: 설정 검증

```bash
# 모든 테스트 실행
nix build .#checks.aarch64-darwin.test-all

# 설정 로딩 테스트
source scripts/utils/config-loader.sh
load_all_configs
```

### Step 4: 사용자 정의 설정 (선택사항)

```bash
# 사용자 정의 설정 생성
cp config/build-settings.yaml config/build-settings.local.yaml

# 로컬 설정 편집
vim config/build-settings.local.yaml
```

## 🔧 커스터마이징 가이드

### 기존 워크플로우 유지

기존 명령어와 스크립트는 변경 없이 계속 사용 가능:

```bash
# 여전히 작동하는 명령어들
nix run #build-switch
nix run #apply
./scripts/check-config
```

### 새로운 기능 활용

#### 1. 개발/프로덕션 프로필

```bash
# 개발 환경 (더 자세한 로그, 긴 타임아웃)
export CONFIG_PROFILE="development"
nix run #build-switch

# 프로덕션 환경 (최적화된 설정)
export CONFIG_PROFILE="production"
nix run #build-switch
```

#### 2. 고급 설정 커스터마이징

```yaml
# config/advanced-settings.yaml
development:
  debug_mode: true
  verbose_logging: true

build_optimization:
  enable_ccache: true
  parallel_builds: true
  memory_limit: "8G"

security:
  strict_permissions: true
  verify_signatures: true
```

#### 3. 플랫폼별 설정 오버라이드

```yaml
# config/platforms.yaml
platform_configs:
  darwin:
    rebuild_command: "darwin-rebuild"
    allow_unfree: true
    use_custom_cache: true
  linux:
    rebuild_command: "nixos-rebuild"
    allow_unfree: false
```

## 🚨 알려진 이슈 및 해결방법

### 이슈 1: 환경변수 충돌

**증상**: 설정이 예상과 다르게 로드됨

**해결방법**:

```bash
# 환경변수 우선순위 확인
echo $CACHE_MAX_SIZE_GB

# 설정 로딩 상태 확인
source scripts/utils/config-loader.sh
is_config_loaded && echo "Config loaded" || echo "Config not loaded"
```

### 이슈 2: 캐시 경로 변경

**증상**: 이전 캐시 디렉토리 사용

**해결방법**:

```bash
# 캐시 설정 확인
source scripts/utils/config-loader.sh
cache_dir=$(get_unified_config "cache_dir" "$HOME/.cache/nix")
echo "Cache directory: $cache_dir"
```

### 이슈 3: 권한 문제

**증상**: sudo 관련 오류

**해결방법**:

```bash
# sudo 설정 확인
source scripts/utils/config-loader.sh
sudo_timeout=$(get_unified_config "sudo_refresh_interval" "240")
echo "Sudo timeout: $sudo_timeout seconds"
```

## 🔄 롤백 가이드

Phase 4 변경사항을 되돌리고 싶은 경우:

### Option 1: Git 롤백

```bash
# 이전 안정 버전으로 되돌리기
git checkout [previous-stable-commit]
nix run #build-switch
```

### Option 2: 레거시 모드

```bash
# 환경변수로 Phase 3 방식 강제
export USE_LEGACY_CONFIG=true
export DISABLE_EXTERNAL_CONFIG=true
nix run #build-switch
```

### Option 3: 선택적 기능 비활성화

```yaml
# config/advanced-settings.yaml
legacy_mode:
  use_hardcoded_values: true
  disable_yaml_config: true
  disable_unified_interface: true
```

## 📞 지원 및 도움

### 문서 리소스

- **Architecture Guide**: `docs/ARCHITECTURE.md`
- **Configuration Guide**: `docs/CONFIGURATION-GUIDE.md`
- **Development Guide**: `docs/DEVELOPMENT.md`
- **API Reference**: `docs/API_REFERENCE.md`

### 문제 해결

1. **설정 검증**: `./scripts/check-config`
2. **로그 확인**: `nix run #build-switch --verbose`
3. **테스트 실행**: `nix build .#checks.aarch64-darwin.test-all`

### 커뮤니티 지원

- **GitHub Issues**: 버그 리포트 및 기능 요청
- **Discussions**: 아키텍처 및 설계 논의
- **Wiki**: 추가 예제 및 팁

## 🎯 다음 단계

Phase 4 마이그레이션 완료 후:

1. **Phase 5 준비**: 성능 최적화 기능 검토
2. **사용자 정의**: 개인 요구사항에 맞는 설정 커스터마이징
3. **피드백**: 새로운 기능에 대한 피드백 제공

Phase 4의 새로운 아키텍처를 통해 더 유연하고 확장 가능한 dotfiles 시스템을 경험해보세요!
