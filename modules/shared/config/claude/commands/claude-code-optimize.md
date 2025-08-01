# /claude-code-optimize - Claude Code 워크플로우 최적화

Claude Code 환경의 개발 생산성을 극대화하는 지능형 최적화 도구.

## Purpose
- **워크플로우 분석**: 현재 Claude Code 활용 패턴의 효율성 진단
- **MCP 서버 최적화**: Context7, Sequential, Magic, Playwright 조합 전략 수립
- **Subagent 협업 개선**: 전문가 간 협업 패턴 최적화 및 자동화 구축
- **메타 코딩 강화**: Claude Code 자체를 더 효율적으로 활용하는 방법 제안
- **생산성 극대화**: 개인화된 최적화 전략으로 개발 효율성 향상

## Usage
```bash
/claude-code-optimize                               # 전체 워크플로우 최적화 분석
/claude-code-optimize --focus mcp                   # MCP 서버 활용 최적화
/claude-code-optimize --focus subagents             # Subagent 협업 패턴 최적화
/claude-code-optimize --focus automation            # 자동화 패턴 구축
/claude-code-optimize --think                       # 심화 분석 모드
/claude-code-optimize --ultrathink                  # 종합 최적화 전략 수립
```

## Process

### 1. 현황 분석 단계
**Current State Assessment**:
- Claude Code 도구 활용 패턴 분석
  - Task, TodoWrite, 사고 모드 플래그 사용 빈도와 효율성
  - MCP 서버 (Context7, Sequential, Magic, Playwright) 활용도
  - Subagent 협업 패턴과 성공률
- 비효율성 포인트 식별
  - 반복적 수작업이 발생하는 영역
  - 과도한 컨텍스트 스위칭 지점
  - 불필요한 도구 중복 사용 패턴
- 개선 기회 발굴
  - 자동화 가능한 워크플로우
  - 최적화 잠재력이 높은 작업 유형

### 2. 최적화 전략 설계
**MCP Server Orchestration**:
```python
# 지능형 MCP 서버 선택 로직 (의사코드)
def optimize_mcp_selection(task_context):
    if requires_documentation_research(task_context):
        return ['Context7'] + complementary_servers(task_context)
    elif requires_systematic_analysis(task_context):
        return ['Sequential'] + parallel_servers(task_context)
    elif involves_ui_components(task_context):
        return ['Magic'] + integration_servers(task_context)
    elif needs_testing_automation(task_context):
        return ['Playwright'] + validation_servers(task_context)
    else:
        return smart_combination(task_context)
```

**Subagent Collaboration Patterns**:
- **순차적 전문가 체인**: debugger → performance-engineer → code-reviewer
- **병렬 분석 협업**: 독립적 도메인의 동시 분석으로 시간 단축
- **전문성 기반 자동 선택**: 작업 특성에 따른 최적 전문가 자동 배정

**Thinking Mode Optimization**:
- 작업 복잡도 자동 감지 → 적절한 --think 레벨 제안
- 특화 모드 활용: --analyze, --debug, --architect, --optimize
- 플래그 조합으로 정밀한 사고 모드 구성

### 3. 자동화 패턴 구축
**Workflow Templates**:
```
기능 개발 최적화 템플릿:
1. Context7 (병렬) → 관련 라이브러리 패턴 조사
2. Sequential (병렬) → 구현 전략 수립
3. TodoWrite → 단계별 작업 관리
4. 구현 → 도메인별 전문가 자동 활용
5. code-reviewer → 자동 품질 검증
6. security-auditor → 보안 점검
7. test-automator → 테스트 보장
```

**Quality Gates**:
- 자동 lint/typecheck 실행
- 단계별 검증과 피드백 루프
- 예방적 문제 감지와 해결

**Batch Operations**:
- 관련 작업들의 효율적 그룹화
- 병렬 처리 가능한 작업 자동 식별
- 컨텍스트 연속성 보장

### 4. 개인화 최적화
**Pattern Learning**:
- jito의 성공적 워크플로우 패턴 학습
- 선호도 기반 도구 조합 추천
- 작업 유형별 최적 접근법 체계화

