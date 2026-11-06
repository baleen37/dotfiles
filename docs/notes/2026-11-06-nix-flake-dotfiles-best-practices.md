# Nix flake dotfiles 베스트 프랙티스와 이 레포 비교

조사일: 2026-11-06. 근거는 1차 출처(공식 매뉴얼, 공식 docs, README)만 사용했다.
1차 출처로 확인하지 못한 내용은 **[미검증]**으로, 문서에서 끌어낸 판단은 (추론)으로 표시한다.

## 우선순위 Top 5

| 순위 | 작업                                                                                | 위치                                      | 예상 시간 |
| :--- | :---------------------------------------------------------------------------------- | :---------------------------------------- | :-------- |
| 1    | `trusted-users`에서 `@admin`과 `@wheel` 제거                                        | `lib/mksystem.nix:33-38`                  | 15분      |
| 2    | Makefile의 `--accept-flake-config` 필요 여부 재검토 (아래 2절 주의 참고)            | `Makefile:84-142`                         | 30분      |
| 3    | VM의 `extraOptions`를 `nix.settings`로 옮기고 기본값과 같은 `keep-derivations` 삭제 | `machines/nixos/vm-shared.nix:35-41`      | 20분      |
| 4    | Renovate lock automerge보다 CI required check가 먼저 걸리는지 확인                  | `renovate.json`, GitHub branch protection | 10분      |
| 5    | 비밀 값이 생기면 sops-nix 도입 (Darwin, NixOS, HM 공통)                             | —                                         | 반나절    |

## 1. 호스트 선언, 시스템 팩토리, flake-parts 구성

**모범 사례**

- `flake.nixosConfigurations`는 "Instantiated NixOS configurations. Used by `nixos-rebuild`."이다. ([flake.parts][fp])
- `perSystem`은 "A function from system to flake-like attributes"이고, 예시는 `_module.args.pkgs`에서 pkgs를 읽는다. ([flake.parts][fp])
- `withSystem`, `easyOverlay`, `darwinConfigurations`의 사용법 **[미검증]**: 같은 페이지에 선언만 있거나 언급이 없다.

**레포 현황**

- `flake.nix:89-96`: `mkFlake`와 `import-tree ./flake-modules`를 쓴다.
- `flake-modules/hosts.nix`: 타입이 있는 `dotfiles.hosts`를 선언한다.
- `flake-modules/systems.nix`: class별로 `mkHost`를 적용한다.
- `flake-modules/args.nix`: perSystem pkgs를 `import nixpkgs`로 만든다.

**판정**: 일치. 지금 구조를 유지한다.

## 2. nix.settings 보안 (trusted-users, 캐시, nixConfig)

**모범 사례** ([nix.conf][conf])

- trusted-users: "Adding a user to `trusted-users` is essentially equivalent to giving that user root access to the system."
- trusted-substituters: 권한 없는 사용자는 "can pass as `substituters` only those URLs listed in `trusted-substituters`."
- `accept-flake-config`의 기본값은 `false`다.
- flake의 `nixConfig`는 확인을 거쳐야 적용된다. 확인 없이 적용되는 옵션은 bash-prompt 계열, `flake-registry`, `commit-lock-file-summary`뿐이다. ([nix flake][flake])

**레포 현황**

- `lib/mksystem.nix:33-38`: `trusted-users`가 `root`, `user`, `@admin`, `@wheel`이다. Darwin에서는 같은 값이 `determinateNix.customSettings`로 들어간다.
- `lib/mksystem.nix:65`: Linux는 `trusted-substituters = substituters`다.
- `flake.nix:4-19`: `nixConfig`가 `lib/cache-config.nix`와 같은 캐시를 중복으로 선언한다.
- Makefile: 빌드와 체크 7곳에 `--accept-flake-config`가 있다.
- `install.sh:148-153`: 첫 활성화 전 부트스트랩에서 `accept-flake-config`를 켠다.

**판정**: 어긋남.

**권장**

1. `trusted-users`를 `[ "root" user ]`로 줄인다. `@admin`이 있으면 macOS 관리자 계정 전원이 root와 같은 권한을 얻는다.
2. `trusted-substituters`는 효과가 없어 보인다. 같은 목록이 이미 전역 `substituters`에 들어 있기 때문이다. 지워도 되지만 우선순위는 낮다. (추론)
3. Makefile의 `--accept-flake-config`
   - 활성화가 끝난 호스트에서는 시스템 nix.conf에 이미 캐시가 있으므로 필요 없다.
   - **주의**: CI 러너의 nix.conf에는 이 캐시가 없을 수 있다. 플래그를 빼기 전에 `.github/actions/setup-nix`가 substituter를 따로 넣어 주는지 확인한다. (추론)

## 3. Darwin의 Determinate Nix

**모범 사례**

- nix-darwin과 함께 쓰려면 `nix.enable = false`를 두거나 determinate 모듈의 `determinateNix.enable = true`를 쓴다. 후자는 "disables nix-darwin's built-in Nix configuration for you"다. ([Determinate nix-darwin][dn])
- 사용자 설정은 `determinateNix.customSettings`로 넣고, `/etc/nix/nix.custom.conf`에 쓰인다. ([Determinate nix-darwin][dn])
- determinate-nixd GC의 기본값은 `automatic`이다. 동작은 "Retain at least 30GB of disk space free"이고, 여유 공간이 5% 아래로 내려가면 urgent 모드로 바뀐다. ([determinate-nixd][dnd])
- lazy-trees 기본값 **[미검증]**

