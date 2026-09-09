# Cachix·CI 캐시 베스트프랙티스: 무엇을 언제 push하고 설정은 어디 한 곳에 두나

- 티켓: [#1448](https://github.com/baleen37/dotfiles/issues/1448) (부모 [#1443](https://github.com/baleen37/dotfiles/issues/1443))
- 조사일: 2026-09-10
- 조사 범위: Cachix 공식 문서·cachix-action README, Nix 매뉴얼(nix.conf, flake), DeterminateSystems 공지·문서, nix-fast-build README, GitHub Actions 캐시·시크릿 문서. 로컬(Determinate Nix 3.13.2 / Nix 2.32.4, macOS)과 CI 실행 기록으로 직접 확인한 항목은 "실측"으로 표시했다.

## 질문

substituter 목록이 `flake.nix` nixConfig, `lib/cache-config.nix`, `ci.yml` NIX_CONFIG, `setup-nix/action.yml` extra-conf 네 곳에 중복되어 있고 awk 스크립트와 unit 테스트로 동기화를 방어한다. Cachix push는 main의 system closure만이고 devShell·checks는 올리지 않는다. 로컬 `make test-build`와 `nix develop`은 매번 재파생된다. 아래를 알아야 한다.

1. `nixConfig`의 실제 제약과, 그럼에도 한 곳만 정본으로 두는 관례
2. `cachix/cachix-action` vs `nix path-info -r | cachix push` vs `cachix watch-exec`, PR 빌드에서 push하는 관례와 신뢰 경계
3. devShells·checks·formatter를 push하는 것이 실제 로컬 히트로 이어지는 조건
4. `magic-nix-cache-action` 종료 여부와 FlakeHub Cache 현황(2026-09), `actions/cache`로 `~/.cache/nix`를 저장하는 현재 방식과의 비교
5. `nix-fast-build`가 우리 규모에 맞는지
6. Determinate Nix 로컬에서 flake nixConfig의 substituter가 신뢰되는 조건(#346 재발 방지)

## 결론 요약

1. `nixConfig`는 flake.nix 최상위 리터럴 attrset이어야 하고 `import` 불가가 맞다. 그러나 flake.nix 자체는 평범한 Nix 파일이라 `nix eval --json --file flake.nix nixConfig`로 그대로 뽑힌다(실측). 정본을 `flake.nix` nixConfig 한 곳으로 두고 `lib/cache-config.nix`·CI 설정은 여기서 파생시킬 수 있다.
2. `nixConfig`의 substituter는 클라이언트 측 설정이다. 로컬에서 실제로 쓰이려면 (a) 사용자가 `accept-flake-config` 또는 프롬프트/`trusted-settings.json`으로 수락하고 (b) 데몬 기준으로 `trusted-users`이거나 해당 URL이 `trusted-substituters`에 있어야 한다. (b)가 빠지면 #346의 "ignoring untrusted substituter"가 재발한다. 이 머신은 nix.custom.conf가 `trusted-users`에 사용자를 넣어 두 조건을 모두 만족한다(실측).
3. push 방식은 셋 다 공식 지원이다. cachix-action은 post-build-hook 데몬으로 "그 잡에서 새로 빌드된 모든 경로"를 올리고, `nix build --json | jq | cachix push`는 지정 closure만, `cachix watch-exec`은 명령 실행 중 생성된 경로를 올린다. PR에서 push하려면 write 토큰이 필요하고, fork PR에는 시크릿이 전달되지 않는다. 같은 리포 브랜치 PR은 시크릿에 접근하므로 push가 가능하지만, 그 경로가 "main에서 검증된 산출물"이 아니라는 신뢰 경계 문제가 생긴다.
4. 우리 캐시 실측: system closure는 Cachix에 있고(200), `unit-cache-config` 체크 출력과 devShell은 없다(404). macOS CI는 `make test-all`이 `nix flake check --no-build`라서 checks 산출물 자체를 빌드하지 않는다. 즉 checks를 push하려면 CI가 먼저 빌드해야 한다.
5. checks·devShell을 push해서 로컬 히트가 나려면 같은 `system`, 같은 `flake.lock`, 같은 소스 트리(derivation 해시 동일)여야 한다. checks는 `runCommand`류라 다운로드 이득은 작고, 로컬 `make test-build`는 dry-run만 1분 15초가 걸릴 만큼 평가(IFD 포함)가 지배한다(실측). 따라서 push만으로는 로컬 체감이 제한적이다.
6. magic-nix-cache-action은 2025-02-01 GitHub 캐시 v1 API 종료로 한 번 중단됐고 2025-06-13 리버스엔지니어링한 v2 API로 복구됐다. 공식 입장은 "언제든 깨질 수 있음, FlakeHub Cache 권장". FlakeHub Cache는 유료 플랜 전용이며 오픈소스는 메일로 무료 계정 요청. 우리 `actions/cache` 방식은 10 GB·7일 미접근 evict·브랜치 스코프 제약 아래 동작한다.
7. `nix-fast-build`는 checks 병렬 평가·빌드와 `--cachix-cache` 업로드를 한 명령으로 처리한다. 우리 checks는 130여 개 속성·699 derivation(aarch64-darwin 실측)이라 평가 병렬화 이득은 있을 수 있으나, IFD가 있는 평가에서 `nix-eval-jobs` 워커가 IFD를 빌드해야 하는 점은 별도 확인이 필요하다.

## 상세

### 1. `nixConfig` 제약과 단일 정본 관례

**확인된 사실**

- `nixConfig`는 "flake의 어떤 부분을 평가할 때든 설정될 nix.conf 옵션 집합"이다. `accept-flake-config`가 꺼져 있으면 `bash-prompt*`, `flake-registry`, `commit-lock-file-summary`만 확인 없이 적용되고 나머지는 프롬프트 또는 거부된다. [Nix manual, nix flake](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake.html)
- `accept-flake-config`: "flake의 Nix 설정을 프롬프트 없이 수락할지". 기본 `false`. [Nix manual, nix.conf](https://nix.dev/manual/nix/latest/command-ref/conf-file.html)
- 프롬프트에서 수락한 값은 `~/.local/share/nix/trusted-settings.json`에 저장되고 이후 "Using saved setting … from ~/.local/share/nix/trusted-settings.json"으로 재사용된다. 이 파일은 매뉴얼에 문서화되어 있지 않다(이슈 open). [NixOS/nix#9643](https://github.com/NixOS/nix/issues/9643) / 로컬 실측: 이 머신의 파일에 우리 substituters·trusted-public-keys가 저장되어 있음.
- `nix flake metadata --json`과 `builtins.getFlake`는 `nixConfig`를 노출하지 않는다(실측: metadata 키는 description·locks·revision 등만, getFlake attrNames에도 없음). 하지만 `nix eval --json --file flake.nix nixConfig`는 flake.nix를 일반 Nix 파일로 읽어 그대로 반환한다(실측, 아래 명령).

```sh
nix eval --json --file flake.nix nixConfig
# {"substituters":["https://baleen-nix.cachix.org",...],"trusted-public-keys":[...]}
```

**추론**

- 따라서 "정본 = flake.nix nixConfig, 파생 = 나머지"가 가능하다.
  - `lib/cache-config.nix`는 `(import ../flake.nix).nixConfig`로 대체 가능하다. flake.nix는 `inputs`·`outputs` 함수도 들고 있지만 `.nixConfig`만 꺼내면 평가되지 않는다(Nix는 lazy). 다만 `tests/unit/cache-config-test.nix`의 `flake-nix-uses-literal-nix-config` 단정은 반대 방향(flake.nix가 import하지 않을 것)만 요구하므로 충돌하지 않는다.
  - CI는 `NIX_CONFIG`를 정적 YAML에 쓰는 대신 스텝에서 `nix eval --json --file flake.nix nixConfig | jq -r 'to_entries[] | "\(.key) = \(.value | join(" "))"' >> $GITHUB_ENV`처럼 생성할 수 있다. 단, 첫 `nix` 호출 전(설치 직후) `extra-conf`에 넣어야 하는 값은 이 방식으로 만들 수 없으므로 `setup-nix/action.yml`의 extra-conf 한 곳은 남거나, `trusted-users = root *` + `--accept-flake-config`(이미 사용 중)로 대체된다. CI는 runner 사용자가 trusted이므로 nixConfig만으로 substituter가 실제 적용된다.
  - 시스템 nix.conf는 이미 activation이 쓴다. `lib/mksystem.nix`가 `cache-config.nix`를 `nix.settings`(NixOS)·`determinateNix.customSettings`(Darwin)로 흘려보내고, Darwin에서는 determinate 모듈이 `/etc/nix/nix.custom.conf`를 생성한다(실측: 파일 헤더 "generated by the determinate module for nix-darwin"). [Determinate docs, nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- 반대 방향(nixConfig를 다른 파일에서 import)은 flake 스키마상 불가하며 현재 테스트가 그 제약을 고정하고 있다. 정본을 한 곳으로 줄이는 방향은 "flake.nix → 나머지"만 가능하다.

### 2. push 방식 비교와 PR push의 신뢰 경계

**확인된 사실**

- cachix-action(v17): 기본 daemon 모드는 "Nix에 post-build hook을 등록해 새로 빌드된 store path를 빌드되는 즉시 push"한다. substitute된 경로는 hook을 타지 않는다. store-scan 모드는 파일시스템 차이를 봐서 substitute 경로까지 잡지만 multi-user store에는 부적합하다. 입력: `skipPush`, `pathsToPush`("비우면 모든 빌드 결과 push"), `pushFilter`(정규식 제외), `authToken`("어떤 캐시든 push하려면 필수"), `signingKey`. fork PR 관련: "Forked pull requests cannot access secrets, so they can only read from public caches." 권장 패턴 `skipPush: ${{ github.event_name == 'pull_request' }}`. [cachix-action README](https://github.com/cachix/cachix-action)
- 수동 push 레시피(공식): `nix build --no-link --print-out-paths | cachix push mycache`(런타임 closure), `nix flake archive --json | jq -r '.path,(.inputs|to_entries[].value.path)' | cachix push mycache`(flake inputs), `nix develop --profile dev-profile -c true && cachix push mycache dev-profile`(devShell), `cachix watch-exec mycache -- <cmd>`("명령 실행 중 생성된 모든 store path push"), `cachix watch-store`. [Cachix docs, Pushing](https://docs.cachix.org/pushing)
- 토큰: 개인 토큰(계정 전체)과 캐시별 토큰(특정 캐시 read/write)이 있다. [Cachix docs, Getting started](https://docs.cachix.org/getting-started)
- GitHub: "With the exception of `GITHUB_TOKEN`, secrets are not passed to the runner when a workflow is triggered from a forked repository." [GitHub docs, secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- Cachix GC: 저장 한도에 닿으면 "마지막 접근일(없으면 생성일) 기준으로 오래된 것부터" 삭제. 오픈소스 무료 5 GB. [Cachix docs, GC](https://docs.cachix.org/garbage-collection) / [Cachix pricing](https://www.cachix.org/pricing)

**추론**

- 우리 `ci.yml`의 `nix path-info -r "$OUT" | cachix push`는 "지정 closure만 push" 방식이고, main·tag에만 동작한다. 이는 cachix-action의 `skipPush`-on-PR 권장과 동일한 정책이다.
- PR에서 push할 때의 위험은 두 층이다. (1) fork PR: 시크릿이 없어 push 자체가 불가하므로 위험도 없다. (2) 같은 리포 브랜치 PR: write 토큰이 있으므로 push된다. 이 경우 리뷰 전 코드가 만든 산출물이 `baleen-nix`에 들어가고, 우리 nixConfig가 그 캐시를 신뢰하므로 이후 모든 머신이 그 경로를 substitute한다. 서명 키는 캐시 단위라 "main에서 나온 것"과 "PR에서 나온 것"을 구분하지 못한다. 단일 사용자 리포에서는 실질 위험이 낮지만, 이것이 cachix-action 문서가 PR push를 기본 권장하지 않는 이유와 같은 경계다.
- 5 GB 한도와 LRU GC를 고려하면 "무엇을 push하는가"보다 "무엇이 계속 접근되는가"가 유지 여부를 정한다. checks 출력처럼 다시 다운로드되지 않는 경로는 곧 evict 후보가 된다.

### 3. devShells·checks·formatter push가 로컬 히트로 이어지는 조건

**확인된 사실**

- 로컬 실측(aarch64-darwin, 이 worktree, 현재 flake.lock):
  - system closure `…-darwin-system-26.11.4cff07d`: Cachix narinfo HTTP 200 (있음)
  - `checks.aarch64-darwin.unit-cache-config` 출력: HTTP 404 (없음)
  - `devShells.aarch64-darwin.default` 출력 `…-nix-shell`: HTTP 404 (없음)
- `nix build .#devShells.aarch64-darwin.default --dry-run`: 빌드 대상은 `nix-shell.drv` 1개뿐. 패키지(deadnix·statix·bats 등)는 이미 로컬에 있거나 cache.nixos.org에서 온다. `formatter`: `treefmt.toml.drv`, `treefmt.drv` 2개.
- `nix build .#checks.aarch64-darwin.all-assertions --dry-run`: "699 derivations will be built", 명령 자체가 1분 15초 소요. dry-run 도중 `baleen-toolkit-gc-runtime`, `zsh-*-runtime` 등 4개 derivation이 실제로 빌드되고 `bash-interactive-dev`가 다운로드됐다. 즉 평가 단계에 IFD(import-from-derivation)가 있다.
- macOS CI의 `make test-all` → `make test` → `nix flake check --no-build`(Makefile 62~101행, CLAUDE.md도 명시). `make test-build`는 CI에서 호출되지 않는다. 최근 main 런(2026-09-09) Darwin 잡의 "Full test suite" 스텝은 20초.
- 리포 안에 `builtins.getEnv` 사용 없음(`tests/unit/evaluation-boundary-test.nix`가 금지 단정). `TEST_USER`는 컨테이너 테스트 셸 변수로만 쓰이고 Nix 평가에는 들어가지 않는다.

**추론**

- 캐시 히트의 조건은 store path 일치, 즉 같은 `system`·같은 `flake.lock`·같은 소스(derivation 입력 해시)다. 우리 flake는 `getEnv`가 없어 순수하므로 CI(macos-15, aarch64-darwin)와 로컬 M-시리즈 Mac은 같은 커밋에서 같은 경로를 만든다. 조건은 충족 가능하다.
- 그러나 이득의 크기가 다르다.
  - devShell: 빌드할 것이 `nix-shell.drv` 하나라 push해도 절약은 수 초 이하. `nix develop`이 느리게 느껴지는 원인은 평가이며 push로 해결되지 않는다. `nix develop --profile`로 GC root를 잡아두는 것이 문서화된 처방이다. [Cachix docs, Pushing](https://docs.cachix.org/pushing)
  - checks: 699개 derivation 대부분이 `touch $out` 수준이라 개별 빌드는 빠르고, 시간은 평가·IFD가 지배한다(dry-run 1분 15초). Cachix가 대체하는 것은 빌드 단계만이므로 `make test-build` 체감 개선은 제한적이다. 게다가 macOS CI는 이 산출물을 빌드하지 않으므로 push 대상이 아예 생성되지 않는다. push하려면 CI에 `make test-build`(또는 nix-fast-build)를 먼저 추가해야 하고, 이는 Makefile 주석이 명시적으로 별개 결정으로 남겨둔 항목이다.
  - formatter: 2개 derivation, 무시 가능.
- 로컬 재파생을 줄이는 더 직접적인 수단은 평가 캐시 유지(`~/.cache/nix/eval-cache-v*`는 flake 입력·소스가 바뀌면 무효)와 IFD 제거다. 이는 이 티켓 범위 밖이지만 "push하면 빨라진다"는 가정을 세우기 전에 확인할 전제다.

### 4. magic-nix-cache-action / FlakeHub Cache 현황(2026-09)과 `actions/cache` 비교

**확인된 사실**

- 2025-01-21 공지: GitHub 캐시 v1 API가 2025-02-01 종료되어 "무료 Magic Nix Cache는 GitHub Enterprise Server가 아니면 동작을 멈춘다". 대안으로 FlakeHub Cache(쿠폰 `FHC` 1개월 무료), 오픈소스는 support@flakehub.com로 무료 계정 요청. [Determinate blog, EOL](https://determinate.systems/blog/magic-nix-cache-free-tier-eol/)
- 2025-06-13 공지: 외부 기여자(jchv)가 새 캐시 API를 리버스엔지니어링한 PR로 v0.1.5부터 다시 동작. 한계: "특정 리포의 특정 워크플로 실행 사이에서만 캐시", 성능은 "decent but not great", "GitHub가 Protobuf 소스를 공개하지 않아 API가 언제든 바뀌어 접근이 무효화될 수 있음". 권장은 "대부분의 경우 FlakeHub Cache". [Determinate blog, Bringing back](https://determinate.systems/blog/bringing-back-magic-nix-cache-action/)
- 현재 README는 "totally free and zero-configuration", "FlakeHub Cache로 업그레이드 가능(쿠폰 FHC)"만 있고 deprecated 표기는 없다. [magic-nix-cache-action README](https://github.com/DeterminateSystems/magic-nix-cache-action)
- FlakeHub Cache: "유료 플랜에서만 제공"(문서 최종 갱신 2026-05-05). CI는 `determinate-nix-action@v3` + `flakehub-cache-action`, `permissions: id-token: write, contents: read` 필수. 로컬은 `determinate-nixd login`. [Determinate docs, FlakeHub Cache](https://docs.determinate.systems/flakehub/cache/) / [migrate guide](https://docs.determinate.systems/guides/migrate-to-flakehub-cache/) / [flakehub-cache-action](https://github.com/DeterminateSystems/flakehub-cache-action)
- GitHub Actions 캐시: 리포당 10 GB, 7일 미접근 evict, 한도 초과 시 마지막 접근일 기준 삭제. 스코프: 현재 브랜치·기본 브랜치·(PR은) base 브랜치 캐시를 읽을 수 있고, 형제·자식 브랜치 캐시와 다른 PR의 캐시는 읽을 수 없다. 키 매칭은 정확 일치 → 부분 일치 → restore-keys → 기본 브랜치 순. [GitHub docs, caching](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/caching-dependencies-to-speed-up-workflows) / [actions/cache README](https://github.com/actions/cache)
- `nix-installer-action`: `determinate` 입력 기본값 `true`("Determinate Nix 설치 + FlakeHub 로그인"), 우리는 `false`. `trust-runner-user` 기본 `true`("runner 사용자를 데몬 trusted로"). `extra-conf`는 `/etc/nix/nix.conf`에 추가된다. [nix-installer-action README](https://github.com/DeterminateSystems/nix-installer-action)

**추론**

- 우리의 `actions/cache`로 `~/.cache/nix`·`~/.local/state/nix` 저장 방식은 store가 아니라 fetcher 캐시·평가 캐시·프로필 상태를 저장한다. Nix store(`/nix/store`)는 저장하지 않으므로 빌드 산출물 재사용은 전부 Cachix에 의존한다. 반면 magic-nix-cache는 store path 단위로 GitHub 캐시에 저장한다. 두 방식은 겹치지 않는다.
- 최근 main 런의 Darwin "Setup Nix with cache" 스텝이 69초로 가장 큰 고정비용인데, 여기에는 Nix 설치 + cachix 설치(`nix-env -iA cachix`) + actions/cache restore가 포함된다. 어느 부분이 지배적인지는 스텝 로그를 봐야 한다(이번 조사 범위 밖).
- magic-nix-cache-action은 "동작은 하지만 비공식 API 의존"이라는 상태이므로, 채택 시 언제 깨질지 모른다는 전제가 붙는다. FlakeHub Cache는 유료(오픈소스 예외)이고 Determinate Nix 의존이다. Cachix는 현행 유지가 가능하고 이미 동작한다.

### 5. `nix-fast-build` 적합성

**확인된 사실**

- "`nix-eval-jobs`의 출력을 이용해 flake 속성을 병렬 평가하고, 속성 평가가 끝나는 즉시 빌드를 시작한다." 기본 대상 `.#checks`. `--skip-cached`("바이너리 캐시에 이미 있는 빌드 건너뜀"), `--cachix-cache`("업로드할 Cachix 캐시"), `--attic-cache`, `--copy-to`, `--eval-workers`, `--max-jobs`, `--result-format {json,junit}`, `--remote`, `--no-nom`. `GITHUB_STEP_SUMMARY`가 있으면 요약을 자동 기록. 사례: disko 테스트 스위트 재빌드 1분 50초 → 10초. [nix-fast-build README](https://github.com/Mic92/nix-fast-build)

**추론**

- 우리 checks는 aarch64-darwin에서 130여 개 최상위 속성이고 대부분 소형 `runCommand`이며 `all-assertions` 집계 하나가 699개를 끌어온다. 개별 속성 평가를 병렬화하면 dry-run 1분 15초 중 평가 부분은 줄어들 수 있다. 단 `nix-eval-jobs`는 IFD를 기본 허용하지 않으므로(`--allow-import-from-derivation` 옵션이 별도로 존재, 이 조사에서는 확인하지 않음) 우리 평가의 IFD가 동작하는지 먼저 확인이 필요하다.
- `--cachix-cache`가 push까지 처리하므로 "checks를 push하려면 CI가 먼저 빌드해야 한다"는 3번의 선결 조건을 한 스텝으로 해결하는 후보다. 다만 이는 macOS CI 시간을 늘리는 결정이고, Makefile 주석이 남겨둔 "test-build를 CI에 켜는 것은 별개 결정"과 같은 항목이다.

### 6. Determinate Nix 로컬에서 flake nixConfig substituter가 신뢰되는 조건

**확인된 사실**

- Nix 매뉴얼: `trusted-users`는 "데몬에 연결할 때 추가 권한을 갖는 사용자. 예: 추가 substituter 지정". `substituters`에 대해 "비특권 사용자(`allowed-users`에만 있고 `trusted-users`에 없는)는 `trusted-substituters`에 있는 URL만 substituters로 넘길 수 있다". `trusted-substituters`는 "기본으로 쓰이지 않지만 데몬 사용자가 substituters로 지정해 켤 수 있는 목록". Determinate 매뉴얼은 여기에 "trusted-users 추가는 사실상 root 권한 부여와 같다"를 덧붙인다. [Nix manual, nix.conf](https://nix.dev/manual/nix/latest/command-ref/conf-file.html) / [Determinate Nix manual, nix.conf](https://manual.determinate.systems/command-ref/conf-file.html)
- NixOS/nix#6752: 비신뢰 사용자가 nixConfig의 substituters·trusted-public-keys 수락 프롬프트에 y를 눌러도 데몬이 "ignoring untrusted substituter" 경고와 함께 무시한다. 원인은 nixConfig가 클라이언트 측에서 적용되는 반면, 제한 설정의 수용 여부는 데몬이 `trusted-users`로 판단하기 때문이다. [NixOS/nix#6752](https://github.com/NixOS/nix/issues/6752)
- Determinate Nix on macOS: `/etc/nix/nix.conf`는 Determinate가 관리("do not modify! this file will be replaced!")하고 `!include nix.custom.conf`로 사용자 설정을 읽는다. nix-darwin과 함께 쓸 때는 `nix.enable = false` + `determinateNix.customSettings`가 `/etc/nix/nix.custom.conf`를 생성한다. [Determinate docs, nix-darwin](https://docs.determinate.systems/guides/nix-darwin/) / [nix-darwin#1298](https://github.com/nix-darwin/nix-darwin/issues/1298)
- 이 머신 실측(Determinate Nix 3.13.2):
  - `/etc/nix/nix.conf`(Determinate 관리)에는 `trusted-users`가 없다. 기본값 `root`만 신뢰. 대신 `extra-trusted-substituters = https://cache.flakehub.com https://install.determinate.systems`, `always-allow-substitutes = true`가 들어 있다.
  - `/etc/nix/nix.custom.conf`(determinate 모듈 생성)에 `trusted-users = root jito.hello @admin @wheel`, `substituters = https://baleen-nix.cachix.org …`, `trusted-public-keys = …`가 있다.
  - 결과: `nix config show`에서 `trusted-users = root jito.hello @admin @wheel`, `nix store info --json`의 `trusted: 1`. 사용자는 `admin` 그룹 소속.
  - `accept-flake-config = false`이고, flake nixConfig는 `~/.local/share/nix/trusted-settings.json`에 저장된 수락으로 적용된다("Using saved setting …" 메시지, 실측).

**추론(조건 정리)**

Determinate Nix macOS에서 비root 사용자가 flake nixConfig의 substituter를 실제로 쓰려면 다음 두 조건이 모두 필요하다.

1. 클라이언트 수락: `--accept-flake-config`, 전역 `accept-flake-config = true`, 또는 프롬프트 y(→ `trusted-settings.json`에 저장). 이 중 하나가 없으면 nixConfig 값은 무시된다.
2. 데몬 신뢰: 사용자가 `trusted-users`에 있거나(직접 또는 `@admin`/`@wheel`), 해당 URL이 `trusted-substituters`에 있어야 한다. 이는 `/etc/nix/nix.custom.conf`에 써야 하며(`nix.conf`는 덮어써짐) 우리 리포에서는 `lib/mksystem.nix`의 `cacheSettings.trusted-users`와 `trusted-substituters = cacheSettings.substituters`가 이 역할을 한다.

#346의 상황("nix-community.cachix.org 무시")은 조건 2가 빠진 경우다. 지금은 nix.custom.conf가 그 조건을 채우고 있으므로, 이 파일이 activation으로 계속 생성되는 한 재발하지 않는다. 반대로 새 머신에서 첫 `make switch` 전에는 조건 2가 없어 nixConfig substituter가 무시되고 cache.nixos.org만 쓰인다. 이는 부트스트랩 단계의 예상된 동작이다.

## 우리 리포에 대한 함의

1. **정본 단일화는 flake.nix 방향만 가능하다.** `lib/cache-config.nix`를 `(import ../flake.nix).nixConfig`로 바꾸면 두 곳이 한 곳이 되고 `scripts/check-cache-sync.sh`와 그 fixture 테스트는 필요가 없어진다. CI의 `NIX_CONFIG`는 `nix eval --json --file flake.nix nixConfig`로 스텝 안에서 생성할 수 있다. `setup-nix/action.yml`의 `extra-conf`는 첫 nix 호출 전에 필요하지만, runner가 trusted이고 빌드가 `--accept-flake-config`를 쓰므로 substituters 줄은 사실 중복이며 제거 후보다. 이 경로는 `tests/unit/cache-config-test.nix`의 네 곳 포함 단정을 함께 바꿔야 한다.
2. **checks·devShell push는 지금 상태로는 효과가 작다.** macOS CI가 checks를 빌드하지 않아 push 대상이 없고, 빌드해도 시간은 평가·IFD에 있다. push를 결정하기 전에 `make test-build`의 평가 시간과 빌드 시간을 분리 측정하는 것이 순서다.
3. **PR push는 정책 문제다.** 기술적으로 같은 리포 브랜치 PR에서는 가능하지만, cachix-action 기본 권장과 우리 현행(main·tag만)이 일치한다. 바꾸려면 "리뷰 전 산출물을 모든 머신이 신뢰하는 캐시에 넣는다"를 받아들이는 결정이 필요하다.
4. **magic-nix-cache로의 이동은 비공식 API 의존을 떠안는 것이고, FlakeHub Cache는 유료·Determinate 종속이다.** Cachix 현행 유지가 가장 적은 변화다. `actions/cache`는 store를 저장하지 않으므로 Cachix와 역할이 겹치지 않고, 두 캐시 모두 미접근 evict가 있어 "push했다 = 남아 있다"가 아니다.
5. **#346 재발 방지는 nix.custom.conf의 `trusted-users`가 담당한다.** 이 값은 `lib/cache-config.nix`가 아니라 `lib/mksystem.nix`에 있고 `cache-config-test`가 "cache-config.nix에 trusted-users를 두지 말 것"을 고정한다. 정본 단일화 시에도 이 분리는 유지해야 한다. 단, `trusted-users`는 root 상당 권한이므로 새 머신 부트스트랩 단계에서 substituter 경고가 나는 것은 정상이다.

## 미확인 사항

- `nix-eval-jobs`가 우리 평가의 IFD를 처리하는지(옵션 존재만 알고 실제 동작 미확인).
- Determinate 설치기가 기본으로 어떤 사용자를 `trusted-users`에 넣는지 공식 문서에서 찾지 못함. 이 머신의 `/etc/nix/nix.conf`에 `trusted-users` 줄이 없다는 실측으로 대체.
- FlakeHub Cache의 정확한 가격표(determinate.systems/pricing 404). "유료 플랜 전용 + 오픈소스 무료 요청"까지만 확인.
- CI "Setup Nix with cache" 69초의 내부 구성(설치 vs cachix 설치 vs restore).

## 출처 목록

- Nix manual, nix.conf: https://nix.dev/manual/nix/latest/command-ref/conf-file.html
- Nix manual, nix flake(flake format, nixConfig): https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake.html
- Determinate Nix manual, nix.conf: https://manual.determinate.systems/command-ref/conf-file.html
- NixOS/nix#6752 (untrusted user + nixConfig 무시): https://github.com/NixOS/nix/issues/6752
- NixOS/nix#9643 (trusted-settings.json 미문서화): https://github.com/NixOS/nix/issues/9643
- cachix-action README: https://github.com/cachix/cachix-action
- Cachix docs, Pushing: https://docs.cachix.org/pushing
- Cachix docs, Getting started: https://docs.cachix.org/getting-started
- Cachix docs, Garbage collection: https://docs.cachix.org/garbage-collection
- Cachix pricing: https://www.cachix.org/pricing
- nix.dev, GitHub Actions CI 튜토리얼: https://nix.dev/tutorials/nixos/continuous-integration-github-actions
- Determinate blog, Magic Nix Cache 무료 티어 EOL (2025-01-21): https://determinate.systems/blog/magic-nix-cache-free-tier-eol/
- Determinate blog, Bringing back the Magic Nix Cache Action (2025-06-13): https://determinate.systems/blog/bringing-back-magic-nix-cache-action/
- magic-nix-cache-action README: https://github.com/DeterminateSystems/magic-nix-cache-action
- Determinate docs, FlakeHub Cache: https://docs.determinate.systems/flakehub/cache/
- Determinate docs, Migrating to FlakeHub Cache: https://docs.determinate.systems/guides/migrate-to-flakehub-cache/
- Determinate docs, nix-darwin: https://docs.determinate.systems/guides/nix-darwin/
- flakehub-cache-action README: https://github.com/DeterminateSystems/flakehub-cache-action
- nix-installer-action README: https://github.com/DeterminateSystems/nix-installer-action
- nix-darwin#1298 (Determinate + custom settings): https://github.com/nix-darwin/nix-darwin/issues/1298
- nix-fast-build README: https://github.com/Mic92/nix-fast-build
- GitHub docs, Using secrets: https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- GitHub docs, Caching dependencies: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/caching-dependencies-to-speed-up-workflows
- actions/cache README: https://github.com/actions/cache
- 리포 내 이전 이슈 #346: https://github.com/baleen37/dotfiles/issues/346
