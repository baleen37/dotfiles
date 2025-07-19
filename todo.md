# 테스트 코드 강화 프로젝트 - 상세 구현 계획

## 🔧 단계별 LLM 프롬프트 가이드

이 문서는 각 단계를 순차적으로 구현하기 위한 상세한 프롬프트들을 포함합니다. 각 프롬프트는 이전 단계의 결과를 기반으로 하여 점진적으로 프로젝트를 완성합니다.

---

## 📝 **PROMPT A1: Homebrew 테스트 헬퍼 함수 작성**

```
**목표**: Homebrew 관련 테스트에서 사용할 공통 헬퍼 함수들을 작성합니다.

**작업 순서**:
1. `tests/lib/homebrew-test-helpers.nix` 파일을 생성
2. 기존 `tests/lib/test-helpers.nix` 파일의 구조와 패턴을 참고
3. 다음 함수들을 구현:
   - `assertCaskValid`: cask 이름 유효성 검사
   - `assertCaskExists`: cask 파일 내 존재 여부 확인
   - `assertMasAppValid`: Mac App Store 앱 ID 유효성 검사
   - `mockHomebrewState`: 테스트용 Homebrew 상태 생성
   - `parseHomebrewConfig`: homebrew 설정 파싱
   - `validateCasksList`: casks.nix 파일 검증

**필요한 컨텍스트**:
- 기존 파일: `/Users/jito/dev/dotfiles/tests/lib/test-helpers.nix`
- 기존 파일: `/Users/jito/dev/dotfiles/modules/darwin/casks.nix`
- 기존 파일: `/Users/jito/dev/dotfiles/modules/darwin/home-manager.nix`

**예상 결과**:
새로운 파일 `tests/lib/homebrew-test-helpers.nix`가 생성되며, 다른 테스트에서 import하여 사용할 수 있는 Homebrew 전용 헬퍼 함수들이 포함됩니다.

**검증 방법**:
```bash
nix-instantiate --eval tests/lib/homebrew-test-helpers.nix
```
```

---

## 📝 **PROMPT A2: Homebrew 핵심 기능 단위 테스트 작성**

```
**목표**: Homebrew 통합 기능의 핵심 동작을 검증하는 종합적인 단위 테스트를 작성합니다.

**작업 순서**:
1. `tests/unit/homebrew-ecosystem-comprehensive-unit.nix` 파일을 생성
2. 기존 단위 테스트 패턴을 참고하여 구조 설계
3. A1에서 작성한 homebrew-test-helpers.nix를 import
4. 다음 테스트 케이스들을 구현:
   - Homebrew 활성화 상태 검증
   - nix-homebrew 통합 설정 검증
   - mas (Mac App Store) 설정 검증
   - homebrew cleanup 설정 검증
   - homebrew 환경변수 설정 검증

**필요한 컨텍스트**:
- 이전 단계: `tests/lib/homebrew-test-helpers.nix` (A1에서 생성)
- 참고 파일: `/Users/jito/dev/dotfiles/tests/unit/build-switch-unit.nix`
- 참고 파일: `/Users/jito/dev/dotfiles/tests/lib/test-helpers.nix`
- 대상 파일: `/Users/jito/dev/dotfiles/modules/darwin/home-manager.nix`

**예상 결과**:
새로운 파일 `tests/unit/homebrew-ecosystem-comprehensive-unit.nix`가 생성되며, Homebrew 시스템의 기본 설정과 통합이 올바르게 구성되어 있는지 검증합니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.homebrew_ecosystem_comprehensive_unit
```
```

---

## 📝 **PROMPT A3: Casks 관리 시스템 단위 테스트 작성**

```
**목표**: casks.nix 파일의 구조와 내용을 검증하는 단위 테스트를 작성합니다.

