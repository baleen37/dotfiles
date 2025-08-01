# /update-claude - 지능형 Claude Code 설정 업데이트

`claude-code-expert` agent를 활용하여 Claude Code 설정과 전체 시스템을 jito의 철학에 맞게 자동으로 업데이트하고 최적화.

## 목적
- **Zero-Config 진화**: 설정 없이 자동으로 최신 베스트 프랙티스 적용
- **지능형 타겟 감지**: 컨텍스트 기반 자동 타겟 선택 (로컬/shared/자체)
- **계층적 업데이트**: Self-Update → Shared First → Local Override 전략
- **안전 우선**: Rule #1 준수하면서 점진적 개선
- **일관성 보장**: jito의 철학과 컨벤션 완벽 유지

## 사용법

### 기본 사용법 (지능형 자동 감지)
```bash
/update-claude                        # 컨텍스트별 자동 타겟 감지 + claude-code-expert 위임
/update-claude --check                # 모든 타겟 상태 점검
/update-claude --safe                 # 안전 모드 (단계별 승인)
```

### 타겟 명시적 지정
```bash
/update-claude --local                # 현재 프로젝트 .claude/ 디렉토리만
/update-claude --shared               # ~/.claude/ 글로벌 설정만
/update-claude --all                  # 모든 타겟 (로컬 + shared + 자체)
/update-claude --self                 # 이 명령어 자체만 업데이트
```

### 고급 옵션
```bash
/update-claude --force                # 강제 전체 업데이트 (주의)
/update-claude --dry-run              # 시뮬레이션 모드 (실제 변경 없음)
/update-claude --rollback [timestamp] # 특정 시점으로 롤백
```

## 🤖 claude-code-expert Agent 활용

이 명령어는 내부적으로 `claude-code-expert` agent를 호출하여 다음과 같은 전문적 분석을 수행합니다:

### 자동 Agent 위임 시스템
```
/update-claude 실행 → Task tool → claude-code-expert agent 자동 호출
                  ↓
            Zero-Config 분석 + superclaude 자동화 + Rule #1 보장
```

**Agent가 수행하는 핵심 작업**:
- **지능형 컨텍스트 분석**: 현재 Claude Code 설정 상태 정밀 분석
- **진화형 최적화 전략**: superclaude 원칙 기반 자동 개선 계획 수립  
- **안전 보장 시스템**: Rule #1 준수하면서 점진적 업데이트 실행
- **품질 검증**: Zero-config 달성도와 jito 철학 일치성 검증

## 지능형 타겟 감지 시스템

### 🧠 자동 타겟 선택 알고리즘
명령어 실행 시 다음 순서로 컨텍스트를 분석하여 최적 타겟을 자동 선택:

#### 1. 컨텍스트 분석 기준
```python
# 의사코드 - 자동 타겟 감지 로직
def detect_update_target():
    context = {
        'current_dir': pwd(),
        'has_local_claude': exists('./.claude/'),
        'is_dotfiles_project': in_dotfiles_repo(),
        'recent_changes': git_status_analysis(),
        'reference_analysis': scan_at_references()
    }

    if context['is_dotfiles_project'] and '--local' not in args:
        return 'shared_first'    # dotfiles 프로젝트면 shared 우선
    elif context['has_local_claude']:
        return 'local_first'     # 로컬 .claude/ 있으면 로컬 우선
    else:
        return 'shared_only'     # 그 외엔 글로벌만
```

