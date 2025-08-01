# 추천 명령어

## 필수 환경 설정

```bash
# USER 변수 설정 (필수)
export USER=$(whoami)
```

## 개발 워크플로

### 빠른 검증
```bash
make lint           # pre-commit 린트 검사 실행
make smoke          # 빌드 없이 flake 구조 검증
make test           # 전체 테스트 스위트 실행
```

### 빌드 및 배포
```bash
make build          # 모든 플랫폼 설정 빌드
make build-current  # 현재 플랫폼만 빌드 (더 빠름)
make build-fast     # 최적화된 빠른 빌드
make switch         # 빌드 + 적용 (sudo 필요)
make deploy         # 빌드+스위치 (모든 컴�터에서 작동)
```

### 플랫폼별 빌드
```bash
make build-darwin   # macOS 설정 빌드
make build-linux    # NixOS 설정 빌드
```

### 테스트 실행
```bash
make test           # 모든 테스트
make test-core      # 핵심 테스트 (빠름, 필수)
make test-workflow  # 워크플로 테스트 (엔드투엔드)
make test-perf      # 성능 테스트
make test-list      # 사용 가능한 테스트 카테고리 나열
```

### 직접 Nix 명령
```bash
nix run .#build         # 현재 플랫폼 빌드
nix run .#build-switch  # 빌드 및 적용 (sudo 처리)
nix run .#test          # 플랫폼별 테스트 스위트 실행
```

### 유틸리티
```bash
make platform-info  # 상세한 플랫폼 정보 표시
make help           # 사용 가능한 모든 타겟 표시
```

## Claude Code 테스트
```bash
./tests/run-claude-tests.sh          # 모든 Claude 테스트
./tests/run-claude-tests.sh --unit-only       # 단위 테스트만
./tests/run-claude-tests.sh --integration-only # 통합 테스트만
./tests/run-claude-tests.sh --e2e-only        # E2E 테스트만
```