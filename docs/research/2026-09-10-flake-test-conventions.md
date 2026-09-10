# flake 테스트 관례: check 카디널리티·eval 비용·테스트 프레임워크

- 이슈: [#1447](https://github.com/baleen37/dotfiles/issues/1447) (부모 [#1443](https://github.com/baleen37/dotfiles/issues/1443))
- 작성일: 2026-09-10
- 검증 환경: Determinate Nix 3.13.2 (= upstream Nix 2.32.4), macOS aarch64, 워크트리 `origin/main` (08421f59), 웜 스토어
- 표기: **[검증]** = 1차 출처(매뉴얼·소스·리포 파일)에서 직접 읽음 / **[실측]** = 이 리포에서 직접 측정 / **[추론]** = 검증된 사실에서 유도

## 질문

우리 리포는 `checks` 146개이고, 이름만 eval하는 데 2분52초가 걸린다고 측정됐다. 커뮤니티의 flake(-parts) 기반 설정 리포가 테스트를 어떻게 구성하고 eval 비용을 어떻게 다루는지 1차 출처로 정리한다.

1. `checks` 하나당 고정 비용의 실체. 각 check가 별 derivation이면 무엇이 반복되는가. 146개를 소수 aggregate로 묶으면 원리상 무엇이 줄어드나.
2. 순수 Nix 단언 도구 비교: `lib.runTests`/`lib.debug`, `nix-unit`, `namaka`, `nixt`. configuration 값 검사 방식과 derivation 생성 여부.
3. 여러 check가 `darwinConfigurations.<host>.config`를 각각 참조할 때 flake eval cache의 공유 단위.
4. flake 안에서 `import <nixpkgs>`의 문제와 flake-parts `perSystem` `pkgs`를 tests에 넘기는 관례.
5. 소스 텍스트 `builtins.readFile` + `hasInfix` 단언에 대한 커뮤니티 입장.

## 결론 요약

1. check 1개당 반복되는 고정 비용은 `checkDerivation` 호출 1회(= derivation 인스턴스화: 해시 + `.drv` 스토어 쓰기)다. 우리 리포의 assertion 단위 derivation은 aggregate 아래에도 의존성으로 남으므로, 146개를 묶어도 `.drv` 개수는 거의 그대로다. [검증][실측]
2. 실측된 비용의 대부분은 check 개수가 아니라 (a) 이름 평가 시점에 조건이 강제되는 attrset 형태 테스트 16개, (b) 그 조건이 호스트 클로저를 인스턴스화하는 것(이름만 뽑는데 `.drv` 22,855개), (c) `import inputs.nixpkgs` 인스턴스 중복이다. [실측]
3. 이 환경에서 이름 eval은 7.5초, `nix flake check --no-build`(로컬 시스템)는 18초였다. 티켓의 2분52초는 재현되지 않았다(조건 차이 미확인). [실측]
4. eval cache의 단위는 flake output attribute path의 리프(문자열·bool·int·attr 이름 목록)다. `config.*` 중간값은 저장되지 않고, 소스가 한 글자라도 바뀌면 fingerprint가 바뀌어 새 DB가 된다. `nix flake check`는 eval cache를 아예 쓰지 않는다(소스에 FIXME). `nix eval`도 항상 강제 평가한다. `nix build`의 커서 경로만 이득을 본다(6.25초 → 0.32초). [검증][실측]
5. 한 프로세스 안에서는 thunk 메모이제이션으로 `darwinConfigurations.<host>.config`가 몇 개 check에서 참조되든 1회 평가된다. 프로세스를 나누면 매번 재평가한다. [검증]
6. 도구: `lib.runTests`·`nix-unit`·`namaka`·`nixt`는 모두 derivation을 만들지 않는 eval-only 도구다. nix-unit의 flake-parts 모듈은 시스템당 derivation 1개(`checks.nix-unit`)로 감싼다. `nixt`는 2024-10 이후 커밋이 없다. [검증]
7. 조사한 설정 리포(Misterio77·mitchellh·srid)는 `checks`를 정의하지 않고, 호스트 평가는 `nix eval ...toplevel.drvPath`·Hydra·omnix로 한다. ryan4yin만 `lib.runTests` 기반 eval 테스트 20개를 시스템당 check 2개(bool + pre-commit)로 노출한다. [검증]
8. `import <nixpkgs>`는 pure-eval에서 에러다. flake-parts는 `perSystem`의 `pkgs`(기본 `inputs.nixpkgs.legacyPackages.${system}`)와 `_module.args.pkgs`·`withSystem`을 제공하고, 인스턴스 1회화에 대한 명시 문구는 없다. [검증]
9. `readFile` + `hasInfix` 소스 텍스트 단언에 대한 1차 출처 논의는 발견하지 못했다. ryan4yin은 생성 산출물(conf, kdl)에만 쓰고 `.nix` 소스에는 쓰지 않는다. [검증]

## 상세

### 1. check 하나당 고정 비용

**`nix flake check`가 하는 일** [검증]

- 매뉴얼: "verifies that the flake ... can be evaluated successfully ..., and that the derivations specified by the flake's `checks` output can be built successfully". `checks.<system>.<name>`은 "must be derivations" 목록에 있다. — https://nix.dev/manual/nix/2.32/command-ref/new-cli/nix3-flake-check
- 소스(`src/nix/flake.cc`, 2.32.4): `checks`를 `forceAttrs`한 뒤 시스템·이름마다 `checkDerivation(...)`을 호출한다. `checkDerivation`은 `getDerivation` + `queryDrvPath()`로 derivation을 인스턴스화한다. 로컬 시스템 것만 `drvPaths`에 넣어 빌드한다. — https://github.com/NixOS/nix/blob/2.32.4/src/nix/flake.cc
- `--no-build`는 `settings.readOnlyMode = true`와 IFD 비활성화를 함께 켠다(`.drv`를 쓰지 않음). `--all-systems`가 없으면 다른 시스템은 평가조차 하지 않고 "The check omitted these incompatible systems" 경고만 낸다. — 같은 파일
- 빌드 단계는 `store->queryMissing`으로 이미 substitute 가능한 출력은 건너뛴다("`nix flake check` only needs to verify buildability"). — 같은 파일
- `nix flake check`는 eval cache를 쓰지 않는다. 소스 주석 `// FIXME: rewrite to use EvalCache.` — 같은 파일

**derivation 1개당 반복되는 것** [검증]

- `derivationStrict`(`src/libexpr/primops.cc`)는 매 호출마다 `hashDerivationModulo` → `writeDerivation(*state.store, drv, ...)`으로 `.drv`를 스토어에 쓰고, 다시 `hashDerivationModulo`를 `drvHashes`에 넣는다. read-only 모드에서는 쓰기만 생략된다. — https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/primops.cc
- 프로세스 간 재사용은 스토어에 같은 `.drv`가 이미 있는 경우의 쓰기 단축뿐이다. 직렬화·해시는 매번 다시 한다. [추론]
- 프로세스 안에서는 `forceValue`가 thunk를 blackhole로 바꾼 뒤 결과로 덮어쓴다. 즉 같은 값을 여러 attribute가 참조해도 1회만 평가된다. — https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/include/nix/expr/eval-inline.hh (매뉴얼은 "lazy: Values are only computed when they are needed"까지만 말한다 — https://nix.dev/manual/nix/2.32/language/index)

**우리 리포 실측** [실측] (모두 `--option eval-cache false`, 웜 스토어)

| 대상 | wall | user CPU | thunks | 인스턴스화된 `.drv` 수 |
| --- | --- | --- | --- | --- |
| E. `import nixpkgs` 1회 + `runCommand` 1개 | 0.81s | 0.28s | 0.36M | — |
| D. `darwinConfigurations.macbook-pro.system.drvPath` | 7.07s | 3.32s | 6.5M | 14,662 |
| A. `checks.aarch64-darwin` 이름만(`attrNames`) | 7.45s | 4.77s | — | 22,855 |
| B. check 1개(`unit-cache-config.drvPath`) | 7.05s | 5.31s | 12.8M | — |
| G4. `all-assertions.drvPath` | — | — | — | 35,469 |
| C. 146개 전부 `drvPath` | 41.65s | 15.23s | 44.4M | 46,727 |
| F. 같은 것, `--read-only` | 14.52s | 11.19s | — | (쓰기 없음) |
| Q. `nix flake check --no-build` (로컬 시스템) | 18.10s | 14.52s | — | (쓰기 없음) |
| H. `all-assertions` 클로저 안의 `test-*` `.drv` | — | — | — | 683 |

읽는 법:

- check 1개(B)가 이름 전체(A)와 같은 비용이다. `tests/default.nix`가 60개 파일을 모두 `tryEval (import ...)`하고 `flatten`에서 `isDerivation`으로 값을 강제하므로, 어느 check를 고르든 discovery 전체가 선행된다. `nix build .#checks.<s>.<one>`에도 같은 비용이 붙는다. [실측][추론]
- 이름만 뽑는데 `.drv` 22,855개가 인스턴스화됐고, 그 안에 `darwin-system-26.11`, `home-manager-generation`, `activation-jito.hello`가 있다. `testSuite`를 쓰지 않는 attrset 형태 파일 16개(`darwin-activation-test.nix` 등)는 `flatten`이 각 attribute를 `isDerivation`으로 강제할 때 `assertTest`의 `if condition`이 평가된다. `activation.script.text`처럼 스토어 경로가 보간된 문자열을 조건에 쓰면 해당 클로저 전체가 인스턴스화된다. `testSuite` 안의 assertion은 buildCommand 문자열 안에 있어 suite의 `drvPath`를 강제할 때까지 지연된다. [실측][추론]
- 146개 전부의 `drvPath`(C)는 wall 41.6초, `--read-only`(F)면 14.5초다. 차이 약 27초가 `.drv` 46,727개를 데몬에 쓰는 비용이다. 그중 테스트 자체의 `.drv`는 683개(1.5%)고 나머지는 호스트·home-manager 클로저다. [실측]
- `nix flake check --no-build --all-systems`는 이 환경에서 34초 만에 `path '/nix/store/...-baleen-toolkit-gc-runtime.drv' is not valid`로 실패했다. read-only 모드에서 `.drv`를 쓰지 않는데 그 경로를 요구하는 check가 Linux 시스템 쪽에 있다는 뜻이다. 원인 파일은 특정하지 않았다. [실측, 원인 미확인]
- 티켓의 "이름만 2분52초"는 재현되지 않았다(7.45초). 스토어에 `.drv`가 없는 콜드 상태에서는 22,855개 쓰기가 붙으므로 크게 느려질 수 있으나, 측정 조건을 확인하지 못했다. [추론]

**146개를 소수 aggregate로 묶으면 줄어드는 것(원리)** [추론, 위 검증 사실에서 유도]

- 줄어드는 것: `nix flake check`의 `checkDerivation` 호출 수(146 → N), `checks` attrset을 만드는 `flatten`/`concatMapAttrs` 오버헤드, 출력 노이즈.
- 줄어들지 않는 것: assertion derivation 683개는 `testSuite`/`all-assertions`가 `cat ${t}`로 의존하므로 aggregate 아래에서도 전부 인스턴스화·빌드된다. 호스트 클로저 인스턴스화(수만 개)는 어떤 조건이 스토어 경로 문자열을 강제하는지에 달려 있고 check 개수와 무관하다. 각 `.drv`가 실제 빌드되는 비용(runCommand 683회 샌드박스 기동)도 그대로다.
- 즉 카디널리티 축소만으로는 eval 시간이 유의미하게 줄지 않는다. 비용은 "assertion을 derivation으로 표현하는 것" 자체와 "조건이 클로저를 강제하는 것"에서 나온다.

### 2. 순수 Nix 단언 도구 비교

| 도구 | 선언 | config 값 검사 | derivation 생성 | 실패 표출 | flake `checks` 연동 | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| `lib.debug.runTests` | `testX = { expr; expected; }` (이름이 `test`로 시작하는 attribute만 실행) | `expr`가 임의 Nix 값이므로 `self.nixosConfigurations.x.config.foo` 가능 [추론] | 없음. 실패 목록 `[ {name; expected; result;} ]` 반환 | 빈 리스트 = 통과. `throwTestFailures`는 trace 출력 후 throw | 내장 없음. nixpkgs는 `runCommand` 안에서 `nix-instantiate --eval --strict ... == '[ ]'` | nixpkgs lib 일부, 활발 |
| `nix-unit` | runTests 호환 `{ expr; expected; }` + `expectedError.type/msg` | 동일. `--flake .#tests`로 flake output 참조 | 없음. C++ 바이너리가 Nix evaluator API로 테스트별 개별 실행("catch test failures individually, even if ... evaluation error") | ✅/❌/☢️ + difftastic diff, 비영 종료 | flake-parts 모듈이 **시스템당 1개** `checks.nix-unit` = `runCommand`에서 `nix-unit --flake ${self}#tests.systems.${system}` (입력은 `nix-unit.inputs`로 `--override-input`) | 2026-07 커밋, nixpkgs lib 테스트도 사용 |
| `namaka` | `tests/<name>/expr.nix` (+ `format.nix`), `namaka.lib.load { src; inputs; }` | `expr.nix`가 임의 값 [추론] | 없음. `load`는 실패 시 `throw`, 성공 시 `{ }` | `throw "the following tests failed: ..."` + `trace "namaka=<json>"`; CLI가 `nix flake check`/`nix eval`을 감싸 스냅샷 `_snapshots/` 갱신·리뷰 | 템플릿은 `checks = namaka.lib.load {...}` → 성공 시 `checks = { }` (derivation 없음), 실패 시 평가 에러 | 2026-08 커밋, "Breaking changes can happen in main branch at any time" |
| `nixt` | `describe "suite" [ (it "case" <bool>) ]` / `__nixt = nixt.lib.grow {...}` | bool 식이므로 `cfg.foo == "bar"` 형태 [추론] | 없음. TypeScript CLI가 `nix eval --json`을 호출 | 트리 출력 `✗ N cases failed.` | 문서화된 연동 없음 | 마지막 커밋 2024-10-18 |
| `pkgs.testers.*` / `runCommand` 단언 (우리 방식) | derivation 빌드 성공 = 통과 | 조건을 Nix에서 계산해 빌드 스크립트에 박음 | **있음**(assertion마다 1개) | 빌드 실패 로그 | 그대로 `checks` | nixpkgs 일부 |
| `nmt` (home-manager) | 모듈 평가 후 생성 파일 비교 | 모듈 시스템 결과물 | 있음(테스트마다 `runCommandLocal`, `linkFarm`으로 집계) | 빌드 실패 | 자체 `build.all` | v0.5.1, 2024-01 |

출처:

- runTests: https://github.com/NixOS/nixpkgs/blob/master/lib/debug.nix · nixpkgs가 돌리는 방식 https://github.com/NixOS/nixpkgs/blob/master/lib/tests/test-with-nix.nix (`nix-instantiate --eval --strict lib/tests/misc.nix ... == '[ ]'`) · https://github.com/NixOS/nixpkgs/blob/master/lib/tests/release.nix · misc.nix 머리말 "error checking is limited to what `builtins.tryEval` can detect" https://github.com/NixOS/nixpkgs/blob/master/lib/tests/misc.nix
- nix-unit: README 비교표(eval 실패 테스트는 nix-unit만 가능, 스냅샷은 namaka만) https://github.com/nix-community/nix-unit · flake-parts 모듈 https://github.com/nix-community/nix-unit/blob/main/lib/modules/flake/system.nix · 문서 "The module then takes care of setting up a `checks` derivation for you." https://github.com/nix-community/nix-unit/blob/main/doc/src/examples/flake-parts.md · derivation 직접 비교는 stack overflow, `drvPath` 문자열로 비교할 것 https://github.com/nix-community/nix-unit/blob/main/doc/src/FAQ.md · nixpkgs 사용 예 https://github.com/NixOS/nixpkgs/blob/master/lib/tests/nix-unit.nix
- namaka: https://github.com/nix-community/namaka · https://github.com/nix-community/namaka/blob/main/nix/load.nix · https://github.com/nix-community/namaka/blob/main/templates/default/flake.nix
- nixt: https://github.com/nix-community/nixt · https://github.com/nix-community/nixt/blob/master/src/components/nix/NixService.ts
- testers: https://github.com/NixOS/nixpkgs/blob/master/doc/build-helpers/testers.chapter.md (`testEqualContents`, `testEqualDerivation`, `testBuildFailure`, `runNixOSTest`, `nixosTest` 등)
- nmt: https://git.sr.ht/~rycee/nmt · https://github.com/nix-community/home-manager/blob/master/tests/default.nix

공통점: 네 eval-only 도구 모두 "configuration 값을 어떻게 검사하나"에 대한 답은 같다. `expr`(또는 bool 식)에 `self.<class>Configurations.<host>.config.<opt>`를 그대로 쓴다. 어느 도구도 문서에 NixOS/darwin config 예제를 두지 않았다(모두 [추론]). nix-unit을 `nix flake check` 안에서 돌리면 샌드박스라서 config가 건드리는 모든 input을 `nix-unit.inputs`에 적어야 한다 [검증].

### 3. flake eval cache의 공유 단위

**저장 위치·키·무효화** [검증]

- `~/.cache/nix/eval-cache-v6/<fingerprint>.sqlite`. 테이블은 `Attributes(parent, name, type, value, context)` 하나다. — https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/eval-cache.cc, 로컬 DB `.schema`로 확인
- fingerprint = 최상위 input의 fingerprint + subdir + lock 파일 전문 + revCount/lastModified의 SHA256. git input은 rev, dirty 트리면 변경 파일 전체 해시가 들어간다. 커밋이나 파일 한 줄 수정마다 새 빈 DB가 된다. — https://github.com/NixOS/nix/blob/2.32.4/src/libflake/flake.cc (`LockedFlake::getFingerprint`), https://github.com/NixOS/nix/blob/2.32.4/src/libfetchers/git.cc
- 매뉴얼 `eval-cache`: "Certain commands won't have to evaluate when invoked for the second time with a particular version of a flake. **Intermediate results are not cached.**" — https://nix.dev/manual/nix/2.32/command-ref/conf-file#conf-eval-cache
- 캐시는 `pure-eval`일 때만 열린다(`--impure`, `--expr`, `--file`은 제외). — https://github.com/NixOS/nix/blob/2.32.4/src/libcmd/installables.cc

**저장 단위와 타입** [검증]

- `AttrType { Placeholder, FullAttrs, String, Missing, Misc, Failed, Bool, ListOfStrings, Int }`. attrset은 attribute 이름 목록만(`FullAttrs`), 문자열·bool·int·문자열 리스트는 값, 함수·기타 리스트·float는 `Misc`(캐시 불가). derivation은 `type = "derivation"`과 `drvPath`/`outPath` 문자열 리프로 저장되고, `.drv`가 GC됐으면 재평가한다. — https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/include/nix/expr/eval-cache.hh, eval-cache.cc `AttrCursor::forceValue` (`else if (v.type() == nAttrs) ; // FIXME: do something?`)
- `AttrCursor::forceValue()`는 캐시 여부와 무관하게 `getValue()`로 **항상 평가**한 뒤 결과를 저장만 한다. 캐시에서 읽어 평가를 생략하는 경로는 `getAttrs`/`getString(WithContext)`/`isDerivation`/`forceDerivation`이다. `nix eval`은 `InstallableFlake::toValue` → `forceValue()`를 쓰고, `nix build`는 `toDerivedPaths` → `isDerivation()` + `forceDerivation()`을 쓴다. — eval-cache.cc 392행 이하, https://github.com/NixOS/nix/blob/2.32.4/src/libcmd/installable-flake.cc 79·157행
- `nix eval --apply`의 결과는 커서를 거치지 않는 일반 값이라 저장되지 않는다. — https://github.com/NixOS/nix/blob/2.32.4/src/nix/eval.cc [검증 코드, "저장 안 됨"은 추론]

**우리 리포 실측** [실측]

| 명령 | 1회 | 2회(캐시 있음) |
| --- | --- | --- |
| `nix eval .#checks.aarch64-darwin.unit-cache-config.drvPath` | 7.95s | 6.61s |
| `nix eval .#checks.aarch64-darwin.all-assertions.drvPath` (이미 DB에 있음) | — | 11.64s |
| `nix build --dry-run .#checks.aarch64-darwin.unit-cache-config` | 6.25s | **0.32s** |

캐시 DB 덤프(43행)에는 `checks.aarch64-darwin.{all-assertions,unit-cache-config,unit-darwin}.drvPath`, `darwinConfigurations.macbook-pro.system.outPath`, `devShells...`, `formatter...`만 있다. `darwinConfigurations.macbook-pro.config`는 `Placeholder`(type 0) 한 행이고 그 아래 값은 없다.

**질문에 대한 답** [추론, 위에서 유도]

- 여러 check가 `darwinConfigurations.<host>.config`를 참조할 때 공유되는 것은 **같은 프로세스 안의 thunk**뿐이다(1절). eval cache는 `checks.<system>.<name>.drvPath` 같은 output 리프만 저장하고 `config.*` 중간값은 저장하지 않는다.
- 그 리프 캐시도 `nix flake check`(FIXME로 미사용)와 `nix eval`(항상 forceValue)에는 효과가 없고, 소스가 바뀌면 사라진다. 개발 중 반복 실행에는 사실상 도움이 되지 않는다. 같은 트리에서 `nix build .#checks.<s>.<one>`을 반복할 때만 빠르다.

### 4. `import <nixpkgs>`와 flake-parts `perSystem` `pkgs`

- `nix` CLI는 `main.cc`에서 `evalSettings.pureEval = true`를 강제한다. pure-eval에서는 `builtins.nixPath`가 비고 `<nixpkgs>` 조회는 `cannot look up '<nixpkgs>' in pure evaluation mode (use '--impure' to override)`로 실패한다. — https://github.com/NixOS/nix/blob/2.32.4/src/nix/main.cc, https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/eval.cc, https://nix.dev/manual/nix/2.32/command-ref/conf-file#conf-pure-eval, https://nix.dev/manual/nix/2.32/language/constructs/lookup-path [검증]
- `import inputs.nixpkgs { inherit system; }`(pure)의 비용: 호출 지점이 다르면 각각 새 fixpoint를 만든다. 공식 문구는 overlays 장의 "`pkgs.extend`/`appendOverlays` ... recompute the Nixpkgs fixpoint, which is somewhat expensive to do"까지다. — https://nixos.org/manual/nixpkgs/stable/#chap-overlays [검증] · 호출 지점별 재평가는 thunk 의미론에서 유도 [추론] · 실측: 인스턴스 1개 + runCommand 1개 = 0.27s CPU, thunk 36만 개(표 E) [실측]
- 우리 리포의 인스턴스: `flake-modules/args.nix`(perSystem pkgs), `tests/default.nix`(별개), `tests/integration/machine-builds-test.nix`, `tests/integration/home-manager-test.nix`, `tests/unit/direnv-overlay-test.nix`(overlay 적용)이 각각 `import inputs.nixpkgs`를 한다. 그 외 16개 파일의 `pkgs ? import inputs.nixpkgs {...}` 기본 인자는 `tests/default.nix`가 `pkgs`를 넘기므로 실행되지 않는다. 호스트 5개는 모듈 시스템 안에서 각자 인스턴스를 만든다. [실측: `rg 'import inputs.nixpkgs'`]
- flake-parts 문서 [검증]:
  - `perSystem`: "A function from system to flake-like attributes omitting the `<system>` attribute." — https://flake.parts/options/flake-parts.html#opt-perSystem
  - `pkgs` 인자: "Default: `inputs.nixpkgs.legacyPackages.${system}`. Set via `config._module.args.pkgs`." · `withSystem`: "Enter the scope of a system." (예: `flake.nixosConfigurations.foo = withSystem "x86_64-linux" (ctx@{ config, inputs', ... }: ...)`) — https://flake.parts/module-arguments.html
  - overlays 페이지: "Flake parts does not yet come with an endorsed module that initializes the `pkgs` argument." 뒤에 `perSystem = { system, ... }: { _module.args.pkgs = import inputs.nixpkgs { inherit system; overlays = [...]; config = { }; }; }` 레시피 — https://flake.parts/overlays.html
  - `perSystem.checks`: "Derivations to be built by nix flake check. Type: lazy attribute set of package." — https://flake.parts/options/flake-parts.html#opt-perSystem.checks
  - 세 페이지 어디에도 "nixpkgs를 한 번만 인스턴스화하라"는 문구는 없다.
- 관례(리포) [검증]: srid는 `_module.args.pkgs = import inputs.nixpkgs {...}` 1회로 통일하고 나머지는 `perSystem { pkgs }`를 받는다 — https://github.com/srid/nixos-config/blob/master/flake.nix. Misterio77는 flake-parts 없이 `pkgsFor = lib.genAttrs (import systems) (system: import nixpkgs {...})`로 시스템당 1회 — https://github.com/Misterio77/nix-config/blob/main/flake.nix. nix-unit flake-parts 모듈은 `perSystem { pkgs }`를 그대로 받아 `pkgs.runCommand`를 만든다 — https://github.com/nix-community/nix-unit/blob/main/lib/modules/flake/system.nix. 우리 `flake-modules/home.nix`도 `withSystem system ({ pkgs, ... }: ...)`로 같은 형태다.

### 5. 소스 텍스트 `readFile` + `hasInfix` 단언

- discourse.nixos.org 검색과 웹 검색에서 이 패턴을 권고하거나 반대하는 1차 논의를 찾지 못했다. [검증: 부재]
- GitHub 코드 검색으로는 `tests/` 아래 `builtins.readFile` + `hasInfix` 조합이 545건 있다(우리 `tests/unit/cache-config-test.nix`, `ipetkov/crane checks/default.nix` 포함). 존재하지만 어느 것도 관례 문서는 아니다. [검증]
- ryan4yin은 `builtins.readFile hm.xdg.configFile."hypr/hypridle.conf".source`와 `../../hosts/idols-ai/niri-hardware.kdl`처럼 **생성 산출물·데이터 파일**에 쓰고, `.nix` 소스에는 쓰지 않는다. — https://github.com/ryan4yin/nix-config/blob/main/outputs/aarch64-linux/tests/home-manager/expr.nix, https://github.com/ryan4yin/nix-config/blob/main/outputs/x86_64-linux/tests/idols-ai-gpu/expr.nix [검증]
- 우리 리포: `readFile`을 쓰는 테스트 파일 14개, `hasInfix` 250회. 대상은 `.nix` 소스(`flake-modules/home.nix`, `users/shared/darwin/scripts.nix`)와 비-Nix 파일(`Makefile`, `ci.yml`, `.envrc`)이 섞여 있다. [실측]
- 대안으로 관찰되는 형태: `.nix` 소스 문자열 대신 평가 결과(`config.<opt>`, 생성 파일 `.source`)를 검사한다(ryan4yin, nmt, home-manager). 소스 텍스트 검사는 리팩터링(변수명·줄바꿈)에 깨지고 평가 결과 검사는 의미 변경에 깨진다는 차이가 있다. [추론]

### 6. 설정 리포의 tests/checks 구성

| 리포 | `checks` | 종류·개수 | pkgs 전달 | config 값 단언 | 소스 텍스트 단언 | 호스트 평가 보장 |
| --- | --- | --- | --- | --- | --- | --- |
| Misterio77/nix-config | 없음 | `hydraJobs.hosts = mapAttrs (_: cfg: cfg.config.system.build.toplevel)` | `pkgsFor` 시스템당 1회 | 없음 | 없음 | 자체 Hydra가 모든 호스트 빌드 |
| mitchellh/nixos-config | 없음 | — | `lib/mksystem.nix` | 없음 | 없음 | Makefile `check`: `nix flake check --all-systems --no-build` + 호스트별 `nix eval --raw '.#...toplevel.drvPath'` 4줄 |
| srid/nixos-config | 없음 | — | flake-parts `_module.args.pkgs` 1회 | 없음 | 없음 | `nix run nixpkgs#omnix ci`(packages·checks·devShells·nixosConfigurations·darwinConfigurations·homeConfigurations 빌드) |
| ryan4yin/nix-config | 시스템당 2개 | `eval-tests = evalTests == { }`(bool, derivation 아님) + `pre-commit-check`; 테스트 20개(haumea `loadEvalTests` → `lib.runTests`) | `nixpkgs.legacyPackages.${system}` + 다수 `import inputs.nixpkgs-*` | 있음(`config.networking.hostName`, `security.apparmor.enable`, `home.homeDirectory` 등) | 생성 산출물만 | CI는 `nix eval .#evalTests`만. 워크플로 주석에 `# stack overflow... # nix eval .#checks` |
| nix-community/disko | 있음 | `tests/*.nix` 파일마다 VM 테스트 1개(x86_64만) + treefmt·doc 등 4개 | `nixpkgs.legacyPackages.${system}` | 없음 | 없음 | VM 테스트 |
| nix-community/nixos-anywhere | 있음 | packages·devShells 재노출 + VM 테스트 10개 | `legacyPackages` | 없음 | 없음 | VM 테스트 |
| hercules-ci/flake-parts (dev) | 있음 | `checks.nix-unit` 1개 + `checks.perSystem-memoize` 1개 | perSystem | nix-unit | 없음 | — |
| nixops4/nixops4 (dev) | 있음 | `checks.nix-unit` 1개. 주석 "Run with either: `nix-unit --flake .#tests.systems.<system>` or, slower: `nix build .#checks.<system>.nix-unit`" | perSystem | nix-unit | 없음 | — |

출처: https://github.com/Misterio77/nix-config/blob/main/flake.nix · https://github.com/Misterio77/nix-config/blob/main/hydra.nix · https://github.com/mitchellh/nixos-config/blob/main/Makefile · https://github.com/srid/nixos-config/blob/master/README.md · https://omnix.page/om/ci.html · https://github.com/ryan4yin/nix-config/blob/main/outputs/default.nix · https://github.com/ryan4yin/nix-config/blob/main/.github/workflows/flake_evaltests.yml · https://github.com/nix-community/haumea/blob/main/src/loadEvalTests.nix · https://github.com/nix-community/disko/blob/master/flake.nix · https://github.com/nix-community/nixos-anywhere/blob/main/flake.nix · https://github.com/hercules-ci/flake-parts/blob/main/dev/flake-module.nix · https://github.com/nixops4/nixops4/blob/main/dev/flake-module.nix

관찰: 개인 설정 리포에서 `checks`는 0~2개가 보통이고, "호스트가 평가되는가"는 toplevel `drvPath`를 eval하거나 CI가 toplevel을 빌드하는 것으로 확인한다. 값 단언이 있는 경우(ryan4yin, flake-parts, nixops4)는 eval-only 도구를 쓰고 derivation은 시스템당 0~1개다. check 개수에 대한 수치 권고는 어느 1차 출처에도 없다. eval 비용에 대한 커뮤니티 도구 문구: nix-eval-jobs "When evaluating NixOS machines, evaluation can take several minutes when run on a single core" — https://github.com/nix-community/nix-eval-jobs · nix-fast-build "rebuilding the already-compiled disko integration test suite demands 1:50 minutes ... only takes a 10 seconds with `nix-fast-build`"(병렬 eval) — https://github.com/Mic92/nix-fast-build [검증]

## 우리 리포에 대한 함의

판정 없이, 위 사실에서 따라오는 선택지만 적는다.

1. **카디널리티 축소는 비용의 주인이 아니다.** 146개를 aggregate 몇 개로 묶어도 assertion `.drv` 683개와 호스트 클로저 인스턴스화는 그대로다(1절). 절감이 나오는 지점은 (a) attrset 형태 파일 16개가 이름 평가 시점에 조건을 강제하는 구조, (b) 조건이 `activation.script.text`처럼 스토어 경로 보간 문자열을 요구해 클로저를 인스턴스화하는 것, (c) `tests/default.nix`·`machine-builds-test`·`home-manager-test`·`direnv-overlay-test`의 별도 `import inputs.nixpkgs`다.
2. **eval cache는 개발 루프에 기여하지 않는다.** `nix flake check`·`nix eval`은 캐시를 읽어 평가를 생략하지 않고, 소스 변경마다 DB가 새로 생긴다(3절). "여러 check가 config를 공유"하는 이득은 한 프로세스 안에서만 생기므로, 실행 단위를 한 프로세스(`nix flake check` 또는 `nix build .#checks.<s>.all-assertions`)로 유지하는 것이 그 공유를 살리는 길이다. check를 개별 `nix build`로 나눠 부르면 매번 discovery 전체 비용(약 7초)이 반복된다.
3. **eval-only 도구로 옮기면 `.drv` 683개와 runCommand 빌드 683회가 사라진다.** nix-unit(flake-parts 모듈, 시스템당 derivation 1개)과 `lib.runTests`(derivation 0개, `nix eval .#evalTests`) 두 경로가 있고, 각각 ryan4yin·flake-parts·nixops4에 선례가 있다. 단 nix-unit을 `nix flake check` 안에서 돌리면 config가 건드리는 모든 flake input을 `nix-unit.inputs`에 적어야 하고, 우리 리포의 "빌드가 곧 러너"라는 `tests/README.md` 계약과 `make test-build`가 바뀐다. `tests/README.md`가 경고하는 "`--no-build`는 단언을 실행하지 않는다" 문제는 eval-only 도구에서는 존재하지 않는다(평가가 곧 실행).
4. **`readFile` + `hasInfix`에 대한 커뮤니티 규범은 없다.** 선례는 생성 산출물 검사다(5절). 우리 `.nix` 소스 검사 14개 파일을 유지할지, `config.<opt>`·생성 파일 검사로 바꿀지는 리팩터링 내구성과 의미 검증 중 어느 쪽 실패를 잡고 싶은지의 문제다.
5. **`nix flake check --no-build --all-systems`가 이 환경에서 `... is not valid`로 실패한다**(1절). CI가 같은 명령을 쓰므로 조건 차이를 확인할 가치가 있다. 이 문서 범위 밖이라 원인은 추적하지 않았다.
6. 이번 실측과 티켓의 2분52초가 다르다. 콜드 스토어(`.drv` 부재)에서는 이름 평가에 `.drv` 22,855개 쓰기가 붙으므로 그 차이가 설명될 수 있으나 확인하지 못했다. 재측정 시 `--option eval-cache false`, `NIX_SHOW_STATS=1`, `--read-only` 유무를 함께 기록하면 비교가 된다.

## 출처 목록

Nix 매뉴얼(2.32)·소스(tag 2.32.4)

- https://nix.dev/manual/nix/2.32/command-ref/new-cli/nix3-flake-check
- https://nix.dev/manual/nix/2.32/command-ref/new-cli/nix3-flake
- https://nix.dev/manual/nix/2.32/command-ref/conf-file#conf-eval-cache
- https://nix.dev/manual/nix/2.32/command-ref/conf-file#conf-pure-eval
- https://nix.dev/manual/nix/2.32/command-ref/conf-file#conf-restrict-eval
- https://nix.dev/manual/nix/2.32/language/index
- https://nix.dev/manual/nix/2.32/language/constructs/lookup-path
- https://github.com/NixOS/nix/blob/2.32.4/src/nix/flake.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/nix/eval.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/nix/main.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/primops.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/eval.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/eval-cache.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/include/nix/expr/eval-cache.hh
- https://github.com/NixOS/nix/blob/2.32.4/src/libexpr/include/nix/expr/eval-inline.hh
- https://github.com/NixOS/nix/blob/2.32.4/src/libflake/flake.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libfetchers/git.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libcmd/installables.cc
- https://github.com/NixOS/nix/blob/2.32.4/src/libcmd/installable-flake.cc
- https://raw.githubusercontent.com/DeterminateSystems/nix-src/refs/tags/v3.13.2/.version (Determinate 3.13.2 = 2.32.4)

nixpkgs

- https://github.com/NixOS/nixpkgs/blob/master/lib/debug.nix
- https://github.com/NixOS/nixpkgs/blob/master/lib/tests/test-with-nix.nix
- https://github.com/NixOS/nixpkgs/blob/master/lib/tests/release.nix
- https://github.com/NixOS/nixpkgs/blob/master/lib/tests/misc.nix
- https://github.com/NixOS/nixpkgs/blob/master/lib/tests/nix-unit.nix
- https://github.com/NixOS/nixpkgs/blob/master/doc/build-helpers/testers.chapter.md
- https://nixos.org/manual/nixpkgs/stable/#chap-overlays

테스트 도구

- https://github.com/nix-community/nix-unit
- https://github.com/nix-community/nix-unit/blob/main/lib/modules/flake/system.nix
- https://github.com/nix-community/nix-unit/blob/main/lib/modules/flake/system-agnostic.nix
- https://github.com/nix-community/nix-unit/blob/main/lib/flake-checks/flake.nix
- https://github.com/nix-community/nix-unit/blob/main/doc/src/examples/flake-parts.md
- https://github.com/nix-community/nix-unit/blob/main/doc/src/FAQ.md
- https://github.com/nix-community/namaka
- https://github.com/nix-community/namaka/blob/main/nix/load.nix
- https://github.com/nix-community/namaka/blob/main/templates/default/flake.nix
- https://github.com/nix-community/nixt
- https://github.com/nix-community/nixt/blob/master/src/components/nix/NixService.ts
- https://github.com/nix-community/haumea/blob/main/src/loadEvalTests.nix
- https://github.com/nix-community/haumea/blob/main/docs/src/api/loadEvalTests.md
- https://git.sr.ht/~rycee/nmt
- https://github.com/nix-community/home-manager/blob/master/tests/default.nix
- https://github.com/nix-community/nix-eval-jobs
- https://github.com/Mic92/nix-fast-build

flake-parts

- https://flake.parts/options/flake-parts.html#opt-perSystem
- https://flake.parts/options/flake-parts.html#opt-perSystem.checks
- https://flake.parts/module-arguments.html
- https://flake.parts/overlays.html
- https://github.com/hercules-ci/flake-parts/blob/main/dev/flake-module.nix

설정 리포

- https://github.com/Misterio77/nix-config/blob/main/flake.nix
- https://github.com/Misterio77/nix-config/blob/main/hydra.nix
- https://github.com/Misterio77/nix-config/blob/main/.hydra.json
- https://github.com/mitchellh/nixos-config/blob/main/flake.nix
- https://github.com/mitchellh/nixos-config/blob/main/Makefile
- https://github.com/srid/nixos-config/blob/master/flake.nix
- https://github.com/srid/nixos-config/blob/master/README.md
- https://github.com/srid/nixos-unified/blob/master/nix/modules/flake-parts/autowire.nix
- https://omnix.page/om/ci.html
- https://github.com/ryan4yin/nix-config/blob/main/outputs/default.nix
- https://github.com/ryan4yin/nix-config/blob/main/outputs/x86_64-linux/default.nix
- https://github.com/ryan4yin/nix-config/blob/main/outputs/aarch64-linux/tests/hostname/expr.nix
- https://github.com/ryan4yin/nix-config/blob/main/outputs/aarch64-darwin/tests/home-manager/expr.nix
- https://github.com/ryan4yin/nix-config/blob/main/outputs/aarch64-linux/tests/home-manager/expr.nix
- https://github.com/ryan4yin/nix-config/blob/main/outputs/x86_64-linux/tests/idols-ai-gpu/expr.nix
- https://github.com/ryan4yin/nix-config/blob/main/.github/workflows/flake_evaltests.yml
- https://github.com/nix-community/disko/blob/master/flake.nix
- https://github.com/nix-community/disko/blob/master/tests/default.nix
- https://github.com/nix-community/nixos-anywhere/blob/main/flake.nix
- https://github.com/nixops4/nixops4/blob/main/dev/flake-module.nix

2차 출처(참고만)

- https://nixos-and-flakes.thiscute.world/nixpkgs/multiple-nixpkgs ("each import evaluates separately, creating a new nixpkgs instance each time")
- https://github.com/NixOS/nix/issues/6806 (`nix flake check`가 타 시스템까지 평가하던 이슈, 2023 수정)
