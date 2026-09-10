# Determinate Nix vs nix-darwin 관리 Nix: 2026-09 시점 트레이드오프

- 이슈: https://github.com/baleen37/dotfiles/issues/1446 (part of #1443)
- 조사일: 2026-09-10
- 조사 기준 버전
  - nix-darwin: flake.lock 고정 rev `4cff07de` (LnL7/nix-darwin)
  - determinate flake: flake.lock 고정 `0.1.435+rev-b484316` = 태그 `v3.22.2` (2026-08-21). FlakeHub 최신은 `3.22.3` (2026-09-03)
  - 이 Mac에 실제 설치된 Determinate Nix: `3.13.2` (upstream Nix 2.32.4 기반). `determinate-nixd version`이 최신 3.22.3 안내
  - upstream Nix 최신 릴리즈: 2.35.2 (2026-06-22). nixpkgs 고정 rev `c27cdad`의 `pkgs.nix` = 2.34.8, `nixVersions.latest` = 2.35.2, `pkgs.lix` = 2.95.2

표기: **[검증]** = 1차 출처(소스·공식 문서·로컬 실측)에서 직접 확인. **[추론]** = 검증된 사실에서 끌어낸 판단.

## 질문

macOS에서 Determinate Nix(`nix.enable = false` + `determinateNix.customSettings`)를 계속 쓰는 것과 nix-darwin이 Nix를 관리하도록 되돌리는 것의 트레이드오프를 1차 출처로 정리한다.

1. Determinate 사용 시 nix-darwin에서 못 쓰는 옵션 목록과 Determinate 쪽 대체 수단
2. `nix.enable = false`에서 `nix.settings`가 조용히 무시되는지, 평가 시 경고가 나는지
3. Determinate의 실질 이점(GC 자동화, FlakeHub cache, parallel eval, lazy trees 등)이 2026-09 현재 upstream Nix/Lix에도 있는지
4. 되돌릴 때의 마이그레이션 경로와 위험
5. Determinate 유지 시 `machines/darwin/common.nix`의 linux-builder 40줄을 대체할 방법

## 결론 요약