**작업 순서**:
1. `tests/unit/casks-management-unit.nix` 파일을 생성
2. A1에서 작성한 homebrew-test-helpers.nix를 활용
3. 다음 테스트 케이스들을 구현:
   - 모든 cask 이름 형식 유효성 검사
   - 중복된 cask 항목 탐지
   - 카테고리별 cask 분류 검증 (주석 기반)
   - 알려진 문제가 있는 cask 탐지
   - cask 이름 알파벳 순서 검증

**필요한 컨텍스트**:
- 이전 단계: `tests/lib/homebrew-test-helpers.nix` (A1에서 생성)
- 대상 파일: `/Users/jito/dev/dotfiles/modules/darwin/casks.nix`
- 참고 파일: `/Users/jito/dev/dotfiles/tests/unit/configuration-validation-unit.nix`

**예상 결과**:
새로운 파일 `tests/unit/casks-management-unit.nix`가 생성되며, casks.nix 파일의 품질과 일관성을 검증합니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.casks_management_unit
```
```

---

## 📝 **PROMPT A4: 기존 brew 테스트 확장 및 Nix 통합**

```
**목표**: 기존의 `brew-karabiner-test.sh`를 확장하고 Nix 테스트 프레임워크에 통합합니다.

**작업 순서**:
1. 기존 `tests/brew-karabiner-test.sh` 파일 분석
2. 해당 테스트를 Nix 기반으로 재작성: `tests/unit/brew-karabiner-integration-unit.nix`
3. A1에서 작성한 homebrew-test-helpers.nix 활용
4. 기존 테스트 케이스를 모두 포함하되 Nix 테스트 패턴으로 변환
5. 추가 테스트 케이스 구현:
   - Karabiner-Elements의 Homebrew vs Nix 설치 충돌 검증
   - 설정 파일 경로 일관성 검증
   - 버전 호환성 검증

**필요한 컨텍스트**:
- 기존 파일: `/Users/jito/dev/dotfiles/tests/brew-karabiner-test.sh`
- 이전 단계: `tests/lib/homebrew-test-helpers.nix` (A1에서 생성)
- 관련 설정: karabiner-elements 관련 설정 부분

**예상 결과**:
새로운 파일 `tests/unit/brew-karabiner-integration-unit.nix`가 생성되고, 기존 bash 테스트가 Nix 테스트 프레임워크에 통합됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.brew_karabiner_integration_unit
```
```

---

## 📝 **PROMPT B1: Homebrew-Nix 충돌 관리 통합 테스트**

```
**목표**: Homebrew와 Nix 패키지 간의 충돌을 감지하고 관리하는 통합 테스트를 작성합니다.

**작업 순서**:
1. `tests/integration/homebrew-nix-conflict-resolution.nix` 파일을 생성
2. A1에서 작성한 homebrew-test-helpers.nix 활용
3. 다음 시나리오들을 테스트:
   - 동일한 앱이 Homebrew와 Nix 모두에서 설치되는 경우
   - PATH 환경변수에서의 우선순위 충돌
   - 심볼릭 링크 충돌 시나리오
   - 라이브러리 충돌 감지

**필요한 컨텍스트**:
- 이전 단계: Phase A의 모든 결과물
- 참고 파일: `/Users/jito/dev/dotfiles/tests/integration/cross-platform-integration.nix`
- 관련 설정: `/Users/jito/dev/dotfiles/modules/darwin/packages.nix`

**예상 결과**:
Homebrew와 Nix 생태계 간의 잠재적 충돌을 사전에 감지할 수 있는 통합 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.homebrew_nix_conflict_resolution
```
```

---

## 📝 **PROMPT B2: build-switch + Homebrew 통합 테스트**

