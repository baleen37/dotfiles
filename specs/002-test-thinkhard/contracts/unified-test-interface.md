# Unified Test Interface Contract

**Version**: 1.0.0  
**Date**: 2025-09-04  
**Status**: Draft

## Interface Overview

통합된 테스트 인터페이스는 현재 분산된 15+ 테스트 명령어를 하나의 일관된 CLI로 통합하여 개발자 경험을 향상시킵니다.

## Command Line Interface

### Primary Command

```bash
test [CATEGORY] [OPTIONS] [PATTERNS...]
```

### Categories

- `all` - 모든 테스트 실행 (기본값)
- `quick` - 빠른 피드백용 핵심 테스트
- `unit` - 단위 테스트만
- `integration` - 통합 테스트만  
- `e2e` - 종단간 테스트만
- `performance` - 성능 테스트만
- `smoke` - 스모크 테스트만

### Global Options

- `--help, -h` - 도움말 표시
- `--version, -v` - 버전 정보 표시
- `--format FORMAT` - 출력 형식 (tap, json, human) [기본: human]
- `--verbose` - 상세 출력
- `--quiet` - 최소 출력
- `--parallel N` - 병렬 실행 워커 수 [기본: auto]
- `--timeout SECONDS` - 전역 타임아웃 설정
- `--dry-run` - 실행 계획만 표시

### Filtering Options

- `--changed` - 변경된 파일과 관련된 테스트만 실행
- `--failed` - 이전에 실패한 테스트만 재실행
- `--tag TAG` - 특정 태그가 있는 테스트만 실행
- `--exclude TAG` - 특정 태그 제외
- `--platform PLATFORM` - 플랫폼별 테스트 (darwin, nixos)

### Pattern Matching

```bash
# 파일 패턴으로 테스트 선택
test "platform*"          # platform으로 시작하는 테스트
test "*integration*"      # integration이 포함된 테스트
test "bats/**/*"          # bats 디렉토리 하위 모든 테스트

# 테스트 이름으로 선택
test --name "user resolution"  # 테스트 이름 매칭
```

## Input/Output Contract

### Exit Codes

- `0` - 모든 테스트 성공
- `1` - 하나 이상의 테스트 실패
- `2` - 명령어 사용법 오류
- `3` - 설정 오류
- `4` - 시스템 오류 (권한, 리소스 등)
- `130` - 사용자 중단 (SIGINT)

### Standard Output Formats

#### Human Format (기본)

```
🚀 Running test suite: core
==================================
▶ Platform Detection Test         ... PASSED (2.1s)
▶ User Resolution Test           ... PASSED (1.8s)
▶ Build System Test             ... FAILED (5.2s)

==================================  
📊 Results: 2 passed, 1 failed (9.1s total)
❌ Failed tests:
  - Build System Test: /tests/bats/test_build_system.bats:42
```

#### TAP Format  

```
1..3
ok 1 - Platform Detection Test
ok 2 - User Resolution Test
not ok 3 - Build System Test
  ---
  message: "Build failed with exit code 1"
  severity: fail
  data:
    file: "/tests/bats/test_build_system.bats"
    line: 42
    duration: 5.2
  ...
```

#### JSON Format

```json
{
  "version": "1.0.0",
  "timestamp": "2025-09-04T10:30:00Z",
  "summary": {
    "total": 3,
    "passed": 2,
    "failed": 1,
    "skipped": 0,
    "duration_ms": 9100
  },
  "results": [
    {
      "id": "platform-detection",
      "name": "Platform Detection Test",
      "status": "passed",
      "duration_ms": 2100,
      "file": "/tests/bats/test_platform_detection.bats"
    }
  ]
}
```

### Standard Error

에러 메시지, 디버그 정보, 진행 상황 표시기 출력

## Backward Compatibility

### Legacy Command Mapping

기존 명령어들은 새로운 인터페이스로 자동 매핑됩니다:

```bash
# 기존 → 새로운 인터페이스
make test         → test all
make test-quick   → test quick  
make test-core    → test unit
make test-bats    → test integration --tag bats
make test-perf    → test performance
make smoke        → test smoke

# 기존 명령어는 deprecation warning과 함께 계속 동작
make test-quick   # → "Warning: Use 'test quick' instead"
```

### Configuration Compatibility

- 기존 `tests/config/test-config.sh` 설정 완전 지원
- 기존 환경변수 (`DEBUG_TESTS`, `VERBOSE_OUTPUT`) 지원
- 기존 성능 모니터링 시스템과 통합

## Error Handling

### Input Validation

- 잘못된 카테고리명 → 사용 가능한 옵션 제안
- 잘못된 패턴 → 매칭 예시 제공  
- 충돌하는 옵션 → 명확한 오류 메시지

### Runtime Errors  

- 테스트 파일 없음 → 경로 및 수정 제안
- 권한 오류 → 필요한 권한 안내
- 타임아웃 → 진행 상황과 함께 부분 결과 제공
- 메모리 부족 → 병렬 실행 수 조정 제안

### Recovery Strategies

- 일부 테스트 실패 시 → 계속 진행하여 전체 결과 제공
- 시스템 리소스 부족 → 자동으로 병렬 실행 수 조정
- 네트워크 오류 → 재시도 로직 (설정 가능)

## Performance Contract

### Response Time Guarantees

- 명령어 시작 → 첫 출력: < 500ms
- 테스트 발견 완료: < 1s
- quick 카테고리 전체 실행: < 10s
- 성능 데이터 수집 오버헤드: < 5%

### Resource Usage

- 메모리 사용량: < 100MB (기본 실행)
- 동시 프로세스: 시스템 코어 수 기반 자동 조정
- 임시 파일: 실행 후 자동 정리 (실패 시 보존)

### Scalability

- 테스트 수 증가에 따른 선형적 성능 저하
- 최대 1000개 테스트 파일 지원
- 병렬 실행으로 전체 실행 시간 최적화

## Integration Points

### CI/CD Integration

- TAP 형식으로 표준 CI 도구와 호환
- JUnit XML 출력 지원 (--format junit)
- 성능 회귀 탐지 결과를 CI 상태로 반영

### Development Tools

- Git hooks와 통합 (pre-commit, pre-push)
- IDE 플러그인 지원을 위한 JSON API
- 성능 데이터 시각화 도구 연동

### Monitoring Integration

```bash
# 성능 데이터 출력 위치
.test-performance/performance.log    # 기존 시스템 유지
.test-results/latest/summary.json    # 새로운 구조화된 결과
```

## Security Considerations

### Input Sanitization

- 파일 패턴 인젝션 방지
- 환경변수 검증
- 실행 권한 최소화

### Output Safety  

- 민감한 정보 로그 제외
- 임시 파일 보안 처리
- 오류 메시지에서 시스템 정보 노출 방지

## Extension Points

### Plugin Architecture

```bash
# 플러그인 디렉토리 구조
tests/plugins/
├── reporters/     # 커스텀 리포터
├── filters/       # 커스텀 필터
└── hooks/         # 실행 훅
```

### Configuration Hooks

- 테스트 실행 전/후 훅
- 결과 변환 파이프라인
- 커스텀 성능 메트릭 수집

이 계약은 기존 테스트 시스템의 모든 기능을 보존하면서도 통합된 개발자 경험을 제공하는 인터페이스를 정의합니다.
