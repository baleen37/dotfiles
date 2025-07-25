# 테스트 리팩토링 상세 계획서

## 📊 우선순위별 통합 전략

### 🥇 높은 우선순위 (즉시 통합)

#### 1. Build-switch 테스트 그룹 (19개 → 3개)
**통합 이유**: 가장 많은 중복과 가장 높은 통합 효과
- `build-switch-unit.nix` (기본 기능)
- `build-switch-integration.nix` (시스템 통합)
- `build-switch-performance.nix` (성능 최적화)

**삭제 대상**: 16개 중복 파일
- `build-switch-basic-test.nix`
- `build-switch-advanced-test.nix`
- `build-switch-error-handling.nix`
- 등등...

#### 2. Claude CLI 테스트 그룹 (6개 → 2개)
**통합 이유**: 최신 기능으로 표준화된 구조 필요
- `claude-cli-integration.nix` (통합 테스트)
- `claude-cli-e2e.nix` (완전한 워크플로우)

**삭제 대상**: 4개 분산된 파일

### 🥈 중간 우선순위 (2차 통합)

#### 3. Homebrew 관련 테스트 (6개 → 2개)
- `homebrew-integration.nix`
- `homebrew-performance.nix`

#### 4. User Resolution 테스트 (5개 → 1개)
- `user-resolution-unified.nix`

#### 5. ZSH 설정 테스트 (4개 → 2개)
- `zsh-config.nix`
- `zsh-integration.nix`

### 🥉 낮은 우선순위 (3차 통합)

#### 6. 기타 단일 기능 테스트들
- 개별적으로 검토하여 통합 또는 유지

## 📏 통합 효과 예상

| 그룹 | 현재 | 목표 | 감소율 | 우선순위 |
|------|------|------|--------|----------|
| Build-switch | 19개 | 3개 | 84% | 🥇 |
| Claude CLI | 6개 | 2개 | 67% | 🥇 |
| Homebrew | 6개 | 2개 | 67% | 🥈 |
| User Resolution | 5개 | 1개 | 80% | 🥈 |
| ZSH | 4개 | 2개 | 50% | 🥈 |

**전체 효과**: 133개 → 35개 (74% 감소)

## 🏗️ 새로운 디렉토리 구조

```
tests/
├── core/                    # 핵심 기능 테스트
│   ├── build-switch-unit.nix
│   ├── build-switch-integration.nix
│   ├── build-switch-performance.nix
│   ├── claude-cli-integration.nix
│   ├── claude-cli-e2e.nix
│   └── user-resolution-unified.nix
├── integration/             # 시스템 통합 테스트
│   ├── homebrew-integration.nix
│   ├── homebrew-performance.nix
│   ├── zsh-config.nix
│   └── zsh-integration.nix
├── e2e/                     # 종단간 테스트
│   ├── full-workflow.nix
│   └── deployment-scenarios.nix
├── performance/             # 성능 테스트
│   ├── build-optimization.nix
│   └── system-benchmarks.nix
├── lib/                     # 공통 라이브러리
│   ├── test-helpers.nix
│   ├── build-test-lib.nix
│   ├── claude-test-lib.nix
│   └── integration-helpers.nix
└── default.nix             # 새로운 테스트 진입점
```

## 🔧 구현 단계

### Phase 1A: Build-switch 통합 (Day 1-2)
1. 기존 19개 파일 분석 및 로직 추출
2. 3개 통합 파일 TDD 방식으로 구현
3. 모든 기존 검증 로직 포함 확인
4. 기존 파일 삭제 및 정리

### Phase 1B: Claude CLI 통합 (Day 3)
1. 최신 구조 기반으로 2개 파일 통합
2. E2E 시나리오 완성도 검증

### Phase 1C: 기반 구조 완성 (Day 4-5)
1. 새로운 디렉토리 구조 생성
2. 공통 라이브러리 리팩토링
3. default.nix 업데이트

## ✅ 품질 보증 체크리스트

### 통합 완료 후 필수 검증
- [ ] 모든 기존 검증 로직 포함됨
- [ ] 테스트 실행 시간 5분 이내
- [ ] 코드 중복률 10% 이하
- [ ] 테스트 커버리지 유지
- [ ] CI/CD 파이프라인 정상 동작

### TDD 준수 확인
- [ ] Red-Green-Refactor 사이클 따름
- [ ] 각 통합 파일마다 충분한 테스트 케이스
- [ ] 실패 시나리오 포함
- [ ] 성능 테스트 포함

## 📋 다음 액션 아이템

1. **즉시 시작**: Build-switch 19개 파일 상세 분석
2. **준비 완료**: 새로운 디렉토리 구조 생성
3. **대기 중**: Claude CLI 통합 시작점 확정