```
**목표**: build-switch 명령어 실행 시 Homebrew 변경사항이 올바르게 적용되는지 검증하는 통합 테스트를 작성합니다.

**작업 순서**:
1. `tests/integration/build-switch-homebrew-integration.nix` 파일을 생성
2. 기존 build-switch 테스트 패턴을 참고
3. 다음 시나리오들을 테스트:
   - casks.nix 변경 후 build-switch 실행
   - mas 앱 추가 후 build-switch 실행
   - homebrew 설정 변경 후 build-switch 실행
   - 실패한 설치 후 재시도 시나리오

**필요한 컨텍스트**:
- 이전 단계: Phase A의 모든 결과물
- 기존 파일: `/Users/jito/dev/dotfiles/tests/integration/build-switch-workflow-integration-test.nix`
- 대상 스크립트: `/Users/jito/dev/dotfiles/apps/aarch64-darwin/build-switch`

**예상 결과**:
build-switch와 Homebrew의 통합 동작을 검증하는 포괄적인 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.build_switch_homebrew_integration
```
```

---

## 📝 **PROMPT B3: Homebrew rollback 시나리오 통합 테스트**

```
**목표**: Homebrew 관련 변경사항의 실패 시 롤백 메커니즘을 검증하는 테스트를 작성합니다.

**작업 순서**:
1. `tests/integration/homebrew-rollback-scenarios.nix` 파일을 생성
2. 다음 실패 시나리오들을 시뮬레이션:
   - 네트워크 오류로 인한 cask 다운로드 실패
   - 디스크 공간 부족으로 인한 설치 실패
   - 권한 오류로 인한 설치 실패
   - 부분적 설치 실패 후 시스템 상태 복구

**필요한 컨텍스트**:
- 이전 단계: Phase A와 B1, B2의 결과물
- 참고 파일: `/Users/jito/dev/dotfiles/tests/integration/build-switch-rollback-integration.nix`

**예상 결과**:
Homebrew 관련 오류 상황에서의 시스템 복구 능력을 검증하는 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.homebrew_rollback_scenarios
```
```

---

## 📝 **PROMPT C1: macOS 시스템 통합 E2E 테스트**

```
**목표**: macOS 시스템 레벨에서의 Homebrew 통합을 검증하는 end-to-end 테스트를 작성합니다.

**작업 순서**:
1. `tests/e2e/macos-system-integration-e2e.nix` 파일을 생성
2. 다음 시스템 통합 요소들을 테스트:
   - LaunchServices 데이터베이스 등록 상태
   - Spotlight 인덱싱 상태
   - 앱 권한 및 서명 검증
   - Dock 통합 상태

**필요한 컨텍스트**:
- 이전 단계: Phase A, B의 모든 결과물
- 참고 파일: `/Users/jito/dev/dotfiles/tests/e2e/system-build-e2e.nix`
- macOS 특화 기능 관련 설정들

**예상 결과**:
macOS 시스템과의 완전한 통합을 검증하는 포괄적인 E2E 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.macos_system_integration_e2e
```
```

---

## 📝 **PROMPT C2: macOS 버전별 호환성 통합 테스트**

```
**목표**: 다양한 macOS 버전에서의 Homebrew 호환성을 검증하는 테스트를 작성합니다.

**작업 순서**:
1. `tests/integration/macos-version-compatibility.nix` 파일을 생성
2. macOS 버전 감지 로직 구현
3. 버전별 차이점을 고려한 테스트 케이스 작성:
   - macOS Sonoma (14.x) 특화 테스트
   - macOS Sequoia (15.x) 특화 테스트
   - 버전별 Homebrew 동작 차이 검증

**필요한 컨텍스트**:
- 이전 단계: Phase A, B, C1의 결과물
- macOS 버전별 알려진 차이점들

**예상 결과**:
macOS 버전에 관계없이 일관된 동작을 보장하는 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.macos_version_compatibility
```
```

---

## 📝 **PROMPT D1: 네트워크 조건별 E2E 테스트**

