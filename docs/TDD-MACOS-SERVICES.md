# TDD-Verified macOS Services Configuration

## Overview

이 문서는 TDD(Test-Driven Development) 방법론으로 구현된 macOS 키보드 단축키 충돌 해결 솔루션을 설명합니다.

## Problem

macOS 10.14.4 업데이트 이후 "Search man Page Index in Terminal" 서비스가 기본적으로 Shift+Cmd+A 키보드 단축키를 사용하여 다른 앱에서 해당 단축키를 사용할 수 없게 됩니다.

## TDD Implementation

### 🔴 Red Phase: 실패하는 테스트 작성

```bash
# 테스트 파일: tests/integration/test-macos-services-disabled.sh
./tests/integration/test-macos-services-disabled.sh
```

**테스트 내용**:

1. 'Search man Page Index in Terminal' 서비스가 비활성화되었는지 확인
2. Shift+Cmd+A 키 조합이 다른 앱에서 사용 가능한지 확인
3. 설정이 영구적으로 저장되었는지 확인

### 🟢 Green Phase: 최소 구현으로 테스트 통과

```bash
# 구현 스크립트: scripts/disable-macos-services.sh
./scripts/disable-macos-services.sh
```

**구현 내용**:

- 기존 NSServicesStatus 설정 확인
- 서비스가 이미 올바르게 비활성화되어 있음을 검증
- 설정 상태 리포팅

### 🔵 Refactor Phase: 코드 정리 및 개선

**Nix Home Manager 통합** (`modules/shared/home-manager.nix`):

```nix
# TDD로 검증된 macOS Services 비활성화
SERVICE_KEY="com.apple.Terminal - Search man Page Index in Terminal - searchManPages" # pragma: allowlist secret
# 현재 설정 상태 확인 로직
```

**Makefile 통합**:

```bash
make test-macos-services  # TDD 검증된 macOS Services 테스트
```

## Usage

### 테스트 실행

```bash
# TDD 테스트 실행
make test-macos-services
```

### 설정 적용

```bash
# Nix Home Manager를 통한 자동 적용
make build-switch
```

## Verification

### 수동 확인

```bash
# 서비스 상태 확인
defaults read pbs NSServicesStatus | grep -A 10 "Search man Page"

# 출력 예시:
# "enabled_context_menu" = 0;
# "enabled_services_menu" = 0;
```

### 자동 확인

```bash
# TDD 테스트로 자동 확인
./tests/integration/test-macos-services-disabled.sh
```

## Benefits

1. **Test-Driven**: 모든 기능이 테스트로 검증됨
2. **Automated**: Nix를 통한 자동 설정 관리
3. **Repeatable**: 동일한 환경에서 재현 가능
4. **Documented**: 명확한 문서화와 테스트 케이스

## Files

- **테스트**: `tests/integration/test-macos-services-disabled.sh`
- **설정**: `modules/shared/home-manager.nix`
- **문서**: `docs/TDD-MACOS-SERVICES.md`

## Platform Support

- ✅ aarch64-darwin (Apple Silicon Mac)
- ✅ x86_64-darwin (Intel Mac)
- ⏭️ Linux (자동 스킵)

## Conclusion

이 TDD 접근방식을 통해 macOS 키보드 단축키 충돌 문제를 안정적이고 재현 가능한 방식으로 해결했습니다.
