# Fix GitHub Issue

GitHub 이슈를 분석하고 수정하는 명령어입니다.

## 사용법
```
/project:fix-github-issue <issue-number>
```

## 실행 단계

GitHub 이슈를 분석하고 수정하기 위해 다음 단계를 따릅니다:

1. `gh issue view <issue-number>`를 사용하여 이슈 세부 정보 확인
2. 이슈에서 설명된 문제점 파악
3. 관련 파일을 찾기 위해 코드베이스 검색
4. 이슈를 해결하기 위한 필요한 변경사항 구현
5. 수정 사항을 검증하기 위한 테스트 작성 및 실행
6. 코드가 linting 및 타입 체크를 통과하는지 확인
7. 설명적인 커밋 메시지 작성
8. 푸시 및 PR 생성

모든 GitHub 관련 작업에는 GitHub CLI (`gh`)를 사용합니다.

## 예시
```
/project:fix-github-issue 123
```

이 명령어는 이슈 #123을 분석하고 수정합니다.