```
**목표**: 다양한 네트워크 조건에서의 Homebrew 동작을 검증하는 E2E 테스트를 작성합니다.

**작업 순서**:
1. `tests/e2e/network-conditions-homebrew-e2e.nix` 파일을 생성
2. 네트워크 조건 시뮬레이션 로직 구현
3. 다음 시나리오들을 테스트:
   - 느린 네트워크에서의 타임아웃 처리
   - 간헐적 네트워크 중단 시 재시도 로직
   - 프록시 환경에서의 동작
   - DNS 해결 실패 시 처리

**필요한 컨텍스트**:
- 이전 단계: Phase A-C의 모든 결과물
- 참고 파일: `/Users/jito/dev/dotfiles/tests/e2e/network-failure-recovery-e2e.nix`

**예상 결과**:
다양한 네트워크 환경에서의 견고성을 검증하는 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.network_conditions_homebrew_e2e
```
```

---

## 📝 **PROMPT D2: 시스템 리소스 제약 성능 테스트**

```
**목표**: 시스템 리소스 제약 상황에서의 Homebrew 성능을 검증하는 테스트를 작성합니다.

**작업 순서**:
1. `tests/performance/homebrew-resource-constraints-perf.nix` 파일을 생성
2. 리소스 제약 시뮬레이션 로직 구현
3. 다음 제약 상황들을 테스트:
   - 디스크 공간 부족 시 동작
   - 메모리 부족 시 동작
   - CPU 부하가 높은 상황에서의 성능
   - 동시 다운로드 제한 테스트

**필요한 컨텍스트**:
- 이전 단계: Phase A-D1의 모든 결과물
- 참고 파일: `/Users/jito/dev/dotfiles/tests/performance/build-switch-perf.nix`

**예상 결과**:
리소스 제약 상황에서도 안정적으로 동작하는지 검증하는 성능 테스트가 완성됩니다.

**검증 방법**:
```bash
nix build .#checks.aarch64-darwin.homebrew_resource_constraints_perf
```
```

---

## 📝 **PROMPT E1: tests/default.nix 테스트 등록**

```
**목표**: 새로 작성한 모든 테스트들을 tests/default.nix에 등록하여 테스트 프레임워크에 통합합니다.

**작업 순서**:
1. `tests/default.nix` 파일 수정
2. Phase A-D에서 작성한 모든 테스트들을 적절한 카테고리에 추가
3. 테스트 메타데이터 업데이트
4. 종속성 관계 확인 및 설정

**필요한 컨텍스트**:
- 기존 파일: `/Users/jito/dev/dotfiles/tests/default.nix`
- 이전 단계: Phase A-D의 모든 테스트 파일들

**예상 결과**:
모든 새로운 테스트가 기존 테스트 프레임워크에 완전히 통합됩니다.

**검증 방법**:
```bash
nix flake check
```
```

---

## 📝 **PROMPT E2: 통합 테스트 헬퍼 함수 작성**

```
**목표**: 복잡한 통합 시나리오를 위한 고수준 헬퍼 함수들을 작성합니다.

**작업 순서**:
1. `tests/lib/integration-test-helpers.nix` 파일을 생성
2. 다음 헬퍼 함수들을 구현:
   - `testBuildSwitchWithHomebrew`: build-switch + Homebrew 통합 테스트
   - `compareSystemState`: 시스템 상태 비교
   - `simulateNetworkConditions`: 네트워크 조건 시뮬레이션
   - `measureResourceUsage`: 리소스 사용량 측정

**필요한 컨텍스트**:
- 이전 단계: Phase A-D의 모든 결과물에서 발견된 공통 패턴들
- 기존 파일: `/Users/jito/dev/dotfiles/tests/lib/test-helpers.nix`

**예상 결과**:
복잡한 통합 테스트 시나리오를 간소화하는 헬퍼 함수 라이브러리가 완성됩니다.

**검증 방법**:
```bash
nix-instantiate --eval tests/lib/integration-test-helpers.nix
```
```

---

## 📝 **PROMPT E3: 테스트 실행 스크립트 업데이트**

```
**목표**: 새로운 테스트들을 실행할 수 있도록 기존 테스트 스크립트들을 업데이트합니다.

**작업 순서**:
1. `scripts/test-all-local` 스크립트 수정
2. 새로운 테스트 카테고리를 위한 개별 실행 스크립트 작성
3. Homebrew 관련 테스트만 실행하는 스크립트 작성: `scripts/test-homebrew`

