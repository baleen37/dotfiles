# 테스트 코드 리팩토링 상세 계획

## 🎯 프로젝트 개요
dotfiles 프로젝트의 테스트 시스템을 133개 파일에서 35개 파일로 통합하여 유지보수성과 성능을 대폭 향상시키는 종합적인 리팩토링 프로젝트

## 📊 현황 분석 결과

### 문제점
- **과도한 테스트 파일**: 133개 파일로 관리 복잡성 증가
- **심각한 중복**: build-switch 관련 22개, Claude CLI 관련 14개 파일 중복
- **일관성 없는 명명**: `-test.nix`, `-unit.nix`, `-e2e.nix` 혼재
- **비효율적 실행**: 단일 derivation 방식으로 리소스 낭비
- **의미 없는 테스트**: 단순 파일 존재성 검사만 하는 테스트 다수

### 목표 지표
| 지표 | 현재 | 목표 | 개선률 |
|------|------|------|--------|
| 테스트 파일 수 | 133개 | 35개 | -74% |
| 중복 테스트 | 40% | 10% | -75% |
| 실행 시간 | ~10분 | ~5분 | -50% |
| 코드 품질 | 중간 | 높음 | +100% |

## 🏗️ 리팩토링 아키텍처

### 새로운 테스트 구조
```
tests/
├── core/              # 핵심 기능 테스트 (15개)
│   ├── build-switch-core.nix
│   ├── claude-configuration.nix
│   ├── claude-commands.nix
│   ├── user-resolution.nix
│   ├── platform-detection.nix
│   ├── flake-structure.nix
│   ├── configuration-validation.nix
│   ├── package-management.nix
│   ├── auto-update-core.nix
│   ├── homebrew-integration.nix
│   ├── zsh-configuration.nix
│   ├── app-links-core.nix
│   ├── security-policies.nix
│   ├── performance-configs.nix
│   └── error-handling-core.nix
├── integration/       # 통합 테스트 (10개)
│   ├── build-switch-flow.nix
│   ├── claude-workflow.nix
│   ├── system-deployment.nix
│   ├── cross-platform.nix
│   ├── homebrew-ecosystem.nix
│   ├── auto-update-integration.nix
│   ├── sudoers-workflow.nix
│   ├── file-generation.nix
│   ├── cache-management.nix
│   └── network-resilience.nix
├── e2e/              # E2E 테스트 (5개)
│   ├── complete-workflow.nix
│   ├── build-switch-scenarios.nix
│   ├── claude-config-workflow.nix
│   ├── system-build-deployment.nix
│   └── rollback-recovery.nix
├── performance/      # 성능 테스트 (3개)
│   ├── build-performance.nix
│   ├── resource-usage.nix
│   └── cache-optimization.nix
├── lib/              # 공통 라이브러리
│   ├── test-helpers.nix
│   ├── test-fixtures.nix
│   ├── mock-system.nix
│   └── performance-utils.nix
└── fixtures/         # 테스트 데이터
    ├── mock-configs/
    ├── sample-flakes/
    └── test-environments/
```

## 📋 Phase별 상세 구현 계획

### Phase 1: 기반 정리 (1주, 5일)

#### Day 1: 테스트 분류 및 매핑
```markdown
**목표**: 현재 테스트들을 기능별로 분류하고 통합 계획 수립

**작업 내용**:
1. 133개 테스트 파일의 기능별 분류 매트릭스 작성
2. 중복 테스트 그룹 식별 (build-switch 22개, claude 14개 등)
3. 통합 우선순위 결정 (높음/중간/낮음)
4. 삭제 대상 테스트 식별 (의미없는 파일 존재성 검사)

**결과물**:
- `test-mapping.md`: 테스트 분류 매트릭스
- `integration-plan.md`: 통합 계획서
- `deletion-candidates.md`: 삭제 대상 목록
```

