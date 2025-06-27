# ssulmeta-go

Hexagonal Architecture를 적용한 Go 웹 애플리케이션 예제입니다.

## 프로젝트 구조

이 프로젝트는 **Hexagonal Architecture** (Ports and Adapters Pattern)를 사용하여 구성되어 있습니다.

```
ssulmeta-go/
├── cmd/
│   └── api/
│       └── main.go              # HTTP 서버 엔트리포인트
├── internal/                    
│   ├── calculator/              # 계산기 기능
│   │   ├── core/               # 비즈니스 로직
│   │   ├── ports/              # 인터페이스
│   │   └── adapters/           # HTTP 어댑터
│   ├── text/                    # 텍스트 처리 기능
│   │   ├── core/               # 비즈니스 로직
│   │   ├── ports/              # 인터페이스
│   │   └── adapters/           # HTTP 어댑터
│   └── health/                  # 헬스체크
│       └── adapters/           # HTTP 어댑터
├── ARCHITECTURE.md              # 아키텍처 상세 문서
└── CLAUDE.md                    # 개발 가이드라인
```

## 시작하기

### 필수 요구사항

- Go 1.19 이상
- Nix (선택사항, 개발 환경용)

### 개발 환경 설정

#### 빠른 설정 (권장)

새로운 개발자는 다음 명령어로 모든 개발 도구와 git hooks를 한 번에 설치할 수 있습니다:

```bash
# 모든 개발 도구 및 hooks 자동 설치
make setup-dev
```

이 명령어는 다음을 자동으로 수행합니다:
- `goimports` 설치 (코드 포맷팅)
- `golangci-lint` 설치 (코드 품질 검사)
- Git pre-commit hooks 설정 (커밋 시 자동 검사)

#### 개별 설치

필요에 따라 개별적으로 설치할 수도 있습니다:

```bash
# 개발 도구만 설치
make install-tools

# Git hooks만 설치
make setup-hooks
```

#### Nix 사용 (선택사항)

Nix를 사용하는 경우:
```bash
direnv allow
# 또는
nix develop
```

### 빌드 및 실행

```bash
# 빌드
go build -o ssulmeta-api ./cmd/api

# 실행
./ssulmeta-api
# 또는
go run ./cmd/api
```

서버는 기본적으로 `:8080` 포트에서 실행됩니다.

## API 엔드포인트

### 헬스체크
```bash
GET /health
```

응답 예시:
```json
{
    "status": "healthy",
    "service": "ssulmeta-go"
}
```

### 계산기 기능

#### 덧셈
```bash
GET /calculator/add?a=5&b=3
```

응답 예시:
```json
{
    "result": 8,
    "operation": "add",
    "a": 5,
    "b": 3
}
```

#### 곱셈
```bash
GET /calculator/multiply?a=5&b=3
```

응답 예시:
```json
{
    "result": 15,
    "operation": "multiply",
    "a": 5,
    "b": 3
}
```

### 텍스트 처리 기능

#### 문자열 뒤집기
```bash
GET /text/reverse?text=hello
```

응답 예시:
```json
{
    "result": "olleh",
    "operation": "reverse",
    "original": "hello"
}
```

#### 대문자 변환
```bash
GET /text/capitalize?text=hello%20world
```

응답 예시:
```json
{
    "result": "Hello World",
    "operation": "capitalize",
    "original": "hello world"
}
```

## 테스트

```bash
# 모든 테스트 실행
go test ./...

# 상세 출력과 함께 실행
go test -v ./...

# 커버리지와 함께 실행
go test -cover ./...

# 벤치마크 실행
go test -bench=. ./...
```

## 코드 품질

### 린트
```bash
golangci-lint run ./...
```

### 포맷팅
```bash
gofmt -w .
goimports -w .
```

## 아키텍처

이 프로젝트는 Hexagonal Architecture를 따릅니다:

- **Core**: 순수한 비즈니스 로직 (외부 의존성 없음)
- **Ports**: 코어가 제공하는 기능의 인터페이스
- **Adapters**: 외부 시스템과의 통신 (HTTP, DB 등)

자세한 내용은 [ARCHITECTURE.md](./ARCHITECTURE.md)를 참조하세요.

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.