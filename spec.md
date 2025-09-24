# Pre-commit Build-Switch Unit Validation System

## Feature Overview

- **Name**: Pre-commit Build-Switch Unit Validation System
- **Description**: `nix run #build-switch` 실행 전 스크립트 구조/문법 오류를 사전 차단하는 pre-commit hook 시스템
- **User Value**: CI 파이프라인 진입 전 로컬에서 즉시 문제 발견 및 해결, 개발 생산성 향상

## User Stories & Scenarios

### Primary User Journey

1. 개발자가 build-switch 관련 코드 수정
2. `git commit` 실행
3. Pre-commit hook이 자동으로 Unit 검증 실행 (1-30초)
4. 문제 발견 시 상세한 오류 메시지와 수정 방법 제시
5. 모든 검증 통과 후 커밋 완료

### Edge Cases

- 네트워크 없는 환경에서도 오프라인 검증 가능
- 일부 스크립트 누락 시 자동 복구 제안
- 권한 문제 발생 시 해결책 안내

### Success Criteria

- Pre-commit hook 실행 시간 30초 이내
- 스크립트 문법 오류 100% 차단
- CI 파이프라인 진입 전 90% 이상 문제 사전 발견

## Requirements

### Functional Requirements

#### 1. 스크립트 존재성 검증

필수 스크립트 파일들 존재 확인:

- `scripts/build-switch-common.sh`
- `scripts/lib/*.sh` (핵심 라이브러리들)
- `lib/platform-system.nix` 내 build-switch 정의

#### 2. 문법 검증

Bash/Nix 스크립트 구문 오류 탐지:

- `bash -n` 구문 검사
- `nix eval` 문법 검증
- Shell 함수 정의 완성도 확인

#### 3. 의존성 검증

필수 도구 및 라이브러리 가용성 확인:

- Nix 설치 상태
- Home Manager 접근성
- 필수 환경 변수 설정

#### 4. 구조 무결성 검증

스크립트 간 호출 관계 검증:

- 함수 정의와 호출 일치성
- 상호 의존성 순환 참조 확인
- 로깅 시스템 연동 상태

### Non-functional Requirements

- **성능**: Pre-commit hook 실행 시간 30초 이내
- **안정성**: 네트워크 장애 시에도 오프라인 검증 가능
- **사용성**: 명확한 오류 메시지와 수정 방법 제시
- **확장성**: 새로운 스크립트 추가 시 자동 탐지 및 검증

### Constraints

- Git pre-commit hook 환경에서 실행
- 로컬 개발 환경 리소스만 사용
- CI 파이프라인과 독립적으로 동작

## Implementation Scope

### In Scope

- Pre-commit hook 스크립트 개발
- Unit 레벨 검증 로직 구현
- 오류 진단 및 해결 가이드 시스템
- 기존 `.pre-commit-config.yaml`에 통합

### Out of Scope

- 실제 build-switch 실행 테스트 (Integration/E2E 영역)
- CI 파이프라인 수정
- GUI 애플리케이션 상태 검증
- 성능 모니터링 및 최적화

## Dependencies & Assumptions

### Dependencies

- 기존 pre-commit 인프라 (`.pre-commit-config.yaml`)
- Nix 패키지 매니저 설치
- Git 저장소 구조 유지

### Assumptions

- 개발자가 로컬에 Nix 설치되어 있음
- Pre-commit hooks가 활성화되어 있음
- 프로젝트 디렉토리 구조 변경 없음
