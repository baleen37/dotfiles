# Home-Manager 모듈 옵션 패턴 및 머신별 프로파일 토글 설계

**Date:** 2026-05-25
**Status:** Draft — 사용자 검토 대기
**Scope:** `users/shared/programs/*`, `users/shared/packages/*`, `flake-modules/hosts.nix`, `lib/mksystem.nix`, `tests/lib/`
**Prior work:** PR #1268 (`refactor(nix): adopt flake-parts industry-standard layout`)

## 1. 배경

PR #1268로 flake-parts + import-tree + 자체 `mksystem` 팩토리 기반의 모던 레이아웃을 갖췄다. 그러나 그 위에서 다음 갭이 남아 있다.

- **A. 모듈 패턴 비대칭**: `users/shared/packages/*.nix` 11개는 `myHome.packages.<name>.enable` 옵션을 정의하지만, `users/shared/programs/*.nix` 10개는 옵션 없이 항상 활성화된다. CLAUDE.md는 "enable-flag pattern (default true)"이라고 명시하는데 실제 코드와 불일치.
- **B. 머신별 토글 부재**: `flake.homeConfigurations`와 darwin/nixos configurations 모두 동일한 `users/shared/home-manager.nix`를 import한다. `kakaostyle-jito`(회사 macOS)에서 `hammerspoon`/`karabiner`를 끄거나, baleen에서 ai 카테고리를 빼는 방법이 없다.
- **C. 테스트 헬퍼 비대**: `tests/lib/` 22개. `assertions.nix` ↔ `common-assertions.nix`, `test-helpers.nix` ↔ `test-helpers-advanced.nix`, `test-helpers-property.nix` ↔ `property-test-helpers.nix` 등 이름만 다른 중복 의심 페어가 다수.
- **D. mkEnableOption 안티패턴**: 현재 `packages/*.nix` 모두 `lib.mkEnableOption "..." // { default = true; }`를 사용. mkEnableOption은 의도상 default=false. NixOS Discourse가 안티패턴으로 지적.
- **E. 비표준 네임스페이스**: `myHome.packages.*`는 업계 어디서도 보이지 않는 이름. 업계는 `modules.*` (notusknot/hlissner), `noughty.*` (wimpysworld) 등 저장소 식별자나 일반적 `modules`를 쓴다.

## 2. 비목표 (Out of Scope)

- 새 패키지 추가/삭제 (이름·위치만 정리)
- 테스트 자체의 unit/integration 경계 재정의 (헬퍼 정리에만 집중)
- 테스트 프레임워크 교체
- `flake.lib` 외부 노출 (단일 dotfiles repo에서 ROI Low — 의식적 비채택)
- `flake.nix` `nixConfig` ↔ `lib/cache-config.nix` 중복 (nix flake 문법 제약으로 어쩔 수 없음 — 의식적 잔존)
- nixpkgs deprecation 후속 (grep 결과 사용 0건 — 액션 불필요)

## 3. 성공 기준

1. `nix flake check --impure`가 변경 전후 모두 통과.
2. `make test`가 변경 전후 모두 통과 (헬퍼 정리 후 테스트 카운트는 동일하거나 더 적게).
3. `macbook-pro`, `baleen-macbook`, `kakaostyle-jito`, `vm-aarch64-utm`, `vm-x86_64-utm` 모두 `nix build` 성공.
4. `kakaostyle-jito` 빌드 결과에 `~/.hammerspoon` 심볼릭 링크가 **없다**. `macbook-pro` 빌드 결과에 `~/.hammerspoon`이 **있다**.
5. `users/shared/programs/*.nix` 10개 모두 `modules.programs.<name>.enable` 옵션을 노출.
6. `users/shared/packages/*.nix` 11개 모두 `modules.packages.<name>.enable` 옵션을 노출.
7. `mkEnableOption "..." // { default = true; }` 패턴이 코드베이스에서 0건.
8. CLAUDE.md의 enable-flag 관련 서술이 실제 코드와 일치.

## 4. Sub-projects

본 스펙은 5개의 sub-project로 분해된다. 각각이 자체 검증 기준을 갖고, **개별 PR로 머지 가능**하다. 의존 관계는 *Sub-project 2가 1에 의존*. 나머지는 독립.

