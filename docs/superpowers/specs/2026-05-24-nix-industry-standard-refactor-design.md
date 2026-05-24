# Nix Flake-Parts 업계 표준 리팩토링 설계

**Date:** 2026-05-24
**Status:** Draft — 사용자 검토 대기
**Scope:** dotfiles 저장소 전체 구조 정비 (단일 PR)

## 1. 배경

이 저장소는 이미 `flake-parts`를 채택하고 있고, 모듈화·테스트·CI·캐시 인프라까지 갖춰져 있다. 다만 다음과 같은 구조적 부채가 누적되어 있다.

- `lib/mksystem.nix`는 일반 함수라서 `flake-modules/{darwin,nixos}.nix`가 매번 수동으로 `import`해서 호출한다. flake-parts 모듈 시스템의 이점을 살리지 못한다.
- `overlays`, `getEnv "USER"` 로직, `cacheConfig` import가 darwin/nixos/home 세 모듈에 중복되어 있다.
- `machines/macbook-pro.nix`, `baleen-macbook.nix`, `kakaostyle-jito.nix`가 모두 `darwin-common.nix`만 import하고 끝나는 빈 파일이다.
- `users/shared/home-manager.nix`가 142줄로 패키지 리스트 전체를 평탄하게 보유해 호스트별 토글이 불가능하다.
- `flake.nix`의 `nixConfig`와 `lib/cache-config.nix`가 수동 동기화 대상이라 drift 위험이 있다.
- `nixfmt`/`statix`/`deadnix`가 통합 포매터 없이 패키지로만 존재하며, `make format` / `pre-commit` / CI가 서로 분리된 호출 경로를 가진다.

업계 리서치(Misterio77, Mic92, evantravers, MatthiasBenaets, AlexNabokikh, srid, mrjones2014)에 따르면 2025–2026년의 dotfiles 표준은 다음으로 수렴하고 있다.

- flake-parts top-level (강한 합의)
- 호스트를 단일 attrset으로 선언하고 모듈이 `mapAttrs`로 펼치는 패턴 (명확한 수렴)
- `import-tree` 또는 동등한 자동 모듈 발견 (떠오르는 표준)
- `treefmt-nix`를 flake-parts 공식 모듈로 통합 (강한 합의)
- `home-manager.useGlobalPkgs + useUserPackages` (강한 합의 — 이미 적용됨)

본 설계는 위 업계 표준을 현 저장소에 일관성 있게 적용하기 위한 **단일 PR 마이그레이션** 계획이다.

## 2. 비목표 (Out of Scope)

- 새로운 기능 추가 (disko, sops-nix, impermanence, nh 등 도입은 별도 결정)
- 머신별 동작 변경
- Determinate Nix → 다른 Nix 구현으로 전환
- 패키지 추가/제거 (이동만 함)
- CI 외부 도구(GitHub Actions runner, Cachix 등) 변경

## 3. 성공 기준

1. `nix flake check --impure`이 변경 전후 모두 통과한다.
2. `make test`가 변경 전후 모두 통과한다.
3. 세 darwin 호스트(`macbook-pro`, `baleen-macbook`, `kakaostyle-jito`)와 두 NixOS 호스트(`vm-aarch64-utm`, `vm-x86_64-utm`)가 모두 `nix build` 성공한다.
4. `make switch`로 현재 머신에 실제 적용 시 활성화 결과가 변경 전과 기능적으로 동일하다 (설치된 패키지 셋, dock/finder/keyboard 설정, programs 설정).
5. `nix fmt` 한 명령으로 nixfmt+statix+deadnix+shfmt+prettier가 모두 실행된다.
6. `flake-modules/`에 새 `.nix` 파일을 추가하면 별도 등록 없이 자동 로딩된다 (`import-tree` 적용).
7. 새 사용자/머신을 추가할 때 `flake-modules/hosts.nix`에 한 줄만 추가하면 된다.

