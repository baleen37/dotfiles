# tests/lib/ Inventory — 2026-05-25

> Sub-project 4 (tests-lib-consolidation) 작업을 위한 사실 조사.
> 모든 결정은 이 문서의 grep 실증 결과에 근거한다. 추측 삭제 금지.

## 파일 목록 (22개)

| 파일 | import 카운트 | export 핵심 함수 | 결정 | 비고 |
|---|---|---|---|---|
| assertions.nix | 2 | assertTestWithDetails (7-arg), assertFileContent | **보존** | `test-helpers-advanced.assertTestWithDetailsVerbose`의 re-export 래퍼. 서로 다른 두 파일의 re-export 역할 수행. `common-assertions.nix`와 내용 완전히 다름 |
| claude-test-helpers.nix | 1 | assertClaudeFileConfigured, assertClaudeDirRecursive 등 도메인 전용 | **보존** | 도메인 헬퍼 |
| common-assertions.nix | 5 | assertCondition, assertAttrExists, assertAttrPathExists, assertListContains, assertStringContains 등 25개+ | **보존** | assertions.nix와 완전히 다른 파일. 실제 assertion 라이브러리 본체. 5곳에서 직접 import |
| constants.nix | 2 | darwinWindowResizeTime, starshipCommandTimeout, tmuxHistoryLimit 등 | **보존** | 테스트 상수 |
| conventions.nix | 0 | (함수 없음 - 코드 주석/문서 파일) | **삭제 후보** | 전체가 주석으로 된 문서. `_: rec {}` 형태. 코드로서 아무 역할 없음 |
| darwin-test-helpers.nix | 2 | assertDarwinOptimizationsLevel1/2/3, assertDockOptimizations 등 | **보존** | 도메인 헬퍼 |
| e2e-helpers.nix | 0 | assertTest, assertFileExists, bootstrapWorkflow, vmCommandTest 등 | **보존** | import 0건이지만 e2e/helpers.nix와 이름·용도 유사해 혼동 가능. 아직 쓰임새 불분명이므로 보존 |
| git-test-helpers.nix | 1 | assertGitUserInfo, assertGitAliasesBulk 등 | **보존** | 도메인 헬퍼 |
| mock-config.nix | 4 | mkEmptyConfig, mkHomeConfig, mkGitConfig, mkVimConfig 등 | **보존** | 여러 테스트에서 사용 |
| patterns.nix | 2 | testHomeFileConfig, testPackagesInstalled, testProgramEnabled 등 | **보존** | 재사용 테스트 패턴 |
| performance-baselines.nix | 0 | systemBaselines, operationBaselines, regressionThresholds 등 | **삭제 후보** | import 0건. performance.nix 위에 있는 베이스라인 데이터. 단독으로 사용처 없음 |
| performance.nix | 2 | perf.time, perf.memory, perf.build, perf.regression 등 | **보존** | 성능 테스트 유틸 |
| platform-helpers.nix | 2 | isCurrentPlatform, mkPlatformTest, filterPlatformTests 등 | **보존** | 플랫폼 필터링 핵심 |
| plugin-test-helpers.nix | 2 | assertPluginByName, assertConfigPattern, mkPluginTester 등 | **보존** | 도메인 헬퍼 |
| property-test-helpers.nix | 0 | forAll, forAllCases, generateUsername, userConfigConsistencyProperty 등 | **삭제 후보** | import 0건. test-helpers-property.nix와 이름 유사하나 내용 완전히 다름 (더 크고 rich한 독립 라이브러리). test-helpers.nix가 내부적으로 import하지 않음 |
| starship-test-helpers.nix | 1 | assertStarshipEnabled, assertStarshipFormatHasModule 등 | **보존** | 도메인 헬퍼 |
| test-builders.nix | 6 | mkBasicTest, mkUserTest, mkDualMachineTest, mkCrossPlatformTest 등 | **보존** | NixOS 테스트 빌더 |
| test-helpers-advanced.nix | 0 (직접) | assertPerformance, assertFileContent, assertTestWithDetailsVerbose, assertGitUserInfo 등 | **보존** | test-helpers.nix가 내부적으로 import (`advancedHelpers`). 직접 외부 import는 0건이나 test-helpers.nix를 통해 간접 사용 |
| test-helpers-property.nix | 0 (직접) | propertyTest, multiParamPropertyTest, forAllCases | **보존** | test-helpers.nix가 내부적으로 import (`propertyHelpers`). 직접 외부 import는 0건이나 test-helpers.nix를 통해 간접 사용 |
| test-helpers.nix | 48 | assertTest, testSuite, mkTest, assertFileExists, assertHasAttr, assertContains 등 | **보존** | 핵심 헬퍼. 모든 테스트의 기반 |
| test-runner.nix | 1 | mkTestSuite | **보존** | 테스트 실행기 |
| fixtures/ | - | (디렉토리) | **보존** | 도메인 데이터 |

