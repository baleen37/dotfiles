# API Reference

> **Version**: 1.0  
> **Last Updated**: 2025-07-08  
> **Target**: 개발자 및 고급 사용자

## Overview

이 문서는 dotfiles 프로젝트의 주요 API와 함수들에 대한 참조 가이드입니다. 모든 API는 **외부화된 설정 시스템**과 **모듈화된 아키텍처**를 기반으로 설계되었습니다.

## Configuration API

### config-loader.sh

설정 파일 로드 및 환경변수 관리를 위한 API입니다.

#### `load_config(config_file, key_path, default_value)`

YAML 설정 파일에서 값을 로드합니다.

**Parameters:**
- `config_file` (string): 설정 파일명 (예: "cache.yaml")
- `key_path` (string): YAML 경로 (예: ".cache.local.max_size_gb")  
- `default_value` (string): 기본값

**Returns:** 설정값 또는 기본값

**Example:**
```bash
source scripts/lib/config-loader.sh
cache_size=$(load_config "cache.yaml" ".cache.local.max_size_gb" "5")
```

#### `load_cache_config(key, default)`

캐시 관련 설정을 로드합니다.

**Parameters:**
- `key` (string): 설정 키 ("max_size_gb", "cleanup_days", "cache_dir", "binary_caches")
- `default` (string): 기본값

**Returns:** 캐시 설정값

**Example:**
```bash
max_size=$(load_cache_config "max_size_gb" "5")
cleanup_days=$(load_cache_config "cleanup_days" "7")
```

#### `load_network_config(key, default)`

네트워크 관련 설정을 로드합니다.

**Parameters:**
- `key` (string): 설정 키 ("http_connections", "connect_timeout", "download_attempts")
- `default` (string): 기본값

**Returns:** 네트워크 설정값

**Example:**
```bash
connections=$(load_network_config "http_connections" "50")
timeout=$(load_network_config "connect_timeout" "5")
```

#### `load_platform_config(platform, key, default)`

플랫폼별 설정을 로드합니다.

**Parameters:**
- `platform` (string): 플랫폼명 ("darwin", "linux")
- `key` (string): 설정 키 ("rebuild_command", "platform_name")
- `default` (string): 기본값

**Returns:** 플랫폼 설정값

**Example:**
```bash
rebuild_cmd=$(load_platform_config "darwin" "rebuild_command" "darwin-rebuild")
platform_name=$(load_platform_config "darwin" "platform_name" "Nix Darwin")
```

#### `load_security_config(key, default)`

보안 관련 설정을 로드합니다.

**Parameters:**
- `key` (string): 설정 키 ("ssh_key_type", "sudo_refresh_interval")
- `default` (string): 기본값

**Returns:** 보안 설정값

**Example:**
```bash
key_type=$(load_security_config "ssh_key_type" "ed25519")
refresh_interval=$(load_security_config "sudo_refresh_interval" "240")
```

#### `get_dotfiles_root()`

dotfiles 프로젝트의 루트 디렉토리를 찾습니다.

**Returns:** 프로젝트 루트 경로

**Example:**
```bash
root_dir=$(get_dotfiles_root)
echo "Project root: $root_dir"
```

## Cache Management API

### cache-management.sh

Nix 빌드 캐시 관리를 위한 API입니다.

#### Environment Variables

```bash
CACHE_MAX_SIZE_GB="${CACHE_MAX_SIZE_GB:-5}"
CACHE_CLEANUP_DAYS="${CACHE_CLEANUP_DAYS:-7}"
CACHE_STAT_FILE="${CACHE_STAT_FILE:-$HOME/.cache/nix-build-stats}"
BINARY_CACHES="${BINARY_CACHES:-https://cache.nixos.org https://nix-community.cachix.org}"
```

#### Functions

캐시 관리 함수들은 `scripts/lib/cache-management.sh`에 정의되어 있습니다:

- `init_cache_stats()`: 캐시 통계 초기화
- `update_cache_stats()`: 캐시 통계 업데이트
- `cleanup_old_cache()`: 오래된 캐시 정리
- `optimize_cache_usage()`: 캐시 사용량 최적화

## Build System API

### Build Logic API

#### Platform Detection

```bash
# Platform configuration loading
source apps/$PLATFORM_SYSTEM/config.sh

# Available variables:
# - PLATFORM_TYPE: "darwin" or "linux"
# - ARCH: "aarch64" or "x86_64"  
# - PLATFORM_SYSTEM: "aarch64-darwin", "x86_64-linux", etc.
```

#### Build Commands

```bash
# Platform-specific build commands
case "$PLATFORM_TYPE" in
  "darwin")
    REBUILD_COMMAND="darwin-rebuild"
    FLAKE_PREFIX="darwinConfigurations"
    ;;
  "linux")
    REBUILD_COMMAND="nixos-rebuild"
    FLAKE_PREFIX="nixosConfigurations"
    ;;
esac
```

## Nix Module API

### Conditional File Copy API

#### `conditional-file-copy.nix`

조건부 파일 복사를 위한 Nix 모듈입니다.

**Functions:**
- `conditionalFileCopy`: 메인 복사 함수
- `advanced.batchCopy`: 배치 복사 함수
- `modules.copyEngine`: 복사 엔진 모듈
- `modules.policyResolver`: 정책 해결 모듈
- `modules.changeDetector`: 변경 감지 모듈

