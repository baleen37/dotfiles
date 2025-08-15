#!/usr/bin/env python3
import json
import re

# 실제 명령어 테스트
command = '''gh pr create --title "개선: Claude Code 설정 및 훅 경로 최적화" --body "## 요약
Claude Code 설정 및 훅 시스템을 개선하여 더 안정적이고 효율적인 개발 환경을 구축했습니다.

## 변경사항
- [x] 설정 변경
- [x] 문서 업데이트
- [x] 기능 추가/수정

### 주요 개선사항
1. **훅 경로 수정**: $CLAUDE_PROJECT_DIR 환경변수 사용으로 경로 문제 해결
2. **Context7 가이드라인 강화**: resolve-library-id 우선 사용, topic 파라미터 활용 명시
3. **체계적 디버깅 워크플로**: 5단계 디버깅 프로세스 추가
4. **언어 정책 명확화**: Claude Code에서 모든 대화는 한국어로 통일
5. **문서 연구 의사결정 트리**: Context7 → WebSearch → WebFetch 선택 기준 명확화
6. **훅 개선**: git-commit-validator.py 오탐지 문제 해결 및 테스트 코드 추가

## 테스트 계획
- [x] git commit --no-verify 차단 확인 (훅 작동 검증)
- [x] git commit 정상 작동 확인
- [x] 훅 테스트 코드 10개 케이스 모두 통과
- [x] gh pr create 명령 정상 작동 확인
- [x] pre-commit 훅 통과 확인

## 체크리스트
- [x] 코드가 프로젝트의 코딩 스타일을 따름
- [x] 자체 검토를 완료함
- [x] 필요한 경우 문서를 업데이트함
- [x] 변경사항이 기존 기능을 손상시키지 않음"'''

print("=== 명령어 분석 ===")
print(f"명령어: {command[:100]}...")

# git commit 명령인지 확인
git_commit_check = re.search(r"\bgit\s+commit\b", command)
print(f"git commit 명령인가? {bool(git_commit_check)}")

# --no-verify 포함 여부 확인
no_verify_simple = re.search(r"--no-verify", command)
print(f"--no-verify 포함 (단순)? {bool(no_verify_simple)}")

if no_verify_simple:
    # 위치 찾기
    for match in re.finditer(r"--no-verify", command):
        start, end = match.span()
        context = command[max(0, start-20):end+20]
        print(f"발견 위치: {start}-{end}, 컨텍스트: '{context}'")
