# Smart Test Selection Contract

**Version**: 1.0.0  
**Date**: 2025-09-04  
**Status**: Draft

## Overview

스마트 테스트 선택 시스템은 코드 변경사항을 분석하여 관련된 테스트만 선택적으로 실행함으로써 개발자의 피드백 루프를 단축시킵니다.

## Selection Algorithms

### Change-Based Selection

Git 변경사항을 기반으로 영향받는 테스트를 식별합니다.

#### Input Sources

```bash
# Git 변경사항 감지
git diff --name-only HEAD~1      # 최근 커밋 대비 변경
git diff --name-only main        # main 브랜치 대비 변경  
git status --porcelain           # 작업 디렉토리 변경
```

#### Mapping Rules

```bash
# 파일 변경 → 테스트 매핑 규칙
modules/shared/packages.nix        → tests/unit/*package*
modules/darwin/casks.nix           → tests/integration/*darwin*
lib/platform-system.nix           → tests/bats/test_platform_detection.bats
tests/lib/test-framework.sh       → tests/unit/test-framework-validation.sh
Makefile                          → tests/integration/test-build-*
```

#### Pattern Matching

```typescript
interface ChangeMapping {
  filePattern: string;      // 변경된 파일 패턴
  testPatterns: string[];   // 실행할 테스트 패턴
  priority: number;         // 우선순위 (1-10)
  rationale: string;        // 매핑 이유
}

const mappings: ChangeMapping[] = [
  {
    filePattern: "lib/*.nix",
    testPatterns: ["tests/unit/test-lib-*", "tests/bats/test_lib_*"],
    priority: 9,
    rationale: "Core library changes require comprehensive testing"
  },
  {
    filePattern: "modules/shared/*",
    testPatterns: ["tests/integration/*", "tests/e2e/*"],
    priority: 7,
    rationale: "Shared modules affect multiple system components"
  }
];
```

### Dependency-Based Selection

파일 간 의존성을 분석하여 영향 범위를 확장합니다.

#### Dependency Graph

```bash
# Nix 의존성 분석
nix-store --query --references /nix/store/...
nix show-derivation | jq '.[] | .inputDrvs'

# 동적 의존성 추적
tests/lib/test-framework.sh → 모든 BATS 테스트
tests/config/test-config.sh → 전체 테스트 스위트
```

#### Impact Analysis

```typescript
interface DependencyImpact {
  changedFile: string;
  directDependents: string[];     // 직접 의존하는 파일들
  transitiveDependents: string[]; // 간접 의존하는 파일들
  testCoverage: string[];         // 커버해야 할 테스트들
  riskScore: number;              // 변경 위험도 (1-10)
}
```

### Historical Analysis

과거 실패 이력을 기반으로 테스트 우선순위를 조정합니다.

#### Failure Correlation

```bash
# 실패 이력 데이터
.test-performance/failure-history.json
{
  "file_changes": {
    "lib/platform-system.nix": {
      "frequently_broken_tests": [
        "test_platform_detection.bats",
        "test-build-switch-health"
      ],
      "failure_rate": 0.15,
      "last_failures": ["2025-09-03", "2025-08-28"]
    }
  }
}
```

#### Risk-Based Prioritization

```typescript
interface TestRisk {
  testId: string;
  baseRisk: number;           // 기본 위험도
  changeRisk: number;         // 변경사항 기반 위험도
  historicalRisk: number;     // 이력 기반 위험도
  finalPriority: number;      // 최종 우선순위
}

function calculatePriority(test: Test, changes: Change[]): number {
  const baseRisk = test.category === 'e2e' ? 8 : 5;
  const changeRisk = calculateChangeImpact(test, changes);
  const historicalRisk = getHistoricalFailureRate(test.id);

  return Math.min(10, baseRisk + changeRisk + historicalRisk);
}
```

## Selection Strategies

### Fast Feedback Strategy

빠른 개발 피드백을 위한 최소 테스트 세트 선택

```typescript
interface FastFeedbackConfig {
  maxExecutionTime: 30;      // 최대 30초
  maxTestCount: 10;          // 최대 10개 테스트
  priorityThreshold: 7;      // 우선순위 7 이상만
  includeFailedTests: true;  // 이전 실패 테스트 포함
}
```

### Comprehensive Strategy  

포괄적 검증을 위한 확장된 테스트 세트 선택

```typescript
interface ComprehensiveConfig {
  maxExecutionTime: 300;     // 최대 5분
  includeTransitive: true;   // 간접 의존성 포함
  includeRegression: true;   // 회귀 테스트 포함
  coverageThreshold: 0.8;    // 80% 커버리지 목표
}
```

