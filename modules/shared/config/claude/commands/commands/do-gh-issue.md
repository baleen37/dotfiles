# Do GitHub Issue - GitHub Issues 기반 실행 및 구현

## Prerequisites
- Git 저장소여야 함
- GitHub 원격 저장소 설정되어 있어야 함
- GitHub Issues가 활성화되어 있어야 함

## Process

1. **환경 확인**
   - Git 저장소 상태 확인
   - GitHub 원격 저장소 연결 확인
   - 브랜치 전략 확인

2. **이슈 선택**
   - GitHub Issues 목록 확인
   - 작업할 이슈 선택 및 할당
   - 이슈 요구사항 분석

3. **브랜치 생성**
   - 이슈 번호 기반 브랜치 생성 (예: feature/#123-add-login)
   - 최신 main/master에서 브랜치 시작

4. **구현**
   - TDD 접근법 적용
   - 커밋 메시지에 이슈 번호 포함 (예: "feat: add login feature #123")
   - 기존 코드 스타일 준수

5. **품질 보증**
   - 모든 테스트 통과 확인
   - CI/CD 파이프라인 통과
   - 코드 리뷰 준비

6. **Pull Request 생성**
   - PR 템플릿 작성
   - 이슈 자동 연결 (Closes #123)
   - 리뷰어 할당

7. **이슈 관리**
   - PR 머지 시 이슈 자동 종료
   - 필요시 관련 이슈 생성

## GitHub CLI 명령어
```bash
# 이슈 목록 보기
gh issue list

# 이슈 생성
gh issue create --title "Title" --body "Description"

# PR 생성
gh pr create --title "Title" --body "Closes #123"

# 이슈 상태 변경
gh issue close 123
```

## Next Step
- PR 리뷰 대기 또는 다음 이슈 작업