### Sub-project 1: programs/와 packages/ 모듈 옵션 패턴 통일

**목표.** 모든 `programs/*.nix`와 `packages/*.nix`를 `modules.<programs|packages>.<name>.enable` NixOS-style 모듈로 변환한다.

**표준 모듈 형태:**

```nix
# users/shared/programs/git.nix
{ config, lib, ... }:
let cfg = config.modules.programs.git;
in {
  options.modules.programs.git.enable = lib.mkEnableOption "Git configuration";

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;
      # ... (기존 설정 그대로)
    };
  };
}
```

**플랫폼 종속 모듈 (예외):**

`hammerspoon`, `karabiner`, `ghostty`는 macOS 전용. home-manager 공식 `launchd.enable`이 사용하는 패턴 그대로:

```nix
# users/shared/programs/hammerspoon.nix
{ config, lib, pkgs, ... }:
let cfg = config.modules.programs.hammerspoon;
in {
  options.modules.programs.hammerspoon.enable = lib.mkEnableOption "Hammerspoon" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    home.file.".hammerspoon" = {
      source = ./.config/hammerspoon;
      recursive = true;
      force = true;
    };
  };
}
```

> 이 예외는 "mkEnableOption은 default=false" 원칙을 어기지만, home-manager 공식이 사용하는 검증된 패턴이며 specialArgs 의존성을 줄인다 (`isDarwin` 인자 대신 `pkgs.stdenv.hostPlatform.isDarwin` 사용).

**활성화 정책.** `users/shared/home-manager.nix`에서 명시적으로 활성화. mkEnableOption의 default=false 원칙은 모듈에서 유지, 활성화는 호출자에서 한다.

```nix
# users/shared/home-manager.nix
{ ... }: {
  imports = [
    ./programs/git.nix
    ./programs/vim.nix
    # ... 기존 imports 그대로
  ];

  modules.programs = {
    git.enable = true;
    vim.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    starship.enable = true;
    claude-code.enable = true;
    codex.enable = true;
    opencode.enable = true;
    # hammerspoon, karabiner, ghostty는 모듈 default(=isDarwin)에 위임
  };

  modules.packages = {
    core.enable = true;
    dev.enable = true;
    # ... 11개 카테고리 모두
  };
}
```

**packages/ 정정.** 모든 11개 파일을 다음과 같이 정리한다:

```nix
# Before
options.myHome.packages.core.enable = lib.mkEnableOption "core utilities" // { default = true; };

# After
options.modules.packages.core.enable = lib.mkEnableOption "core utilities";
```

**검증.**
- `nix flake check --impure` 통과
- 5개 머신 모두 `nix build` 성공
- 새 unit test: `modules.programs.<name>.enable`이 10개 모두에 존재, `modules.packages.<name>.enable`이 11개 모두에 존재
- 새 unit test: `kakaostyle-jito` (또는 NixOS 머신)을 평가 시 `hammerspoon/karabiner/ghostty`의 `cfg.enable`이 falsey
- grep `// { default = true; }` 결과 0건
- CLAUDE.md의 "enable-flag pattern" 서술이 코드와 일치 (예: default가 false임을 명시, 활성화는 home-manager.nix에서)

**영향 범위.**
- `users/shared/programs/*.nix` 10개 + `users/shared/programs/zsh/default.nix` 1개 (총 11개 파일)
- `users/shared/packages/*.nix` 11개
- `users/shared/home-manager.nix` 활성화 블록 추가
- 새 unit test 2개
- CLAUDE.md 1줄 수정

---

### Sub-project 2: 머신별 프로파일 토글 (D-lite 패턴)

**전제.** Sub-project 1 완료.

**목표.** `flake.hosts`에 머신별 `homeModules` 속성을 추가하고, `mksystem`이 이를 home-manager에 머지하여 머신별로 모듈을 토글 가능하게 한다.

**구조.**

