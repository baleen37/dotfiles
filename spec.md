# Dotfiles Testing Infrastructure Improvement Spec

## Overview

Nix-based dotfiles의 안정성 강화를 위한 테스트 인프라 개선 사양서. 안전한 테스트 환경을 기반으로 단계별 검증 시스템 구축.

## Goals

- 빠른 사전 문제 파악
- 안정성이 보장된 코드 관리  
- 시스템 손상 방지
- Apple Silicon + Linux 플랫폼 지원

## Architecture

### Phase 1: 안전한 테스트 환경 구축

격리된 환경에서 시스템을 망가뜨리지 않는 테스트 모드 구현

**핵심 요구사항:**

- 완전 격리된 테스트 환경 (Docker/VM/Container)
- 실제 시스템에 영향 없는 dry-run 모드
- Apple Silicon, Linux 플랫폼 지원
- 테스트 실패 시 자동 cleanup

**구현 방식:**

- Nix 기반 격리 환경 생성
- Git worktree 활용한 안전한 테스트 공간
- 시스템 상태 백업/복구 메커니즘

### Phase 2: Pre-commit Hook 구현

빠른 구문 검사 및 기본 검증 (1-3분)

**검증 항목:**

- `nix flake check` 구문 검사
- YAML/JSON 구성 파일 문법 검증
- 기본 빌드 가능성 확인
- 심볼링크 경로 유효성

**실패 조건:**

- 구문 오류 발견
- 필수 파일 누락
- 순환 의존성 감지

### Phase 3: Pre-push Hook 구현  

완전한 테스트 실행 (10-30분)

**검증 항목:**

- 전체 시스템 빌드 (Apple Silicon + Linux)
- Home Manager 구성 검증
- 패키지 설치 확인
- 구성 파일 생성 테스트
- 심볼링크 생성 검증

**테스트 시나리오:**

- 새 시스템 초기 설치
- 기존 시스템 업데이트
- 플랫폼별 호환성

### Phase 4: GitHub Actions CI

Pre-push와 동일한 완전한 테스트를 CI 환경에서 실행

**환경 매트릭스:**

- macOS (Apple Silicon 시뮬레이션)  
- Ubuntu (Linux 대표)
- Container 기반 격리

**트리거:**

- Pull Request 생성/업데이트
- Main branch push
- Manual dispatch

## Technical Specifications

### 테스트 레벨 정의

**Level 1 (Pre-commit): 구문 검사**

```bash
nix flake check
yamllint configs/
jsonlint configs/
basic-link-check
```

**Level 2 (Pre-push/CI): 완전 테스트**

```bash
nix build .#homeConfigurations.macos
nix build .#homeConfigurations.linux  
integration-test-runner
configuration-validation
```

### 안전 모드 구현

**격리 환경:**

- Nix container 기반 샌드박스
- 임시 HOME 디렉토리 생성
- 실제 시스템 파일 보호

**백업/복구:**

- 테스트 전 현재 상태 스냅샷
- 실패 시 자동 원복
- 수동 복구 명령어 제공

### 에러 리포팅

**정보 제공:**

- 실패한 구체적 항목 (파일, 모듈)
- 상세한 에러 메시지
- 수정 가이드라인  
- 플랫폼별 차이점

**출력 형식:**

- 구조화된 JSON 로그
- 사람이 읽기 쉬운 요약
- GitHub Actions 결과 통합

## Implementation Priority

1. **Phase 1**: 안전한 테스트 환경 구축
2. **Phase 2**: Pre-commit 빠른 검사
3. **Phase 3**: Pre-push 완전 테스트  
4. **Phase 4**: GitHub Actions CI

## Success Criteria

- 시스템 손상 없이 테스트 가능
- 커밋 전 기본 오류 99% 차단
- 푸시 전 주요 오류 95% 차단  
- Apple Silicon, Linux 플랫폼 완전 지원
- 10분 내 완전 테스트 완료

## Risk Mitigation

- 테스트 환경 완전 격리로 시스템 보호
- 단계적 구현으로 점진적 안정성 확보
- 자동 백업/복구로 데이터 손실 방지
- 플랫폼별 조건부 실행으로 호환성 보장
