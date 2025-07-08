# Development Guide

> **Version**: 2.0  
> **Last Updated**: 2025-07-08  
> **For**: dotfiles 리팩토링 프로젝트

## Getting Started

이 프로젝트는 **TDD(Test-Driven Development)** 방식으로 개발되며, **Nix** 기반의 시스템 구성 관리를 제공합니다.

### Prerequisites

- **Nix**: 패키지 매니저 및 빌드 시스템
- **Git**: 버전 관리
- **Shell**: Bash/Zsh 지원
- **yq**: YAML 파싱 (선택사항, 설정 로더에서 활용)

### Phase 4 Development Features (2025-07-08)

- **External Configuration System**: YAML-based configuration management
- **Unified Config Interface**: `get_unified_config()` for intelligent config access
- **Configuration Profiles**: Environment-specific settings (dev/prod)
- **Performance Optimization**: Configuration caching and state tracking
- **Advanced Directory Structure**: Modularized apps, scripts, and modules organization

### Quick Setup

```bash
# 1. 저장소 클론
git clone <repository-url>
cd dotfiles

# 2. 설정 검증
./scripts/validate-config

# 3. 테스트 실행
nix build .#checks.aarch64-darwin.test-all

# 4. 개발 환경 설정
nix develop
```

## TDD Workflow

이 프로젝트는 **Red-Green-Refactor** 사이클을 엄격히 따릅니다.

### 1. Red Phase: 실패하는 테스트 작성

```bash
# 새로운 기능을 위한 테스트 작성
# 위치: tests/unit/feature-name-unit.nix

{ pkgs, flake ? null, src ? ../. }:
pkgs.runCommand "feature-test" { } ''
  # 실패해야 하는 테스트 로직
  echo "❌ Feature not implemented yet"
  exit 1
''
```

### 2. Green Phase: 최소 구현

```bash
# 테스트를 통과시키는 최소한의 코드 작성
# 목표: 테스트 통과, 품질은 다음 단계에서
```

### 3. Refactor Phase: 코드 품질 개선

```bash
# 기능은 유지하면서 코드 품질 향상
# - 중복 제거
# - 가독성 개선
# - 성능 최적화
```

### TDD 예시

```bash
# Phase 1: Red - 실패하는 테스트
nix build .#checks.aarch64-darwin.new_feature_unit
# Expected: Build fails

# Phase 2: Green - 최소 구현
# 코드 작성 후...
nix build .#checks.aarch64-darwin.new_feature_unit  
# Expected: Build succeeds

# Phase 3: Refactor - 품질 개선
# 리팩토링 후 다시 테스트
nix build .#checks.aarch64-darwin.new_feature_unit
# Expected: Still succeeds
```

## Code Standards

### File Organization

```
dotfiles/
├── apps/           # 플랫폼별 실행 파일
├── config/         # 외부화된 설정 파일
├── docs/           # 문서
├── lib/            # Nix 라이브러리
├── modules/        # Nix 모듈
├── scripts/        # Shell 스크립트
│   ├── lib/        # 공통 라이브러리
│   └── platform/   # 플랫폼별 오버라이드
└── tests/          # 테스트 파일
    ├── unit/       # 단위 테스트
    ├── integration/ # 통합 테스트
    ├── e2e/        # End-to-End 테스트
    └── performance/ # 성능 테스트
```

### Naming Conventions

- **Files**: `kebab-case.nix`, `snake_case.sh`
- **Functions**: `camelCase` (Nix), `snake_case` (Shell)
- **Variables**: `UPPER_CASE` (환경변수), `camelCase` (Nix), `lower_case` (Shell)
- **Tests**: `*-unit.nix`, `*-integration.nix`, `*-e2e.nix`

### Environment Variables

```bash
# 환경변수는 기본값과 함께 정의
VARIABLE_NAME="${VARIABLE_NAME:-default_value}"

# 설정 파일에서 로드 가능
source scripts/lib/config-loader.sh
VALUE=$(load_config "config.yaml" ".path.to.value" "default")
```