```nix
# flake-modules/hosts.nix
{ resolveUser, ... }: {
  flake.hosts = {
    macbook-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = resolveUser "baleen";
    };
    baleen-macbook = {
      system = "aarch64-darwin";
      class = "darwin";
      user = resolveUser "baleen";
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
      homeModules = {
        modules.programs.hammerspoon.enable = false;
        modules.programs.karabiner.enable = false;
      };
    };
    vm-aarch64-utm = {
      system = "aarch64-linux";
      class = "nixos";
      user = resolveUser "baleen";
    };
    vm-x86_64-utm = {
      system = "x86_64-linux";
      class = "nixos";
      user = resolveUser "baleen";
    };
  };
}
```

**`lib/mksystem.nix` 변경 (대략 8~12줄).**

```nix
# 인자에 homeModules 추가
name:
{ system, user, darwin ? false, wsl ? false,
  homeModules ? { },   # ← 추가
}:

# home-manager 통합 블록 안에서 mkMerge
{
  home-manager.users.${user} = lib.mkMerge [
    (import userHMConfig)
    homeModules           # ← 머신별 override 머지
  ];
}
```

**`flake-modules/systems.nix` 변경.**

```nix
mkDarwin = name: h: mkSystem name {
  inherit (h) system user;
  darwin = true;
  homeModules = h.homeModules or { };
};

mkNixos = name: h: mkSystem name {
  inherit (h) system user;
  homeModules = h.homeModules or { };
};
```

**검증.**
- `kakaostyle-jito` 빌드 후 `home-manager.users."jito.hello".home.file` 평가에서 `.hammerspoon` 키 부재
- `macbook-pro` 빌드 후 `home.file.".hammerspoon"` 존재
- `homeModules`가 비어 있는 머신도 정상 빌드 (기본값 `{ }`)
- 새 unit test: `flake.hosts.kakaostyle-jito.homeModules`가 머신 derivation에 반영

**영향 범위.**
- `flake-modules/hosts.nix`: `kakaostyle-jito`에 `homeModules` 블록 추가
- `flake-modules/systems.nix`: `homeModules` 전달 2줄
- `lib/mksystem.nix`: 인자 1개 + `mkMerge` 적용 (~10줄)
- 새 unit test 1개

---

### Sub-project 3: `flake.lib` 노출 — 의식적 비채택

**결정.** 본 스펙 범위에서 제외.

**근거.** 단일 dotfiles repo에서 `mkSystem` 등 helper를 외부에 노출할 사용처가 없다. 업계 표준 조사 결과 비슷한 규모의 저장소(karol-broda 등)도 `parts/lib/builders.nix`를 내부 import만 한다. 향후 별도 머신 그룹이 분리될 때 추가하면 된다. YAGNI.

---

### Sub-project 4: 테스트 헬퍼 정리

**목표.** `tests/lib/` 22개 파일 중 명백한 중복과 unused 파일을 정리한다. 도메인별 헬퍼는 건드리지 않는다.

**원칙.**
1. **실증 기반.** 각 헬퍼의 import 사용처를 `grep -rn "tests/lib/<name>" tests/`로 매핑한 후 결정. 추측으로 삭제 금지.
2. **머지 우선.** 의미가 비슷한 페어는 삭제가 아니라 머지 (assertions ↔ common-assertions, test-helpers ↔ test-helpers-advanced, property 페어).
3. **도메인 헬퍼 보존.** `claude-test-helpers`, `darwin-test-helpers`, `git-test-helpers`, `plugin-test-helpers`, `starship-test-helpers` — 도메인별 분리는 합리적이므로 보존.
4. **의심스러우면 남김.** unused처럼 보여도 grep으로 확인 안 되면 보존.

**작업 단계.**
1. **Inventory.** 각 `tests/lib/*.nix`의 export 함수 목록과 import 사용처 매핑 표 작성.
2. **머지.** 명백한 중복 페어 머지 (예상 페어 3개: assertions, test-helpers, property).
3. **삭제.** import 0건인 파일만 삭제.
4. **테스트.** `make test`, CI Linux container test 모두 통과 확인.

**검증.**
- 정리 전후 `make test-all` 결과 동일 (pass/fail 카운트 동일)
- 헬퍼 자체 unit test (`tests/unit/assertions-test.nix` 등) 모두 통과
- Inventory 표가 PR description 또는 별도 doc에 첨부됨 (어떤 파일이 어떤 결정을 받았는지 한눈에 보임)
- 머지 결정된 페어가 실제로 단일 파일로 합쳐짐 (`assertions.nix` ↔ `common-assertions.nix` 등)
- 어떤 테스트도 동작 변화 없음

