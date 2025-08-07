# Configuration Guide

> **Version**: 1.0
> **Last Updated**: 2025-07-08
> **Target**: Phase 4 Sprint 4.2 설정 외부화 완료

## Overview

이 프로젝트는 **외부화된 설정 시스템**을 통해 다양한 환경에서 유연하게 동작할 수 있도록 설계되었습니다. 모든 설정은 YAML 파일과 환경변수를 통해 관리됩니다.

## Configuration Files

### Directory Structure

```
config/
├── platforms.yaml     # 플랫폼별 설정
├── cache.yaml         # 캐시 관리 설정
├── network.yaml       # 네트워크 관련 설정
├── performance.yaml   # 성능 최적화 설정
└── security.yaml      # 보안 관련 설정
```

### Configuration Loading

설정은 다음 우선순위로 로드됩니다:

1. **환경변수** (최고 우선순위)
2. **YAML 설정 파일**
3. **코드 내 기본값** (최저 우선순위)

## Platform Settings

### platforms.yaml

```yaml
platforms:
  supported_systems:
    - "x86_64-darwin"
    - "aarch64-darwin"
    - "x86_64-linux"
    - "aarch64-linux"

  platform_configs:
    darwin:
      type: "darwin"
      rebuild_command: "darwin-rebuild"
      flake_prefix: "darwinConfigurations"
      platform_name: "Nix Darwin"

    linux:
      type: "linux"
      rebuild_command: "nixos-rebuild"
      flake_prefix: "nixosConfigurations"
      platform_name: "NixOS"
```

### Environment Variables

```bash
# 플랫폼 오버라이드
export PLATFORM_TYPE="darwin"        # 또는 "linux"
export ARCH="aarch64"                 # 또는 "x86_64"
export PLATFORM_SYSTEM="aarch64-darwin"
```

## Cache Configuration

### cache.yaml

```yaml
cache:
  local:
    max_size_gb: 5              # 로컬 캐시 최대 크기 (GB)
    cleanup_days: 7             # 캐시 정리 주기 (일)
    stat_file: "$HOME/.cache/nix-build-stats"
    cache_dir: "$HOME/.cache/nix"

  binary_caches:
    - "https://cache.nixos.org"
    - "https://nix-community.cachix.org"

  behavior:
    max_cache_size: "50G"       # Nix store 캐시 최대 크기
    min_free_space: "1G"        # 최소 여유 공간
    max_free_space: "10G"       # 최대 여유 공간
```

### Environment Variables

```bash
# 캐시 설정 오버라이드
export CACHE_MAX_SIZE_GB=10
export CACHE_CLEANUP_DAYS=14
export CACHE_STAT_FILE="$HOME/.nix-cache-stats"
export BINARY_CACHES="https://cache.nixos.org https://custom-cache.com"
```

## Network Settings

### network.yaml

```yaml
network:
  http:
    connections: 50             # 동시 HTTP 연결 수
    connect_timeout: 5          # 연결 타임아웃 (초)
    download_attempts: 3        # 다운로드 재시도 횟수

  repositories:
    nixpkgs: "github:nixos/nixpkgs/nixos-unstable"
    home_manager: "github:nix-community/home-manager"
    nix_darwin: "github:LnL7/nix-darwin/master"

  substituters:
    - url: "https://cache.nixos.org"
      public_key: "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    - url: "https://nix-community.cachix.org"
      public_key: "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
```

### Environment Variables

```bash
# 네트워크 설정 오버라이드
export HTTP_CONNECTIONS=100
export CONNECT_TIMEOUT=10
export DOWNLOAD_ATTEMPTS=5
```

## Performance Settings

### performance.yaml

```yaml
performance:
  build:
    max_jobs: "auto"            # 빌드 작업 수 ("auto" 또는 숫자)
    cores: 0                    # 사용할 코어 수 (0 = 모든 코어)
    parallel_builds: true

  memory:
    min_free: 1073741824        # 1GB (바이트)
    max_free: 10737418240       # 10GB (바이트)

  system:
    file_descriptors: 4096      # 파일 디스크립터 제한
    max_user_processes: 2048

  nix:
    sandbox: true
    auto_optimise_store: true
    max_substitution_jobs: 16
```

### Environment Variables

```bash
# 성능 설정 오버라이드
export MAX_JOBS=8
export BUILD_CORES=4
export MIN_FREE_SPACE=2147483648  # 2GB
```

## Security Settings

### security.yaml