#### Day 2: 공통 유틸리티 설계
```markdown
**목표**: test-helpers.nix 확장 및 새로운 공통 유틸리티 설계

**작업 내용**:
1. 현재 test-helpers.nix 분석 및 개선점 도출
2. 테스트 픽스처 시스템 설계
3. 모킹 시스템 설계 (mock-system.nix 개선)
4. 성능 측정 유틸리티 설계

**결과물**:
- `lib/test-helpers-v2.nix`: 확장된 헬퍼
- `lib/test-fixtures.nix`: 픽스처 시스템
- `lib/performance-utils.nix`: 성능 유틸리티
```

#### Day 3: 테스트 템플릿 설계
```markdown
**목표**: 일관된 테스트 구조를 위한 템플릿 설계

**작업 내용**:
1. Core 테스트 템플릿 설계
2. Integration 테스트 템플릿 설계  
3. E2E 테스트 템플릿 설계
4. 네이밍 규칙 확정

**결과물**:
- `templates/core-test-template.nix`
- `templates/integration-test-template.nix`
- `templates/e2e-test-template.nix`
- `TESTING-GUIDELINES.md`: 새로운 테스트 작성 가이드
```

#### Day 4-5: 기반 구조 구현
```markdown
**목표**: 새로운 테스트 디렉토리 구조 및 기반 파일들 구현

**작업 내용**:
1. 새로운 디렉토리 구조 생성
2. 공통 유틸리티 구현
3. 테스트 템플릿 구현
4. CI/CD 스크립트 업데이트 준비

**결과물**:
- 새로운 tests/ 디렉토리 구조
- 구현된 공통 유틸리티들
- 업데이트된 Makefile/스크립트
```

### Phase 2: 핵심 테스트 통합 (2주, 10일)

#### Week 1: 가장 중복이 심한 테스트 그룹 통합

**Day 6-7: Build-Switch 테스트 통합 (22개 → 3개)**
```markdown
**작업 내용**:
1. build-switch 관련 22개 테스트 분석
2. core/build-switch-core.nix 구현
   - 스크립트 존재성 및 실행 권한
   - 기본 색상 및 로깅 함수
   - 플래그 처리 로직
   - 에러 핸들링
3. integration/build-switch-flow.nix 구현
   - 시스템 상태 관리
   - 롤백 기능
   - 네트워크 장애 복구
4. e2e/build-switch-scenarios.nix 구현
   - 전체 빌드 워크플로우
   - 다양한 시나리오 (성공/실패/복구)

**검증 기준**:
- 기존 22개 테스트의 모든 검증 로직 포함
- 실행 시간 50% 단축
- 코드 중복 90% 제거
```

**Day 8-9: Claude CLI 테스트 통합 (14개 → 3개)**
```markdown
**작업 내용**:
1. Claude 관련 14개 테스트 분석
2. core/claude-configuration.nix 구현
   - CLAUDE.md 파일 검증
   - settings.json 구조 검증
   - 명령어 파일들 존재성 검증
3. core/claude-commands.nix 구현
   - 각 명령어 기능 테스트
   - 명령어 실행 검증
4. integration/claude-workflow.nix 구현
   - 전체 Claude CLI 워크플로우
   - 설정-명령어-실행 통합 테스트

**검증 기준**:
- Claude 관련 모든 기능 검증 유지
- JSON 파싱 및 유효성 검사 포함
- 명령어별 개별 실행 테스트 포함
```

**Day 10: Zsh & Shell 테스트 통합 (5개 → 2개)**
```markdown
**작업 내용**:
1. Zsh 관련 5개 테스트 통합
2. core/zsh-configuration.nix 구현
3. integration/shell-workflow.nix 구현

**검증 기준**:
- Powerlevel10k 설정 검증
- Zsh 플러그인 검증
- Shell 통합 기능 검증
```

#### Week 2: 나머지 핵심 테스트들 통합

**Day 11-12: 시스템 관련 테스트 통합**
- user-resolution (3개 → 1개)  
- platform-detection (2개 → 1개)
- flake-structure (4개 → 1개)
- configuration-validation (3개 → 1개)

**Day 13-14: 패키지 및 자동화 테스트 통합**
- package-management (6개 → 1개)
- auto-update (5개 → 2개)
- homebrew-integration (8개 → 2개)

