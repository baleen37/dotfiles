# 리팩토링 Todo 및 Agent 할당 (수정됨)

## 현재 진행 상황

### ✅ 완료된 작업
- [x] 현재 코드베이스 상태 분석 및 이해
- [x] 리팩토링이 필요한 영역 식별
- [x] 단계별 리팩토링 계획 수립
- [x] 종합 계획서 작성 (plan.md)
- [x] Phase 3 제거 및 계획 단순화

### 🚧 진행 중인 작업
- [x] 전문 에이전트별 역할 분담 세부 계획 수립

## Agent 할당 및 역할 (3단계로 축소)

### Phase 1: Dead Code 정리
**Lead Agent**: `debugger`  
**Supporting Agent**: `legacy-modernizer`

#### 세부 작업 분담

**debugger 담당**:
- [ ] `.dead-code-backup/` 폴더 의존성 분석
- [ ] False positive 파일들 실제 사용 여부 검증
- [ ] 안전한 파일 제거 절차 수립
- [ ] 각 제거 단계별 build 테스트 실행

**legacy-modernizer 담당**:
- [ ] `tests-consolidated/` 구식 테스트 패턴 분석
- [ ] 중복된 테스트 로직 현대적 패턴으로 통합
- [ ] 레거시 configuration 파일들 정리
- [ ] 구식 Nix 패턴들 현대 버전으로 마이그레이션

### Phase 2: 모듈 구조 최적화
**Lead Agent**: `backend-architect`  
**Supporting Agent**: `test-automator`

#### 세부 작업 분담

**backend-architect 담당**:
- [ ] lib/ 폴더 의존성 그래프 재설계
- [ ] 플랫폼별 모듈 공통 로직 추출 아키텍처 설계
- [ ] `lib/utils-system.nix` 중심 계층 구조 구축
- [ ] 순환 의존성 해결 방안 구현

**test-automator 담당**:
- [ ] 29개 테스트 파일 기능별 재그룹핑 전략 수립
- [ ] Unit/Integration/E2E 테스트 분리 자동화
- [ ] `tests/lib/` 헬퍼 함수 통합 및 재사용성 개선
- [ ] 테스트 실행 시간 최적화 (20% 단축 목표)

### Phase 3: 성능 및 품질 개선
**Lead Agent**: `performance-engineer`  
**Supporting Agent**: `code-reviewer`

#### 세부 작업 분담

**performance-engineer 담당**:
- [ ] Build 성능 메트릭 수집 시스템 구축
- [ ] 불필요한 rebuild 트리거 최소화
- [ ] Nix store cache 전략 개선
- [ ] 병렬 빌드 최적화 (멀티코어 활용)

**code-reviewer 담당**:
- [ ] Pre-commit hooks 강화 (기본 → 포괄적 검증)
- [ ] Nix 코드 linting 규칙 표준화
- [ ] 코드 품질 메트릭 85점 이상 달성
- [ ] 자동화된 코드 리뷰 체계 구축

## 지원 Agent 역할

### `context-manager`
- [ ] 전체 프로젝트 컨텍스트 관리 및 Phase 간 연계
- [ ] Agent 간 정보 공유 및 협업 조정
- [ ] 장기적 아키텍처 일관성 유지
- [ ] 프로젝트 진행 상황 추적 및 보고

### `security-auditor`
- [ ] 보안 관련 변경사항 검토 (모든 Phase)
- [ ] 설정 파일 외부화 시 보안 검증
- [ ] Agent 시스템 통합 시 권한 검토
- [ ] 전체 시스템 보안 무결성 검증

### 품질 보증 체계

#### 각 Phase별 검증 Agent
1. **debugger**: Phase 1 완료 후 전체 시스템 무결성 검증
2. **test-automator**: Phase 2 완료 후 테스트 커버리지 100% 달성 확인
3. **performance-engineer**: Phase 3 완료 후 성능 지표 달성 확인

#### 지속적 품질 관리
- **code-reviewer**: 모든 코드 변경에 대한 품질 검토
- **security-auditor**: 보안 관련 변경사항 지속 모니터링
- **context-manager**: 전체 아키텍처 일관성 유지

## 다음 단계

### 즉시 실행할 작업
1. **debugger** 에이전트 활성화하여 Phase 1 시작
2. `.dead-code-backup/` 폴더 상세 분석 실행
3. False positive 파일들 의존성 검증 시작

### 주간 마일스톤 (수정됨)
- **Week 1 목표**: Phase 1 완료, dead code 0개 달성
- **Week 2 목표**: Phase 2 시작 및 50% 진행, 의존성 그래프 재설계 완료
- **Week 3 목표**: Phase 2 완료
- **Week 4 목표**: Phase 3 선택적 진행 (성능 및 품질 개선)

## 변경 사항 요약

### 제거된 내용
- 기존 Phase 3 (아키텍처 개선) 완전 제거
- `cloud-architect` 및 `devops-troubleshooter` 메인 역할 제거
- 복잡한 플랫폼 분리 및 설정 관리 작업 제거

### 단순화된 접근
- 3단계로 축소: Dead Code → 모듈 최적화 → 성능 개선
- 더 집중적이고 실용적인 리팩토링
- 복잡성 감소로 위험 요소 최소화

이 수정된 할당 체계를 통해 더 집중적이고 실행 가능한 리팩토링을 진행할 수 있습니다.
