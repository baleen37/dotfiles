# /claude:config - 설정 모듈 관리

Claude 핵심 설정 파일들을 안전하게 관리하는 도구.

**Process**:
1. Read tool로 대상 설정 파일 확인
2. STOP - jito에게 변경 계획 보고 및 승인 요청
3. jito "허가한다" 확인 후에만 진행  
4. Edit tool로 변경 실행
5. @참조 링크 무결성 확인

**설정 위치**: `modules/shared/config/claude/`

**4개 핵심 모듈**:
- **CLAUDE.md**: jito 메인 설정, Rule #1, 코딩 규칙
- **MCP.md**: MCP 서버 자동 실행 시스템  
- **SUBAGENT.md**: Task 도구와 25개 subagent 협업
- **FLAG.md**: --think, --ultrathink 사고 모드 플래그 시스템

**사용 예시**:
- "CLAUDE.md의 Rule #1 섹션 수정해줘"
- "MCP.md에 새 서버 추가해줘"  
- "SUBAGENT.md 작업 패턴 개선해줘"
- "FLAG.md에 새 플래그 옵션 추가해줘"

**vs /claude:update**: 단순 수정은 config, 복잡한 통합 관리는 update 사용

**중요**: CLAUDE.md는 최고 우선순위 - 극도로 신중하게 수정

**@참조 무결성**: CLAUDE.md → @MCP.md, @SUBAGENT.md, @FLAG.md 링크 유지

**Rule #1 절대 준수**: 모든 변경 전 jito 명시적 승인 필수