**Day 15: 기타 기능 테스트 통합**
- app-links (3개 → 2개)
- security-policies (4개 → 1개)
- error-handling (6개 → 1개)

### Phase 3: 구조 최적화 (1주, 5일)

#### Day 16-17: 테스트 실행 최적화
```markdown
**작업 내용**:
1. 병렬 실행 가능한 테스트 식별
2. 의존성 그래프 구성
3. 테스트 실행 순서 최적화
4. 캐싱 전략 구현

**결과물**:
- 최적화된 test runner
- 의존성 기반 실행 스크립트
- 캐시 관리 시스템
```

#### Day 18-19: 성능 테스트 재구성
```markdown
**작업 내용**:
1. 기존 성능 테스트 통합 (5개 → 3개)
2. 성능 벤치마크 기준선 설정
3. 성능 회귀 검출 시스템 구현

**결과물**:
- performance/build-performance.nix
- performance/resource-usage.nix  
- performance/cache-optimization.nix
```

#### Day 20: 새로운 default.nix 구현
```markdown
**작업 내용**:
1. 새로운 테스트 구조를 반영한 default.nix 구현
2. 카테고리별 테스트 실행 지원
3. 메타데이터 및 리포팅 개선

**결과물**:
- 새로운 tests/default.nix
- 카테고리별 실행 스크립트
- 테스트 결과 리포팅 시스템
```

### Phase 4: 품질 및 성능 향상 (1주, 5일)

#### Day 21-22: 성능 최적화
```markdown
**작업 내용**:
1. 공통 설정 캐싱 구현
2. 중복 연산 제거
3. 조건부 테스트 실행 로직
4. 테스트 병렬화 구현

**목표 성능**:
- 전체 테스트 실행 시간 50% 단축
- 개별 테스트 시작 시간 30% 단축
- 리소스 사용량 40% 감소
```

#### Day 23-24: 문서화 및 가이드라인
```markdown
**작업 내용**:
1. 새로운 테스트 작성 가이드
2. 리팩토링 결과 문서화
3. CI/CD 파이프라인 업데이트
4. 개발자 온보딩 가이드

**결과물**:
- `docs/TESTING-V2.md`: 새로운 테스트 가이드
- `docs/REFACTORING-RESULTS.md`: 리팩토링 결과
- 업데이트된 CI/CD 스크립트
```

#### Day 25: 검증 및 마무리
```markdown
**작업 내용**:
1. 전체 테스트 스위트 실행 및 검증
2. 성능 지표 확인
3. 레거시 테스트 정리
4. 문서 최종 검토

**검증 기준**:
- 모든 기존 기능 검증 로직 보존
- 목표 성능 지표 달성
- 새로운 구조로 완전 이전 완료
```

## 🚀 구현 프롬프트 시리즈

### Phase 1 프롬프트들

**Prompt 1-1: 테스트 분류 및 매핑**
```
jito님, 현재 dotfiles 프로젝트의 133개 테스트 파일을 분석해서 기능별로 분류하고 통합 계획을 수립해주세요.

작업 내용:
1. tests/ 디렉토리의 모든 .nix 파일을 읽어서 기능별로 분류
2. 중복되는 테스트 그룹 식별 (예: build-switch 관련, claude 관련)
3. 각 테스트가 실제로 검증하는 내용 파악
4. 통합 가능한 테스트들과 삭제 대상 테스트들 구분

결과물로 test-mapping.md 파일을 생성해주세요.
```

**Prompt 1-2: 공통 유틸리티 확장**
```
jito님, 현재 tests/lib/test-helpers.nix를 기반으로 확장된 테스트 유틸리티를 설계하고 구현해주세요.

개선 사항:
1. 더 강력한 assertion 함수들
2. 테스트 픽스처 생성 시스템
3. 모킹 시스템 개선
4. 성능 측정 유틸리티
5. 테스트 데이터 관리 시스템

lib/test-helpers-v2.nix, lib/test-fixtures.nix, lib/performance-utils.nix 파일들을 구현해주세요.
```

### Phase 2 프롬프트들