**레포 현황**

- `lib/mksystem.nix:91-99`: `customSettings = cacheSettings`와 `garbageCollector.strategy = "automatic"`을 설정한다.
- 같은 파일에서 Darwin은 `nix.settings`와 `nix.gc`를 끈다.

**판정**: 일치.

**권장**

- `strategy = "automatic"`은 기본값이라 지워도 동작이 같다. 의도를 드러내려고 남겨 두는 것도 괜찮다.
- `customSettings`의 trusted-users도 2절과 같이 줄인다.

## 4. GC와 스토어 최적화

**모범 사례** ([nix.conf][conf])

- `auto-optimise-store`는 같은 파일을 "replaces them with hard links"로 합친다. 기본값은 `false`다.
- `keep-outputs`의 기본값은 `false`, `keep-derivations`의 기본값은 `true`다.
- NixOS의 `nix.gc`, `nix.optimise`, `nh clean` 의미 **[미검증]**

**레포 현황**

- `lib/mksystem.nix:68-72`: Linux는 매일 `--delete-older-than 7d`로 GC한다.
- `machines/nixos/vm-shared.nix:35-41`: `extraOptions` 문자열로 experimental-features, `keep-outputs = true`, `keep-derivations = true`를 넣는다.
- `machines/nixos/wsl.nix`: experimental-features를 `nix.settings` 형태로 넣는다. VM과 형식이 다르다.

**판정**: 채택 고려.

**권장**

1. VM 설정을 `nix.settings`로 옮겨 WSL과 형식을 맞춘다.
2. `keep-derivations`는 기본값과 같으므로 지운다.
3. `keep-outputs`를 켜 두면 GC로 회수되는 공간이 줄어든다. 유지할지 판단한다. (추론)

## 5. input follows와 lock 관리

**모범 사례**

- `follows`의 목적은 "This is useful to minimize flake dependencies."다. ([nix flake][flake])
- 트레이드오프: 상위 flake가 테스트하지 않은 nixpkgs와 조합될 수 있다. (추론)
- Renovate nix 매니저와 update-flake-lock **[미검증]**

**레포 현황**

- `flake.nix:21-85`: 거의 모든 입력이 `follows = "nixpkgs"`이고, nixpkgs는 unstable이다.
- `flake.nix:57`: direnv-instant는 특정 커밋에 고정돼 있다.
- `renovate.json`: `lockFileMaintenance`를 automerge한다.

**판정**: 일치.

**권장**

1. direnv-instant를 커밋에 고정한 이유를 주석으로 남긴다.
2. automerge는 CI `make test-build`가 required check일 때만 안전하다. 해당 설정을 확인한다. (추론)

## 6. 시크릿 관리: sops-nix와 agenix

**비교**

| 항목         | [sops-nix][sops]                                                        | [agenix][age]                   |
| :----------- | :---------------------------------------------------------------------- | :------------------------------ |
| NixOS        | 지원                                                                    | 지원                            |
| nix-darwin   | "A module for `nix-darwin` is also available"                           | README에 언급 없음 **[미검증]** |
| Home Manager | 지원                                                                    | 지원                            |
| 키           | GPG 또는 age 키. `ssh-to-age`로 SSH 키를 변환할 수 있음                 | SSH 공개키                      |
| 복호화 위치  | 활성화 시점. 시스템은 `/run/secrets`, HM은 `$XDG_RUNTIME_DIR/secrets.d` | 활성화 시점                     |

**레포 현황**: 시크릿 모듈이 없다. CI 토큰은 GitHub Secrets의 `CACHIX_AUTH_TOKEN`만 쓴다.

**판정과 권장**: 관리할 비밀이 생겼을 때만 도입한다. 그때는 세 플랫폼 지원이 문서에 모두 명시된 sops-nix를 고른다.

## 7. 테스트와 CI

**모범 사례** ([nix flake check][check])

- `checks`를 빌드하고 `nixosConfigurations.<name>.config.system.build.toplevel`을 평가한다.
- `--no-build`를 붙이면 checks를 빌드하지 않는다.
- nixosTest, magic-nix-cache **[미검증]**

**레포 현황**

- KVM이 없으면 `--no-build`로 대체한다.
- 이 경우 assertion이 실행되지 않으므로 CI에서 `cachix watch-exec ... make test-build`로 실제로 빌드해 보완한다.

**판정**: 일치. 지금 방식을 유지한다.

## 출처

- https://nix.dev/manual/nix/latest/command-ref/conf-file
- https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake
- https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-check
- https://flake.parts/options/flake-parts.html
- https://docs.determinate.systems/guides/nix-darwin
- https://docs.determinate.systems/determinate-nix/determinate-nixd
- https://github.com/Mic92/sops-nix
- https://github.com/ryantm/agenix

[conf]: https://nix.dev/manual/nix/latest/command-ref/conf-file
[flake]: https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake
[check]: https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-check
[fp]: https://flake.parts/options/flake-parts.html
[dn]: https://docs.determinate.systems/guides/nix-darwin
[dnd]: https://docs.determinate.systems/determinate-nix/determinate-nixd
[sops]: https://github.com/Mic92/sops-nix
[age]: https://github.com/ryantm/agenix