### Risk-Based Strategy

위험도 기반 선택적 테스트 실행

```typescript
interface RiskBasedConfig {
  highRiskFiles: string[];   // 높은 위험도 파일 목록
  criticalPaths: string[];   // 중요 경로 패턴
  safetyMargin: 1.5;        // 안전 계수
}
```

## API Interface

### Command Line Interface

```bash
# 스마트 선택 옵션
test --changed                    # 변경된 파일 관련 테스트
test --changed --strategy fast    # 빠른 피드백 전략
test --changed --since main       # main 브랜치 이후 변경분
test --changed --include-deps     # 의존성 포함
test --failed --retry            # 실패한 테스트 재실행

# 세부 제어 옵션
test --max-tests 15              # 최대 테스트 수 제한
test --max-time 60               # 최대 실행 시간 (초)
test --priority-min 5            # 최소 우선순위
test --risk-threshold 7          # 위험도 임계값
```

### Programmatic Interface

```bash
# 선택 결과 쿼리
test --changed --dry-run --format json
{
  "strategy": "fast-feedback",
  "total_available": 45,
  "selected_count": 8,
  "estimated_duration": 25,
  "selection_rationale": {
    "file_changes": ["lib/platform-system.nix"],
    "affected_tests": [
      {
        "id": "platform-detection",
        "reason": "direct dependency",
        "priority": 9
      }
    ]
  }
}
```

## Cache Management

### Selection Cache

반복적인 분석을 피하기 위한 선택 결과 캐싱

```bash
.test-cache/selection/
├── git-hash-abc123.json         # Git 해시별 선택 결과
├── dependency-graph.json        # 의존성 그래프 캐시
└── mapping-rules.json          # 매핑 룰 캐시
```

#### Cache Invalidation

```typescript
interface CacheInvalidation {
  triggerEvents: [
    "git commit",
    "dependency file change",
    "test file addition/removal",
    "mapping rule update"
  ];
  maxAge: 24;  // 24시간 후 자동 만료
  sizeLimit: 50; // 최대 50개 항목 유지
}
```

### Performance Optimization

```bash
# 백그라운드 캐시 준비
test --prepare-cache &           # 의존성 그래프 사전 분석
test --warm-cache               # 자주 사용되는 선택 패턴 캐싱
```

## Configuration

### Mapping Configuration

```yaml
# tests/config/selection-mappings.yml
file_mappings:
  - pattern: "lib/*.nix"
    tests: ["tests/unit/test-lib-*", "tests/bats/test_lib_*"]
    priority: 9

  - pattern: "modules/shared/packages.nix"  
    tests: ["tests/integration/*package*"]
    priority: 7

custom_rules:
  - name: "critical-path"
    files: ["flake.nix", "lib/platform-system.nix"]
    tests: ["tests/integration/*", "tests/e2e/*"]
    always_run: true
```

### Strategy Configuration

```yaml
# tests/config/selection-strategies.yml
strategies:
  fast:
    max_time: 30
    max_tests: 10
    priority_min: 7

  comprehensive:
    max_time: 300
    include_transitive: true
    coverage_threshold: 0.8

  ci:
    max_time: 600
    include_all_failed: true
    regression_testing: true
```

## Monitoring and Analytics

### Selection Metrics

```json
{
  "selection_stats": {
    "average_reduction": 0.73,     // 평균 73% 테스트 감소
    "time_saved": 180,             // 평균 3분 절약
    "accuracy_rate": 0.95,         // 95% 정확도 (놓친 버그 비율)
    "false_positive_rate": 0.08    // 8% 불필요한 테스트 실행
  }
}
```

### Continuous Improvement

```bash
# 선택 정확도 피드백 수집
test --changed --track-accuracy    # 정확도 추적 모드
test --analyze-misses             # 놓친 테스트 분석
test --update-mappings            # 학습된 패턴으로 매핑 업데이트
```

## Error Handling

### Selection Failures

- Git 정보 접근 실패 → 전체 테스트 실행으로 폴백
- 의존성 분석 실패 → 파일 패턴 매칭으로 폴백  
- 캐시 손상 → 캐시 재생성 후 계속 진행

### Edge Cases

- 새로운 파일 추가 → 보수적 선택 (관련 가능성 있는 모든 테스트)
- 대규모 리팩토링 → 자동으로 comprehensive 전략으로 전환
- 테스트 파일 자체 변경 → 해당 테스트 및 관련 테스트 실행

이 계약은 개발자의 생산성을 향상시키면서도 테스트 커버리지를 보장하는 지능적인 테스트 선택 시스템을 정의합니다.