## 4. 최종 디렉터리 구조

```
flake.nix                          # nixConfig + inputs만, 최소화
flake-modules/                     # import-tree로 자동 발견
  args.nix                         # _module.args: overlays, cacheConfig, resolveUser
  hosts.nix                        # 호스트 attrset 단일 소스
  systems.nix                      # mkSystem 호출, darwin/nixos/home outputs 생성
  formatter.nix                    # treefmt-nix
  checks.nix                       # 기존 유지
  dev-shells.nix                   # 기존 유지
  packages.nix                     # 기존 유지 (test-vm, e2e)
lib/
  mksystem.nix                     # 함수 유지, systems.nix가 래핑
  cache-config.nix                 # SSOT
  user-info.nix                    # 기존 유지
  # overlays.nix 삭제 (args.nix로 흡수)
machines/
  darwin/
    common.nix                     # 기존 darwin-common.nix 이동
  nixos/
    vm-aarch64-utm.nix             # 기존 위치 유지
    vm-shared.nix                  # 기존 위치 유지
  # macbook-pro.nix, baleen-macbook.nix, kakaostyle-jito.nix 삭제
users/shared/
  default.nix                      # 진입점 (기존 home-manager.nix 대체)
  packages/                        # 카테고리별 enable-flag 모듈
    core.nix                       # wget curl tree ripgrep fd bat eza fzf jq ...
    dev.nix                        # nodejs bun python uv direnv pre-commit vscode
    lsp.nix                        # gopls ts-ls pyright lua-ls
    nix-tools.nix                  # nixfmt statix deadnix
    cloud.nix                      # gh awscli2 act
    security.nix                   # age sops
    ssh.nix                        # mosh teleport sshpass
    media.nix                      # ffmpeg
    fonts.nix                      # noto-cjk cascadia d2coding
    databases.nix                  # postgresql sqlite
  programs/                        # 툴 설정 그대로 이동
    git.nix vim.nix zsh/ starship.nix tmux.nix
    claude-code.nix codex.nix opencode.nix
    ghostty.nix hammerspoon.nix karabiner.nix
  darwin/                          # darwin-only 시스템 모듈
    default.nix                    # 기존 darwin.nix
    homebrew.nix                   # 기존 darwin-homebrew.nix
    scripts.nix                    # 기존 darwin-scripts.nix
```

## 5. 핵심 컴포넌트 설계

### 5.1 `flake-modules/args.nix`

`overlays`, `cacheConfig`, `resolveUser` 헬퍼를 `_module.args`로 노출해 모든 flake-parts 모듈에서 인자로 받을 수 있게 한다. `lib/overlays.nix`를 이 파일로 흡수하여 삭제.

```nix
{ inputs, ... }:
{
  perSystem = { system, ... }: {
    _module.args.overlays = import ../lib/overlays.nix { inherit inputs; };
  };
  _module.args = {
    cacheConfig = import ../lib/cache-config.nix;
    resolveUser = fallback:
      let env = builtins.getEnv "USER";
      in if env != "" && env != "root" then env else fallback;
  };
}
```

### 5.2 `flake-modules/hosts.nix`

호스트 정의의 단일 소스. 한 줄로 호스트 추가 가능.

```nix
{ resolveUser, ... }:
{
  flake.hosts = {
    macbook-pro     = { system = "aarch64-darwin"; class = "darwin"; user = resolveUser "baleen"; };
    baleen-macbook  = { system = "aarch64-darwin"; class = "darwin"; user = resolveUser "baleen"; };
    kakaostyle-jito = { system = "aarch64-darwin"; class = "darwin"; user = "jito.hello"; };
    vm-aarch64-utm  = { system = "aarch64-linux";  class = "nixos";  user = resolveUser "baleen"; };
    vm-x86_64-utm   = { system = "x86_64-linux";   class = "nixos";  user = resolveUser "baleen"; };
  };
}
```

