# Task 도구와 Subagent 활용 지침

Claude Code의 Task 도구를 통한 전문 subagent 활용 전략과 협업 패턴.

## Task 도구 핵심 개념

### Subagent 자동 선택
Claude Code는 작업 컨텍스트에 따라 적절한 전문 subagent를 자동으로 선택:
- **코드 작성 완료 시**: `code-reviewer` 자동 실행
- **에러 발생 시**: `debugger` 자동 활성화  
- **성능 이슈 시**: `performance-engineer` 자동 위임
- **보안 검토 시**: `security-auditor` 자동 호출

### 명시적 Subagent 호출
특정 전문가가 필요한 경우 직접 지정:
```
"code-reviewer로 이 코드를 검토해줘"
"security-auditor로 인증 로직을 점검해줘"  
"performance-engineer로 이 쿼리를 최적화해줘"
```

### 컨텍스트 기반 지능형 자동 선택
키워드와 상황을 분석하여 최적의 subagent 자동 선택:

#### 키워드 매칭 자동화
**보안 관련 키워드**:
- "보안", "취약점", "인증", "권한", "암호화" → security-auditor 자동 호출
- "SQL 인젝션", "XSS", "CSRF" → security-auditor 우선 활성화

**성능 관련 키워드**:
- "성능", "느림", "최적화", "병목", "속도" → performance-engineer 자동 호출
- "메모리", "CPU", "쿼리 최적화" → performance-engineer 우선 활성화

**에러/디버깅 키워드**:
- "에러", "버그", "실패", "오류", "문제" → debugger 자동 호출
- "예외", "크래시", "타임아웃" → debugger 우선 활성화

**코드 품질 키워드**:
- "리뷰", "개선", "리팩토링", "클린업" → code-reviewer 자동 호출
- "가독성", "유지보수", "구조" → code-reviewer 우선 활성화

#### 상황별 자동 활성화
**코드 작성 완료 감지**:
- 새로운 함수/컴포넌트 구현 완료 → code-reviewer 자동 실행
- 복잡한 로직 구현 후 → performance-engineer 자동 검토 제안

**테스트 관련 작업**:
- "테스트", "E2E", "단위테스트" → test-automator 자동 호출
- 테스트 실패 감지 → debugger + test-automator 체인 실행

## 작업 분해와 병렬 처리

### 복잡한 작업의 단계별 분해
1. **TodoWrite 도구 우선 사용**: 작업을 체계적으로 추적
2. **단일 작업 in_progress**: 한 번에 하나의 작업만 진행 상태로 유지
3. **즉시 완료 표시**: 작업 완료 즉시 상태 업데이트

### 지능형 작업 복잡도 감지
작업 요청을 분석하여 자동으로 복잡도 판단하고 적절한 분해 전략 적용:

#### 복잡도 자동 감지 기준
**단순 작업 (1-2단계)**:
- 단일 파일 수정, 명확한 단일 목적
- 예: "이 함수에 주석 추가해줘"
- → 직접 처리, TodoWrite 불필요

**중복잡 작업 (3-5단계)**:
- 여러 파일 관련, 다단계 논리 필요
- 예: "사용자 로그인 기능 구현해줘"
- → TodoWrite 자동 생성, 3-5개 하위 작업으로 분해

**고복잡 작업 (6단계+)**:
- 시스템 전반, 아키텍처 변경, 다양한 기술 스택
- 예: "전체 인증 시스템 재설계해줘"
- → TodoWrite + Task 도구 조합, 다중 subagent 병렬 활용

#### 자동 분해 알고리즘
```python
# 의사코드
def auto_task_breakdown(user_request):
    complexity_score = analyze_complexity(user_request)

    if complexity_score >= 6:
        # 고복잡: TodoWrite + Task 도구 + 다중 subagent
        return {
            'strategy': 'multi_agent_parallel',
            'tools': ['TodoWrite', 'Task'],
            'estimated_subtasks': 6-10,
            'subagents': ['backend-architect', 'security-auditor', 'test-automator']
        }
    elif complexity_score >= 3:
        # 중복잡: TodoWrite + 순차 subagent
        return {
            'strategy': 'sequential_breakdown',
            'tools': ['TodoWrite'],
            'estimated_subtasks': 3-5,
            'subagents': ['code-reviewer']
        }
    else:
        # 단순: 직접 처리
        return {
            'strategy': 'direct_execution',
            'tools': [],
            'estimated_subtasks': 1-2,
            'subagents': []
        }
```

### 병렬 작업 전략
- **독립적 분석**: 여러 파일을 동시에 다른 subagent에게 위임
- **도메인별 분리**: Frontend/Backend 작업을 각각 전문 subagent에게 할당
- **검증 단계**: 구현 완료 후 자동으로 품질 검증 subagent 실행

## Subagent 협업 패턴

### 순차적 협업
```
1. backend-architect: API 설계
2. database-optimizer: 스키마 최적화  
3. security-auditor: 보안 검증
4. test-automator: 테스트 작성
5. code-reviewer: 최종 검토
```

### 병렬 협업
```
동시 실행:
- frontend-developer: UI 컴포넌트 구현
- backend-architect: API 엔드포인트 설계
- database-optimizer: 데이터 모델링
```

### 전문성 체인
```
debugger → performance-engineer → code-reviewer
(오류 발견) → (성능 최적화) → (품질 검증)
```

## 실무 적용 가이드

### 새 기능 개발
1. **계획 단계**: Task 도구로 작업 분해
2. **구현 단계**: 도메인별 전문 subagent 활용
3. **검증 단계**: 자동 품질 검증 체인 실행

### 버그 수정
1. **debugger**: 문제 원인 분석
2. **관련 전문가**: 도메인별 해결책 제시
3. **test-automator**: 회귀 방지 테스트 작성
4. **code-reviewer**: 수정사항 검토

### 코드 리뷰
1. **code-reviewer**: 전반적 품질 검토
2. **security-auditor**: 보안 취약점 점검
3. **performance-engineer**: 성능 최적화 기회 식별

## 효율성 극대화

### 컨텍스트 유지
- **상태 연속성**: subagent 간 작업 결과 자동 전달
- **메모리 활용**: 이전 subagent 결과를 다음 작업에 활용
- **오류 복구**: 실패한 subagent 작업의 자동 대안 제시

### 학습과 개선
- **패턴 인식**: 자주 사용되는 subagent 조합 학습
- **효율성 추적**: 작업별 최적 subagent 선택 패턴 분석
- **자동 최적화**: 사용자 선호도에 따른 자동 조정

## 품질 보장

### 자동 검증 체인
모든 코드 변경 시 자동 실행:
1. **code-reviewer**: 코드 품질 검증
2. **security-auditor**: 보안 취약점 점검  
3. **test-automator**: 테스트 커버리지 확인
4. **performance-engineer**: 성능 영향 분석

### 오류 방지
- **사전 검증**: 구현 전 설계 단계에서 전문가 검토
- **단계별 확인**: 각 subagent 작업 완료 시 결과 검증
- **롤백 준비**: 문제 발생 시 즉시 이전 상태로 복원 가능
