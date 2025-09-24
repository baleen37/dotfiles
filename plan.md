# Pre-commit Build-Switch Unit Validation System - Implementation Plan

**Branch**: main
**Date**: 2025-01-27
**Spec**: [spec.md](./spec.md)

## Technical Context

**Language**: Nix (primary), Bash (validation scripts)
**Dependencies**: Nix package manager, shellcheck, bash
**Testing Framework**: Nix derivation-based testing
**Integration**: Pre-commit hooks system

## Constitution Check

No constitution.md found - proceeding with standard implementation approach.

## Implementation Phases

### Phase 1: Setup & Foundation (1-2일)

**Goal**: Nix 검증 인프라 구축 및 기본 구조 생성

**Success Criteria**:

- `lib/validate-build-switch.nix` 파일 생성
- `flake.nix`에 `validate-build-switch` app 추가
- 기본 Nix derivation 동작 확인
- Pre-commit hook 설정 완료

**Tasks**:

- 1.1: Nix 검증 모듈 생성 (2-3시간)
- 1.2: Flake 통합 (1시간)
- 1.3: Pre-commit Hook 설정 (1-2시간)

### Phase 2: Core Implementation (2-3일)

**Goal**: 4가지 핵심 검증 로직 구현

**Success Criteria**:

- 스크립트 존재성 검증 100% 동작
- Bash/Nix 문법 검증 완료
- 의존성 검증 로직 구현
- 구조 무결성 검증 기본 동작

**Tasks**:

- 2.1: 스크립트 존재성 검증 (2-3시간)
- 2.2: Bash 문법 검증 (3-4시간)
- 2.3: Nix 표현식 검증 (2-3시간)
- 2.4: 구조 무결성 검증 (4-5시간)

### Phase 3: Integration & Testing (1-2일)

**Goal**: 전체 시스템 통합 및 최적화

**Success Criteria**:

- 30초 이내 실행 시간 달성
- 오프라인 모드 100% 동작
- 기존 pre-commit hooks와 충돌 없음
- 에러 메시지 사용자 친화적 포맷

**Tasks**:

- 3.1: 전체 시스템 통합 (2-3시간)
- 3.2: 오류 보고 시스템 (2-3시간)
- 3.3: Edge Case 처리 (2-3시간)
- 3.4: 기존 시스템과 통합 테스트 (1-2시간)

## Project Structure

```text
├── lib/
│   └── validate-build-switch.nix    # 새로 생성: 핵심 검증 로직
├── flake.nix                        # 수정: validate-build-switch app 추가
├── .pre-commit-config.yaml          # 수정: 새 hook 추가
└── tests/
    └── unit/
        └── test-validate-build-switch.bats  # 새로 생성: 단위 테스트
```

## Architecture Overview

**Core Components**:

1. **validate-build-switch.nix**: Nix derivation 기반 검증 엔진
2. **Validation Modules**:
   - Script existence checker
   - Bash syntax validator (shellcheck + bash -n)
   - Nix expression validator (nix eval)
   - Structure integrity checker
3. **Error Reporting**: 구조화된 오류 메시지 시스템
4. **Pre-commit Integration**: 기존 hooks와 병행 실행

**Data Flow**:

1. Pre-commit trigger → nix run .#validate-build-switch
2. Parallel validation of all components
3. Result aggregation and user-friendly error reporting
4. Success/failure exit codes for git workflow

## Dependencies & Risk Assessment

**Critical Dependencies**:

- Nix package manager (로컬 설치 필수)
- shellcheck package (Nix closure 포함)
- bash (시스템 기본)

**Key Risks**:

- Phase 2.4: 복잡한 의존성 분석 로직 구현
- Phase 3.1: 30초 성능 목표 달성
- Phase 3.4: 기존 pre-commit hooks와의 호환성

**Mitigation Strategies**:

- 단계별 점진적 구현 및 테스트
- 성능 측정 도구 조기 도입
- 기존 시스템 분석 선행

## Resource & Timeline Estimation

**Total Effort**: 20-30시간 (3-5일)
**Critical Path**: Phase 1 → Phase 2 → Phase 3 (순차 진행)
**Parallel Opportunities**: Phase 2 내 일부 작업들 병렬 수행 가능

**Timeline**:

- Day 1-2: Phase 1 완료
- Day 3-4: Phase 2 완료
- Day 5: Phase 3 완료

## Testing Strategy

**TDD Approach**:

- 각 검증 모듈별 failing test 먼저 작성
- Nix derivation 기반 테스트 실행
- Red-Green-Refactor 사이클 유지

**Test Coverage**:

- Unit tests: 각 검증 로직별 독립 테스트
- Integration tests: 전체 시스템 동작 테스트
- Edge case tests: 오프라인, 파일 누락 등