머신별 추가 모듈이 필요하면 `extraModules = [ ./machines/foo.nix ];` 같은 필드를 attrset에 추가하면 됨.

### 5.3 `flake-modules/systems.nix`

`hosts.nix`를 받아 `mapAttrs`로 darwin/nixos configurations 생성. 기존 `darwin.nix`/`nixos.nix` 두 파일을 통합.

```nix
{ self, inputs, lib, config, overlays, ... }:
let
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };
  hosts = config.flake.hosts;
  byClass = cls: lib.filterAttrs (_: h: h.class == cls) hosts;
in
{
  flake.darwinConfigurations =
    lib.mapAttrs (name: h: mkSystem name { inherit (h) system user; darwin = true; })
      (byClass "darwin");

  flake.nixosConfigurations =
    lib.mapAttrs (name: h: mkSystem name { inherit (h) system user; })
      (byClass "nixos");
}
```

`flake-modules/home.nix`도 같은 패턴으로 `homeConfigurations`를 생성하도록 흡수 가능하지만, 현재 home outputs는 standalone 용도(testuser 포함)이므로 별도 모듈로 유지한다.

### 5.4 `flake-modules/formatter.nix`

```nix
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        shfmt.enable = true;
        prettier.enable = true;
      };
    };
  };
}
```

`make format`, `.pre-commit-config.yaml`, CI는 모두 `nix fmt` 호출로 통일.

### 5.5 `users/shared/packages/*.nix` (enable 플래그 패턴)

각 카테고리는 NixOS 모듈 스타일로 `myHome.packages.<category>.enable` 옵션을 정의한다. 모두 `default = true;`라 무동작 상태에서 기존과 동등.

```nix
# users/shared/packages/dev.nix
{ config, lib, pkgs, ... }:
let cfg = config.myHome.packages.dev;
in {
  options.myHome.packages.dev.enable = lib.mkEnableOption "development packages" // {
    default = true;
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs_22 bun python3 python3Packages.pipx virtualenv uv
      direnv pre-commit vscode gnumake cmake
    ];
  };
}
```

### 5.6 `users/shared/default.nix`

```nix
{ pkgs, currentSystemUser, isDarwin ? pkgs.stdenv.isDarwin, ... }:
{
  imports = [
    ./packages
    ./programs
  ];
  home = {
    username = currentSystemUser;
    homeDirectory = if isDarwin then "/Users/${currentSystemUser}" else "/home/${currentSystemUser}";
    stateVersion = "24.11";
  };
  xdg.enable = true;
}
```

호스트별 enable 토글이 필요해질 때 `users/shared/default.nix` 또는 호스트별 모듈에서 `myHome.packages.databases.enable = false;`로 끌 수 있다.

### 5.7 import-tree 채택

`flake.nix`에 `inputs.import-tree.url = "github:vic/import-tree";` 추가. `flake-modules/`와 `users/shared/{packages,programs}/`는 디렉터리 통째로 자동 발견되도록 한다.

```nix
# flake.nix outputs
outputs = inputs@{ flake-parts, import-tree, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
    imports = import-tree ./flake-modules;
  };
```

## 6. 마이그레이션 순서 (단일 PR 내부 커밋 단위)

작업은 단일 PR로 묶지만, 회귀 추적을 위해 다음 커밋 순서를 유지한다. 매 커밋마다 `nix flake check --impure` + `make test` 통과를 자체 검증한다.