**영향 범위.**
- `tests/lib/*.nix` 일부 머지·삭제
- 일부 `tests/unit/*-test.nix`, `tests/integration/*-test.nix`의 import 경로 업데이트
- 동작 변화 0

---

### Sub-project 5: 정합성 점검 (메모성)

**결정.** 별도 sub-project로 분리하지 않음. Sub-project 1 작업에 흡수.

**세부.**
- **nixpkgs deprecation 확인 완료.** `lib.types.either`, `oneOf`, `number`, `numbers.*`, `functor.wrapped` 사용 — grep 결과 **0건**. 액션 불필요.
- **CLAUDE.md 정합.** Sub-project 1의 PR에 포함.
- **`flake.nix` nixConfig 중복.** `lib/cache-config.nix`와 수동 동기화 주석이 달려 있음. nix flake 문법상 nixConfig가 import 불가하므로 회피 불가. 의식적 잔존.

## 5. 실행 순서 권장

1. **Sub-project 1** (programs/packages 모듈화) — 가장 큰 작업, 단독 PR
2. **Sub-project 4** (테스트 헬퍼 정리) — Sub-project 1과 독립, 병행 가능
3. **Sub-project 2** (머신별 토글) — Sub-project 1 완료 후, 별도 PR

Sub-project 3, 5는 PR 없음 (스펙 본문에서 결정만 기록).

## 6. 비채택안 (Considered Alternatives)

### 머신별 토글 패턴 비교

조사한 5개 저장소(Misterio77, wimpysworld, Mic92, hlissner, karol-broda)의 패턴:

| 패턴 | 빈도 | 대표 저장소 | 우리 채택? |
|---|---|---|---|
| A: 머신별 .nix 파일에서 imports + override | 3/5 | Misterio77, Mic92, karol-broda | ✗ — 현재 darwin은 `common.nix` 단일 패턴 유지가 자연스러움 |
| B: 호스트 옵션 데이터 + 모듈이 옵션 읽음 | 1/5 | hlissner | ✗ — 옵션 트리 별도 정의 필요, 비대 |
| **D-lite: hosts.nix에 modules.* 직접 override, mksystem이 mkMerge** | 채택 | (자체 변형) | ✓ — flake-parts 메타데이터 + 기존 mksystem 활용, 최소 변경 |
| D-full: 메타데이터 + self-gating 모듈 | 1/5 | wimpysworld (12 hosts) | ✗ — 12+ 호스트일 때 의미, 우리 5개에는 과함 |

### 네임스페이스 비교

- `programs.*` (upstream 네임스페이스 확장) — 충돌 위험 (`programs.git.enable`이 두 번 정의됨)
- `myHome.*` (현재 packages) — 업계 어디서도 안 보임, 비표준
- **`modules.*`** — notusknot, hlissner 등 다수 사용. 채택.
- `noughty.*` 류 (저장소 식별자) — wimpysworld가 사용하지만 큰 저장소에 어울리는 스타일.

## 7. 참고 자료

- [home-manager `launchd.enable` 패턴](https://github.com/nix-community/home-manager/blob/master/modules/launchd) — 플랫폼 종속 default 표준
- [NixOS Discourse: mkEnableOption vs mkOption](https://discourse.nixos.org/t/mkenableoption-vs-mkoption-type-bool/27736)
- [notusknot/dotfiles-nix](https://github.com/notusknot/dotfiles-nix) — `config.modules.*` 패턴
- [hlissner/dotfiles](https://github.com/hlissner/dotfiles) — 호스트 옵션 데이터 패턴 (5 hosts)
- [wimpysworld/nix-config](https://github.com/wimpysworld/nix-config) — 메타데이터 self-gating (12 hosts)
- [flake.parts 공식](https://flake.parts/) — `flake.hosts` + `mapAttrs` 패턴
- 사전 작업: PR #1268 `refactor(nix): adopt flake-parts industry-standard layout`
- 사전 스펙: `docs/superpowers/specs/2026-05-24-nix-industry-standard-refactor-design.md`
