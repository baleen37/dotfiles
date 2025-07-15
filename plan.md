# Project Plan: Build-Switch 안정화 및 테스트 코드 보강

## 1. Executive Summary
이 프로젝트는 `nix run .#build-switch` 명령어의 안정화와 향후 유사한 문제를 예방하기 위한 포괄적인 테스트 코드 보강을 목표로 합니다. 현재 REBUILD_COMMAND_PATH 경로 문제로 인한 실행 실패를 해결하고, TDD 접근법을 통해 견고한 테스트 인프라를 구축하여 시스템 안정성을 확보합니다.

## 2. Technology Stack
### Options Analysis
- **Option 1: Quick Fix Approach**
  - **Benefits:** 빠른 문제 해결, 최소한의 변경
  - **Trade-offs:** 근본적 문제 해결 부족, 향후 유사 이슈 재발 가능성

- **Option 2: Comprehensive TDD Refactoring**
  - **Benefits:** 근본적 문제 해결, 강력한 테스트 커버리지, 장기적 안정성
  - **Trade-offs:** 더 많은 개발 시간 필요, 복잡한 테스트 인프라

- **Option 3: Phased Stabilization with Enhanced Testing**
  - **Benefits:** 즉시 문제 해결 + 점진적 안정화, 위험 최소화, 체계적 접근
  - **Trade-offs:** 중간 수준의 시간 투자

### Recommendation
**Chosen Stack:** Phased Stabilization with Enhanced Testing (Option 3)
**Rationale:** 즉시 사용자 문제를 해결하면서도 장기적 안정성을 확보하는 균형잡힌 접근법입니다. TDD를 통한 체계적 테스트 보강으로 향후 회귀를 방지하고, 단계적 접근으로 위험을 최소화합니다.

## 3. High-Level Architecture
현재 build-switch 아키텍처의 개선된 구조:

```
apps/
├── aarch64-darwin/build-switch     # 플랫폼별 엔트리포인트
├── x86_64-linux/build-switch       # 크로스 플랫폼 지원
└── common/                         # 공통 설정 및 유틸리티

scripts/
├── build-switch-common.sh          # 메인 로직 (개선됨)
├── lib/
│   ├── build-logic.sh             # 핵심 빌드 로직 (강화됨)
│   ├── error-handling.sh          # 오류 처리 (신규)
│   └── path-resolver.sh           # 경로 해결 (신규)
└── utils/
    ├── pre-flight-check.sh        # 사전 검증 (신규)
    └── fallback-handler.sh        # 대체 실행 경로 (신규)

tests/
├── unit/                          # 단위 테스트 (확장)
├── integration/                   # 통합 테스트 (신규)
├── e2e/                          # 엔드투엔드 테스트 (강화)
└── regression/                    # 회귀 테스트 (신규)
```

## 4. Project Phases & Sprints

### Phase 1: 즉시 문제 해결 (Hotfix)
- **Goal:** `nix run .#build-switch` 명령어가 정상 동작하도록 긴급 수정
- **Estimated Duration:** 1일
- **Sprint 1.1:** REBUILD_COMMAND_PATH 경로 문제 수정
- **Sprint 1.2:** Combined 모드 워크플로 개선
- **Sprint 1.3:** 기본 오류 처리 강화

### Phase 2: 테스트 인프라 구축
- **Goal:** 포괄적인 테스트 커버리지로 향후 회귀 방지
- **Estimated Duration:** 3일
- **Sprint 2.1:** 회귀 테스트 케이스 작성 (현재 버그 시나리오)
- **Sprint 2.2:** 통합 테스트 확장 (시스템 상태별 테스트)
- **Sprint 2.3:** E2E 테스트 시나리오 보강 (다양한 환경)

### Phase 3: 견고성 향상
- **Goal:** build-switch 시스템의 전반적 안정성 및 복구 능력 강화
- **Estimated Duration:** 2일
- **Sprint 3.1:** 사전 검증 시스템 구현
- **Sprint 3.2:** 대체 실행 경로 구현
- **Sprint 3.3:** 향상된 오류 메시지 및 복구 가이드

### Phase 4: 성능 및 모니터링 강화
- **Goal:** 현재 2% 캐시 적중률 개선 및 성능 모니터링 고도화
- **Estimated Duration:** 2일
- **Sprint 4.1:** 캐시 최적화 전략 구현
- **Sprint 4.2:** 성능 모니터링 대시보드 구축
- **Sprint 4.3:** 알림 및 자동 복구 시스템