1. **chore: treefmt-nix 도입** — `flake-modules/formatter.nix` 추가, `make format`/pre-commit이 `nix fmt` 호출하도록 변경.
2. **refactor: args.nix로 공통 인자 노출** — `lib/overlays.nix` 삭제, darwin/nixos/home 모듈에서 수동 import 제거.
3. **refactor: hosts.nix + systems.nix 도입** — `flake-modules/darwin.nix`, `nixos.nix`를 `systems.nix`로 통합. `lib/mksystem.nix`는 유지.
4. **chore: 빈 머신 파일 제거** — `machines/macbook-pro.nix`, `baleen-macbook.nix`, `kakaostyle-jito.nix` 삭제. `lib/mksystem.nix`의 `machineConfig` 로직을 `if darwin then ../machines/darwin/common.nix else ../machines/nixos/${name}.nix`로 단순화 (darwin 호스트는 모두 동일한 common을 공유, NixOS는 호스트별 파일 유지). 호스트별 추가 모듈이 필요해지면 `hosts.nix`의 `extraModules` 필드로 주입.
5. **refactor: users/shared 카테고리화** — `home-manager.nix`를 `default.nix`로 이름 변경, packages를 카테고리별 모듈로 분해. `programs/`, `darwin/` 하위 디렉터리로 이동.
6. **chore: import-tree 도입** — `flake.nix`에 `import-tree` input 추가, `flake-modules/` 자동 발견으로 전환.
7. **chore: 동기화 점검** — `flake.nix nixConfig`와 `lib/cache-config.nix` drift 검증을 위한 단순 어설션 테스트 추가.

## 7. 위험과 완화

| 위험 | 완화 |
|---|---|
| `mksystem.nix`의 `machineConfig` 경로 변경으로 빌드 깨짐 | 커밋 4에서 `machines/darwin/common.nix` 경로 수정과 함께 처리, `nix flake check`로 즉시 검증 |
| `import-tree` 외부 입력 의존 | 떠오르는 표준이지만 새 의존성. 만약 비용이 더 크다고 판단되면 커밋 6은 롤백 가능 (앞 커밋들과 독립) |
| `useGlobalPkgs` 변경 영향 | 이미 적용 상태(`lib/mksystem.nix:90`). 변경 없음 |
| `myHome.packages.*.enable` 네이밍 충돌 | `myHome` 네임스페이스 사용으로 home-manager upstream 옵션과 충돌 회피 |
| `make switch` 회귀로 머신 상태 오염 | PR 머지 직전 `--dry-run` 빌드 → 실제 `make switch` 순으로 자기 머신에서 검증 |
| Cache config drift | `lib/cache-config.nix`가 SSOT임을 README와 주석에 명시. 자동화는 후속 작업 |

## 8. 검증 체크리스트

PR 머지 전 다음을 모두 통과해야 한다.

- [ ] `USER=$(whoami) nix flake check --impure` 통과
- [ ] `make test` 통과
- [ ] `nix build .#darwinConfigurations.macbook-pro.system --impure` 성공
- [ ] `nix build .#darwinConfigurations.baleen-macbook.system --impure` 성공
- [ ] `nix build .#darwinConfigurations.kakaostyle-jito.system --impure` 성공
- [ ] `nix build .#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel --impure` 성공
- [ ] `nix build .#nixosConfigurations.vm-x86_64-utm.config.system.build.toplevel --impure` 성공
- [ ] `nix fmt` 실행 후 변경사항 없음
- [ ] 현재 머신에 `make switch` 적용 후 zsh, tmux, vim, claude-code, ghostty, hammerspoon, karabiner 정상 동작 확인
- [ ] dock/finder/keyboard 설정 변경 전후 동일 확인

## 9. 후속 작업 (별도 PR 후보)

이번 PR에서는 다루지 않지만 같은 방향에서 가치 있는 후속 작업.

- `cache-config.nix` ↔ `flake.nix nixConfig` 자동 동기화 (build-time generation 또는 lint)
- `home-manager` outputs을 `systems.nix`에 흡수
- `nh` 도입으로 `make switch` 대체 검토
- `lib/user-info.nix` ↔ `hosts.nix` 통합 검토 (사용자 메타데이터를 hosts attrset로 흡수)
- `disko`/`impermanence`/`sops-nix` 도입 검토 (NixOS VM 호스트 한정)