**Adaptive Recommendations**:
- 사용 패턴 분석 기반 개선 제안
- 새로운 기능과 패턴의 점진적 도입
- 피드백 기반 지속적 최적화

## 주요 최적화 영역

### 🧠 지능형 작업 분해
- **복잡도 기반 분해**: 작업을 최적 단위로 자동 분해
- **병렬/순차 결정**: 의존성 분석으로 최적 실행 순서 결정
- **리소스 최적화**: 메모리와 컨텍스트 효율적 활용

### 🤖 MCP 서버 마스터리
- **Context7 최적화**: 문서 조사와 패턴 검색 효율성 극대화
- **Sequential 활용**: 복잡한 분석 작업의 체계적 처리
- **Magic 통합**: UI 작업에서 디자인 시스템 자동 적용
- **Playwright 연계**: 테스트 자동화 워크플로우 구축

### 🎯 Subagent 협업 혁신
- **전문가 체인 최적화**: 작업별 최적 전문가 순서 자동 구성
- **병렬 협업 극대화**: 독립적 작업의 동시 진행으로 시간 단축
- **컨텍스트 관리**: 전문가 간 정보 연속성 자동 보장

### 💡 메타 코딩 능력 강화
- **자동화 템플릿**: 반복 패턴의 지능적 템플릿화
- **사고 모드 최적화**: 상황별 최적 --think 레벨 자동 선택
- **학습 기반 개선**: 성공 패턴 학습과 적응적 최적화

## 실전 적용 예시

### 📊 현황 분석 결과 예시
```
분석 결과:
✅ 강점: TodoWrite 활용률 95%, 체계적 작업 관리 우수
⚠️  개선점: MCP 서버 조합 효율성 68% - Sequential+Context7 동시 활용 부족
❌ 문제점: 반복적 수작업 35% - 자동화 템플릿 구축 필요

우선 개선 영역:
1. MCP 서버 병렬 활용 (예상 효율성 증대: 40%)
2. 자동화 워크플로우 구축 (반복 작업 70% 감소)
3. Subagent 협업 패턴 최적화 (품질 향상 25%)
```

### 🚀 최적화 전략 예시
```
개인화된 최적화 전략:
- 문서 조사 + 구현 작업 → Context7과 Sequential 병렬 활용
- 복잡한 디버깅 → debugger(--debug) + performance-engineer 체인
- UI 컴포넌트 작업 → Magic + security-auditor 자동 연계
- 아키텍처 설계 → Sequential(--architect) + cloud-architect 협업
```

### 📈 성과 측정 지표
- **효율성 지표**: 작업 완료 시간 25-40% 단축
- **품질 지표**: 자동 검증 통과율 95% 이상 달성
- **만족도 지표**: 워크플로우 만족도 향상
- **학습 지표**: 새로운 패턴 적용 성공률 추적

## 통합 연계

### → 다른 Commands와 연계
- **→ /implement**: 최적화된 구현 전략 자동 적용
- **→ /analyze**: 분석 워크플로우 최적화 패턴 활용
- **→ /task**: 작업 관리 효율성 개선 연계
- **← /workflow**: 전체 개발 프로세스 최적화

### ↔️ Agent 협업
- **claude-code-expert**: 메타 코딩 전문성 활용
- **performance-engineer**: 워크플로우 성능 최적화
- **code-reviewer**: 최적화 결과 품질 검증

## 기대 효과

### 🎯 즉시 효과
- 작업 시간 25-40% 단축
- 반복 작업 자동화로 인지 부하 감소
- 품질 게이트 자동화로 안정성 향상

### 📈 중장기 효과
- 개인화된 워크플로우 템플릿 구축
- 학습 기반 지속적 최적화 시스템
- Claude Code 마스터리 수준 도달

### 🌟 메타 효과
- 메타 코딩 능력으로 도구 활용 극대화
- 자동화 패턴으로 창의적 작업 집중 가능
- 지속적 학습으로 생산성 복리 효과

**jito의 개발 생산성을 극대화하는 지능형 최적화 - Claude Code의 모든 잠재력을 실현합니다! 🚀**
