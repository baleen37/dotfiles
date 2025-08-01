# /update-claude - 지능형 Claude Code 설정 업데이트

Claude Code 설정과 전체 시스템을 jito의 철학에 맞게 자동으로 업데이트하고 최적화.

## 목적
- **Zero-Config 진화**: 설정 없이 자동으로 최신 베스트 프랙티스 적용
- **지능형 감지**: 변경된 부분만 스마트하게 업데이트
- **안전 우선**: Rule #1 준수하면서 점진적 개선
- **일관성 보장**: jito의 철학과 컨벤션 완벽 유지

## 사용법
```bash
/update-claude                        # 지능형 자동 업데이트
/update-claude --check                # 업데이트 필요 항목 확인만
/update-claude --safe                 # 안전 모드 (승인 후 적용)
/update-claude --force                # 강제 전체 업데이트 (주의)
```

## 자동 감지 범위

### 🧠 설정 파일 지능형 분석
```bash
/update-claude                        # 모든 설정 자동 스캔
```
**자동 감지 항목**:
- **CLAUDE.md**: @참조 무결성, Rule #1 준수, 철학 일관성
- **MCP.md**: 서버 자동 실행 로직, 키워드 매칭 최적화
- **SUBAGENT.md**: Task 도구 협업 패턴, 복잡도 감지 알고리즘
- **FLAG.md**: 사고 모드 플래그 활용법, 성능 최적화
- **ORCHESTRATION.md**: 지능형 자동화 시스템, 학습 기반 개선
- **agents/*.md**: Subagent 전문성, 도구, 워크플로우 검증
- **commands/*.md**: 명령어 일관성, 사용법, 철학 적합성

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

## 실전 워크플로우

### 📅 일상적 유지보수 (주 1회)
```bash
# 빠른 건강 상태 확인
/update-claude --check

# 문제 발견시 안전 모드로 수정
/update-claude --safe
```

### 🔧 정기적 최적화 (월 1회)
```bash
# 전체 시스템 최적화
/update-claude --think

# 성능과 일관성 종합 점검
/update-claude --ultrathink --safe
```

### 🆘 긴급 수정 (문제 발생시)
```bash
# Rule #1 위반이나 심각한 문제 발견시
/update-claude --force --safe

# 롤백이 필요한 경우
/update-claude --rollback [timestamp]
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

*지능적 진화, 안전한 업데이트 - Claude Code 설정을 항상 최신 최적 상태로 유지*