**필요한 컨텍스트**:
- 기존 파일: `/Users/jito/dev/dotfiles/scripts/test-all-local`
- 기존 파일들: `/Users/jito/dev/dotfiles/scripts/test-build-switch-*`
- E1에서 업데이트된 tests/default.nix

**예상 결과**:
새로운 테스트들을 편리하게 실행할 수 있는 스크립트들이 완성됩니다.

**검증 방법**:
```bash
./scripts/test-homebrew
./scripts/test-all-local
```
```

---

## 📝 **PROMPT E4: 문서 업데이트**

```
**목표**: 새로운 테스트들에 대한 문서를 작성하고 기존 문서를 업데이트합니다.

**작업 순서**:
1. `docs/TESTING.md` 파일 업데이트 - 새로운 테스트 카테고리 추가
2. `README.md` 파일 업데이트 - 테스트 실행 방법 추가
3. `CONTRIBUTING.md` 파일 업데이트 - 테스트 작성 가이드라인 추가

**필요한 컨텍스트**:
- 기존 파일: `/Users/jito/dev/dotfiles/docs/TESTING.md`
- 기존 파일: `/Users/jito/dev/dotfiles/README.md`
- 기존 파일: `/Users/jito/dev/dotfiles/CONTRIBUTING.md`
- Phase A-E3의 모든 결과물

**예상 결과**:
새로운 테스트 시스템에 대한 완전한 문서화가 완성됩니다.

**검증 방법**:
문서의 일관성과 완전성을 수동으로 검토
```

---

## 📝 **PROMPT E5: CI/CD 통합 및 최종 검증**

```
**목표**: CI/CD 시스템에 새로운 테스트들을 통합하고 전체 시스템의 최종 검증을 수행합니다.

**작업 순서**:
1. GitHub Actions 워크플로우 업데이트 (있는 경우)
2. 전체 테스트 스위트 실행 및 성능 측정
3. 테스트 커버리지 측정 및 보고서 생성
4. 최종 통합 테스트 실행

**필요한 컨텍스트**:
- Phase A-E4의 모든 결과물
- CI/CD 설정 파일들 (있는 경우)
- 성능 벤치마크 기준

**예상 결과**:
완전히 통합되고 자동화된 테스트 시스템이 완성됩니다.

**검증 방법**:
```bash
# 전체 테스트 실행
nix flake check

# 새로운 Homebrew 테스트만 실행
./scripts/test-homebrew

# 성능 측정
time ./scripts/test-all-local
```
```

---

## 📊 **구현 순서 및 의존성**

```
A1 → A2 → A3 → A4 → B1 → B2 → B3 → C1 → C2 → D1 → D2 → E1 → E2 → E3 → E4 → E5
│     │     │     │     │     │     │     │     │     │     │     │     │     │     │     └─ 최종 통합
│     │     │     │     │     │     │     │     │     │     │     │     │     │     └─ 문서화
│     │     │     │     │     │     │     │     │     │     │     │     │     └─ 스크립트 업데이트
│     │     │     │     │     │     │     │     │     │     │     │     └─ 헬퍼 함수 통합
│     │     │     │     │     │     │     │     │     │     │     └─ 테스트 등록
│     │     │     │     │     │     │     │     │     │     └─ 성능 테스트
│     │     │     │     │     │     │     │     │     └─ 네트워크 테스트
│     │     │     │     │     │     │     │     └─ 버전 호환성
│     │     │     │     │     │     │     └─ macOS 통합
│     │     │     │     │     │     └─ 롤백 테스트
│     │     │     │     │     └─ build-switch 통합
│     │     │     │     └─ 충돌 관리
│     │     │     └─ 기존 테스트 확장
│     │     └─ Casks 관리
│     └─ Homebrew 핵심 기능
└─ 테스트 헬퍼 함수
```

각 단계는 이전 단계의 완료를 전제로 하며, 점진적으로 복잡도가 증가하는 구조로 설계되어 있습니다.
