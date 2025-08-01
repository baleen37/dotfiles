# 작업 완료 워크플로

## 작업 완료 시 필수 단계

### 1. 품질 검사
```bash
make lint           # pre-commit 린트 검사
make smoke          # flake 구조 검증 (빌드 없이)
make test           # 전체 테스트 스위트
```

### 2. 빌드 검증
```bash
# USER 환경 변수 설정 확인
export USER=$(whoami)

# 빌드 검증
make build-current  # 현재 플랫폼만 (빠른 검증)
# 또는
make build          # 모든 플랫폼 (완전한 검증)
```

### 3. 테스트 실행
```bash
# 핵심 테스트 (빠름)
make test-core

# 전체 테스트 (완전한 검증)
make test

# Claude 관련 변경 시
./tests/run-claude-tests.sh
```

### 4. 시스템 적용 (선택사항)
```bash
make switch         # 현재 시스템에 적용
```

## Pre-commit Hook 동작

- **자동 실행**: git commit 시 자동으로 품질 검사 실행
- **빌드 검증**: 중요한 파일 변경 시 빌드 검증
- **테스트 실행**: git push 시 CI와 동일한 테스트 실행

## CI/CD와의 일치

- **로컬 테스트**: `CI_MODE=local`로 CI와 동일한 환경에서 테스트
- **경고 필터링**: CI와 동일한 경고 필터링 적용
- **플랫폼별 테스트**: 각 플랫폼에 맞는 테스트 실행

## 문제 해결

### 빌드 실패 시
```bash
# USER 변수 확인
export USER=$(whoami)

# 캐시 정리 후 재시도
nix store gc
make build
```

### 권한 문제 시
```bash
# build-switch는 처음부터 sudo 필요
sudo nix run --impure .#build-switch
```