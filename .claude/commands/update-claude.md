# /update-claude: Claude 설정 최적화 도구

ABOUTME: Claude Code 설정 파일들의 lint, 구조, 링크 검증 및 자동 수정

## 개요 및 원칙

**YAGNI 우선**: 실용적 자동화만, 복잡성 제거  
**안전한 수정**: 읽기 → 분석 → 수정 → 검증  
**직접 편집**: Edit/MultiEdit로 즉시 수정, 백업 파일 생성 안함  
**전문가 위임**: 복잡한 최적화는 prompt-engineer 활용

## 실행 로직 (단계별)

### 자동 수정 대상

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

### 단계별 처리 과정

```bash
# 1. 구조 탐색
find .claude -name "*.md" -type f
find modules -path "*/claude/*.md" -type f
ls -la .claude/ modules/*/config/claude/

# 2. 컨텐츠 분석 대상 파일 수집
for file in $(find .claude modules -name "*.md" -type f); do
  echo "Processing: $file"
  # ABOUTME, 섹션 구조, 스타일 패턴 추출
done

# 3. 링크 유효성 검증
grep -r "@[a-zA-Z].*\.md" .claude/ modules/*/config/claude/
# 참조된 파일들이 실제로 존재하는지 확인

# 4. Markdown lint 문제 감지
# MD022: 제목 주변 공백 문제
# MD025: 여러 H1 제목 문제
grep -n "^##[^ ]" *.md  # MD022 감지 예시

# 5. ABOUTME 누락 감지
grep -L "ABOUTME:" .claude/commands/*.md

# 6. 실행 (예시)
# Claude Code의 Edit/MultiEdit 도구 활용
```

## 도구별 사용법

### Claude Code 도구

- **Glob**: 설정 파일 패턴 발견
- **Grep**: lint 패턴, 링크 검증
- **Read**: 현재 상태 파악
- **Edit/MultiEdit**: 직접 수정
- **prompt-engineer**: 복잡한 프롬프트 최적화

### 안전장치 및 검증

- **Read-first 원칙**: 상태 파악 후 수정  
- **단계별 검증**: 수정 후 즉시 확인  
- **대안 전략**: MultiEdit 실패 시 Edit 사용  
- **백업 없음**: 직접 수정 방식, Git으로 버전 관리

## 사용 예시 및 시나리오

### 기본 사용

```bash
/update-claude
# 예상 결과: MD022 오류 수정, 깨진 링크 수정, 완료 메시지 표시
```

### 전문가 모드 (구현 예정)

```bash
# TODO: 향후 구현 예정
# /update-claude --expert
# 결과: prompt-engineer 에이전트 활용, 토큰 효율성 개선
```

### 검사 모드 (구현 예정)

```bash
# TODO: 향후 구현 예정
# /update-claude --check  
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

## 성능 및 제한사항

**속도**: 일반적 수정 예상 시간 (벤치마크 예정)
**정확도**: 자동 수정 성공률 (측정 후 업데이트)
**안전성**: Read-first 원칙, 단계별 검증 적용

## 제한사항

**수정하지 않음**:

- SuperClaude 핵심 철학 변경  
- 보안 설정 수정  
- 새로운 자동화 규칙 생성

**오류 처리 전략**:

- 다른 도구로 재시도 (MultiEdit → Edit)  
- 실패 시 prompt-engineer 에이전트에게 위임  
- Read-first 원칙으로 상태 파악 후 수정

---
*실용적 • 안전한 • 효과적*
