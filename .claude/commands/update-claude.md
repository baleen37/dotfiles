# /update-claude - Practical 5-Stage Wave System

Claude Code 설정의 체계적 개선을 위한 실용적 5단계 Wave 시스템.

## Command Usage

```bash
/update-claude                    # 자동 Wave 시스템 실행
/update-claude --analyze-only     # 현황 분석만 (변경 없음)
/update-claude --safe-mode        # Rule #1 준수 강화
/update-claude --quick-fix        # 안전한 자동 수정만
```

## 🌊 5-Stage Wave System

### Wave 1 - Configuration Scan (현황 분석)
**목표**: Claude 설정 전체 상태 파악 및 문제점 분류
**시간**: 2-3분, **토큰**: 3-5K

**실행 단계**:
1. **전체 스캔**: `Grep "\.md$|\.yaml$" modules/shared/config/claude` 
2. **구조 검증**: 파일 존재성, @참조 링크 무결성
3. **문법 체크**: Markdown lint, YAML 구조 검증
4. **카테고리 분류**: Syntax/Structure/Performance/Quality 이슈

**출력**: 문제점 우선순위 매트릭스, Wave 2-5 작업 계획

### Wave 2 - Strategy & Expert Selection (전략 수립)
**목표**: 안전한 자동화 vs 승인 필요 작업 분류
**시간**: 1-2분, **토큰**: 1-2K

**실행 단계**:
1. **위험도 평가**: Rule #1 관련 변경 감지
2. **자동화 범위**: 안전한 수정 (MD lint, 포맷팅) vs 구조적 변경
3. **Task 도구 선택**: 필요한 전문 영역별 agent 결정
4. **병렬 처리**: 독립적 파일별 동시 작업 계획

**출력**: 자동 실행 목록, 승인 필요 목록, Task 위임 계획

### Wave 3 - Core Implementation (핵심 변경)
**목표**: 구조적 개선사항 안전하게 실행
**시간**: 5-10분, **토큰**: 8-15K

**실행 도구**:
- **MultiEdit**: 다중 파일 동시 수정 (참조 링크 정합성)
- **Task**: 복잡한 구조 변경은 전문 agent에 위임
- **Grep + Read**: 변경 전 정확한 현재 상태 파악

