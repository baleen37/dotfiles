# Bash 테스트 프레임워크 - Phase 2 통합 완료

## 개요

이 디렉토리는 dotfiles 프로젝트의 통합 Bash 테스트 프레임워크를 포함합니다. Phase 2에서 기존의 분산된 3개 라이브러리를 단일 테스트 코어로 통합했습니다.

## 통합 아키텍처

### 기존 (Phase 1)

```bash
# 개별적으로 로드해야 했던 라이브러리들
source "../lib/common.sh"         # 257라인
source "../lib/test-framework.sh" # 333라인  
source "../lib/mock-environment.sh" # 519라인
```

### 새로운 (Phase 2)

```bash
# 단일 진입점
source "../lib/test-core.sh"      # 모든 기능 포함 + 새로운 기능들
```

## 핵심 파일들

- **`tests/lib/test-core.sh`**: 통합 테스트 코어 (단일 진입점)
- **`tests/lib/test-lifecycle.sh`**: Bats 스타일 생명주기 관리 (선택적)
- **`tests/templates/test-template.sh`**: 새 테스트용 10라인 템플릿

## 새 테스트 작성법

### 1. 기본 템플릿 사용

```bash
#!/usr/bin/env bash
set -euo pipefail

# 테스트 코어 로드 (단일 진입점)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-core.sh"

# 테스트 스위트 초기화
test_suite_init "Your Test Suite Name"

# 환경 설정 (필요에 따라 선택)
setup_standard_test_environment "test-prefix"

# 테스트 케이스들
test_your_functionality() {
    start_test_group "기능 테스트"

    assert_equals "expected" "actual" "테스트 설명"

    end_test_group
}

# 테스트 실행
test_your_functionality

# 스위트 완료
test_suite_finish
```

### 2. 템플릿 파일 복사

```bash
cp tests/templates/test-template.sh tests/unit/test-your-feature.sh
# 템플릿 편집
```

## 환경 설정 옵션

### 표준 테스트 환경

```bash
setup_standard_test_environment "test-prefix"
# → TEST_DIR 전역 변수 설정됨
```

### Claude 전용 환경

```bash
setup_claude_test_environment "claude-test"
# → CLAUDE_SOURCE_DIR, CLAUDE_TARGET_DIR 설정됨
# → 모의 Claude 환경 자동 생성
```

### Nix 전용 환경

```bash
setup_nix_test_environment "nix-test" "project-name"
# → 모의 Nix 프로젝트 구조 생성
```

## 새로운 Assert 함수들

### 기존 함수들 (모두 지원)

- `assert_equals`, `assert_not_equals`, `assert_contains`
- `assert_file_exists`, `assert_dir_exists`
- `assert_command_success`, `assert_command_fails`

### 새로운 함수들

```bash
# Nix 관련
assert_nix_eval "expression" "expected" "테스트명"
assert_nix_file_eval "file.nix" "attribute" "expected" "테스트명"

# 파일 시스템
assert_symlink_target "link" "target" "테스트명"

# JSON (jq 필요)
assert_json_has_key "file.json" ".key" "테스트명"
assert_json_value "file.json" ".key" "expected" "테스트명"

# 패턴 매칭
assert_matches_pattern "text" "regex" "테스트명"

# 성능
performance_test "function_name" 1000 "성능 테스트"
```

## 조건부 테스트

### 플랫폼별 테스트

```bash
# Darwin에서만 실행
darwin_only_test test_macos_feature

# Linux에서만 실행
linux_only_test test_linux_feature

# CI 환경에서만 실행
ci_only_test test_ci_feature
```

### 조건부 Skip

```bash
# 조건이 참이면 건너뜀
skip_if "[[ ! -f required_file ]]" "필수 파일 없음"

# 명령어 없으면 건너뜀
skip_unless_command "jq" # jq가 없으면 건너뜀
```

## 테스트 그룹 관리

```bash
test_feature_group() {
    start_test_group "기능 그룹"

    assert_equals "a" "a" "첫 번째 테스트"
    assert_equals "b" "b" "두 번째 테스트"

    end_test_group
}
```

## 백워드 호환성

**모든 기존 테스트가 수정 없이 동작합니다.**

- 기존 `assert_test()` 함수 지원
- 기존 로깅 함수들 (`log_info`, `log_error` 등) 지원
- 기존 환경 설정 함수들 지원

## 실행 방법

```bash
# 개별 테스트 실행
./tests/unit/test-your-feature.sh

# 전체 테스트 실행
make test

# 핵심 테스트만 실행
make test-core
```

## 예제

### 기존 스타일 (여전히 동작함)

```bash
source "$SCRIPT_DIR/../lib/common.sh"
assert_test "[[ 'hello' == 'hello' ]]" "문자열 비교"
```

### 새로운 스타일 (권장)

```bash
source "$SCRIPT_DIR/../lib/test-core.sh"
test_suite_init "My Tests"
assert_equals "hello" "hello" "문자열 비교"
test_suite_finish
```

## 이점

1. **90% 중복 코드 제거**: 단일 진입점으로 통합
2. **표준화된 생명주기**: setup/teardown 패턴 통일
3. **향상된 Assert 함수들**: Nix, JSON, 성능 테스트 지원
4. **조건부 실행**: 플랫폼별, CI별 테스트 분기
5. **완전한 백워드 호환성**: 기존 27개 테스트 파일 무수정 지원
6. **Bats 베스트 프랙티스**: 생명주기 관리와 모듈화

## 마이그레이션

기존 테스트를 새 프레임워크로 마이그레이션하는 것은 선택사항입니다:

1. **즉시 이익**: 새 테스트는 새 프레임워크 사용
2. **점진적 마이그레이션**: 필요에 따라 기존 테스트 업데이트
3. **혼용 가능**: 새 스타일과 기존 스타일 혼용 가능

더 자세한 예제는 `tests/unit/test-core-integration.sh`와 `tests/unit/test-platform-system-new.sh`를 참조하세요.