## 머지 페어 분석

| Pair | 분석 결과 | 결정 |
|---|---|---|
| assertions.nix ↔ common-assertions.nix | **완전히 다른 파일**. assertions.nix는 7-arg API re-export 래퍼 (15줄). common-assertions.nix는 독립 assertion 라이브러리 (525줄). 함수 이름 충돌 없음. 각자 다른 사용처 | **머지 스킵** — 각자 보존 |
| test-helpers.nix ↔ test-helpers-advanced.nix | **test-helpers.nix가 test-helpers-advanced.nix를 내부 import**함 (`advancedHelpers = import ./test-helpers-advanced.nix`). 이미 통합된 상태. 외부에서 직접 import하는 파일 없음 | **머지 스킵** — 현재 구조가 올바름 |
| test-helpers-property.nix ↔ property-test-helpers.nix | 두 파일 모두 외부 직접 import 0건. test-helpers.nix가 test-helpers-property.nix만 내부 import. property-test-helpers.nix는 완전히 별도의 독립 파일 (475줄, forAll 생성기 기반). | test-helpers-property.nix는 보존 (test-helpers.nix 의존). property-test-helpers.nix는 **삭제 후보** |

## 삭제 후보 (import 0건 + 실증 확인)

1. **conventions.nix** — 전체가 주석 문서. `_: rec {}` 반환. 코드로서 아무 역할 없음. import 0건 확인.
2. **performance-baselines.nix** — import 0건. performance.nix 위에 있는 베이스라인 데이터이지만 아무도 import하지 않음.
3. **property-test-helpers.nix** — import 0건. test-helpers.nix가 test-helpers-property.nix를 import하지 이것을 import하지 않음. 내용은 풍부하지만 사용처 없음.

> e2e-helpers.nix는 import 0건이지만 e2e 테스트의 의도된 헬퍼일 가능성이 있어 보존 결정.

## 사용처 표 (import count > 0인 헬퍼들)

| 헬퍼 | import 카운트 | 사용 파일 |
|---|---|---|
| test-helpers.nix | 48 | (거의 모든 테스트 파일) |
| test-builders.nix | 6 | (여러 통합/컨테이너 테스트) |
| common-assertions.nix | 5 | unit/darwin-test.nix, unit/property-based-git-config-test.nix, unit/lib-user-info-test.nix, integration/git-configuration-test.nix, integration/home-manager-test.nix |
| mock-config.nix | 4 | (여러 테스트) |
| assertions.nix | 2 | unit/assertions-test.nix, integration/home-manager/git-config-generation-test.nix |
| constants.nix | 2 | (여러 테스트) |
| darwin-test-helpers.nix | 2 | (darwin 테스트) |
| patterns.nix | 2 | (여러 테스트) |
| performance.nix | 2 | (성능 테스트) |
| platform-helpers.nix | 2 | (플랫폼 테스트) |
| plugin-test-helpers.nix | 2 | (플러그인 테스트) |
| claude-test-helpers.nix | 1 | unit/claude-test.nix |
| git-test-helpers.nix | 1 | (git 테스트) |
| starship-test-helpers.nix | 1 | (starship 테스트) |
| test-runner.nix | 1 | (테스트 러너 테스트) |

## 결론

- **머지 없음**: 3개 의심 페어 모두 머지 불필요 (이미 통합되어 있거나 완전히 다른 역할)
- **삭제 대상**: conventions.nix, performance-baselines.nix, property-test-helpers.nix (3개)
- **보존**: 나머지 19개
- **예상 결과**: 22 → 19개 (fixtures/ 디렉토리 제외)