## 5. Key Milestones & Deliverables
- **[Day 1] Hotfix Complete:** `nix run .#build-switch` 정상 동작
- **[Day 4] Test Infrastructure:** 90%+ 테스트 커버리지 달성
- **[Day 6] Robustness Enhanced:** 자동 복구 기능 완성
- **[Day 8] Performance Optimized:** 캐시 적중률 50%+ 달성

## 6. Dependencies
- **Sprint 1.1 → Sprint 1.2:** 경로 수정 후 워크플로 개선 가능
- **Sprint 2.1 → Sprint 2.2:** 회귀 테스트 완성 후 통합 테스트 확장
- **Sprint 3.1 → Sprint 3.2:** 사전 검증 로직 완성 후 대체 경로 구현

## 7. Risk Assessment & Mitigation

| Risk Description | Likelihood | Impact | Mitigation Strategy |
|---|---|---|---|
| 수정 중 기존 기능 손상 | Low | High | TDD 접근법, 각 변경사항마다 테스트 실행 |
| 플랫폼 호환성 문제 | Medium | Medium | 다중 플랫폼 테스트 자동화, 점진적 배포 |
| 성능 저하 | Low | Medium | 성능 벤치마크 테스트, 병렬 실행 유지 |
| 복잡한 오류 시나리오 | High | Medium | 포괄적 오류 케이스 테스트, 사용자 피드백 수집 |

## 8. Testing Strategy

### Unit Testing
- **Framework:** Nix-based 테스트 시스템
- **Coverage:** 각 함수별 독립적 테스트
- **Focus Areas:** 경로 해결, 환경 변수, 오류 처리

### Integration Testing
- **Scope:** 모듈 간 상호작용 검증
- **Test Cases:**
  - Darwin/Linux 크로스 플랫폼 동작
  - 캐시 시스템 통합
  - sudo 권한 처리

### End-to-End Testing
- **Scenarios:**
  - 첫 실행 (clean state)
  - 재실행 (cached state)
  - 오류 상황에서 복구
  - 네트워크 장애 시나리오

### Regression Testing
- **Current Bug Scenarios:**
  - REBUILD_COMMAND_PATH 없을 때
  - Combined 모드 실행 실패
  - sudo 권한 문제

### Performance Testing
- **Metrics:**
  - 빌드 시간 (목표: <90초)
  - 캐시 적중률 (목표: >50%)
  - 메모리 사용량 최적화

## 9. Implementation Details

### 즉시 수정 사항
```bash
# 현재 문제적 코드
REBUILD_COMMAND_PATH="./result/sw/bin/darwin-rebuild"

# 수정된 코드 (대체 경로 로직)
if [[ -f "./result/sw/bin/darwin-rebuild" ]]; then
    REBUILD_COMMAND_PATH="./result/sw/bin/darwin-rebuild"
elif command -v darwin-rebuild >/dev/null 2>&1; then
    REBUILD_COMMAND_PATH="darwin-rebuild"
else
    REBUILD_COMMAND_PATH="/run/current-system/sw/bin/darwin-rebuild"
fi
```

### 테스트 케이스 예시
```nix
# tests/regression/build-switch-path-resolution-test.nix
{
  testCleanStateExecution = {
    description = "Test build-switch execution from clean state";
    command = "nix run .#build-switch -- --dry-run";
    expectedExitCode = 0;
    expectedOutput = "Successfully completed";
  };

  testCachedStateExecution = {
    description = "Test build-switch with existing result link";
    setup = "nix build .#darwinConfigurations.aarch64-darwin.system";
    command = "nix run .#build-switch -- --dry-run";
    expectedExitCode = 0;
  };
}
```

## 10. Success Criteria

### Technical Metrics
- ✅ `nix run .#build-switch` 100% 성공률
- ✅ 테스트 커버리지 90% 이상
- ✅ 캐시 적중률 50% 이상
- ✅ 빌드 시간 90초 이하

### Quality Metrics
- ✅ 모든 회귀 테스트 통과
- ✅ CI/CD 파이프라인 통합
- ✅ 자동 복구 메커니즘 동작
- ✅ 명확한 오류 메시지 제공

이 계획을 통해 build-switch의 즉시 문제를 해결하고, 향후 유사한 문제를 예방할 수 있는 견고한 테스트 인프라를 구축합니다.
