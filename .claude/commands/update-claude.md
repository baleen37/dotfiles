# /update-claude: Claude 설정 최적화 도구

ABOUTME: Claude Code 설정 파일들의 lint, 구조, 링크 검증 및 자동 수정

## 핵심 원칙

**YAGNI 우선**: 실용적 자동화만, 복잡성 제거
**안전한 수정**: 읽기 → 분석 → 수정 → 검증
**직접 편집**: Edit/MultiEdit로 즉시 수정, 백업 파일 생성 안함
**전문가 위임**: 복잡한 최적화는 claude-prompt-expert 활용

## 기본 동작

### 자동 감지 및 수정

**즉시 수정 대상**:

- 마크다운 lint 오류 (MD022, MD025 등)
- 깨진 @reference 링크
- 누락된 ABOUTME 헤더
- 중복 콘텐츠 및 dead code
- 오타 및 포맷 불일치

**승인 필요**:

- 새 섹션 추가
- 구조적 변경
- 기능 확장

### 처리 과정

```bash
# 1. 발견 (병렬)
Glob(".claude/**/*.md") + Grep(lint_patterns) + Grep("@.*\.md")

# 2. 분석 및 분류
자동 수정 vs 승인 필요 vs 금지 사항 구분

# 3. 실행
Edit/MultiEdit로 직접 수정 → 검증
```

## 도구 활용

### Claude Code 도구

- **Glob**: 설정 파일 패턴 발견
- **Grep**: lint 패턴, 링크 검증
- **Read**: 현재 상태 파악
- **Edit/MultiEdit**: 직접 수정
- **claude-prompt-expert**: 복잡한 프롬프트 최적화

### 안전장치

- Read-first 원칙 (상태 파악 후 수정)
- 단계별 검증 (수정 후 즉시 확인)
- 실패 시 대안 전략 (MultiEdit → Edit)

## 사용 예시

### 기본 사용

```bash
/update-claude
# 결과: 5개 MD022 오류 수정, 2개 링크 수정, 45초 완료
```

### 전문가 모드

```bash
/update-claude --expert
# 결과: claude-prompt-expert 활용, 토큰 효율성 30% 개선
```

### 검사만

```bash
/update-claude --check  
# 결과: 문제 보고서만 생성, 수정 안함
```

## 실제 수정 사례

### Lint 오류 수정

```markdown
# 수정 전
##Title without space

# 수정 후  
## Title with space
```

### 링크 수정

```markdown
# 수정 전
@nonexistent.md

# 수정 후
@RULES.md
```

### ABOUTME 추가

```markdown
# 수정 전
# /command: Some command

# 수정 후
# /command: Some command

ABOUTME: Brief description of command purpose
```

## 성능 목표

**속도**: 일반적 수정 <2분, 복잡한 최적화 <5분
**정확도**: 95% 이상 자동 수정 성공률
**안전성**: 0 실패, 복원 가능한 수정만

## 제한사항

**수정하지 않음**:

- SuperClaude 핵심 철학 변경
- 보안 설정 수정  
- 새로운 자동화 규칙 생성

**실패 처리**:

- 다른 도구로 재시도 (MultiEdit → Edit)
- 실패 시 전문가에게 위임

---
*실용적 • 안전한 • 효과적*