**핵심 작업**:
1. **참조 링크 수정**: @CLAUDE.md, @commands/* 등 일관성 확보
2. **구조 표준화**: YAML frontmatter, 헤더 레벨 통일
3. **중복 제거**: 동일 내용 통합, 토큰 효율성 개선

### Wave 4 - Quality Assurance (품질 검증)
**목표**: 전체 설정 시스템 통합성 확인
**시간**: 2-3분, **토큰**: 2-4K

**검증 체크리스트**:
- [ ] **Markdown Syntax**: CommonMark 호환성
- [ ] **YAML Structure**: 헤더 스키마 검증
- [ ] **Link Integrity**: 모든 @참조 해결 가능
- [ ] **Rule #1 Compliance**: 핵심 철학 보존

**도구 활용**:
- **Grep**: 깨진 링크, 구문 오류 스캔
- **Read**: 수정된 파일 재검증
- **Task**: 복잡한 품질 검증은 code-reviewer에게 위임

### Wave 5 - Optimization & Cleanup (최적화)
**목표**: 토큰 효율성과 사용성 최적화
**시간**: 2-4분, **토큰**: 3-5K

**최적화 작업**:
1. **토큰 압축**: 불필요한 설명 제거, 핵심만 유지
2. **구조 정리**: 파일 순서, 섹션 배치 최적화
3. **사용성 개선**: 명령어 예시, 참조 가이드 개선
4. **최종 검증**: 전체 시스템 일관성 확인

## 🎯 Practical Implementation Strategy

### 간단한 복잡도 판단
```bash
# 자동 수정 가능 (Wave 3에서 즉시 실행)
- MD lint 오류 (MD001, MD022, MD032 등)
- @참조 링크 수정
- YAML frontmatter 표준화
- 오타, 포맷팅 일관성

# Task 위임 필요 (전문 agent 활용)
- 구조적 재설계 (3+ 파일 영향)
- 새로운 명령어/agent 추가
- 복잡한 로직 변경
- Rule #1 관련 수정

# 승인 필요 (절대 자동화 금지)
- YAGNI 철학 변경
- 핵심 제약사항 수정
- 새로운 자동화 규칙
- 보안 정책 변경
```

### Task Tool Integration
```yaml
# Wave 3에서 전문 agent 활용
agent_selection:
  config-auditor:        # 구조 검증, 일관성 체크
    - 파일 구조 분석
    - 참조 무결성 검증
    
  prompt-engineer:       # 토큰 최적화, 프롬프트 개선  
    - 불필요한 설명 제거
    - 명령어 효율성 개선
    
  code-reviewer:         # Wave 4 품질 검증
    - 전체 변경사항 리뷰
    - 안전성 최종 확인
```

### Resource Management
```bash
# 실제 성능 목표
총 실행 시간: 10-20분 (이론적 30분 아님)
토큰 사용량: 15-25K (실용적 범위)
병렬 처리: 독립적 파일별 동시 작업
메모리 효율: 필요한 파일만 Read, 선택적 Grep 사용
```

## 🛡️ Safety & Quality Gates

### Automatic Safety Checks
1. **Rule #1 Guardian**: 핵심 철학 변경 감지시 즉시 중단
2. **Reference Integrity**: @링크 수정 후 실제 파일 존재 확인
3. **Syntax Validation**: 모든 MD/YAML 구문 오류 사전 방지
4. **Backup Strategy**: 중요 변경 전 현재 상태 기록

### Quality Metrics
- **Link Resolution**: 100% @참조 해결 가능
- **Syntax Clean**: 모든 MD lint 오류 제거
- **Token Efficiency**: 평균 20-30% 토큰 절약
- **Structural Consistency**: 95% 이상 표준 패턴 준수

## 🚀 Real Execution Example

```bash
$ /update-claude
🌊 Wave 1 - Configuration Scan
   📁 Found: 13 Claude config files
   🔍 Issues: 5 MD lint, 2 broken @links, 3 format inconsistencies
   📊 Complexity: Medium (auto-fixable + 1 Task delegation)

🌊 Wave 2 - Strategy Selection  
   ✅ Auto-fix: MD022, MD032, @SIMPLE_COMMANDS.md link
   📋 Task delegate: Structural reorganization → config-auditor
   ⚠️  Manual approval: None required

🌊 Wave 3 - Core Implementation
   🔧 MultiEdit: Fixed 5 MD lint issues across 4 files
   🤖 Task → config-auditor: Reorganized command references
   🔗 Updated @links: 2 broken references resolved

🌊 Wave 4 - Quality Assurance
   ✅ Markdown syntax: All files valid
   ✅ YAML structure: Headers standardized  
   ✅ Link integrity: 100% @references resolved
   ✅ Rule #1 check: No philosophy changes

🌊 Wave 5 - Optimization
   📉 Token reduction: 1,247 tokens saved (22% improvement)
   📋 Structure cleanup: Command index reorganized
   🎯 Consistency: 96% standard pattern compliance

🎉 Complete: 14m 32s, 18.7K tokens, 0 manual approvals needed
```

## Key Improvements from Original

**제거된 복잡성**:
- 복잡한 수학적 복잡도 계산
- 가상의 "SuperClaude Framework" 참조  
- 과도한 이론적 설명과 알고리즘

**강화된 실용성**:
- 명확한 Wave별 목표와 실행 도구
- 실제 실행 시간과 토큰 사용량
- 구체적인 안전장치와 품질 기준
- jito의 실제 사용 패턴 반영

**핵심 가치 유지**:
- 체계적인 5-Stage 처리
- Rule #1 절대 보호
- 안전한 자동화 vs 승인 필요 구분
- Task 도구를 통한 전문가 활용

**Philosophy**: "Systematic • Practical • Safe • Token-Efficient"