---
title: "/analyze - 지능형 코드 분석"
description: "자동 감지 기반의 포괄적 분석 시스템"
keywords: ["analyze", "code analysis", "mcp", "sequential", "thinkhard"]
---

# /analyze - 지능형 코드 분석

자동 감지 기반의 포괄적 분석 시스템

## 사용법

```bash
/analyze [target]              # 기본 분석
/analyze [target] --think      # Sequential MCP로 깊은 분석
/analyze [target] --deep       # 최대 깊이 종합 분석
/analyze [target] thinkhard    # 복잡한 문제 해결용 deep thinking
```

## 분석 대상

- `[target]` - 파일, 디렉토리, 또는 시스템 컴포넌트 (기본: 현재 프로젝트)
- `@security` - 보안 중심 분석
- `@performance` - 성능 중심 분석
- `src/components` - 특정 디렉토리 분석

## 🧠 Deep Thinking & Sequential Analysis

### thinkhard 모드
**복잡한 문제 해결용 Sequential thinking 활성화**
- 다단계 추론으로 문제의 근본 원인 분석
- 시스템 전체 맥락에서 문제 파악
- 단계별 검증을 통한 정확한 진단
- 실행 가능한 해결책 도출

### 자동 MCP 서버 선택
- **Sequential**: 복잡한 논리 분석, 다단계 추론 필요시
- **Context7**: 라이브러리/프레임워크 패턴 분석 필요시
- **Task**: 전문 도메인 분석 필요시 (보안, 성능, Nix 등)

### 자동 라우팅 조건

- **복잡한 버그**: Sequential MCP로 단계별 분석
- **아키텍처 문제**: Sequential + Task(general-purpose) 조합
- **보안 이슈**: Task(security-auditor) 우선 위임
- **성능 문제**: Task(performance-engineer) + Sequential 조합
- **Nix 설정**: Task(nix-system-expert) 즉시 위임

## 분석 영역

### 📊 품질 분석
- 코드 복잡도, 유지보수성, 기술 부채

### 🛡️ 보안 분석
- 취약점 평가, 보안 모범 사례

### ⚡ 성능 분석
- 병목점 식별, 리소스 최적화

### 🏗️ 아키텍처 분석
- 디자인 패턴, 결합도/응집도 평가

## 출력 형식

### 분석 결과
- **핵심 이슈**: 가장 중요한 문제점 요약
- **상세 분석**: 근거와 함께 제시
- **개선 방안**: 구체적이고 실행 가능한 해결책

### 명령어 연계
- **→ /improve**: 분석 결과 기반 개선 실행
- **→ /implement**: 권장 솔루션 구현
- **→ /debug**: 발견된 문제 디버깅

## 예시

### 기본 사용
```bash
/analyze                          # 전체 프로젝트 분석
/analyze src/auth.js             # 특정 파일 분석
/analyze api/                    # 디렉토리 분석
```

### 심화 분석
```bash
/analyze --think                 # Sequential MCP로 논리적 분석
/analyze auth.js thinkhard       # 복잡한 인증 로직 deep thinking
/analyze . --deep                # 전체 시스템 종합 분석
```

### 도메인 특화
```bash
/analyze @security               # 보안 중심 분석
/analyze @performance            # 성능 중심 분석
```
