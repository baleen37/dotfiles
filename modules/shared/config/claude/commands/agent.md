# /claude:agent - Subagent 관리

dotfiles의 agent 파일을 안전하게 관리하는 도구.

**Process**:
1. Read tool로 대상 agent 파일 확인
2. STOP - jito에게 변경 계획 보고 및 승인 요청
3. jito "허가한다" 확인 후에만 진행
4. Edit/Write tool로 변경 실행
5. 결과 확인

**Agent 위치**: `modules/shared/config/claude/agents/`

**사용 예시**:
- "code-reviewer agent 수정해줘"
- "새로운 testing-expert agent 만들어줘"  
- "mobile-developer agent 삭제해줘"

**Agent 구조 필수 요소**:
- kebab-case 이름 (예: code-reviewer)
- Task 도구와 일치하는 subagent_type
- 전문 영역과 도구 명시
- 일관된 마크다운 형식

## 주요 특징

- **Rule #1 절대 준수**: 모든 변경 전 jito 명시적 승인 필수
- **24개 Agents 관리**: Task 도구의 subagent_type과 일치
- **전문성 보장**: 각 영역별 전문 에이전트 관리
- **안전한 수정**: 단계별 검증 및 확인 과정