## Testing Guidelines

### Test Categories

1. **Unit Tests**: 개별 함수/모듈 테스트
2. **Integration Tests**: 모듈 간 상호작용 테스트  
3. **E2E Tests**: 전체 워크플로우 테스트
4. **Performance Tests**: 성능 측정 테스트

### Test Structure

```nix
# tests/unit/example-unit.nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "example-test"
{
  buildInputs = with pkgs; [ bash ];
} ''
  echo "🧪 Example Test Suite"
  echo "==================="

  # Test 1: Basic functionality
  echo "📋 Test 1: Basic Test"
  # Test logic here

  if [[ condition ]]; then
    echo "✅ Test passed"
  else
    echo "❌ Test failed"
    exit 1
  fi

  echo "🎉 All tests completed!"
  touch $out
''
```

### Test Registration

```nix
# tests/default.nix에 테스트 추가
example_test = import ./unit/example-unit.nix { inherit pkgs flake; src = ../.; };

# lib/check-builders.nix에 테스트명 추가
"example_test"
```

## Contributing

### Workflow

1. **Issue 생성**: 기능 요청 또는 버그 리포트
2. **브랜치 생성**: `feature/description` 또는 `fix/description`
3. **TDD 개발**: Red-Green-Refactor 사이클
4. **테스트 확인**: 모든 테스트 통과 확인
5. **Pull Request**: 코드 리뷰 요청
6. **머지**: 승인 후 메인 브랜치에 병합

### Commit Messages

```bash
# 형식: type: description
feat: 새로운 기능 추가
fix: 버그 수정
refactor: 리팩토링 (기능 변경 없음)
test: 테스트 추가/수정
docs: 문서 업데이트
perf: 성능 개선
style: 코드 스타일 변경
```

### Code Review Checklist

- [ ] TDD 사이클을 올바르게 따랐는가?
- [ ] 모든 테스트가 통과하는가?
- [ ] 코드 스타일 가이드를 준수하는가?
- [ ] 문서가 업데이트되었는가?
- [ ] 기존 기능에 영향을 주지 않는가?

## Development Tools

### Useful Commands

```bash
# 설정 검증
./scripts/validate-config

# 특정 테스트 실행
nix build .#checks.aarch64-darwin.test_name

# 모든 테스트 실행
nix build .#checks.aarch64-darwin.test-all

# 빌드 및 설치
nix run #build-switch

# 개발 모드 진입
nix develop
```

### Debugging

```bash
# 상세한 빌드 로그
nix build --show-trace

# 테스트 로그 확인
nix-store -l /nix/store/...-test.drv

# 설정 값 확인
source scripts/lib/config-loader.sh
load_config "cache.yaml" ".cache.max_size_gb" "5"
```

## Project Phases

현재 프로젝트는 다음 단계로 진행됩니다:

- [x] **Phase 1**: 중복 코드 제거 및 통합
- [x] **Phase 2**: 대형 모듈 분해
- [x] **Phase 3**: 테스트 및 품질 향상  
- [🔄] **Phase 4**: 구조 최적화 (현재)
- [ ] **Phase 5**: 성능 최적화

각 Phase는 Sprint 단위로 세분화되어 TDD 방식으로 진행됩니다.

## Advanced Development Patterns

### Phase 4 Development Workflow

#### Configuration-Driven Development
```bash
# 1. Define configuration requirements first
# config/feature-settings.yaml
feature:
  enabled: true
  timeout: 30
  retry_count: 3

# 2. Write failing test for configuration usage
# tests/unit/feature-config-unit.nix

# 3. Implement configuration loading
source scripts/utils/config-loader.sh
feature_enabled=$(get_unified_config "feature_enabled" "false")
```

