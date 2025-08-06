# /analyze - 지능형 코드 분석

자동 감지 기반의 포괄적 분석 시스템

## 사용법
```bash
/analyze [target]              # 스마트 자동 분석
/analyze [target] --think      # 깊은 분석  
/analyze [target] --deep       # 최대 깊이 분석
```

## 분석 대상
- `[target]` - 파일, 디렉토리, 또는 시스템 컴포넌트 (기본: 현재 프로젝트)
- `@security` - 보안 중심 분석
- `@performance` - 성능 중심 분석
- `src/components` - 특정 디렉토리 분석

## 🤖 자동 지능화 시스템

### 시스템이 자동으로 수행
- 🔍 코드베이스 구조 분석 및 핵심 영역 식별
- 🎯 가장 중요한 이슈 감지 및 조사 우선순위 결정  
- ⚖️ 복잡도 평가 및 적절한 분석 깊이 선택
- 🤖 최적의 MCP 서버 선택 (Sequential, Context7, Magic 등)
- 📋 구조화된 분석 계획 수립
- ✅ 다차원 분석 실행 (품질+보안+성능+아키텍처)
- 📊 실행 가능한 인사이트로 종합

### Smart Routing Conditions

**Frontend Detection**: React/Vue components → Context7 (best practices) + Sequential (analysis) review
**Backend Detection**: APIs/databases → Context7 (patterns) + security-auditor consideration  
**Complex Architecture**: → Sequential MCP priority + Task delegation for system analysis
**Security Focus**: → security-auditor priority + Context7 (security patterns) support
**Nix/System Config**: → nix-system-expert priority delegation
**Performance Issues**: → performance-engineer + Sequential combination review

## 분석 영역 (자동 활성화)

### 📊 품질 분석

- 코드 복잡도, 유지보수성, 기술 부채, 테스트 품질

### 🛡️ 보안 분석

- 취약점 평가, 위협 모델링, 규정 준수, 보안 모범 사례

### ⚡ 성능 분석

- 병목점 식별, 확장성 평가, 리소스 최적화, 알고리즘 분석

### 🏗️ 아키텍처 분석

- 디자인 패턴 평가, 결합도 분석, 응집도 평가, 진화 준비도

## 출력 및 통합

### 스마트 출력

- **요약 보고서**: 비즈니스 영향 평가가 포함된 상위 수준 결과
- **상세 분석**: 증거가 포함된 포괄적 기술 결과
- **실행 로드맵**: 구현 지침이 포함된 우선순위 개선 계획

### 자동 연계

- **→ /improve**: 분석 결과를 체계적 개선으로 직접 전달
- **→ /implement**: 권장 솔루션 구현 트리거
- **↔️ /workflow**: 개발 워크플로우와 연계

## 예시

### 기본 스마트 분석

```bash
/analyze                           # 전체 자동 감지 및 포괄적 분석
/analyze src/components           # 컴포넌트 품질 및 패턴 분석  
/analyze api/                     # API 보안 및 성능 분석
```

### 깊이 있는 분석

```bash
/analyze src/ --think             # 아키텍처 인사이트를 포함한 깊은 분석
/analyze . --deep                 # 복잡한 시스템을 위한 최대 지능 분석
```

**Future of Code Analysis**: Just specify what to analyze and how deep to think - the system handles the rest automatically! 🌟