```yaml
security:
  ssh:
    key_type: "ed25519"         # SSH 키 타입
    key_size: 256
    default_dir: "$HOME/.ssh"

  users:
    allowed_users: ["@wheel", "@admin"]
    trusted_users: ["root", "@wheel", "@admin"]

  sudo:
    refresh_interval: 240       # sudo 세션 갱신 간격 (초)
    session_timeout: 900        # 세션 타임아웃 (초)
    require_tty: false

  policies:
    allow_unfree: true
    allow_broken: false
    allow_unsupported: false
```

### Environment Variables

```bash
# 보안 설정 오버라이드
export SSH_KEY_TYPE="rsa"
export SSH_DIR="/custom/ssh/path"
export SUDO_REFRESH_INTERVAL=600
```

## Configuration Loading API

### Using config-loader.sh

```bash
# 설정 로더 로드
source scripts/utils/config-loader.sh

# 캐시 설정 로드
cache_size=$(load_cache_config "max_size_gb" "5")
cleanup_days=$(load_cache_config "cleanup_days" "7")

# 네트워크 설정 로드
connections=$(load_network_config "http_connections" "50")
timeout=$(load_network_config "connect_timeout" "5")

# 플랫폼 설정 로드
rebuild_cmd=$(load_platform_config "darwin" "rebuild_command" "darwin-rebuild")

# 보안 설정 로드
key_type=$(load_security_config "ssh_key_type" "ed25519")
```

### Direct YAML Loading

```bash
# yq를 사용한 직접 로드 (yq 설치 필요)
cache_size=$(yq eval '.cache.local.max_size_gb' config/cache.yaml)
binary_caches=$(yq eval '.cache.binary_caches[]' config/cache.yaml)
```

## Validation

### Configuration Validation

```bash
# 모든 설정 파일 검증
./scripts/validate-config

# 특정 설정 검증
./scripts/validate-config --config cache.yaml
```

### Validation Output

```
[INFO] Starting configuration validation
[INFO] Configuration directory: /path/to/config
✅ [SUCCESS] platforms.yaml syntax is valid
✅ [SUCCESS] cache.yaml syntax is valid
✅ [SUCCESS] network.yaml syntax is valid
✅ [SUCCESS] platforms.yaml is complete
✅ [SUCCESS] cache.yaml is complete
✅ [SUCCESS] All configuration validation checks passed!
```

## Environment-Specific Configurations

### Development Environment

```bash
# 개발용 설정
export CACHE_MAX_SIZE_GB=2
export CACHE_CLEANUP_DAYS=3
export HTTP_CONNECTIONS=20
```

### Production Environment

```bash
# 프로덕션용 설정
export CACHE_MAX_SIZE_GB=20
export CACHE_CLEANUP_DAYS=30
export HTTP_CONNECTIONS=100
export MAX_JOBS=16
```

### Testing Environment

```bash
# 테스트용 설정
export CACHE_MAX_SIZE_GB=1
export CACHE_CLEANUP_DAYS=1
export HTTP_CONNECTIONS=5
```

## Migration Guide

### From Hardcoded Values

기존에 하드코딩된 값들을 설정 파일로 마이그레이션:

```bash
# 이전: 하드코딩
CACHE_SIZE=5

# 이후: 환경변수 기본값
CACHE_SIZE="${CACHE_MAX_SIZE_GB:-5}"

# 설정 파일에서 로드
cache_size=$(load_cache_config "max_size_gb" "5")
```

### Backward Compatibility

- 모든 기존 환경변수는 계속 작동
- 기본값은 이전과 동일하게 유지
- 새로운 설정 시스템은 선택적 활용 가능

## Troubleshooting

### Common Issues

1. **설정 파일이 로드되지 않음**
   ```bash
   # config 디렉토리 확인
   ls -la config/

   # 파일 권한 확인
   chmod 644 config/*.yaml
   ```

2. **환경변수가 적용되지 않음**
   ```bash
   # 환경변수 확인
   env | grep CACHE

   # 설정 로더 디버깅
   bash -x scripts/utils/config-loader.sh
   ```

3. **YAML 구문 오류**
   ```bash
   # YAML 검증
   yq eval '.' config/cache.yaml

   # 또는 Python으로 검증
   python3 -c "import yaml; yaml.safe_load(open('config/cache.yaml'))"
   ```

### Support

설정 관련 문제는 다음을 참조하세요:

- **Validation**: `./scripts/validate-config`
- **Documentation**: `docs/` 디렉토리
- **Examples**: 각 설정 파일의 주석과 예시