#### 2. 타겟별 감지 범위
**로컬 타겟 (.claude/ 디렉토리)**:
- **CLAUDE.md**: 프로젝트별 @참조, Rule #1 준수, 철학 일관성
- **agents/*.md**: 프로젝트 특화 Subagent 설정
- **commands/*.md**: 프로젝트별 명령어 최적화

**Shared 타겟 (~/.claude/ 글로벌)**:
- **CLAUDE.md**: 글로벌 진입점, @참조 무결성
- **MCP.md**: 서버 자동 실행 로직, 키워드 매칭 최적화
- **SUBAGENT.md**: Task 도구 협업 패턴, 복잡도 감지 알고리즘
- **FLAG.md**: 사고 모드 플래그 활용법, 성능 최적화
- **ORCHESTRATION.md**: 지능형 자동화 시스템, 학습 기반 개선

**자체 업데이트 (--self)**:
- 이 명령어 파일 자체의 최신화
- 다른 프로젝트의 update-claude.md와 동기화

### 🔍 자동 품질 검증
**Rule #1 준수 검증**:
- [ ] 모든 변경사항 명시적 승인 체계 확인
- [ ] 안전 장치와 롤백 메커니즘 검증
- [ ] 점진적 변경 원칙 적용 여부

**jito 철학 일치성**:
- [ ] "단순함이 최고의 복잡성" 원칙 준수
- [ ] YAGNI와 실용주의 접근법 적용
- [ ] 한국어 우선, 기술 용어 적절한 영어 혼용

**기술적 무결성**:
- [ ] @참조 링크 유효성 100% 보장
- [ ] 마크다운 문법 및 구조 일관성
- [ ] 토큰 효율성 최적화 상태

## 업데이트 전략

### 🎯 지능형 우선순위 자동 결정
```python
# 의사코드 - 자동 우선순위 매트릭스
def calculate_update_priority():
    priority_matrix = {
        'rule_1_violation': 'CRITICAL',      # 즉시 수정 필요
        'philosophy_drift': 'HIGH',          # 철학 불일치
        'broken_references': 'HIGH',         # @참조 링크 깨짐
        'convention_mismatch': 'MEDIUM',     # 컨벤션 불일치
        'performance_issue': 'MEDIUM',       # 성능 최적화 기회
        'enhancement_opportunity': 'LOW'      # 개선 기회
    }
```

### 🛡️ 안전 모드 업데이트
```bash
/update-claude --safe
```
**안전 장치 활동**:
1. **백업 자동 생성**: 모든 변경 전 현재 상태 보존
2. **변경사항 미리보기**: 적용될 변경사항 상세 표시
3. **단계별 승인**: 각 주요 변경사항마다 jito 승인 요청
4. **실시간 검증**: 각 단계 후 무결성 확인
5. **즉시 롤백**: 문제 발생시 자동 복원

### ⚡ 빠른 점검 모드
```bash
/update-claude --check
```
**점검 리포트 생성**:
- 📊 현재 설정 상태 점수 (Rule #1, 철학, 기술)
- 🔍 발견된 문제점과 개선 기회 목록
- ⏱️ 예상 업데이트 시간과 영향도 분석
- 📋 권장 업데이트 순서와 우선순위

## 실제 구현: Task Tool 자동 위임

이 명령어의 실제 구현은 다음과 같이 `cloud-code-expert` agent에게 작업을 위임합니다:

### 기본 실행 로직
```markdown
$ARGUMENTS를 분석하여 타겟과 모드 결정:
- 인수 없음: 컨텍스트 기반 자동 타겟 감지 + 지능형 업데이트
- --local/--shared/--all/--self: 명시적 타겟 지정  
- --check: 모든 타겟 상태 점검
- --safe: 안전 모드 활성화
- --force: 강제 업데이트 모드

Task tool을 사용하여 claude-code-expert에게 다음 프롬프트 전달:
"Claude Code 설정을 [$TARGET 타겟]에서 [$MODE 모드]로 업데이트해주세요.

타겟별 분석 범위:
- 로컬: 현재 프로젝트 .claude/ 디렉토리
- Shared: ~/.claude/ 글로벌 설정 (CLAUDE.md, MCP.md, SUBAGENT.md, FLAG.md, ORCHESTRATION.md)
- 자체: update-claude.md 명령어 파일들

jito의 실용주의 철학(단순함 > 복잡성, YAGNI)과 superclaude의 Zero-config 원칙에 맞게 최적화하되,
Rule #1을 절대 준수하여 모든 중요 변경사항은 사전 승인을 받고 안전하게 진행해주세요."
```

### Agent 협업 워크플로우
```
1. /update-claude 명령어 실행
2. 📋 $ARGUMENTS 파싱 및 모드 결정
3. 🤖 Task(claude-code-expert) 자동 호출
4. 🔍 Agent의 지능형 분석 시작
5. ⚡ superclaude 최적화 실행
6. ✅ 결과 검증 및 피드백
```

## 실전 워크플로우

### 🎯 지능형 타겟별 워크플로우

#### 📅 일상적 유지보수 (주 1회)
```bash
# 컨텍스트 기반 자동 감지로 관련 타겟만 점검
/update-claude --check                # 현재 위치 기준 자동 타겟 선택

# dotfiles 프로젝트에서 실행시: shared 우선 점검
# 로컬 .claude/ 있는 프로젝트: 로컬 우선 점검
# 일반 디렉토리: shared만 점검
```

#### 🔧 정기적 최적화 (월 1회)
```bash
# 전체 시스템 통합 최적화
/update-claude --all --think          # 모든 타겟 + 전략적 사고

# 심층 분석으로 종합 점검
/update-claude --all --ultrathink --safe
```

#### 🎛️ 타겟별 세밀한 관리
```bash
# 현재 프로젝트 설정만 개선
/update-claude --local --safe

# 글로벌 설정 업데이트 (모든 프로젝트 영향)
/update-claude --shared --analyze --safe

# 명령어 자체 최신화 (다른 프로젝트와 동기화)
/update-claude --self --check
```

#### 🆘 긴급 수정 (문제 발생시)
```bash
# Rule #1 위반이나 심각한 문제 발견시
/update-claude --all --force --safe   # 모든 타겟 강제 복구

# 특정 타겟만 롤백
/update-claude --shared --rollback [timestamp]
/update-claude --local --rollback [timestamp]
```

## 자동화 수준

### 🤖 완전 자동 (승인 불필요)
- 오타 수정과 문법 교정
- 링크 유효성 복구
- 성능 최적화 (안전한 수준)
- 중복 제거 및 정리

### 🤝 승인 후 자동 (jito 확인 필요)
- 설정 구조 변경
- 새로운 기능 추가
- 워크플로우 개선
- 철학이나 컨벤션 업데이트

### 🛑 수동 전용 (절대 자동화 금지)
- Rule #1 관련 변경
- 핵심 철학 수정
- 보안 관련 설정
- 실험적 기능 도입

## 품질 지표

### 📊 설정 건강도 측정
```
건강도 점수 (100점 만점):
- Rule #1 준수도: 25점
- 철학 일관성: 25점  
- 기술적 무결성: 25점
- 성능 최적화: 25점

목표: 95점 이상 유지
```

### 🎯 성공 기준
- **Zero Regression**: 업데이트로 인한 기능 저하 0건
- **Rule #1 100%**: 모든 중요 변경사항 사전 승인
- **링크 무결성**: @참조 유효성 100% 보장
- **철학 준수**: jito 컨벤션 완벽 적용

## 롤백 및 복구

### 🔄 자동 롤백 트리거
- Rule #1 위반 감지시
- @참조 링크 무결성 파괴시
- 설정 로딩 실패시
- 사용자 명시적 요청시

### 💾 백업 및 버전 관리
```bash
# 자동 백업 위치
~/.claude/backups/YYYY-MM-DD-HH-MM-SS/

# 특정 시점으로 롤백
/update-claude --rollback 2025-01-15-14-30-00
```

## 고급 사용법

### 🎛️ 세밀한 제어
```bash
# 특정 파일만 업데이트
/update-claude CLAUDE.md --safe

# 특정 유형만 검사
/update-claude --check --focus=references

# 드라이런 모드 (실제 변경 없이 시뮬레이션)
/update-claude --dry-run --ultrathink
```

### 📈 분석 및 최적화
```bash
# 성능 분석 포함
/update-claude --analyze --optimize

# 토큰 사용량 최적화 집중
/update-claude --optimize-tokens

# 전체 아키텍처 재검토
/update-claude --architect --ultrathink --safe
```

## 📋 실전 체크리스트

### 업데이트 전 확인사항
- [ ] 현재 작업 중인 프로젝트 없음
- [ ] Git 상태 클린 (커밋되지 않은 변경사항 없음)
- [ ] 충분한 시간 확보 (복잡한 업데이트의 경우)
- [ ] 문제 발생시 롤백 계획 확보

### 업데이트 후 검증사항
- [ ] 모든 @참조 링크 정상 작동
- [ ] Claude Code 정상 실행 확인
- [ ] 주요 명령어 테스트 실행
- [ ] 성능 최적화 효과 확인
- [ ] jito 철학과 컨벤션 유지 확인

---

## 🛠️ 실제 구현

```markdown
# 1. 타겟 감지 및 인수 파싱
if [[ "$ARGUMENTS" == *"--local"* ]]; then
    TARGET="local"; MODE="로컬 .claude/ 디렉토리 업데이트"
elif [[ "$ARGUMENTS" == *"--shared"* ]]; then
    TARGET="shared"; MODE="~/.claude/ 글로벌 설정 업데이트"
elif [[ "$ARGUMENTS" == *"--all"* ]]; then
    TARGET="all"; MODE="모든 타겟 통합 업데이트"
elif [[ "$ARGUMENTS" == *"--self"* ]]; then
    TARGET="self"; MODE="update-claude.md 자체 업데이트"
else
    # 지능형 자동 감지
    TARGET=$(detect_context_target)
    MODE="컨텍스트 기반 자동 감지 업데이트"
fi

# 모드 세부 설정
if [[ "$ARGUMENTS" == *"--check"* ]]; then
    MODE="$MODE (점검 모드)"
elif [[ "$ARGUMENTS" == *"--safe"* ]]; then
    MODE="$MODE (안전 모드)"
elif [[ "$ARGUMENTS" == *"--force"* ]]; then
    MODE="$MODE (강제 모드)"
fi

# 2. claude-code-expert agent에게 Task 위임
Task tool 사용:
subagent_type: claude-code-expert
description: "Claude Code 설정 [$TARGET] 타겟 업데이트"
prompt: "Claude Code 설정을 [$TARGET 타겟]에서 [$MODE]로 업데이트해주세요.

타겟별 세부 작업:
- local: 현재 프로젝트 .claude/ 디렉토리 전체 분석 및 최적화
- shared: ~/.claude/ 글로벌 설정 (CLAUDE.md, MCP.md, SUBAGENT.md, FLAG.md, ORCHESTRATION.md) 통합 관리
- all: 로컬 + shared + 자체 업데이트의 계층적 실행
- self: update-claude.md 파일들의 최신화 및 동기화

jito의 실용주의 철학(단순함 > 복잡성, YAGNI, 문제 중심)과 superclaude Zero-config 원칙을 완벽 구현하되,
Rule #1을 절대 준수하여 모든 중요 변경사항은 반드시 사전 승인을 받고 안전하게 진행해주세요.

핵심 분석 영역:
- @참조 무결성과 링크 유효성 100% 보장
- jito 컨벤션 완벽 준수 (한국어, 실용주의, YAGNI)
- 토큰 효율성과 성능 자동 최적화
- superclaude 자동화 원칙과 Zero-config 달성도
- Rule #1 보장 체계와 안전 장치 완결성

모든 변경사항은 점진적, 안전하게 적용하고 완료 후 전체 시스템 건강도를 상세 리포트해주세요."
```

*claude-code-expert agent가 jito의 철학에 맞는 지능적 진화와 안전한 업데이트를 담당합니다*
