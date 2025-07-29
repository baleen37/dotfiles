# Nix Dotfiles 리팩토링 계획

## 개요

이 문서는 Professional Nix Dotfiles 시스템의 리팩토링 계획을 제시합니다. Phase 3를 제거하여 더 집중적이고 실용적인 접근을 취합니다.

## 현재 상태 분석

### 강점
- ✅ 전문적인 Nix flakes 기반 아키텍처
- ✅ macOS/NixOS 크로스 플랫폼 지원
- ✅ 포괄적인 테스트 프레임워크
- ✅ Claude Code 통합으로 AI 개발 지원

### 주요 이슈
- ❌ 52개 dead code 파일 (주로 `.dead-code-backup/` 폴더)
- ❌ 복잡한 의존성 구조 (43개 라이브러리 의존성)
- ❌ 중복된 테스트 구조
- ❌ 8개 potential false positive 파일

## 리팩토링 계획

### Phase 1: Dead Code 정리 (우선순위: 높음)

#### 목표
기존 시스템에서 사용되지 않는 코드와 백업 파일들을 안전하게 제거하여 코드베이스를 깔끔하게 정리

#### 작업 항목

**1.1 Backup 폴더 완전 제거**
- `.dead-code-backup/phase1_20250728_105904/` 전체 폴더 삭제
- 45개 백업된 라이브러리 및 테스트 파일들 제거
- Git history에서 완전 제거

**1.2 Consolidated Tests 정리**
- `tests-consolidated/` 디렉토리 완전 제거 (35개 파일)
- 중복된 테스트 파일들과 실제 테스트 파일들 통합 확인
- 테스트 커버리지 유지 검증

**1.3 False Positive 검증**
- `lib/performance-config.nix` → 실제 사용 여부 재확인
- `modules/darwin/dock/default.nix` → 의존성 체크
- `overlays/10-feather-font.nix`, `overlays/20-hammerspoon.nix` → 활용도 검증
- `tests/config/test-suite.nix`, `tests/default.nix` → 테스트 러너 역할 확인

**예상 소요 시간**: 3-4시간  
**담당 에이전트**:
- **debugger**: 의존성 검증 및 안전한 제거
- **legacy-modernizer**: 구식 패턴 식별 및 정리

**성공 지표**:
- Dead code 파일 수 0개 달성
- `nix flake check` 성공 유지
- 전체 테스트 suite 통과 (100%)
- Build 시간 10-15% 개선

### Phase 2: 모듈 구조 최적화 (우선순위: 중간)

#### 목표
라이브러리 간 의존성을 단순화하고 중복 코드를 통합하여 유지보수성 향상

#### 작업 항목

**2.1 Library 의존성 단순화**
- 현재 43개 의존성 관계를 25개 이하로 축소
- `lib/utils-system.nix`를 중심으로 한 계층 구조 확립
- `lib/error-system.nix` 기반 통합 에러 처리 시스템 구축
- 순환 의존성 완전 해결

**2.2 플랫폼별 모듈 통합**
- `modules/darwin/home-manager.nix` ↔ `modules/nixos/home-manager.nix` 공통 로직 추출
- 플랫폼 특화 로직을 `modules/shared/` 활용도 증대
- 중복된 패키지 설정 통합

**2.3 테스트 구조 개선**
- 현재 29개 테스트 파일을 기능별로 재그룹핑
- Unit/Integration/E2E 테스트 명확한 분리 및 표준화
- `tests/lib/` 헬퍼 함수들 통합 및 재사용성 증대

**예상 소요 시간**: 5-6시간  
**담당 에이전트**:
- **backend-architect**: 모듈 아키텍처 설계 및 의존성 최적화
- **test-automator**: 테스트 구조 개선 및 자동화

**성공 지표**:
- 라이브러리 의존성 그래프 복잡도 30% 감소
- 중복 코드 라인 50% 감소  
- 테스트 실행 시간 20% 단축
- 모든 플랫폼에서 테스트 100% 통과