**Example:**
```nix
{ lib, ... }:
let
  conditionalCopy = import ./lib/conditional-file-copy.nix { inherit lib; };
in {
  # 기본 사용
  home.file = conditionalCopy {
    source = ./config;
    target = ".config";
    condition = "always";
  };

  # 고급 사용
  home.file = conditionalCopy.advanced.batchCopy {
    copies = [
      { source = ./vscode; target = ".vscode"; }
      { source = ./git; target = ".gitconfig"; }
    ];
  };
}
```

### Platform Detection API

#### `platform-detector.nix`

플랫폼 감지 및 시스템 정보를 제공합니다.

**Functions:**
- `detectPlatform`: 현재 플랫폼 감지
- `getSupportedSystems`: 지원되는 시스템 목록
- `getPlatformConfig`: 플랫폼별 설정

**Example:**
```nix
{ lib, ... }:
let
  platformDetector = import ./lib/platform-detector.nix { inherit lib; };
  currentPlatform = platformDetector.detectPlatform;
in {
  # 플랫폼별 조건부 설정
  home.packages = lib.optionals (currentPlatform == "darwin") [
    pkgs.darwin-specific-package
  ];
}
```

### Configuration System API

#### `flake-config.nix`

Flake 설정을 위한 유틸리티입니다.

**Functions:**
- `mkFlakeConfig`: Flake 설정 생성
- `getPlatformSystems`: 플랫폼별 시스템 구성
- `getFlakeInputs`: Flake 입력 관리

#### `system-configs.nix`

시스템별 설정 빌더입니다.

**Functions:**
- `mkDarwinConfigurations`: macOS 설정 생성
- `mkNixosConfigurations`: Linux 설정 생성
- `mkAppConfigurations`: 애플리케이션 설정 생성

## Testing API

### Test Framework

#### Test Categories

1. **Unit Tests**: `tests/unit/*-unit.nix`
2. **Integration Tests**: `tests/integration/*-integration.nix`
3. **E2E Tests**: `tests/e2e/*-e2e.nix`
4. **Performance Tests**: `tests/performance/*-perf.nix`

#### Test Structure

```nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "test-name"
{
  buildInputs = with pkgs; [ bash coreutils ];
} ''
  echo "🧪 Test Suite Name"
  echo "=================="

  # Test logic here

  if [[ condition ]]; then
    echo "✅ Test passed"
  else
    echo "❌ Test failed"
    exit 1
  fi

  touch $out
''
```

#### Test Registration

```nix
# tests/default.nix
{
  test_name = import ./unit/test-name-unit.nix { inherit pkgs flake; src = ../.; };
}

# lib/check-builders.nix
coreTests = nixpkgs.lib.filterAttrs (name: _:
  builtins.elem name [
    # ... other tests
    "test_name"
  ]
) testSuite;
```

## Validation API

### Configuration Validation

#### `validate-config`

설정 파일 검증 스크립트입니다.

**Usage:**
```bash
# 모든 설정 검증
./scripts/validate-config

# 상세 로그와 함께 실행
./scripts/validate-config --verbose

# 특정 설정만 검증
./scripts/validate-config --config cache.yaml
```

**Exit Codes:**
- `0`: 검증 성공
- `1`: 검증 실패

**Functions:**
- `validate_yaml_syntax()`: YAML 구문 검증
- `validate_config_completeness()`: 설정 완전성 검증
- `validate_platform_configs()`: 플랫폼 설정 검증
- `validate_cache_configs()`: 캐시 설정 검증
- `validate_network_configs()`: 네트워크 설정 검증

## Error Handling API

### Error Management

#### `error-handler.nix`

Nix 레벨 오류 처리를 제공합니다.

**Functions:**
- `throwIf`: 조건부 오류 발생
- `warnIf`: 조건부 경고 출력
- `tryDefault`: 기본값과 함께 안전한 실행

**Example:**
```nix
{ lib, ... }:
let
  errorHandler = import ./lib/error-handler.nix { inherit lib; };
in {
  # 조건부 오류
  assertion = errorHandler.throwIf
    (config.invalid == true)
    "Invalid configuration detected";

  # 기본값과 함께 안전한 실행
  value = errorHandler.tryDefault
    config.risky_value
    "safe_default";
}
```

## Performance API

### Performance Configuration

#### `performance-config.nix`

성능 관련 설정을 제공합니다.

**Configuration Sections:**
- `buildConfig`: 빌드 성능 설정
- `cacheConfig`: 캐시 성능 설정  
- `networkConfig`: 네트워크 성능 설정
- `systemConfig`: 시스템 성능 설정

## Migration API

### Legacy Compatibility

#### Backward Compatibility Functions

기존 코드와의 호환성을 유지하는 함수들:

```bash
# 레거시 환경변수 지원
LEGACY_CACHE_SIZE="${CACHE_SIZE:-${CACHE_MAX_SIZE_GB:-5}}"

# 레거시 설정 경로 지원
if [[ -f "$HOME/.dotfiles-config" ]]; then
  source "$HOME/.dotfiles-config"
fi
```

## Extension API

### Custom Modules

새로운 모듈 작성을 위한 가이드라인:

```nix
# 모듈 템플릿
{ lib, config, pkgs, ... }:

with lib;

{
  options.custom.module = {
    enable = mkEnableOption "custom module";

    setting = mkOption {
      type = types.str;
      default = "default_value";
      description = "Description of the setting";
    };
  };

  config = mkIf config.custom.module.enable {
    # Module implementation
  };
}
```

## Support

### API Support

- **Documentation**: 이 API 참조 문서
- **Examples**: `docs/examples/` 디렉토리
- **Tests**: 각 API 함수별 테스트 케이스
- **Issues**: GitHub Issues를 통한 API 관련 문의
