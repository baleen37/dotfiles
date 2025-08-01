# Token Optimization Guide for Claude Configuration

## 압축 성과
- **Before**: 234 lines, ~3,500 tokens
- **After**: 105 lines, ~1,500 tokens  
- **Reduction**: 55% smaller, 57% token savings

## 핵심 최적화 전략

### 1. 중복 제거 (Deduplication)
```markdown
# BEFORE: 중복된 설명
- Smart Enhancement: Multi-dimensional improvement
- Auto-Orchestration: Seamless Wave mode activation
- Safe Optimization: Built-in safety mechanisms

# AFTER: 핵심만
Analyze complexity → delegate → integrate → validate
```

### 2. 리스트 압축 (List Compression)
```markdown
# BEFORE: 장황한 설명
- **Context Preservation**: Maintain project context across all delegations
- **Strategic Delegation**: Match tasks to subagent expertise automatically
- **Result Integration**: Synthesize subagent outputs into coherent solutions

# AFTER: 핵심 키워드
- Preserve context. Coordinate validation. Avoid overhead for simple tasks.
```

### 3. 예시 축소 (Example Reduction)
```markdown
# BEFORE: 긴 예시들
Examples:
// BAD: This uses Zod for validation instead of manual checking
// BAD: Refactored from the old validation system
// BAD: Wrapper around MCP tool protocol
// GOOD: Executes tools with validated arguments

# AFTER: 간결한 대비
Domain names: `Tool` not `AbstractToolInterface`
```

### 4. 섹션 병합 (Section Merging)
```markdown
# BEFORE: 분리된 섹션들
## Task Management
## Quality Gates  
## Subagent Management

# AFTER: 통합 섹션
<issues>
**TodoWrite**: ...
**Quality Gates**: ...
**Subagents**: ...
</issues>
```

### 5. 불필요한 설명문 제거
```markdown
# BEFORE: 마케팅 톤
YOU MUST ALWAYS find the root cause of any issue you are debugging. YOU MUST NEVER fix a symptom or add a workaround.

# AFTER: 직접적 명령
Find root cause, never fix symptoms.
```

### 6. 축약 표현 활용
```markdown
# BEFORE: 완전한 문장
When you disagree with my approach, YOU MUST push back, citing specific technical reasons

# AFTER: 핵심 동작
Speak up when unsure or disagreeing
```

## 적용 규칙

### ✅ 유지해야 할 것
- Rule #1과 핵심 제약사항
- 필수 워크플로우 단계
- jito의 핵심 철학과 원칙
- 모듈 간 @참조 링크

### ❌ 제거 가능한 것
- 반복적인 강조 표현 (YOU MUST, NEVER)
- 장황한 설명문
- 중복된 예시들
- 마케팅 톤의 형용사들
- 과도한 formatting (이모지, 굵은글씨)

### 🔄 압축 기법
- **병합**: 관련 섹션들을 하나로 통합
- **축약**: 긴 문장을 핵심 단어로 압축
- **구조화**: bullet point와 간결한 구조 활용
- **키워드화**: 동작 중심의 간결한 표현

## 가독성 유지 전략

### 1. 명확한 구조
```markdown
<section>
**핵심개념**: 간결한 설명
- 세부사항 1
- 세부사항 2
</section>
```

### 2. 논리적 흐름
1. 역할 정의 → 2. 철학 → 3. 제약사항 → 4. 구체적 규칙들

### 3. 스캔 가능한 형태
- 굵은 키워드로 핵심 포인트 표시
- bullet point로 세부사항 정리
- 짧은 문단으로 구분

## 토큰 효율성 측정

### 계산 방법
- 일반적으로 4 characters ≈ 1 token (영어 기준)
- 한글은 약 2-3 characters ≈ 1 token
- 공백과 punctuation도 토큰에 포함

### 최적화 목표
- **50% 이상 토큰 감소**: 의미 손실 없이 달성 가능
- **가독성 유지**: 핵심 정보 접근성 보장
- **기능 보존**: 모든 필수 기능과 규칙 유지

## 활용 지침

이 가이드를 다른 설정 파일에도 적용:
1. MCP.md → 서버별 핵심 기능만 유지
2. SUBAGENT.md → 필수 협업 패턴만 문서화
3. FLAG.md → 사고 모드별 핵심 차이점만 설명
4. Commands/*.md → 사용법과 핵심 기능만 포함