**Prompt 2-1: Build-Switch 테스트 통합**
```
jito님, build-switch 관련 22개 테스트 파일을 3개로 통합해주세요.

현재 build-switch 관련 테스트들:
- build-switch-unit.nix
- build-switch-e2e.nix
- build-switch-perf.nix
- build-switch-claude-code-environment-test.nix
- (기타 18개 파일...)

통합 목표:
1. core/build-switch-core.nix: 기본 기능 검증
2. integration/build-switch-flow.nix: 시스템 통합 테스트
3. e2e/build-switch-scenarios.nix: E2E 워크플로우

모든 기존 검증 로직을 보존하면서 중복을 제거해주세요.
```

**Prompt 2-2: Claude CLI 테스트 통합**
```
jito님, Claude CLI 관련 14개 테스트 파일을 3개로 통합해주세요.

현재 Claude 관련 테스트들 분석 후:
1. core/claude-configuration.nix: 설정 파일 검증
2. core/claude-commands.nix: 명령어 기능 검증  
3. integration/claude-workflow.nix: 전체 워크플로우

JSON 검증, 파일 존재성, 명령어 실행 등 모든 기능을 포함해주세요.
```

### Phase 3 프롬프트들

**Prompt 3-1: 테스트 실행 최적화**
```
jito님, 새로운 테스트 구조에서 병렬 실행과 캐싱을 통한 성능 최적화를 구현해주세요.

최적화 목표:
1. 병렬 실행 가능한 테스트 식별
2. 의존성 기반 실행 순서
3. 공통 설정 캐싱
4. 중복 작업 제거

tests/default.nix와 실행 스크립트를 업데이트해주세요.
```

**Prompt 3-2: 성능 테스트 재구성**
```
jito님, 기존 성능 테스트들을 3개로 통합하고 성능 회귀 검출 시스템을 구현해주세요.

통합 대상:
- build-time-perf.nix, resource-usage-perf.nix 등
- 총 5개 → 3개로 통합

새로운 구조:
1. performance/build-performance.nix
2. performance/resource-usage.nix
3. performance/cache-optimization.nix

성능 벤치마크 기준선 설정도 포함해주세요.
```

### Phase 4 프롬프트들

**Prompt 4-1: 문서화 및 가이드라인**
```
jito님, 리팩토링된 테스트 시스템에 대한 문서를 작성해주세요.

문서 내용:
1. docs/TESTING-V2.md: 새로운 테스트 시스템 가이드
2. docs/REFACTORING-RESULTS.md: 리팩토링 결과 요약
3. 새로운 테스트 작성 가이드라인  
4. 개발자 온보딩 문서

기존 TESTING.md는 TESTING-LEGACY.md로 백업하고 새로운 문서로 교체해주세요.
```

**Prompt 4-2: 최종 검증 및 정리**
```
jito님, 리팩토링된 테스트 시스템의 최종 검증을 수행해주세요.

검증 항목:
1. 모든 테스트가 올바르게 실행되는지 확인
2. 성능 목표 달성 여부 확인 (50% 시간 단축)
3. 기존 검증 로직이 모두 보존되었는지 확인
4. 레거시 테스트 파일 정리

최종 결과 리포트를 작성해주세요.
```

## 📊 성공 지표

### 정량적 지표
- **파일 수**: 133개 → 35개 (74% 감소)
- **실행 시간**: 10분 → 5분 (50% 단축)
- **코드 중복**: 40% → 10% (75% 감소)
- **테스트 커버리지**: 유지 (100%)

### 정성적 지표
- **유지보수성**: 높음 (일관된 구조, 명명 규칙)
- **가독성**: 높음 (통합된 테스트, 명확한 분류)
- **확장성**: 높음 (템플릿 기반, 재사용 가능)
- **성능**: 높음 (병렬 실행, 캐싱)

## 🎯 최종 목표
**"133개의 복잡하고 중복된 테스트를 35개의 깔끔하고 효율적인 테스트로 변환하여, 개발자 경험과 시스템 품질을 동시에 향상시킨다."**

---

이 계획은 TDD 원칙을 준수하며, 기존 기능을 완전히 보존하면서도 대폭적인 개선을 달성하는 것을 목표로 합니다.
