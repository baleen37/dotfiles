---
name: restore
description: "Restore previously saved TodoWrite state and work context"
agents: []
---

# /restore - Restore Work State

**Purpose**: 저장된 TodoWrite 상태와 작업 컨텍스트를 복원

## Usage

```bash
/restore                     # 저장된 플랜 목록 보기
/restore <name>              # 특정 플랜 복원 (이름/부분 검색)
/restore <number>            # 리스트에서 번호로 선택
```

## List Mode

`.claude/plans/` 디렉토리에서 `plan_*.md` 파일 스캔:

```
📋 저장된 플랜 3개 발견:

1. fix-build-errors (2024-08-12 15:30)
   상태: pending(2), in-progress(1), completed(0)
   컨텍스트: lib/platform-system.nix 빌드 오류 수정 중

2. config-improvements (2024-08-11 09:15)
   상태: pending(1), in-progress(0), completed(3)
   컨텍스트: Claude 명령어 세션 관리 개선

3. nix-update (2024-08-10 14:00)
   상태: pending(0), in-progress(1), completed(4)
   컨텍스트: flake inputs 업데이트 및 크로스 플랫폼 테스트
```

## Restore Process

복원 전 확인 메시지:

```
🔄 플랜 복원: fix-build-errors

현재 할 일 목록이 다음으로 교체됩니다:

🔄 진행 중 (1):
  - platform-system.nix syntax 오류 수정

📋 대기 중 (2):
  - 테스트 실행 및 검증
  - 문서 업데이트

계속하시겠습니까? [Y/n]
```

## Implementation Details

1. **File Discovery**: `.claude/plans/plan_*.md` 검색
2. **Markdown Parsing**: ## Current Todos 섹션에서 상태 추출
3. **Fuzzy Matching**: 단어 부분 매칭 (예: "build" → "fix-build-errors")
4. **State Restoration**: TodoWrite로 정확한 상태 재생성
5. **Coordination**: `/save`와 동일한 markdown 형식 사용
6. **Safety**: 복원 전 현재 상태 보여주고 확인 요청
