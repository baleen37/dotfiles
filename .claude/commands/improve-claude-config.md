---
description: Diagnose Claude Code configuration and suggest improvements based on best practices from official documentation and release notes.
---

User input:

$ARGUMENTS

Goal: 사용자의 Claude Code 설정을 진단하고, 공식 문서와 최신 베스트 프랙티스를 기반으로 개선 방안을 제안합니다.

## Execution Steps

### 1. 개선 목표 파악 (Interactive Discovery)

사용자에게 개선하고 싶은 영역을 질문합니다 (최대 3개 선택):

| 영역 | 설명 |
|------|------|
| A | **MCP 서버 설정** - Model Context Protocol 서버 연동 및 설정 최적화 |
| B | **모델 선택 및 설정** - 사용 모델, 토큰 제한, 성능 최적화 |
| C | **Hooks 설정** - Pre-commit, post-command 등 자동화 훅 |
| D | **Commands 구조** - Slash commands 구성 및 효율성 |
| E | **프로젝트별 설정** - `.claude/settings.json` 최적화 |
| F | **전역 설정** - `~/.claude/settings.json` 최적화 |
| G | **성능 개선** - 응답 속도, 토큰 사용량 최적화 |
| H | **보안 및 권한** - API 키 관리, 접근 제어 |
| All | **전체 진단** - 모든 영역 종합 검토 |

**질문 형식**:
- "어떤 영역을 개선하고 싶으신가요? (A-H 또는 All 입력)"
- 사용자가 선택한 영역에 대해 현재 불편한 점이나 목표 추가 질문 (선택적)

### 2. 현재 설정 분석

선택된 영역에 따라 다음 설정 파일들을 읽고 분석합니다:

**공통**:
- `.claude/settings.json` (프로젝트 설정)
- `.claude/CLAUDE.md` (프로젝트 지침)
- `~/.claude/settings.json` (전역 설정, 가능한 경우)

**영역별 추가 분석**:
- **A (MCP)**: MCP 서버 목록 확인
- **D (Commands)**: `.claude/commands/*.md` 파일 목록 및 패턴
- **C (Hooks)**: Hook 설정 존재 여부 및 구조
- **E/F (설정)**: settings.json 구조 및 값 검토

현재 설정을 내부 모델로 정리:
- 사용 중인 기능 목록
- 미사용/누락된 설정
- 잠재적 문제점 (예: 하드코딩된 값, 비효율적 패턴)

### 3. 베스트 프랙티스 조사

선택된 영역에 대해 최신 정보를 수집합니다:

**공식 문서 조회** (WebFetch를 사용하여 병렬 조회):
- https://docs.claude.com/en/docs/claude-code/claude_code_docs_map.md (전체 맵)
- 영역별 관련 문서 URL (예: MCP 설정, 모델 선택, hooks 가이드)

**릴리즈 노트 조회** (WebSearch 사용):
- "Claude Code release notes 2025" 검색
- "Claude Code [선택된 영역] best practices 2025" 검색

**패턴 수집**:
- 권장 설정 값
- 새로 추가된 기능
- Deprecated된 설정
- 일반적인 실수 및 해결책

### 4. 개선 제안 생성

분석 결과를 바탕으로 구조화된 개선 제안서를 작성합니다:

```markdown
## Claude Code 설정 개선 제안서

### 현재 상태 요약
- 분석 대상 영역: [선택된 영역들]
- 발견된 설정 항목: [개수]
- 주요 문제점: [요약]

### 개선 제안 상세

#### [영역명 1]

| 현재 설정 | 문제점 | 개선안 | 우선순위 | 예상 효과 |
|-----------|--------|--------|----------|-----------|
| [현재값/상태] | [무엇이 문제인가] | [어떻게 바꿀 것인가] | High/Medium/Low | [어떤 개선이 예상되는가] |

**적용 방법**:
```json
// .claude/settings.json
{
  "기존설정": "old_value",  // [X] 제거 또는 변경
  "새설정": "new_value"     // [+] 추가
}
```

**근거**:
- 공식 문서: [URL]
- 릴리즈 노트: [버전 및 내용]
- 베스트 프랙티스: [설명]

---

#### [영역명 2]
[동일한 구조 반복]

---

### 종합 개선 계획

**Phase 1 - 즉시 적용 권장 (High Priority)**:
1. [개선 항목]
2. [개선 항목]

**Phase 2 - 점진적 개선 (Medium Priority)**:
1. [개선 항목]

**Phase 3 - 선택적 최적화 (Low Priority)**:
1. [개선 항목]

### 예상 결과
- 성능: [예상 개선 사항]
- 개발 경험: [예상 개선 사항]
- 유지보수: [예상 개선 사항]
```

### 5. 사용자 승인 및 적용

제안서 출력 후 사용자에게 질문:

1. **"위 제안 중 어떤 것을 적용하시겠습니까?"**
   - 옵션: "All High Priority", "Specific items (번호 입력)", "Show details first", "Cancel"

2. 사용자가 선택한 항목에 대해:
   - 기존 파일 Read
   - Edit 또는 Write로 변경 적용
   - 변경 사항 요약 출력

3. 적용 후 검증:
   - 변경된 파일 경로 나열
   - "설정이 적용되었습니다. Claude Code를 재시작하거나 새 세션을 시작하세요."

### 6. 완료 리포트

```markdown
## 개선 완료 보고

### 적용된 변경사항
- 파일: [변경된 파일 경로들]
- 개선 항목: [적용된 개수] / [제안된 개수]

### 다음 단계
- [ ] Claude Code 재시작
- [ ] 새 세션에서 변경 사항 테스트
- [ ] [추가 권장 작업]

### 미적용 제안
- [사용자가 적용하지 않은 항목들]
- 나중에 `/improve-claude-config --review` 명령으로 다시 검토 가능
```

## Behavior Rules

- **대화형 우선**: 각 단계에서 사용자 확인 필요
- **사용자 승인 필수**: 파일 수정 전 반드시 승인 받기
- **근거 제시**: 모든 제안에 공식 문서나 릴리즈 노트 링크 포함
- **단계별 진행**: 한 번에 하나의 영역씩 집중
- **롤백 가능**: 변경 전 현재 설정 백업 (사용자에게 안내)
- **최신 정보 우선**: 2024-2025년 정보 우선 참조
- **실용적 제안**: 이론적 최적화보다 실제 개선 효과가 있는 것 우선

## Special Flags (from $ARGUMENTS)

- `--review`: 이전 제안 중 미적용 항목 다시 검토
- `--quick`: 간단한 진단만 수행 (질문 생략, All 영역 자동 선택)
- `--area=X`: 특정 영역만 지정 (예: `--area=MCP`)
- `--no-apply`: 제안만 생성, 적용하지 않음

## Context

User context: $ARGUMENTS
