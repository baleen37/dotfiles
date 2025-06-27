# Do Jira - Jira 티켓 기반 실행 및 구현

## Prerequisites
- Jira 프로젝트 설정되어 있어야 함
- Jira API 토큰 또는 인증 설정
- 프로젝트 키 및 워크플로우 이해

## Process

1. **환경 확인**
   - Jira 연결 상태 확인
   - 프로젝트 워크플로우 확인
   - 개발 환경 설정

2. **티켓 선택**
   - 스프린트 백로그 확인
   - 티켓 할당 및 상태 변경 (To Do → In Progress)
   - 수락 기준(Acceptance Criteria) 분석

3. **브랜치 생성**
   - Jira 티켓 키 기반 브랜치 생성 (예: feature/PROJ-123-user-authentication)
   - 티켓과 브랜치 연결

4. **구현**
   - TDD 접근법 적용
   - 커밋 메시지에 티켓 키 포함 (예: "PROJ-123: Add user authentication")
   - Jira 스마트 커밋 활용

5. **품질 보증**
   - Definition of Done 체크리스트 확인
   - 모든 테스트 통과
   - 코드 리뷰 준비

6. **티켓 업데이트**
   - 작업 로그 기록
   - 상태 변경 (In Progress → Code Review → Done)
   - 필요한 문서 첨부

7. **통합 및 배포**
   - PR/MR 생성 및 Jira 연동
   - 빌드 및 배포 상태 Jira에 반영
   - 릴리스 노트 업데이트

## Jira 스마트 커밋
```bash
# 시간 기록과 함께 커밋
git commit -m "PROJ-123 #time 2h #comment 로그인 기능 구현 완료"

# 티켓 상태 변경
git commit -m "PROJ-123 #done #comment 모든 테스트 통과"

# 여러 작업 동시 처리
git commit -m "PROJ-123 #time 1h #status In Review #comment PR 생성"
```

## Next Step
- 코드 리뷰 대기 또는 다음 스프린트 티켓 작업
