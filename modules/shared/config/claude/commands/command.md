# /claude:command - Command 관리

dotfiles의 command 파일을 안전하게 관리하는 도구.

**Process**:
1. Read tool로 대상 command 파일 확인
2. STOP - jito에게 변경 계획 보고 및 승인 요청  
3. jito "허가한다" 확인 후에만 진행
4. Edit/Write tool로 변경 실행
5. 결과 확인

**Command 위치**: `modules/shared/config/claude/commands/`

**사용 예시**:
- "implement command 개선해줘"
- "새로운 deploy command 만들어줘"
- "outdated command 삭제해줘"

**Command 구조 필수 요소**:
- kebab-case 이름 (예: analyze)
- Purpose/Objective 섹션
- 구체적 실행 단계
- 일관된 마크다운 형식

**기존 22개 Commands**:
analyze, brainstorm, build, cleanup, commit, create-pr, design, document, estimate, explain, fix-pr, implement, improve, index, load, research-plan-execute, sanity-check, spawn, task, test, troubleshoot, workflow

## 주요 특징

- **Rule #1 절대 준수**: 모든 변경 전 jito 명시적 승인 필수
- **22개 Commands 관리**: 전체 command 생명주기 관리
- **안전한 수정**: 단계별 검증 및 확인 과정
- **기존 패턴 준수**: jito의 검증된 구조 유지
