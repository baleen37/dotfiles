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

## 작업 분해와 병렬 처리

### 복잡한 작업의 단계별 분해
1. **TodoWrite 도구 우선 사용**: 작업을 체계적으로 추적
2. **단일 작업 in_progress**: 한 번에 하나의 작업만 진행 상태로 유지
3. **즉시 완료 표시**: 작업 완료 즉시 상태 업데이트

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
