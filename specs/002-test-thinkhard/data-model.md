# Data Model: Test Code Next-Level Enhancement

**Date**: 2025-09-04  
**Phase**: 1 - Design & Contracts  
**Status**: Complete ✓

## Core Entities

### TestSuite

테스트 그룹의 논리적 단위를 나타내는 엔티티

**Fields**:

- `id`: string - 고유 식별자 (예: "core", "integration", "performance")
- `name`: string - 사람이 읽을 수 있는 이름 (예: "Core Tests", "Integration Suite")
- `description`: string - 테스트 스위트의 목적과 범위
- `category`: TestCategory - 테스트 분류
- `tests`: Test[] - 포함된 개별 테스트들
- `config`: TestConfig - 스위트별 설정
- `metadata`: TestMetadata - 실행 메타데이터

**Validation Rules**:

- `id`는 영숫자와 하이픈만 허용 (kebab-case)
- `name`은 1-50자 제한
- `category`는 유효한 TestCategory 값이어야 함
- `tests` 배열은 최소 1개 이상의 테스트 포함

**State Transitions**:

```
pending → running → completed
pending → running → failed  
pending → skipped
running → cancelled
```

### Test

개별 테스트 케이스를 나타내는 엔티티

**Fields**:

- `id`: string - 고유 테스트 식별자
- `name`: string - 테스트 이름
- `file_path`: string - 테스트 파일 경로 (절대 경로)
- `category`: TestCategory - 테스트 분류
- `dependencies`: string[] - 의존성 테스트 ID 목록
- `tags`: string[] - 검색 및 필터링용 태그
- `timeout`: number - 타임아웃 (초)
- `parallel_safe`: boolean - 병렬 실행 가능 여부
- `platform_specific`: string[] - 지원 플랫폼 목록

**Validation Rules**:

- `file_path`는 존재하는 실행 가능한 파일이어야 함
- `timeout`은 test-config.sh의 임계값 준수
- `platform_specific`는 ["darwin", "nixos"] 중 값만 허용
- 순환 의존성 방지 검증

### TestCategory

테스트 분류를 나타내는 열거형

**Values**:

- `unit`: 단위 테스트 (< 30초)
- `integration`: 통합 테스트 (< 60초)  
- `e2e`: 종단간 테스트 (< 300초)
- `performance`: 성능 테스트 (< 600초)
- `smoke`: 스모크 테스트 (< 10초)

**Properties per Category**:

```bash
unit:
  max_duration: 30s
  parallel_safe: true
  isolation_required: true

integration:
  max_duration: 60s
  parallel_safe: false (기본값)
  cleanup_required: true

e2e:
  max_duration: 300s  
  parallel_safe: false
  full_system_required: true

performance:
  max_duration: 600s
  parallel_safe: false
  monitoring_required: true

smoke:
  max_duration: 10s
  parallel_safe: true
  minimal_setup: true
```

### TestResult

테스트 실행 결과를 나타내는 엔티티

**Fields**:

- `test_id`: string - 실행된 테스트 ID
- `status`: TestStatus - 실행 상태
- `start_time`: timestamp - 시작 시간
- `end_time`: timestamp - 종료 시간
- `duration`: number - 실행 시간 (밀리초)
- `stdout`: string - 표준 출력
- `stderr`: string - 오류 출력  
- `exit_code`: number - 프로세스 종료 코드
- `performance_data`: PerformanceData - 성능 메트릭
- `environment`: TestEnvironment - 실행 환경 정보

**Validation Rules**:

- `status`는 유효한 TestStatus 값이어야 함
- `duration`은 해당 category의 max_duration을 초과할 수 없음
- `exit_code`는 0 (성공) 또는 양수 (실패)
- `end_time >= start_time`

### TestStatus

테스트 실행 상태를 나타내는 열거형

**Values**:

- `pending`: 대기 중
- `running`: 실행 중
- `passed`: 통과
- `failed`: 실패
- `skipped`: 건너뜀
- `timeout`: 타임아웃
- `cancelled`: 취소됨

### TestConfig

테스트 설정을 나타내는 엔티티

**Fields**:

- `timeouts`: TimeoutConfig - 타임아웃 설정
- `resources`: ResourceConfig - 리소스 제한
- `environment`: EnvironmentConfig - 환경 설정
- `reporting`: ReportingConfig - 리포팅 설정
- `parallel`: ParallelConfig - 병렬 실행 설정

**Sub-entities**:

#### TimeoutConfig

