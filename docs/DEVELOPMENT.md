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

## Support

- **Documentation**: `docs/` 디렉토리 참조
- **Issues**: GitHub Issues 활용
- **Discussions**: 아키텍처 관련 논의
