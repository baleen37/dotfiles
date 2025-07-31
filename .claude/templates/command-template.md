# Command Template

Claude Code 명령어 생성을 위한 표준 템플릿

## 구조

```markdown
# [COMMAND-NAME] - [한글 간단 설명]

[한 줄 영어 설명]

<persona>
You are a [DOMAIN] specialist for the Claude Code assistant. You are an expert at [CORE-EXPERTISE]. You understand [KEY-KNOWLEDGE-AREAS].
</persona>

<objective>
[PRIMARY-GOAL] with [KEY-CAPABILITIES], ensuring [QUALITY-STANDARDS].
</objective>

<workflow>
  <step name="[STEP-NAME]" number="1">
    - **[Action]**: [Description]
    - **[Action]**: [Description]
  </step>

  <step name="[STEP-NAME]" number="2">
    - **[Action]**: [Description]
    - **[Action]**: [Description]
  </step>

  <step name="[STEP-NAME]" number="3">
    - **[Action]**: [Description]
    - **[Action]**: [Description]
  </step>

  <step name="[STEP-NAME]" number="4">
    - **[Action]**: [Description]
    - **[Action]**: [Description]
  </step>
</workflow>

<constraints>
- [Item] MUST [Requirement]
- [Item] MUST NOT [Prohibition]
- ALL [Scope] MUST [Validation]
</constraints>

<validation>
- [Criteria] successfully [completed/validated]
- User confirms [acceptance criteria]
- [Integration] integrates properly
</validation>
```

## 작성 가이드

### 1. 명령어 이름
- `kebab-case` 형식 필수
- 동사-명사 구조 권장 (예: `create-agent`, `update-claude`)

### 2. Persona 섹션
- "You are a [domain] specialist" 패턴
- 핵심 전문성과 지식 영역 명시
- Claude Code 컨텍스트 유지

### 3. Objective 섹션
- 주요 목표를 명확하게 정의
- 품질 기준과 요구사항 포함
- 한 문장으로 간결하게

### 4. Workflow 섹션
- 4단계 구조 권장
- 각 단계는 4개 정도의 액션으로 구성
- 액션은 **굵은 글씨**로 시작

### 5. Constraints 섹션
- MUST/MUST NOT 형식
- 구체적이고 검증 가능한 제약사항
- 파일명, 구조, 검증 규칙 포함

### 6. Validation 섹션
- 성공 기준을 명확히 정의
- 사용자 승인 단계 포함
- 통합 테스트 관점 포함

## 참조 문서

- **패턴 가이드**: [command-patterns.md](../docs/command-patterns.md)
- **Agent 템플릿**: [agent-template.md](./agent-template.md)
- **실제 예시**:
  - XML 구조: `commands/claude/agent.md`, `commands/claude/command.md`
  - 표준화된 예시: `commands/claude/update.md`
