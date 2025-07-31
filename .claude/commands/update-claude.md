---
description: "Claude 설정 파일을 modules/shared/config/claude/에서 관리"
---

# /update-claude - Claude 설정 관리

## 목적
`modules/shared/config/claude/`에 있는 Claude 설정을 수정하고 `nix run #build-switch`로 시스템에 반영.

## 사용법
```bash
/update-claude [파일명]
```

## 워크플로우
1. **설정 수정** - `modules/shared/config/claude/` 파일 편집
2. **검증** - YAML frontmatter, 마크다운 문법 확인
3. **반영** - `nix run #build-switch` 실행
4. **확인** - Claude 재시작 후 동작 테스트

## 관리 파일들
- **핵심**: `CLAUDE.md`, `COMMANDS.md`, `PRINCIPLES.md`, `RULES.md`, `MODES.md`
- **명령어**: `commands/*.md`
- **에이전트**: `agents/*.md`
- **문서**: `docs/*.md`

## 예시
```bash
# 새 명령어 추가
vim modules/shared/config/claude/commands/새기능.md
nix run #build-switch

# 설정 수정
vim modules/shared/config/claude/PRINCIPLES.md
nix run #build-switch
```
