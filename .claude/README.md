# Claude Code 설정 및 사용 가이드

> dotfiles 프로젝트의 Claude Code 설정, Commands, 최적화 전략을 한 곳에서 관리합니다.

---

## 📋 목차

1. [설정 파일 구조](#설정-파일-구조)
2. [Available Commands](#available-commands)
3. [MCP 서버 관리](#mcp-서버-관리)
4. [성능 최적화](#성능-최적화)
5. [문제 해결](#문제-해결)

---

## 설정 파일 구조

### 3계층 설정 시스템

```
로컬 (.claude/settings.local.json)  ← 최고 우선순위 (개인 환경)
    ↓
프로젝트 (.claude/settings.json)   ← 중간 (팀 공유, Git 추적)
    ↓
전역 (~/.claude/settings.json)     ← 최저 (모든 프로젝트 공통)
```

### 각 파일의 역할

| 파일 | Git 추적 | 용도 | 포함 내용 |
|------|---------|------|-----------|
| `~/.claude/settings.json` | ❌ | 전역 기본값 | 기본 권한, MCP 정책, 전역 hooks |
| `.claude/settings.json` | ✅ | 팀 공유 | 프로젝트 hooks, 팀 워크플로우 |
| `.claude/settings.local.json` | ❌ | 개인 환경 | 개인 경로, 사용자명, 실험 권한 |

### 현재 프로젝트 설정

**전역** (`~/.claude/settings.json` - Nix store, 읽기 전용):
```json
{
  "permissions": {
    "allow": ["Bash", "Read", "Write", "mcp__*", ...],
    "deny": []
  },
  "enableAllProjectMcpServers": true,
  "alwaysThinkingEnabled": true
}
```

**프로젝트** (`.claude/settings.json` - Git 추적):
```json
{
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "claude-hooks git-commit-validator"}]}],
    "PostToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "claude-hooks message-cleaner"}]}]
  }
}
```

**로컬** (`.claude/settings.local.json` - .gitignore):
```json
{
  "permissions": {
    "allow": [
      "Bash(export USER=jito)",
      "Bash(/Users/jito/dev/dotfiles/**:*)",
      "mcp__serena__search_for_pattern",
      "Read(//nix/store/**)"
    ]
  }
}
```

---

## Available Commands

### `/improve-claude-config`

**용도**: Claude Code 설정 진단 및 개선 제안

**기능**:
- 9개 영역 선택형 진단 (MCP, 모델, Hooks, Commands, 보안 등)
- 공식 문서 기반 베스트 프랙티스 조사
- 구조화된 개선 제안서 생성
- 승인 후 자동 적용

**사용법**:
```bash
/improve-claude-config              # 대화형 진단
/improve-claude-config --quick      # 전체 자동 진단
/improve-claude-config --area=MCP   # 특정 영역만
/improve-claude-config --no-apply   # 제안만 생성
```

**워크플로우**:
1. 개선하고 싶은 영역 선택 (A-H 또는 All)
2. 현재 설정 자동 분석
3. WebFetch/WebSearch로 최신 베스트 프랙티스 조사
4. 비교표 및 우선순위 포함 제안서 제공
5. 사용자 승인 후 선택 적용

---

## MCP 서버 관리

### 현재 활성 서버

```bash
$ claude mcp list

✓ context7           - 외부 라이브러리 문서 조회
✓ sequential-thinking - 복잡한 다단계 문제 해결
✓ serena             - 대규모 코드베이스 분석
```

### 서버별 사용 가이드

| 서버 | 언제 사용 | 사용 빈도 | 권장 |
|------|-----------|-----------|------|
| **context7** | Nix/외부 라이브러리 문서 필요 시 | 중간 | ✅ 활성화 유지 |
| **sequential-thinking** | 복잡한 디버깅/설계 | 낮음 | ⚠️ 필요시만 |
| **serena** | 대규모 코드 탐색/리팩토링 | 높음 | ✅ 활성화 유지 |

### 최적화 권장안

**문제점**: `enableAllProjectMcpServers: true` → 모든 서버가 컨텍스트 소비

**해결책**:
```json
// ~/.claude/settings.json (또는 Home Manager)
{
  "enableAllProjectMcpServers": false,
  "rejectedMcpServers": ["sequential-thinking"]  // 필요시 수동 활성화
}
```

**예상 효과**: 컨텍스트 토큰 5-10% 절감

### 서버 관리 명령어

```bash
# 서버 추가
claude mcp add --transport stdio my-server -- npx -y my-mcp-server

# 서버 제거
claude mcp remove my-server

# 디버그 모드
claude --mcp-debug
```

---

## 성능 최적화

### 즉시 적용 가능한 개선

#### 1. Thinking 모드 선택적 활성화

**현재**: `alwaysThinkingEnabled: true` (모든 응답에서 사고 과정 표시)

**개선**:
```json
{
  "alwaysThinkingEnabled": false  // 필요시 수동 활성화
}
```

**효과**: 토큰 사용량 감소, 응답 속도 향상

#### 2. MCP 서버 선택적 로드

위 [MCP 서버 관리](#mcp-서버-관리) 참조

#### 3. Hook 최적화

불필요한 Hook 제거 또는 조건부 실행:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "if git diff --name-only | grep -E '\\.(nix|md)$'; then make format-changed; fi"
        }]
      }
    ]
  }
}
```

### 모델 선택 전략

| 작업 유형 | 권장 모델 | 이유 |
|-----------|-----------|------|
| 간단한 코드 리뷰 | Haiku | 빠르고 저렴 |
| 일반 개발 | Sonnet (기본값) | 균형 잡힌 성능 |
| 복잡한 아키텍처 설계 | Opus | 높은 추론 능력 |

**사용법**:
```bash
claude --model claude-3-haiku-20240307  # 간단한 작업
```

---

## 보안 권장사항

### Deny 규칙 추가 (선택사항)

**현재**: `permissions.deny: []` (비어있음)

**권장** (보안 강화 필요 시):
```json
{
  "permissions": {
    "deny": [
      "Read(**/.env*)",
      "Read(**/secrets/**)",
      "Read(**/*credentials*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(rm -rf:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

**근거**: [Claude Code Security Best Practices](https://www.backslash.security/blog/claude-code-security-best-practices)

---

## 문제 해결

### Q: 설정이 적용되지 않아요

**A**: 우선순위 확인
- 로컬 > 프로젝트 > 전역 순서
- 로컬 설정(`.local.json`)이 다른 설정을 덮어씀

### Q: 전역 설정이 읽기 전용이에요

**A**: Nix/Home Manager 환경
- Nix store 파일은 수정 불가
- `modules/shared/claude.nix`에서 변경 필요

### Q: Hook이 실행되지 않아요

**A**: 실행 권한 및 경로 확인
```bash
chmod +x ~/.claude/hooks/*
which claude-hooks
```

### Q: MCP 서버가 연결 안 돼요

**A**: 디버그 모드로 확인
```bash
claude --mcp-debug
claude mcp list
```

---

## 베스트 프랙티스

### ✅ 권장

1. **최소 권한**: 필요한 권한만 추가
2. **계층 분리**: 전역 < 프로젝트 < 로컬 역할 명확화
3. **Git 주의**: `.local.json`에만 개인 정보 (커밋 안됨)
4. **문서화**: 특이한 설정은 이 파일에 기록

### ❌ 주의

1. **개인 정보 커밋 금지**: 프로젝트 설정에 사용자명/경로 금지
2. **과도한 권한**: `Bash(bash:*)` 같은 광범위한 권한 지양
3. **Hook 무한 루프**: Hook이 파일 수정 시 재귀 호출 주의
4. **보안 무시**: deny 규칙 없이 allow만 사용하지 말 것

---

## 참고 자료

- [Claude Code 공식 문서](https://docs.claude.com/en/docs/claude-code/settings)
- [Hooks 가이드](https://docs.claude.com/en/docs/claude-code/hooks-guide)
- [MCP 서버 설정](https://docs.claude.com/en/docs/claude-code/mcp)
- [Security Best Practices](https://www.backslash.security/blog/claude-code-security-best-practices)