### Phase 3: 성능 및 품질 개선 (우선순위: 낮음)

#### 목표
시스템 성능을 최적화하고 코드 품질을 향상시켜 장기적 안정성 확보

#### 작업 항목

**3.1 Build 성능 최적화**
- 불필요한 rebuild 트리거 최소화
- Nix store cache 전략 개선
- 병렬 빌드 최적화 (현재 단일 코어 → 멀티코어 활용)

**3.2 코드 품질 향상**
- Pre-commit hooks 강화 (현재 기본 → 포괄적 검증)
- Nix 코드 linting 규칙 표준화
- 타입 안전성 개선 및 문서화 자동화

**3.3 모니터링 개선**
- Build 성능 메트릭 수집 시스템 구축
- 에러 추적 및 분석 자동화
- 시스템 사용 통계 수집

**예상 소요 시간**: 3-4시간  
**담당 에이전트**:
- **performance-engineer**: Build 성능 최적화
- **code-reviewer**: 코드 품질 기준 수립 및 적용

**성공 지표**:
- 전체 build 시간 20% 단축
- 코드 품질 메트릭 85점 이상
- 에러 발생률 50% 감소
- CI/CD 파이프라인 안정성 95% 이상

## 실행 전략

### 타임라인 (수정됨)
- **Week 1**: Phase 1 완료 (Dead Code 정리)
- **Week 2**: Phase 2 시작 및 진행 (모듈 구조 최적화)
- **Week 3**: Phase 2 완료
- **Week 4**: Phase 3 선택적 진행 (성능 및 품질 개선)

### Agent 협업 전략

#### Primary Agent 역할 분담
- **context-manager**: 전체 프로젝트 컨텍스트 관리 및 Phase 간 연계
- **debugger**: 안전한 코드 제거 및 의존성 검증
- **legacy-modernizer**: 구식 패턴 현대화 및 기술 부채 해결
- **backend-architect**: 모듈 아키텍처 설계 및 최적화
- **test-automator**: 테스트 전략 수립 및 CI/CD 개선

#### Agent 협업 프로토콜
1. **정보 공유**: 각 Agent는 작업 결과를 context-manager에게 전달
2. **품질 보증**: 모든 변경사항은 code-reviewer의 검토 필수
3. **성능 검증**: performance-engineer가 각 Phase 완료 후 성능 측정
4. **위험 관리**: security-auditor가 보안 관련 변경사항 검토

### 품질 보증 체계

#### 각 Phase 완료 기준
1. **기능 검증**: 모든 기존 기능 정상 동작 확인
2. **성능 검증**: 기준 성능 지표 달성 확인
3. **안정성 검증**: 48시간 연속 운영 테스트 통과
4. **호환성 검증**: 모든 지원 플랫폼에서 정상 동작

#### 롤백 계획
- 각 Phase 시작 전 전체 시스템 백업
- Git 태그를 통한 버전 관리
- 자동화된 롤백 스크립트 준비
- 긴급 상황 대응 매뉴얼 준비

## 예상 효과

### 즉시 효과 (Phase 1 완료 후)
- 코드베이스 크기 30% 감소
- Build 시간 15% 개선
- 개발자 경험 향상 (깔끔한 구조)

### 중기 효과 (Phase 2 완료 후)
- 유지보수 시간 40% 단축
- 새로운 기능 추가 시간 25% 단축
- 버그 발생률 60% 감소

### 장기 효과 (전체 계획 완료 후)
- 시스템 안정성 95% 이상
- 개발 생산성 50% 향상
- 기술 부채 80% 해결

이 리팩토링 계획은 안전하고 점진적인 접근 방식을 통해 현재 시스템의 강점을 유지하면서도 문제점을 체계적으로 해결합니다. Phase 3를 제거함으로써 더 집중적이고 실용적인 개선에 집중할 수 있습니다.