#### Modular Component Development
```bash
# 1. Create component in appropriate directory
# apps/common/feature-core.sh      # Shared logic
# apps/platforms/feature-darwin.sh # Platform-specific
# apps/targets/feature-aarch64.sh  # Architecture-specific

# 2. Follow TDD for each component
# Red → Green → Refactor for each module

# 3. Integration testing across modules
```

### Performance-Oriented Development

#### Configuration Optimization Patterns
```bash
# Cache configuration at component level
if [[ -z "$COMPONENT_CONFIG_LOADED" ]]; then
    load_component_config
    COMPONENT_CONFIG_LOADED=true
fi

# Use unified config for cross-component settings
shared_timeout=$(get_unified_config "timeout" "30")
```

#### Build Performance Testing
```bash
# Include performance validation in TDD cycle
# tests/performance/feature-performance.nix
start_time=$(date +%s%N)
# ... feature execution ...
end_time=$(date +%s%N)
execution_time=$(( (end_time - start_time) / 1000000 ))

# Assert performance requirements
if [[ $execution_time -gt 1000 ]]; then
    echo "❌ Performance regression: ${execution_time}ms > 1000ms"
    exit 1
fi
```

### Code Quality Standards

#### Documentation-Driven Development
1. **API Documentation First**: Write API docs before implementation
2. **Example-Driven**: Include working examples in all documentation
3. **Test Documentation**: Document test strategy and coverage

#### Configuration Best Practices
```bash
# ✅ Good: Use unified config with fallbacks
timeout=$(get_unified_config "build_timeout" "3600")

# ❌ Avoid: Hardcoded values
timeout=3600

# ✅ Good: Environment variable override support
export BUILD_TIMEOUT=7200  # User override
timeout=$(get_unified_config "timeout" "3600")  # Returns 7200

# ✅ Good: Profile-aware configuration
export CONFIG_PROFILE="development"
load_all_configs  # Loads development-specific settings
```

### Refactoring Guidelines

#### Configuration Externalization Pattern
```bash
# Before (Phase 3): Hardcoded values
CACHE_SIZE=5
SSH_DIR="/Users/$USER/.ssh"

# After (Phase 4): External configuration
source scripts/utils/config-loader.sh
cache_size=$(get_unified_config "max_size_gb" "5")
ssh_dir=$(get_unified_config "ssh_dir_darwin" "/Users/$USER/.ssh")
```

#### Module Extraction Pattern
```bash
# Before: Monolithic script
# apps/aarch64-darwin/apply (200+ lines)

# After: Modular architecture
# apps/common/apply-core.sh         # Shared logic
# apps/platforms/darwin.sh          # Platform-specific
# apps/targets/aarch64-darwin.sh    # Target-specific
# apps/aarch64-darwin/apply         # 11-line delegation
```

## Support

### Development Resources

- **Documentation**: `docs/` 디렉토리 참조
- **Examples**: `docs/examples/` 실용적 예제
- **Architecture**: `docs/ARCHITECTURE.md` 시스템 설계
- **Configuration**: `docs/CONFIGURATION-GUIDE.md` 설정 가이드
- **Migration**: `docs/MIGRATION-GUIDE.md` 업그레이드 가이드

### Community Support

- **Issues**: GitHub Issues 활용 (버그 리포트, 기능 요청)
- **Discussions**: 아키텍처 관련 논의
- **Wiki**: 커뮤니티 가이드 및 팁

### Development Tools Quick Reference

```bash
# Essential Development Commands
./scripts/check-config              # Validate configuration
nix develop                         # Enter development shell
nix build .#checks.aarch64-darwin.test-all  # Run all tests

# TDD Workflow Commands
nix build .#checks.aarch64-darwin.unit-tests      # Unit tests
nix build .#checks.aarch64-darwin.integration-tests  # Integration
nix build .#checks.aarch64-darwin.e2e-tests       # End-to-end

# Performance Monitoring
nix build .#checks.aarch64-darwin.performance-tests
nix run #build-switch --verbose                    # Detailed output
```