```typescript
{
  short: 30,      // TEST_TIMEOUT_SHORT
  medium: 60,     // TEST_TIMEOUT_MEDIUM  
  long: 300,      // TEST_TIMEOUT_LONG
  very_long: 600  // TEST_TIMEOUT_VERY_LONG
}
```

#### ResourceConfig

```typescript
{
  max_memory_mb: 1024,
  max_file_size_kb: 512,
  max_log_size_mb: 1,
  cleanup_on_success: true,
  cleanup_on_failure: false
}
```

#### EnvironmentConfig

```typescript
{
  platform: "darwin" | "nixos",
  architecture: "x86_64" | "aarch64",
  test_dir_base: "/tmp",
  test_dir_prefix: "dotfiles_test",
  mock_environment: boolean
}
```

### PerformanceData

성능 메트릭을 나타내는 엔티티

**Fields**:

- `execution_time_ms`: number - 실행 시간
- `memory_usage_mb`: number - 메모리 사용량
- `cpu_usage_percent`: number - CPU 사용률
- `disk_io_mb`: number - 디스크 I/O
- `network_requests`: number - 네트워크 요청 수
- `cache_hits`: number - 캐시 히트 수
- `cache_misses`: number - 캐시 미스 수

**Collection Points**:

- `.test-performance/performance.log`에서 수집
- 실시간 모니터링 데이터와 통합
- 성능 회귀 탐지를 위한 기준값과 비교

### TestEnvironment

테스트 실행 환경 정보를 나타내는 엔티티

**Fields**:

- `platform`: string - 실행 플랫폼
- `architecture`: string - CPU 아키텍처
- `nix_version`: string - Nix 버전
- `system_info`: SystemInfo - 시스템 정보
- `environment_variables`: Record<string, string> - 환경 변수
- `working_directory`: string - 작업 디렉토리

## Entity Relationships

### Primary Relationships

```
TestSuite 1:N Test
Test 1:1 TestResult  
Test N:N Test (dependencies)
TestConfig 1:1 TestSuite
TestResult 1:1 PerformanceData
TestResult 1:1 TestEnvironment
```

### Aggregation Rules

- TestSuite 상태는 포함된 Test들의 상태로 결정
- 모든 Test가 `passed` → TestSuite는 `passed`
- 하나라도 `failed` → TestSuite는 `failed`
- `running` 상태가 있으면 → TestSuite는 `running`

## Data Storage Strategy

### File-based Storage

```bash
# 설정 데이터
tests/config/test-config.sh           # 중앙집중식 설정
tests/config/test-suites.json         # 테스트 스위트 정의

# 실행 결과
.test-performance/performance.log     # 성능 데이터
.test-results/latest/                 # 최신 실행 결과
.test-results/history/                # 실행 이력

# 캐시 데이터  
.test-cache/discovery/                # 테스트 발견 캐시
.test-cache/dependencies/             # 의존성 캐시
```

### JSON Schema Examples

#### TestSuite Definition

```json
{
  "id": "core",
  "name": "Core Tests",
  "description": "Essential functionality tests",
  "category": "unit",
  "config": {
    "timeouts": {"default": 30},
    "parallel": {"max_workers": 4}
  },
  "tests": [
    {
      "id": "platform-detection",
      "name": "Platform Detection Test",
      "file_path": "/tests/bats/test_platform_detection.bats",
      "tags": ["platform", "essential"]
    }
  ]
}
```

#### TestResult Format

```json
{
  "test_id": "platform-detection",
  "status": "passed",
  "start_time": "2025-09-04T10:30:00Z",
  "end_time": "2025-09-04T10:30:02Z",
  "duration": 2000,
  "exit_code": 0,
  "performance_data": {
    "execution_time_ms": 2000,
    "memory_usage_mb": 45
  }
}
```

## Validation & Constraints

### Data Integrity Rules

1. 테스트 ID는 프로젝트 내에서 고유해야 함
2. 의존성 그래프에 순환 참조가 없어야 함
3. 모든 테스트 파일이 실제로 존재하고 실행 가능해야 함
4. 타임아웃 값은 카테고리별 최대값을 초과할 수 없음
5. 플랫폼별 제약사항을 준수해야 함

### Performance Constraints  

- 테스트 발견은 1초 이내 완료
- 메타데이터 로딩은 500ms 이내 완료
- 결과 저장은 비동기로 처리하여 블로킹 방지

이 데이터 모델은 기존 테스트 시스템의 구조를 존중하면서도 통합된 인터페이스 구현에 필요한 모든 정보를 체계적으로 관리할 수 있도록 설계되었습니다.
