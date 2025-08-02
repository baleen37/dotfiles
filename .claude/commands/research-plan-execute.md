# research-plan-execute: 복잡한 다단계 작업의 체계적 실행

ABOUTME: 복잡한 개발/분석 작업을 Research-Plan-Execute 3단계로 구조화하여 실행
ABOUTME: Task 도구와 sub-agent를 활용한 병렬 처리 및 품질 보장 자동화

## 핵심 원칙

**YAGNI 우선**: 과도한 복잡성 제거, 실용적 자동화만 유지
**병렬 최적화**: 독립적 작업들을 배치로 실행
**명확한 게이트**: 각 단계별 명확한 완료 기준
**Fallback 체인**: 단순한 룰 기반 에이전트 선택

## 3단계 워크플로우

### 1. Research (조사)
**목적**: 현황 파악, 요구사항 분석, 제약조건 식별

**자동 실행 조건**:
- 파일 수 > 10개 또는 키워드 감지 (analyze, investigate, audit)
- 새로운 기술 스택/라이브러리 언급
- 레거시 시스템 현대화 요청

**배치 실행**:
```bash
# 독립적 조사 작업들을 병렬 실행
Task: "코드베이스 현황 분석" + "의존성 분석" + "성능 기준선 측정"
```

**산출물**: 현황 요약, 제약조건 목록, 위험 요소

### 2. Plan (계획)
**목적**: 실행 전략 수립, 작업 분할, 품질 기준 설정

**Sub-agent 선택 룰**:
- Frontend 키워드 → Magic 우선
- Backend/API 키워드 → Context7 우선  
- 복잡한 분석 → Sequential 우선
- 테스팅 → Playwright 우선

**산출물**: 구체적 작업 계획, 우선순위, 완료 기준

### 3. Execute (실행)
**목적**: 계획된 작업 실행, 품질 검증, 결과 통합

**병렬 실행 패턴**:
```bash
# 독립적 구현 작업들
Task: "Backend 구현" + "Frontend 구현" + "테스트 작성"
```

**Quality Gates**:
- 코드 동작 확인
- 테스트 통과
- 기존 패턴 준수

## Sub-agent 활용 전략

### 에이전트 매칭 (단순 룰 기반)

**Analyzer Agent** (`--think` 자동 활성화):
- 트리거: debug, analyze, investigate, audit
- 도구: Grep + Read + Sequential
- 출력: 구조화된 분석 리포트

**Builder Agent**:
- 트리거: implement, create, build, develop  
- 도구: Read + Write + Edit + Context7
- 출력: 동작하는 코드, 구현 문서

**Tester Agent**:
- 트리거: test, validate, verify, quality
- 도구: Bash + Playwright (필요시)
- 출력: 테스트 코드, 검증 결과

### Fallback 체인
1. 특화 에이전트 시도
2. 실패 시 Sequential로 일반 분석
3. 최종적으로 수동 단계별 실행

## 사용 예시

### 예시 1: 성능 최적화
```
Input: "React 앱 성능 최적화"

Research Task:
- 현재 성능 지표 측정
- 번들 크기 분석  
- 렌더링 병목점 식별

Plan:
- 우선순위: 번들 크기 > 렌더링 > 네트워크
- 작업 분할: 코드 스플리팅, 메모이제이션, 이미지 최적화

Execute Tasks (병렬):
- 번들 분석 및 최적화
- 컴포넌트 메모이제이션
- 성능 테스트 작성
```

### 예시 2: 새 기능 개발
```
Input: "사용자 인증 시스템 구현"

Research Task:
- 기존 인증 패턴 조사
- 보안 요구사항 분석
- 사용 가능한 라이브러리 검토

Plan:
- 아키텍처: JWT + Refresh Token
- 구현 순서: Backend API → Frontend UI → 테스트

Execute Tasks (병렬):
- 인증 API 구현 (Backend Agent)
- 로그인 UI 구현 (Frontend Agent)  
- E2E 테스트 작성 (Tester Agent)
```

## 품질 보장

### 각 단계별 완료 기준

**Research 완료**:
- 핵심 제약조건 식별됨
- 위험 요소 문서화됨
- 필요한 정보 수집 완료

**Plan 완료**:
- 구체적 작업 목록 작성됨
- 우선순위 설정됨
- 성공 기준 정의됨

**Execute 완료**:
- 모든 테스트 통과
- 코드 리뷰 기준 충족
- 문서화 완료

### 자동 검증
```bash
# 각 단계 완료 시 자동 실행
make test && make lint && make build
```

## 실패 처리

### 단계별 실패 대응
- **Research 실패**: 수동 정보 수집으로 전환
- **Plan 실패**: 더 단순한 접근법으로 재계획
- **Execute 실패**: 단계별 디버깅 후 부분 재실행

### 품질 저하 허용
- 완벽하지 않더라도 최소 기능은 확보
- 점진적 개선 가능한 구조 유지
- 명확한 기술 부채 문서화

## 성능 최적화

### 토큰 효율성
- 핵심 정보만 전달
- 불필요한 컨텍스트 제거
- 구조화된 산출물로 재사용성 향상

### 병렬 처리
- 독립적 작업 최대한 배치 실행
- Task 도구로 무거운 작업 분산
- MCP 서버 자동 선택으로 최적화

### 캐싱 활용
- 분석 결과 세션 내 재사용
- 패턴 학습 결과 활용
- 중복 작업 방지
