# Hexagonal Architecture Guide

이 문서는 ssulmeta-go 프로젝트의 헥사고날 아키텍처 구조를 설명합니다.

## 아키텍처 개요

이 프로젝트는 **Hexagonal Architecture** (Ports and Adapters Pattern)와 **Feature-First** 구조를 결합하여 구현되었습니다.

### 핵심 원칙

1. **비즈니스 로직 격리**: 코어 도메인 로직은 외부 의존성으로부터 완전히 분리
2. **의존성 역전**: 모든 의존성은 안쪽(코어)을 향함
3. **Feature-First 구성**: 기능별로 모든 레이어를 함께 배치
4. **테스트 용이성**: 각 레이어를 독립적으로 테스트 가능

## 디렉토리 구조

```
ssulmeta-go/
├── cmd/
│   └── api/
│       └── main.go              # HTTP 서버 엔트리포인트
├── internal/                    # 내부 패키지 (외부에서 접근 불가)
│   ├── calculator/              # 계산기 기능
│   │   ├── core/               
│   │   │   └── calculator.go    # 비즈니스 로직 (순수 함수)
│   │   ├── ports/              
│   │   │   └── calculator.go    # 입출력 인터페이스 정의
│   │   └── adapters/           
│   │       └── http.go          # HTTP 핸들러 구현
│   ├── text/                    # 텍스트 처리 기능
│   │   ├── core/
│   │   │   └── processor.go     # 비즈니스 로직
│   │   ├── ports/
│   │   │   └── processor.go     # 인터페이스 정의
│   │   └── adapters/
│   │       └── http.go          # HTTP 핸들러 구현
│   └── health/                  # 헬스체크 기능
│       └── adapters/
│           └── http.go          # 단순 핸들러 (포트/코어 불필요)
```

## 레이어 설명

### 1. Core (비즈니스 로직)

코어는 순수한 비즈니스 로직을 포함합니다. 외부 의존성이 없으며, 프레임워크나 데이터베이스와 무관합니다.

```go
// internal/calculator/core/calculator.go
type Calculator struct{}

func (c *Calculator) Add(a, b int) int {
    return a + b
}
```

**특징:**
- 순수 함수와 구조체만 포함
- 외부 패키지 import 최소화
- 100% 테스트 가능
- 비즈니스 규칙과 도메인 로직 구현

### 2. Ports (인터페이스)

포트는 코어와 외부 세계 간의 계약을 정의합니다.

```go
// internal/calculator/ports/calculator.go
type CalculatorService interface {
    Add(a, b int) int
    Multiply(a, b int) int
}
```

**특징:**
- 인터페이스만 정의
- 코어가 제공하는 기능 명세
- 어댑터가 의존하는 계약

### 3. Adapters (외부 통신)

어댑터는 외부 시스템과의 통신을 담당합니다.

```go
// internal/calculator/adapters/http.go
type HTTPAdapter struct {
    calc ports.CalculatorService
}

func (h *HTTPAdapter) HandleAdd(w http.ResponseWriter, r *http.Request) {
    // HTTP 요청 처리 → 코어 호출 → HTTP 응답
}
```

**특징:**
- HTTP, 데이터베이스, 메시지 큐 등과의 통신
- 포트 인터페이스에 의존
- 외부 프로토콜을 내부 도메인으로 변환

## 의존성 주입

`cmd/api/main.go`에서 모든 의존성을 조립합니다:

```go
func main() {
    // 1. 코어 생성
    calculator := calcCore.NewCalculator()
    textProcessor := textCore.NewProcessor()

    // 2. 어댑터에 코어 주입
    calcAdapter := calcAdapters.NewHTTPAdapter(calculator)
    textAdapter := textAdapters.NewHTTPAdapter(textProcessor)

    // 3. HTTP 라우팅 설정
    mux := http.NewServeMux()
    mux.HandleFunc("/calculator/add", calcAdapter.HandleAdd)
    // ...
}
```

## 새로운 기능 추가하기

### 1. 기능 디렉토리 생성

```bash
mkdir -p internal/myfeature/{core,ports,adapters}
```

### 2. 포트 정의

```go
// internal/myfeature/ports/myfeature.go
package ports

type MyFeatureService interface {
    DoSomething(input string) (string, error)
}
```

### 3. 코어 구현

```go
// internal/myfeature/core/myfeature.go
package core

type MyFeature struct{}

func NewMyFeature() *MyFeature {
    return &MyFeature{}
}

func (f *MyFeature) DoSomething(input string) (string, error) {
    // 비즈니스 로직 구현
    return "processed: " + input, nil
}
```

### 4. 어댑터 구현

```go
// internal/myfeature/adapters/http.go
package adapters

type HTTPAdapter struct {
    feature ports.MyFeatureService
}

func NewHTTPAdapter(feature ports.MyFeatureService) *HTTPAdapter {
    return &HTTPAdapter{feature: feature}
}

func (h *HTTPAdapter) HandleRequest(w http.ResponseWriter, r *http.Request) {
    // HTTP 요청 처리
}
```

### 5. 메인에 통합

```go
// cmd/api/main.go에 추가
myFeature := myFeatureCore.NewMyFeature()
myFeatureAdapter := myFeatureAdapters.NewHTTPAdapter(myFeature)
mux.HandleFunc("/myfeature", myFeatureAdapter.HandleRequest)
```

## 테스트 전략

### 1. 코어 테스트

비즈니스 로직의 단위 테스트:

```go
func TestMyFeature_DoSomething(t *testing.T) {
    feature := NewMyFeature()
    result, err := feature.DoSomething("test")
    assert.NoError(t, err)
    assert.Equal(t, "processed: test", result)
}
```

### 2. 어댑터 테스트

HTTP 핸들러 테스트:

```go
func TestHTTPAdapter_HandleRequest(t *testing.T) {
    feature := mockFeature{} // 또는 실제 구현
    adapter := NewHTTPAdapter(feature)
    
    req := httptest.NewRequest("GET", "/myfeature", nil)
    rr := httptest.NewRecorder()
    
    adapter.HandleRequest(rr, req)
    assert.Equal(t, http.StatusOK, rr.Code)
}
```

### 3. 통합 테스트

전체 시스템 테스트:

```go
func TestFullIntegration(t *testing.T) {
    srv := setupServer()
    ts := httptest.NewServer(srv.Handler)
    defer ts.Close()
    
    resp, err := http.Get(ts.URL + "/myfeature")
    assert.NoError(t, err)
    assert.Equal(t, http.StatusOK, resp.StatusCode)
}
```

## 장점

1. **테스트 용이성**: 각 레이어를 독립적으로 테스트 가능
2. **유연성**: 어댑터를 교체하여 다른 프로토콜 지원 가능
3. **명확한 경계**: 각 레이어의 책임이 명확히 분리
4. **확장성**: 새로운 기능을 쉽게 추가 가능
5. **유지보수성**: 변경사항이 격리되어 영향 범위 최소화

## 주의사항

1. **과도한 추상화 피하기**: 필요하지 않은 인터페이스는 만들지 않음
2. **YAGNI 원칙**: 당장 필요하지 않은 기능은 구현하지 않음
3. **실용주의**: 단순한 기능(예: 헬스체크)은 어댑터만으로 충분

## 참고 자료

- [Hexagonal Architecture by Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)
- [Ports and Adapters Pattern](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software))
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)