1. `nix.enable = false`면 nix-darwin은 Nix 패키지·nix-daemon launchd·`/etc/nix/nix.conf`·build user·`NIX_PATH` 관리를 전부 멈춘다. `nix.gc`/`nix.optimise`/`nix.linux-builder`는 assertion으로 **소리내며** 막히고, `nix.settings`/`nix.extraOptions`/`nix.registry`/`nix.buildMachines`는 **조용히** 버려진다(경고 없음, 실측 `warnings = []`).
2. Determinate 모듈은 `customSettings` → `/etc/nix/nix.custom.conf`, `determinateNixd.*` → `/etc/determinate/config.json`, `registry` → `/etc/nix/registry.json`, `buildMachines` → `/etc/nix/machines`를 쓴다. `nix.enable`은 모듈이 `mkForce false`로 고정한다.
3. lazy trees와 parallel eval(`eval-cores`)은 2026-09 현재 **Determinate 전용**이다. upstream 2.35.2 설정 레퍼런스에 두 설정이 없고, 관련 PR(#13225, #10938)은 미머지 종료. Lix는 "lazy trees를 넣지 않고 자체 대체를 계획"이라고 명시.
4. GC 자동화(디스크 여유 30GB/5~20%/5% 미만 urgent), Keychain 인증서 주입, `determinate-nixd upgrade`는 Determinate Nixd 고유. FlakeHub Cache는 **유료 플랜 전용**이며 우리 리포는 cachix를 쓰므로 현재 의존 없음.
5. 되돌리기는 in-place가 아니다: `sudo /nix/nix-installer uninstall`이 `/nix` 전체와 APFS 볼륨을 지운다(스토어 소실). 그 뒤 upstream Nix 설치 → 모듈 제거 → `nix.enable = true` → 설정을 `nix.*`로 옮긴다. Determinate가 남아 있으면 nix-darwin이 활성화를 중단시킨다.
6. linux-builder 40줄은 Determinate 모듈의 `determinateNix.nixosVmBasedLinuxBuilder`로 거의 1:1 대체 가능하다(같은 `pkgs.darwin.linux-builder`, `config`/`systems`/`maxJobs` 지원). 현재 그 40줄은 Darwin에서 평가상 죽은 코드다(`nix.linux-builder.enable = false` 실측).
7. 리포 상태: 설치된 nixd 3.13.2는 flake.lock(3.22.2)과 무관하게 뒤처져 있고, `eval-cores = 1`(구 기본값)로 돌고 있다. `sudo determinate-nixd upgrade`가 lock 갱신과 별개로 필요하다.

## 상세

### 1. `nix.enable = false`가 끄는 것과 Determinate 대체 수단

**nix-darwin이 `nix.enable`로 게이트하는 것** [검증, nix-darwin 소스 rev 4cff07de]

- 옵션 설명 자체가 범위를 명시한다: "Disabling this will stop nix-darwin from managing the installed version of Nix, the nix-daemon launchd daemon, and the settings in `/etc/nix/nix.conf`. ... `nix.*` options to adjust Nix settings or configure a Linux builder, will be unavailable. You will also have to upgrade Nix yourself." — [modules/nix/default.nix L209-231](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/default.nix)
- 구현: `config = handleUnmanaged { ... }`이고 `handleUnmanaged`는 `mkIf cfg.enable managedConfig`로 전체를 감싼다. 즉 `environment.systemPackages`의 nix 패키지, `environment.etc."nix/nix.conf"`, `registry.json`, `machines`, build user 설정, `NIX_PATH`, 관련 warnings/assertions까지 한 덩어리로 꺼진다. — [같은 파일 L142-160, L730-](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/default.nix)
- nix-daemon launchd: `config = mkIf config.nix.enable { launchd.daemons.nix-daemon = ... }` — [modules/services/nix-daemon.nix L43](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/services/nix-daemon.nix)
- assertion으로 막히는 옵션(켜면 평가 실패):
  - `nix.gc.automatic` — "nix.gc.automatic requires nix.enable" [services/nix-gc/default.nix L62](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/services/nix-gc/default.nix)
  - `nix.optimise.automatic` — [services/nix-optimise/default.nix L58](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/services/nix-optimise/default.nix)
  - `nix.linux-builder.enable` — [modules/nix/linux-builder.nix L171](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/linux-builder.nix)
  - `nixpkgs.flake.setNixPath` / `setFlakeRegistry` (기본값은 `config.nix.enable && ...`라 자동 off) — [modules/nix/nixpkgs-flake.nix L40-98](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/nixpkgs-flake.nix)
  - `services.hercules-ci-agent`, `services.lorri`, `services.cachix-agent`, `services.ofborg`, `services.github-runners.*` — 각 모듈에 동일한 assertion
- 활성화 시 검사: `nix.enable = true`인데 `/usr/local/bin/determinate-nixd`가 존재하면 "Determinate detected, aborting activation"으로 중단. — [modules/system/checks.nix L46-60, L313](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/checks.nix)

**Determinate 모듈이 제공하는 대체** [검증, determinate v3.22.2 `modules/nix-darwin/default.nix`]

| nix-darwin (`nix.enable = true`) | Determinate 모듈 (`determinateNix.*`) | 기록 위치 |
|---|---|---|
| `nix.settings` | `customSettings` (freeform, `cores`/`sandbox`/`trusted-users`/`extra-sandbox-paths`는 타입 있음) | `/etc/nix/nix.custom.conf` |
| `nix.gc` (launchd calendar + options) | `determinateNixd.garbageCollector.strategy = "automatic" \| "disabled"` (interval/options 없음) | `/etc/determinate/config.json` |
| `nix.optimise` | 직접 대응 없음. [추론] `customSettings.auto-optimise-store = true`로 Nix 자체 기능 사용 가능 | `nix.custom.conf` |
| `nix.linux-builder` | `nixosVmBasedLinuxBuilder.*` (5절) 또는 네이티브 빌더 `determinateNixd.builder.state` | launchd + `/etc/nix/machines` + `config.json` |
| `nix.registry` | `registry` (+ `flake-registry` 설정 자동 추가) | `/etc/nix/registry.json` |
| `nix.buildMachines` / `nix.distributedBuilds` | 동명 옵션 | `/etc/nix/machines` |
| `nix.package` / Nix 업그레이드 | 모듈 밖. `sudo determinate-nixd upgrade` | — |
| `nix.nixPath` / `nix.channel` | 없음. nixd가 `extra-nix-path = nixpkgs=flake:...nixpkgs-weekly`를 `nix.conf`에 고정 | `/etc/nix/nix.conf` |

- `customSettings`에서 **금지**되는 키(assertion): `bash-prompt-prefix`, `external-builders`, `extra-nix-path`, `netrc-file`, `ssl-cert-file`, `upgrade-nix-store-path-url` — [default.nix `disallowedOptions`](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/modules/nix-darwin/default.nix). 3.16.3 changelog는 `bash-prompt-prefix`와 `extra-nix-path`를 `nix.custom.conf`에서 override 가능하다고 적었지만, v3.22.2 모듈의 금지 목록에는 여전히 들어 있다(수기 편집과 모듈 경로가 다름). [검증]
- 모듈은 `nix.enable = lib.mkForce false`를 강제한다. 우리가 `mksystem.nix:81`과 `users/shared/darwin/default.nix:127`에서 따로 `false`를 두는 것은 중복이다. [검증]
- `nix.custom.conf`는 nixd가 만드는 `nix.conf` 안에서 `!include nix.custom.conf`로 읽힌다. include 뒤에 nixd 고정값(`bash-prompt-prefix`, `netrc-file`, `extra-substituters`, `ssl-cert-file`, `upgrade-nix-store-path-url`, `extra-nix-path`)이 이어지므로 위 금지 목록과 정확히 일치한다. [검증, 이 Mac의 `/etc/nix/nix.conf`]

### 2. `nix.enable = false`에서 `nix.settings`의 운명

- **조용히 무시된다.** `nix.settings`는 옵션 선언이 남아 있어 정의를 받고 병합까지 하지만, 그 값을 소비하는 `nix.conf` 생성이 `mkIf cfg.enable` 안에 있어 어디에도 쓰이지 않는다. 경고를 내는 코드도 없다. [검증, nix-darwin `modules/nix/default.nix` L142-160·L714·L740]
- 우리 `macbook-pro` 설정을 평가해 확인: `warnings = []`, `environment.etc`의 nix 관련 키는 `determinate/config.json`, `nix/nix.custom.conf` 두 개뿐(`nix/nix.conf` 없음). [검증, `nix eval .#darwinConfigurations.macbook-pro.config`]
- 한 가지 **소리나는** 케이스: 아무 모듈도 `nix.settings`를 정의하지 않은 상태에서 누군가 `config.nix.settings`를 *읽으면* `managedDefault`가 `throw "nix.settings: accessed when nix.enable is off; this is a bug in nix-darwin or a third-party module"`를 던진다. 우리 리포는 `mksystem.nix`가 `nix.settings = lib.mkIf (!darwin) ...`로 Darwin에선 정의하지 않으므로, 테스트나 모듈이 Darwin config의 `nix.settings`를 읽으면 그 자리에서 평가가 깨진다. 실제로 재현했다. [검증]
- `nix.gc.automatic = true`, `nix.linux-builder.enable = true`, `nix.optimise.automatic = true`는 위 1절대로 assertion 실패다. 즉 "조용히 무시"는 `nix.settings`·`nix.extraOptions`·`nix.registry`·`nix.nixPath`·`nix.buildMachines`·`nix.distributedBuilds`·`nix.daemon*`류에 한정된다. [검증]

### 3. Determinate 고유 이점 vs upstream Nix / Lix (2026-09)

| 기능 | Determinate Nix 3.22.x | upstream Nix 2.35.2 | Lix 2.95 |
|---|---|---|---|
| lazy trees | 기본 on (`lazy-trees = true`가 nixd 생성 `nix.conf`에 고정) | 설정 없음. PR #13225 "Lazy trees v2" 미머지 종료 | "포함하지 않으며 upstream 구현을 쓸 생각도 없다, 동등 기능 대체를 계획" |
| parallel eval | `eval-cores` 설정. 3.16.3부터 기본 무제한(전 코어) | 설정 없음. PR #10938 "Multithreaded evaluator" 2025-07-15 미머지 종료. thread-safety 선행 PR은 머지 중 | 이슈 #382 요청만 확인(내용 열람 불가) |
| GC 자동화 | nixd `garbageCollector.strategy = automatic`: 여유 30GB 유지, 5~20% 정상 운전, 5% 미만 urgent | 없음(nix-darwin `nix.gc` 캘런더 launchd가 대체, `nix.enable` 필요) | 없음 |
| FlakeHub Cache | `determinate-nixd login`; **유료 플랜 전용**, push는 CI 신뢰 빌더만 | 미해당 | 미해당 |
| 네이티브 Linux 빌더 | macOS Virtualization framework, aarch64/x86_64-linux. FlakeHub 가입 + 점진 롤아웃 대상자만 | `external-builders` experimental(2.32~)만 있고 빌더 프로그램 없음 | 없음 |
| Keychain 인증서 | `ssl-cert-file = /etc/nix/macos-keychain.crt` 자동 | 없음 | 없음 |
| Nix 업그레이드 | `sudo determinate-nixd upgrade` | nix-darwin `nix.package`(nixpkgs 범프에 연동) | 동일 |

출처와 근거:

- lazy trees 도입·opt-in 시작: [Changelog 3.5.2 (2025-05-15)](https://determinate.systems/blog/changelog-determinate-nix-352/) — "Add `lazy-trees = true` to `/etc/nix/nix.custom.conf`", "3x+ faster, 20x+ less disk", upstream PR #13225 언급. 현재 기본 on은 이 Mac의 nixd 생성 `/etc/nix/nix.conf`(`lazy-trees = true`)로 확인. [검증]
- upstream PR 상태: [NixOS/nix#13225 Lazy trees v2](https://github.com/NixOS/nix/pull/13225) state=closed, merged=false; [NixOS/nix#10938 Multithreaded evaluator](https://github.com/NixOS/nix/pull/10938) closed 2025-07-15, merged=false. [검증, GitHub API]
- upstream 2.35.2 설정 레퍼런스에 `lazy-trees`, `eval-cores` 없음, `external-builders`는 experimental: [conf-file.html](https://nix.dev/manual/nix/latest/command-ref/conf-file.html), [experimental-features.html](https://nix.dev/manual/nix/latest/development/experimental-features.html). upstream master `eval-settings.hh`에도 두 문자열 없음, Determinate 포크 `nix-src`의 같은 파일에는 `"lazy-trees"`(L484)·`"eval-cores"`(L504) 존재. [검증]
- upstream 릴리즈 노트: [2.32.0](https://nix.dev/manual/nix/latest/release-notes/rl-2.32.html) external-builders experimental 도입, [2.34.0](https://nix.dev/manual/nix/latest/release-notes/rl-2.34.html) `nix store roots-daemon`·`ignore-gc-delete-failure`·macOS open-file 한도 자동 상향, [2.35.2](https://nix.dev/manual/nix/latest/release-notes/rl-2.35.html) 소스 스토어 복사 지연(lazy trees와는 다른 최적화)·GC 견고성. parallel eval/lazy-trees 항목 없음. [검증]
- parallel eval 기본 무제한: [Changelog 3.16.3 (2026-03-03, upstream 2.33.3 기반)](https://determinate.systems/blog/changelog-determinate-nix-3163/) — "bumped the number of cores to unlimited". 이 Mac(3.13.2)은 `eval-cores = 1`. [검증]
- 최신 Determinate: [Changelog 3.22.2 (2026-08-26, upstream 2.35.2 기반)](https://determinate.systems/blog/changelog-determinate-nix-3-22-2/); nix-src 최신 릴리즈 v3.22.3 (2026-09-02). [검증]
- Lix lazy trees: [lix.systems/about](https://lix.systems/about/) — "Lix does not include lazy trees, and does not intend to use the upstream implementation of lazy trees; a functionally equivalent replacement is planned". Lix 2.95 릴리즈(2026-03-25)에도 lazy trees/parallel eval 언급 없음. Lix 이슈 #382는 403으로 열람 불가 → 상태 **미검증**. [검증/미검증 구분]
- GC 임계치: [Determinate Nixd 문서](https://docs.determinate.systems/determinate-nix/determinate-nixd/) — "at least 30GB of disk space free", "between 5-20% disk space free", "If your disk falls below 5% free ... urgent". [검증]
- FlakeHub Cache: [docs.determinate.systems/flakehub/cache](https://docs.determinate.systems/flakehub/cache/) — "available only on paid plans", push는 GitHub Actions/GitLab/Semaphore/Buildkite만. [검증]
- 네이티브 빌더: [linux-builder 문서](https://docs.determinate.systems/determinate-nix/linux-builder/), [troubleshooting](https://docs.determinate.systems/troubleshooting/native-linux-builder/) — "sign up for FlakeHub", "currently available to a subset of Determinate Nix users", 접근 요청은 support@determinate.systems. [Changelog 3.8.4 (2025-08-05)](https://determinate.systems/blog/changelog-determinate-nix-384/)는 `external-builders` experimental + `determinate-nixd builder` 프로그램 조합으로 구현됨을 보여준다. [검증]
- 업그레이드: [manual.determinate.systems/installation/upgrading](https://manual.determinate.systems/installation/upgrading.html) — "sudo determinate-nixd upgrade ... upgrading fails without [sudo]". [검증]

[추론] 이점의 무게: lazy trees와 parallel eval은 평가 시간·디스크에 직접 영향을 주고 upstream/Lix 어디에도 없다. GC 자동화는 nix-darwin `nix.gc`로 대체 가능하지만 "디스크 여유 기반" 정책은 nix-darwin에 없다. FlakeHub Cache·네이티브 빌더는 유료/롤아웃 게이트라 현재 우리에게 실효 이점이 아니다.

### 4. 마이그레이션 경로와 위험

**A. Determinate → nix-darwin 관리 Nix(되돌리기)**

1. Determinate 제거: `sudo /nix/nix-installer uninstall`. 이 Mac에 `/nix/nix-installer`와 `/nix/receipt.json`(2025-11)이 존재한다. [검증] 제거 범위: 데몬(`systems.determinate.nix-daemon`, `nix-store`, `nix-installer.nix-hook`), `/nix` 트리, APFS "Nix Store" 볼륨, nix 사용자/그룹. 볼륨·Keychain 항목이 남으면 Disk Utility/Keychain Access로 수동 삭제. — [uninstall 매뉴얼](https://manual.determinate.systems/installation/uninstall), [installation-failed-macos](https://docs.determinate.systems/troubleshooting/installation-failed-macos/), [nix-installer README#Uninstalling](https://github.com/DeterminateSystems/nix-installer#uninstalling). [검증]
2. upstream Nix 설치: 공식 `sh <(curl -L https://nixos.org/nix/install) --daemon` ([installing-binary](https://nix.dev/manual/nix/latest/installation/installing-binary.html)) 또는 `nix-installer install --prefer-upstream-nix`(README가 "Not a supported configuration"이라고 명시). [검증]
3. 설정 변경: `inputs.determinate` 및 `determinate.darwinModules.default` 제거, `nix.enable` 기본값(true) 복귀, `customSettings` → `nix.settings`, `determinateNixd.garbageCollector` → `nix.gc`, (필요시) `nix.linux-builder` 복원. nix-darwin의 `nix.conf` `knownSha256Hashes`에 공식 인스톨러·Determinate nix-installer·lix-installer가 만든 `nix.conf` 해시가 들어 있어 첫 `darwin-rebuild switch`가 기존 파일을 덮어쓸 수 있다. [검증, `modules/nix/default.nix` L743-]
4. 부트스트랩: `/nix`가 사라졌으므로 `darwin-rebuild`도 사라진다. `nix run nix-darwin#darwin-rebuild -- switch --flake .#…`로 재부트스트랩. [추론]

위험:
- **스토어 전체 소실**: in-place 전환 경로가 문서화되어 있지 않다. 캐시 미스분 재빌드. [검증(문서 부재) + 추론]
- Determinate 잔재가 있으면 nix-darwin `checks.nix`가 활성화를 중단시킨다(`/usr/local/bin/determinate-nixd` 존재 검사). [검증]
- Nix 버전이 `pkgs.nix`(현 nixpkgs에서 2.34.8)로 내려가고 lazy trees·parallel eval을 잃는다. 평가 시간·디스크 사용 증가. [검증(버전) + 추론(영향)]
- Nix 업그레이드 주기가 nixpkgs 범프에 묶인다. [검증, `nix.package` 기본 `pkgs.nix`]
- 기존 `/etc/nix/nix.custom.conf`, `/etc/determinate/config.json`은 남아도 무해하지만 nix-darwin이 관리하지 않으므로 수동 삭제 대상. [추론]

**B. nix-darwin 관리 Nix → Determinate(참고)**

- macOS는 "Determinate.pkg로 전환"이 공식 경로. 업그레이드가 in-place인지, 기존 `nix.conf` 백업이 어떻게 되는지는 문서에 없음 → **미검증**. — [migrating-from-upstream-nix](https://docs.determinate.systems/guides/migrating-from-upstream-nix/)
- 설치 후 `nix.enable = true`인 채로 `darwin-rebuild`하면 위 checks가 중단시키므로 모듈 추가(또는 `nix.enable = false`)가 선행되어야 한다. [검증]
- 구(舊) 모듈 사용자를 위한 `darwinModules.migration`이 아직 flake에 남아 있다(우리와 무관). — [migration.nix](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/modules/nix-darwin/migration.nix) [검증]

### 5. `machines/darwin/common.nix` linux-builder 40줄의 대체

현재 상태 [검증]: `useLinuxBuilder = isDarwin && config.nix.enable`이고 Darwin은 `nix.enable = false`이므로 `nix.linux-builder`·`nix.settings.system-features` 블록은 평가상 항상 비활성이다(`nix.linux-builder.enable = false` 실측). 40줄은 죽은 코드다.

대체 1: `determinateNix.nixosVmBasedLinuxBuilder` [검증, determinate v3.22.2 `default.nix`]

- 같은 `pkgs.darwin.linux-builder` 패키지, `config`(deferredModule)로 `virtualisation.cores/memorySize/diskSize`·`boot.binfmt.emulatedSystems` 주입 가능, `systems`(기본은 빌더 VM의 hostPlatform 하나, 리스트로 확장), `maxJobs`(기본 `virtualisation.cores`에서 유도), `protocol`(기본 ssh-ng), `ephemeral`, `supportedFeatures`(기본 `kvm benchmark big-parallel`).
- 켜면 모듈이 자동으로: launchd 데몬(`/var/lib/nixos-vm-based-linux-builder`, 포트 31022), `buildMachines` 항목, `distributedBuilds = true`, `customSettings.builders-use-substitutes = true`, `trusted-public-keys`에 cache.nixos.org, `trusted-users`에 root, 그리고 **네이티브 빌더 `builder.state = "disabled"`** 를 쓴다.
- nix-darwin 원본과 차이: `nix.settings.system-features = [ "nixos-test" "apple-virt" ]`에 해당하는 옵션이 없다 → `customSettings.system-features`(freeform)로 옮기면 된다. 옵션 설명은 "네이티브 빌더 사용을 권하지만 Nixpkgs 빌더도 지원"이라고 적고, "설정을 바꾸기 전에 기본 설정으로 먼저 한 번 빌드하라"고 경고한다.
- 도입 시점: 2025-09-22~28 커밋들("Begin incorporating Linux builder config" 등), 2026-01-09 hostName 기본값 변경·`linux-builder.enable` false 정정. [검증, GitHub API]

대체 2: 네이티브 Linux 빌더 (`determinateNixd.builder.state = "enabled"`)

- nixd 기본값이 "enabled"라 우리 `config.json`(state 미기재)에서도 이미 켜진 상태로 취급된다. 단 FlakeHub 로그인 + 롤아웃 대상자 조건이 있어 실제 동작은 계정 상태에 달려 있다. [검증(문서) / 이 계정의 롤아웃 여부는 미검증]
- 우리 `config.json`에 `builder.memoryBytes = 8GiB`, `cpuCount = 1`이 항상 기록되는 이유는 모듈 옵션 기본값이 non-null이어서다(`garbageCollector.strategy`처럼 null 기본이 아님). [검증, 로컬 `/etc/determinate/config.json` + 모듈 소스]
- NixOS VM 테스트(`nixos-test` feature, KVM)에 쓸 수 있는지는 문서에 없음 → **미검증**.

## 우리 리포에 대한 함의

1. `nix.settings`는 Darwin에서 정의해도 무시되고, 정의 없이 읽으면 throw다. `mksystem.nix`의 `mkIf (!darwin)`은 맞는 처리이며, 테스트가 Darwin config의 `nix.settings`를 읽지 않도록 유지해야 한다.
2. `users/shared/darwin/default.nix:126-129`의 `nix.enable = false`와 `mksystem.nix:81`은 모듈의 `mkForce false`와 중복이다. 하나로 줄여도 동작 동일.
3. `machines/darwin/common.nix:15-59, 87-94`의 linux-builder 블록은 죽은 코드다. Determinate를 유지한다면 `determinateNix.nixosVmBasedLinuxBuilder { enable; systems; config = {...}; }` + `customSettings.system-features`로 약 15줄에 옮길 수 있다. 되돌린다면 현재 블록이 그대로 살아난다.
4. 이 Mac의 Determinate Nix는 3.13.2로 flake.lock(3.22.2)과 별개다. Darwin 모듈은 nixd를 설치하지 않으므로 lock 갱신이 설치 버전을 바꾸지 않는다(README: "does not install Determinate Nix for you"). parallel eval 기본 무제한(3.16.3+)을 받으려면 `sudo determinate-nixd upgrade`가 따로 필요하다.
5. flake input이 `determinate/0.1`인데 README·공식 가이드는 `determinate/3`을 권한다. 오늘 기준 두 경로는 같은 커밋(3.22.3 = 0.1.436+rev-cb76ac2)을 가리키므로 기능 차이는 없지만, 문서 정본과 맞추는 편이 안전하다. README는 `inputs.nixpkgs.follows`를 쓰지 말라고도 하는데, 그 이유(FlakeHub Cache 미스)는 Darwin 모듈 경로에는 해당하지 않는다(모듈은 inputs를 쓰지 않음). [추론]
6. `customSettings`는 `cores = 0`, `sandbox = false`를 기본값으로 항상 기록한다. 의도한 값인지 한 번 확인할 가치가 있다.
7. FlakeHub Cache는 유료라 cachix 유지가 현재 구조와 맞다. Determinate가 `nix.conf`에 넣는 `extra-substituters = https://install.determinate.systems`는 Determinate 자체 배포용이며 우리 substituters 뒤에 붙는다(실측).

## 출처 목록

1차 소스(코드)
- nix-darwin rev 4cff07de: [modules/nix/default.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/default.nix), [modules/services/nix-daemon.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/services/nix-daemon.nix), [modules/services/nix-gc/default.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/services/nix-gc/default.nix), [modules/services/nix-optimise/default.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/services/nix-optimise/default.nix), [modules/nix/linux-builder.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/linux-builder.nix), [modules/nix/nixpkgs-flake.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/nix/nixpkgs-flake.nix), [modules/system/checks.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/checks.nix), [modules/system/activation-scripts.nix](https://github.com/LnL7/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/activation-scripts.nix)
- DeterminateSystems/determinate v3.22.2 (rev b484316): [modules/nix-darwin/default.nix](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/modules/nix-darwin/default.nix), [modules/nix-darwin/config/config.nix](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/modules/nix-darwin/config/config.nix), [modules/nix-darwin/migration.nix](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/modules/nix-darwin/migration.nix), [README.md](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/README.md), [flake.nix](https://github.com/DeterminateSystems/determinate/blob/b484316129e0089e28077f4ede85ac4dbd4b842f/flake.nix)
- DeterminateSystems/nix-src main: [eval-settings.hh](https://github.com/DeterminateSystems/nix-src/blob/main/src/libexpr/include/nix/expr/eval-settings.hh), [releases](https://github.com/DeterminateSystems/nix-src/releases)
- NixOS/nix: [PR #13225 Lazy trees v2](https://github.com/NixOS/nix/pull/13225), [PR #10938 Multithreaded evaluator](https://github.com/NixOS/nix/pull/10938), [master eval-settings.hh](https://github.com/NixOS/nix/blob/master/src/libexpr/include/nix/expr/eval-settings.hh)
- DeterminateSystems/nix-installer: [README](https://github.com/DeterminateSystems/nix-installer#readme)

공식 문서
- Determinate: [Determinate Nix](https://docs.determinate.systems/determinate-nix/), [Determinate Nixd](https://docs.determinate.systems/determinate-nix/determinate-nixd/), [Use Determinate with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/), [Native Linux builder](https://docs.determinate.systems/determinate-nix/linux-builder/), [Native Linux builder troubleshooting](https://docs.determinate.systems/troubleshooting/native-linux-builder/), [Recovering from a failed installation on macOS](https://docs.determinate.systems/troubleshooting/installation-failed-macos/), [Migrating from upstream Nix](https://docs.determinate.systems/guides/migrating-from-upstream-nix/), [FlakeHub Cache](https://docs.determinate.systems/flakehub/cache/), [Uninstalling Nix (manual)](https://manual.determinate.systems/installation/uninstall), [Upgrading Nix (manual)](https://manual.determinate.systems/installation/upgrading.html)
- Determinate changelog: [3.5.2 lazy trees](https://determinate.systems/blog/changelog-determinate-nix-352/), [3.8.4 native Linux builder](https://determinate.systems/blog/changelog-determinate-nix-384/), [3.15.2 nix-darwin module](https://determinate.systems/blog/changelog-determinate-nix-3152/), [3.16.3 parallel eval unlimited](https://determinate.systems/blog/changelog-determinate-nix-3163/), [3.22.2](https://determinate.systems/blog/changelog-determinate-nix-3-22-2/), [Parallel Nix evaluation (2024-06)](https://determinate.systems/blog/parallel-nix-eval/)
- upstream Nix 매뉴얼: [설정 레퍼런스 2.35.2](https://nix.dev/manual/nix/latest/command-ref/conf-file.html), [experimental features](https://nix.dev/manual/nix/latest/development/experimental-features.html), [rl-2.32](https://nix.dev/manual/nix/latest/release-notes/rl-2.32.html), [rl-2.33](https://nix.dev/manual/nix/latest/release-notes/rl-2.33.html), [rl-2.34](https://nix.dev/manual/nix/latest/release-notes/rl-2.34.html), [rl-2.35](https://nix.dev/manual/nix/latest/release-notes/rl-2.35.html), [macOS 설치](https://nix.dev/manual/nix/latest/installation/installing-binary.html)
- Lix: [About Lix](https://lix.systems/about/), [Lix 2.95 릴리즈](https://lix.systems/blog/2026-03-25-lix-2.95-release/), [이슈 #382 (403, 미열람)](https://git.lix.systems/lix-project/lix/issues/382)

로컬 실측(이 Mac, 2026-09-10)
- `/etc/nix/nix.conf`(nixd 생성, `lazy-trees = true`, `eval-cores = 1`, `!include nix.custom.conf`), `/etc/nix/nix.custom.conf`, `/etc/determinate/config.json`, `/Library/LaunchDaemons/systems.determinate.*`, `/nix/nix-installer`, `/nix/receipt.json`, `determinate-nixd version`(3.13.2, 최신 3.22.3)
- `nix eval .#darwinConfigurations.macbook-pro.config`: `nix.enable = false`, `warnings = []`, `nix.linux-builder.enable = false`, etc 키 `determinate/config.json`·`nix/nix.custom.conf`
