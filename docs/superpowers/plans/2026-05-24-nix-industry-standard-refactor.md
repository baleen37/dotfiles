# Nix Flake-Parts 업계 표준 리팩토링 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** dotfiles 저장소 구조를 2025–2026년 flake-parts 업계 표준에 맞춰 단일 PR로 정비한다. `import-tree` 자동 발견, `hosts` attrset 단일 소스, `treefmt-nix` 통합, `users/shared/` 카테고리 모듈화(enable 플래그 패턴), 빈 머신 파일 제거를 포함한다.

**Architecture:** flake-parts top-level은 유지. `lib/mksystem.nix` 함수는 그대로 두고 `flake-modules/systems.nix`가 `hosts.nix` attrset을 `mapAttrs`로 펼쳐 호출. 공통 인자(`overlays`, `cacheConfig`, `resolveUser`)는 `flake-modules/args.nix`가 `_module.args`로 노출. home-manager 진입점은 카테고리별 enable-flag 모듈로 분해.

**Tech Stack:** Nix flakes, flake-parts, nix-darwin, NixOS, home-manager, treefmt-nix, import-tree (vic/import-tree).

**Spec:** `docs/superpowers/specs/2026-05-24-nix-industry-standard-refactor-design.md`

**환경 가정:**

- 작업 디렉터리: `/Users/jito.hello/dotfiles/.worktrees/00042-fuzzy-willow-wall`
- 브랜치: `fuzzy-willow-wall`
- 모든 nix 명령은 `USER=$(whoami)`이 설정된 zsh 셸에서 실행 (direnv가 자동 설정)
- Determinate Nix가 darwin에서 nix를 관리. `nix.enable = false` 유지

**커밋 규칙:** 각 Task 끝의 commit step이 하나의 커밋 = 하나의 논리적 변경. 매 커밋 직전 `nix flake check --impure`와 `make test`(macOS는 validation 모드)를 통과시킨다.

---

## Task 0: 베이스라인 검증

리팩토링 전 현재 상태가 통과하는지 확인하고 기준선을 기록한다.

**Files:** (변경 없음)

- [ ] **Step 1: 현재 브랜치/상태 확인**

```bash
cd /Users/jito.hello/dotfiles/.worktrees/00042-fuzzy-willow-wall
git status
git log --oneline -5
```

Expected: clean working tree, 최신 커밋은 spec 문서 추가 커밋.

- [ ] **Step 2: `nix flake check` 베이스라인**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -20
```

Expected: 모든 checks pass, 오류 없음.

- [ ] **Step 3: 다섯 호스트 빌드 평가**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#darwinConfigurations.macbook-pro.system.outPath' --impure --accept-flake-config --raw > /dev/null
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#darwinConfigurations.baleen-macbook.system.outPath' --impure --accept-flake-config --raw > /dev/null
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#darwinConfigurations.kakaostyle-jito.system.outPath' --impure --accept-flake-config --raw > /dev/null
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel.outPath' --impure --accept-flake-config --raw > /dev/null
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#nixosConfigurations.vm-x86_64-utm.config.system.build.toplevel.outPath' --impure --accept-flake-config --raw > /dev/null
```

Expected: 모두 종료 코드 0. 출력은 store path들 (drop됨).

- [ ] **Step 4: 패키지 목록 스냅샷 저장**

리팩토링 후 home.packages 셋이 동일한지 비교할 기준선 생성.

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#darwinConfigurations.kakaostyle-jito.config.home-manager.users."jito.hello".home.packages' \
  --impure --accept-flake-config --apply 'pkgs: builtins.sort builtins.lessThan (map (p: p.pname or p.name) pkgs)' \
  --json > /tmp/baseline-pkgs.json
wc -l /tmp/baseline-pkgs.json
```

Expected: JSON 파일 생성, non-zero 라인 수. 이 파일은 Task 8에서 비교에 사용.

베이스라인 통과를 못 하면 spec/계획 문제가 아닌 환경 문제 → 사용자에게 보고하고 중단.

---

## Task 1: treefmt-nix 도입

`flake-modules/formatter.nix`를 추가하고 nixfmt/statix/deadnix/shfmt/prettier를 단일 `nix fmt`로 통합한다. 기존 `dev-shells.nix`의 `formatter = pkgs.nixfmt-rfc-style;`는 treefmt가 대체하므로 제거.

**Files:**

- Create: `flake-modules/formatter.nix`
- Modify: `flake.nix` (treefmt-nix input 추가)
- Modify: `flake-modules/dev-shells.nix` (formatter 라인 제거)
- Modify: `Makefile` (`make format`이 `nix fmt` 호출)
- Test: `nix fmt`로 검증

- [ ] **Step 1: flake.nix에 treefmt-nix input 추가**

`flake.nix`의 `inputs` 블록에 추가. 위치는 `nixos-generators` 다음.

```nix
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: `flake-modules/formatter.nix` 작성**

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

      settings.formatter = {
        shfmt.options = [
          "-i" "2"
          "-ci"
          "-bn"
          "-sr"
        ];
        prettier.includes = [ "*.md" "*.yaml" "*.yml" "*.json" ];
      };
    };
  };
}
```

- [ ] **Step 3: flake.nix imports에 formatter.nix 추가**

`flake.nix`의 `imports` 리스트에 한 줄 추가.

```nix
      imports = [
        ./flake-modules/darwin.nix
        ./flake-modules/nixos.nix
        ./flake-modules/home.nix
        ./flake-modules/checks.nix
        ./flake-modules/dev-shells.nix
        ./flake-modules/packages.nix
        ./flake-modules/formatter.nix
      ];
```

- [ ] **Step 4: dev-shells.nix에서 conflicting formatter 제거**

`flake-modules/dev-shells.nix`에서 `formatter = pkgs.nixfmt-rfc-style;` 라인을 제거. (treefmt가 같은 출력을 등록함)

변경 전:

```nix
      formatter = pkgs.nixfmt-rfc-style;

      devShells.default = pkgs.mkShell {
```

변경 후:

```nix
      devShells.default = pkgs.mkShell {
```

- [ ] **Step 5: Makefile의 format 타겟을 nix fmt로 변경**

`Makefile`에서 `format:` 타겟을 찾아 본문을 `$(NIX) fmt`로 단순화. 기존 별도 nixfmt 호출 라인 제거.

먼저 현재 format 타겟을 확인.

```bash
grep -n -A 5 '^format:' Makefile
```

기존 본문이 nixfmt를 직접 호출하고 있으면 다음으로 교체.

```makefile
format:
	@echo "Formatting all files via treefmt..."
	$(NIX_ENV) $(NIX) fmt
```

- [ ] **Step 6: 로컬에서 nix fmt 동작 검증**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  fmt -- --no-cache 2>&1 | tail -30
```

Expected: treefmt가 실행되어 모든 파일을 검사. exit 0. 변경된 파일이 있을 수 있음.

- [ ] **Step 7: 변경된 파일을 stage하고 검증**

```bash
git status
git diff --stat
```

`.git`에 noise가 들어가지 않게 staged 파일이 의도된 것들인지 확인. 의도되지 않은 거대한 reformat이 있으면 Task 1 안에서 따로 다루지 말고 다음 별도 commit으로 분리.

- [ ] **Step 8: nix flake check 통과 확인**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10
```

Expected: 모든 checks pass. treefmt check가 새로 추가됨.

- [ ] **Step 9: Commit**

reformat된 파일이 너무 많으면 두 커밋으로 분리. 그렇지 않으면 한 번에.

```bash
git add flake.nix flake.lock flake-modules/formatter.nix flake-modules/dev-shells.nix Makefile
git commit -m "feat(format): introduce treefmt-nix as unified formatter"
```

만약 Step 6에서 대량 reformat이 발생했다면 별도 커밋:

```bash
git add -A
git commit -m "style: apply treefmt formatting baseline"
```

---

## Task 2: cache-config 동기화 점검 스크립트 추가

`flake.nix`의 `nixConfig`와 `lib/cache-config.nix`가 drift되지 않도록 pre-commit 훅용 스크립트를 추가/확인. `.pre-commit-config.yaml`에 이미 `check-cache-sync` 훅 진입점이 있으나 실제 스크립트가 있는지 확인 후 없으면 작성.

**Files:**

- Create or verify: `scripts/check-cache-sync.sh`

- [ ] **Step 1: 기존 스크립트 존재 여부 확인**

```bash
ls -la scripts/
test -f scripts/check-cache-sync.sh && echo "EXISTS" || echo "MISSING"
```

만약 EXISTS면 Task 2는 스킵하고 Task 3으로. MISSING이면 아래 Step 2로 진행.

- [ ] **Step 2: scripts/check-cache-sync.sh 작성**

```bash
#!/usr/bin/env bash
# 검증: flake.nix nixConfig.substituters/trusted-public-keys가
# lib/cache-config.nix의 값과 일치하는지 확인.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

extract_list() {
  local file="$1" key="$2"
  awk -v k="$key" '
    $0 ~ k "[[:space:]]*=" { in_list=1; next }
    in_list && /\]/ { in_list=0 }
    in_list { gsub(/[",]/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length) print }
  ' "$file" | sort -u
}

for key in substituters trusted-public-keys; do
  a="$(extract_list flake.nix "$key")"
  b="$(extract_list lib/cache-config.nix "$key")"
  if [[ "$a" != "$b" ]]; then
    echo "DRIFT in $key:" >&2
    diff <(echo "$a") <(echo "$b") >&2 || true
    exit 1
  fi
done

echo "cache-config sync OK"
```

- [ ] **Step 3: 실행 권한 부여 및 동작 확인**

```bash
chmod +x scripts/check-cache-sync.sh
scripts/check-cache-sync.sh
```

Expected: `cache-config sync OK` 출력, exit 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-cache-sync.sh
git commit -m "chore: add cache-config drift check script"
```

---

## Task 3: `args.nix`로 공통 인자 노출

`overlays`, `cacheConfig`, `resolveUser`를 `_module.args`로 노출해서 darwin/nixos/home 모듈의 중복 import를 제거한다. `lib/overlays.nix`는 유지(다른 곳에서 함수로 쓸 수 있게)하되 모듈에서는 인자로 받는다.

**Files:**

- Create: `flake-modules/args.nix`
- Modify: `flake.nix` (imports에 args.nix 추가, formatter.nix 다음)
- Modify: `flake-modules/darwin.nix` (overlays 인자로 받기, mkSystem import 인자 단순화)
- Modify: `flake-modules/nixos.nix` (동일)
- Modify: `flake-modules/home.nix` (동일)

- [ ] **Step 1: flake-modules/args.nix 작성**

`overlays`는 flake-level과 perSystem 양쪽에서 인자로 보여야 한다 (systems.nix는 flake-level, packages는 perSystem에서 쓰일 수 있음).

```nix
{ inputs, lib, ... }:
let
  overlays = import ../lib/overlays.nix { inherit inputs; };
in
{
  perSystem = { ... }: {
    _module.args.overlays = overlays;
  };

  _module.args = {
    inherit overlays;
    cacheConfig = import ../lib/cache-config.nix;
    resolveUser =
      fallback:
      let
        env = builtins.getEnv "USER";
      in
      if env != "" && env != "root" then env else fallback;
  };
}
```

- [ ] **Step 2: flake.nix imports에 args.nix 추가**

`imports` 리스트 맨 앞에 추가 (다른 모듈이 args를 받을 수 있도록).

```nix
      imports = [
        ./flake-modules/args.nix
        ./flake-modules/darwin.nix
        ./flake-modules/nixos.nix
        ./flake-modules/home.nix
        ./flake-modules/checks.nix
        ./flake-modules/dev-shells.nix
        ./flake-modules/packages.nix
        ./flake-modules/formatter.nix
      ];
```

- [ ] **Step 3: flake-modules/darwin.nix 리팩토링**

`overlays`를 인자로 받고 `resolveUser` 헬퍼를 사용. 변경 전 17줄에서 변경 후 ~25줄.

변경 전:

```nix
{ inputs, self, ... }:

let
  overlays = import ../lib/overlays.nix { inherit inputs; };
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  user =
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" && envUser != "root" then envUser else "baleen";
in
{
  flake.darwinConfigurations = {
    macbook-pro = mkSystem "macbook-pro" { ... };
    ...
  };
}
```

변경 후:

```nix
{ inputs, self, overlays, resolveUser, ... }:

let
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };
  user = resolveUser "baleen";
in
{
  flake.darwinConfigurations = {
    macbook-pro = mkSystem "macbook-pro" {
      system = "aarch64-darwin";
      user = user;
      darwin = true;
    };

    baleen-macbook = mkSystem "baleen-macbook" {
      system = "aarch64-darwin";
      user = user;
      darwin = true;
    };

    kakaostyle-jito = mkSystem "kakaostyle-jito" {
      system = "aarch64-darwin";
      user = "jito.hello";
      darwin = true;
    };
  };
}
```

- [ ] **Step 4: flake-modules/nixos.nix 리팩토링**

변경 후:

```nix
{ inputs, self, overlays, resolveUser, ... }:

let
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };
  user = resolveUser "baleen";
in
{
  flake.nixosConfigurations = {
    vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
      system = "aarch64-linux";
      user = user;
    };

    vm-x86_64-utm = mkSystem "vm-x86_64-utm" {
      system = "x86_64-linux";
      user = user;
    };
  };
}
```

- [ ] **Step 5: flake-modules/home.nix 리팩토링**

`overlays`만 인자로 변경. 나머지는 그대로.

변경 전:

```nix
{ inputs, self, ... }:

let
  nixpkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  overlays = import ../lib/overlays.nix { inherit inputs; };
  ...
```

변경 후:

```nix
{ inputs, self, overlays, ... }:

let
  nixpkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  ...
```

- [ ] **Step 6: 빌드 검증**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10

USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#darwinConfigurations.kakaostyle-jito.system.outPath' --impure --accept-flake-config --raw > /dev/null
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel.outPath' --impure --accept-flake-config --raw > /dev/null
```

Expected: 모두 성공.

- [ ] **Step 7: Commit**

```bash
git add flake.nix flake-modules/args.nix flake-modules/darwin.nix flake-modules/nixos.nix flake-modules/home.nix
git commit -m "refactor(flake-modules): expose overlays/cacheConfig/resolveUser via _module.args"
```

---

## Task 4: `hosts.nix` + `systems.nix` 도입

기존 `darwin.nix`와 `nixos.nix`를 단일 `systems.nix`로 통합. 호스트 정의는 `hosts.nix`로 분리.

**Files:**

- Create: `flake-modules/hosts.nix`
- Create: `flake-modules/systems.nix`
- Delete: `flake-modules/darwin.nix`
- Delete: `flake-modules/nixos.nix`
- Modify: `flake.nix` (imports 갱신)

- [ ] **Step 1: flake-modules/hosts.nix 작성**

```nix
{ resolveUser, ... }:
{
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

- [ ] **Step 2: flake-modules/systems.nix 작성**

```nix
{
  inputs,
  self,
  lib,
  config,
  overlays,
  ...
}:

let
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  hostsByClass =
    cls: lib.filterAttrs (_: h: h.class == cls) config.flake.hosts;

  mkDarwin = name: h:
    mkSystem name {
      inherit (h) system user;
      darwin = true;
    };

  mkNixos = name: h:
    mkSystem name {
      inherit (h) system user;
    };
in
{
  flake.darwinConfigurations = lib.mapAttrs mkDarwin (hostsByClass "darwin");
  flake.nixosConfigurations = lib.mapAttrs mkNixos (hostsByClass "nixos");
}
```

- [ ] **Step 3: 기존 darwin.nix/nixos.nix 삭제**

```bash
git rm flake-modules/darwin.nix flake-modules/nixos.nix
```

- [ ] **Step 4: flake.nix imports 갱신**

`imports`에서 darwin.nix/nixos.nix 제거하고 hosts.nix/systems.nix 추가.

```nix
      imports = [
        ./flake-modules/args.nix
        ./flake-modules/hosts.nix
        ./flake-modules/systems.nix
        ./flake-modules/home.nix
        ./flake-modules/checks.nix
        ./flake-modules/dev-shells.nix
        ./flake-modules/packages.nix
        ./flake-modules/formatter.nix
      ];
```

- [ ] **Step 5: 다섯 호스트 빌드 평가**

```bash
for host in macbook-pro baleen-macbook kakaostyle-jito; do
  echo "=== $host ==="
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#darwinConfigurations.${host}.system.outPath" --impure --accept-flake-config --raw > /dev/null
done
for host in vm-aarch64-utm vm-x86_64-utm; do
  echo "=== $host ==="
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#nixosConfigurations.${host}.config.system.build.toplevel.outPath" --impure --accept-flake-config --raw > /dev/null
done
```

Expected: 모두 종료 코드 0. 다섯 줄의 `=== <host> ===` 출력.

- [ ] **Step 6: flake check 통과 확인**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10
```

Expected: 모든 checks pass.

- [ ] **Step 7: Commit**

```bash
git add flake.nix flake-modules/hosts.nix flake-modules/systems.nix
git commit -m "refactor(flake-modules): unify darwin/nixos into hosts attrset + systems module"
```

---

## Task 5: 빈 머신 파일 제거 + `mksystem.nix` 경로 단순화

`machines/macbook-pro.nix`, `baleen-macbook.nix`, `kakaostyle-jito.nix`는 모두 `./darwin-common.nix`만 import하는 빈 파일이다. 제거하고 `lib/mksystem.nix`가 darwin 호스트에 대해 직접 `machines/darwin/common.nix`를 import하도록 단순화. `machines/darwin-common.nix`는 `machines/darwin/common.nix`로 이동.

**Files:**

- Create: `machines/darwin/common.nix` (기존 `machines/darwin-common.nix` 이동)
- Delete: `machines/darwin-common.nix`
- Delete: `machines/macbook-pro.nix`
- Delete: `machines/baleen-macbook.nix`
- Delete: `machines/kakaostyle-jito.nix`
- Modify: `lib/mksystem.nix:21-22` (`machineConfig` 결정 로직)

- [ ] **Step 1: machines/darwin/ 디렉터리 생성 및 common.nix 이동**

```bash
mkdir -p machines/darwin
git mv machines/darwin-common.nix machines/darwin/common.nix
```

- [ ] **Step 2: lib/mksystem.nix의 machineConfig 경로 수정**

변경 전 (line 19-22):

```nix
  osConfig = if darwin then "darwin.nix" else "nixos.nix";

  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;
  userOSConfig = ../users/shared/${osConfig};
  machineConfig = if darwin then ../machines/${name}.nix else ../machines/nixos/${name}.nix;
```

변경 후:

```nix
  osConfig = if darwin then "darwin.nix" else "nixos.nix";

  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;
  userOSConfig = ../users/shared/${osConfig};

  # darwin: 모든 호스트가 공유 common 모듈을 사용 (호스트별 차이는 hosts.nix에서 표현)
  # nixos: 호스트별 .nix 파일 유지
  machineConfig =
    if darwin
    then ../machines/darwin/common.nix
    else ../machines/nixos/${name}.nix;
```

- [ ] **Step 3: 빈 머신 파일 삭제**

```bash
git rm machines/macbook-pro.nix machines/baleen-macbook.nix machines/kakaostyle-jito.nix
```

- [ ] **Step 4: 빌드 검증**

```bash
for host in macbook-pro baleen-macbook kakaostyle-jito; do
  echo "=== $host ==="
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#darwinConfigurations.${host}.system.outPath" --impure --accept-flake-config --raw > /dev/null
done
for host in vm-aarch64-utm vm-x86_64-utm; do
  echo "=== $host ==="
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#nixosConfigurations.${host}.config.system.build.toplevel.outPath" --impure --accept-flake-config --raw > /dev/null
done
```

Expected: 모두 종료 코드 0.

- [ ] **Step 5: flake check 통과**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10
```

- [ ] **Step 6: Commit**

```bash
git add machines/ lib/mksystem.nix
git commit -m "refactor(machines): drop empty host files, move darwin-common to machines/darwin/"
```

---

## Task 6: `users/shared/` 카테고리화 — programs/ 와 darwin/ 이동

먼저 위치 이동만 한다(코드 변경 없음). 다음 Task에서 packages만 분해. 위험을 줄이기 위해 두 단계로 나눈다.

**Files:**

- Move: `users/shared/{git,vim,starship,tmux,claude-code,codex,opencode,ghostty,hammerspoon,karabiner}.nix` → `users/shared/programs/`
- Move: `users/shared/zsh/` → `users/shared/programs/zsh/`
- Move: `users/shared/darwin.nix` → `users/shared/darwin/default.nix`
- Move: `users/shared/darwin-homebrew.nix` → `users/shared/darwin/homebrew.nix`
- Move: `users/shared/darwin-scripts.nix` → `users/shared/darwin/scripts.nix`
- Modify: `users/shared/home-manager.nix` (imports 경로 갱신)
- Modify: `users/shared/darwin/default.nix` (imports 경로 갱신)
- Modify: `lib/mksystem.nix` (userOSConfig 경로 갱신)

- [ ] **Step 1: 디렉터리 생성 및 programs 파일 이동**

```bash
mkdir -p users/shared/programs users/shared/darwin

for f in git vim starship tmux claude-code codex opencode ghostty hammerspoon karabiner; do
  git mv users/shared/${f}.nix users/shared/programs/${f}.nix
done
git mv users/shared/zsh users/shared/programs/zsh
```

- [ ] **Step 2: darwin 파일 이동**

```bash
git mv users/shared/darwin.nix users/shared/darwin/default.nix
git mv users/shared/darwin-homebrew.nix users/shared/darwin/homebrew.nix
git mv users/shared/darwin-scripts.nix users/shared/darwin/scripts.nix
```

- [ ] **Step 3: users/shared/home-manager.nix의 imports 경로 갱신**

기존 imports 블록:

```nix
  imports = [
    ./git.nix
    ./vim.nix
    ./zsh
    ./starship.nix
    ./tmux.nix
    ./claude-code.nix
    ./codex.nix
    ./opencode.nix
    ./ghostty.nix
    ./hammerspoon.nix
    ./karabiner.nix
  ];
```

변경 후:

```nix
  imports = [
    ./programs/git.nix
    ./programs/vim.nix
    ./programs/zsh
    ./programs/starship.nix
    ./programs/tmux.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/ghostty.nix
    ./programs/hammerspoon.nix
    ./programs/karabiner.nix
  ];
```

- [ ] **Step 4: users/shared/darwin/default.nix의 imports 경로 갱신**

기존:

```nix
  imports = [
    ./darwin-homebrew.nix
    ./darwin-scripts.nix
  ];
```

변경 후:

```nix
  imports = [
    ./homebrew.nix
    ./scripts.nix
  ];
```

- [ ] **Step 5: lib/mksystem.nix의 userOSConfig 경로 갱신**

`osConfig = if darwin then "darwin.nix" else "nixos.nix";`이 darwin인 경우 `users/shared/darwin.nix`를 가리키는데, 이제 `users/shared/darwin/default.nix`로 바뀌었다. nix는 `default.nix`를 자동 해석하므로 디렉터리 경로만 주면 된다.

변경 전:

```nix
  osConfig = if darwin then "darwin.nix" else "nixos.nix";

  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;
  userOSConfig = ../users/shared/${osConfig};
```

변경 후:

```nix
  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;
  userOSConfig =
    if darwin
    then ../users/shared/darwin
    else ../users/shared/nixos.nix;
```

NOTE: `users/shared/nixos.nix`는 현재 존재하지 않는다. 이 경우 기존 `builtins.pathExists` 가드가 처리하므로 동작 변경 없음.

- [ ] **Step 6: 빌드 검증**

```bash
for host in macbook-pro kakaostyle-jito; do
  echo "=== $host ==="
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#darwinConfigurations.${host}.system.outPath" --impure --accept-flake-config --raw > /dev/null
done
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel.outPath' --impure --accept-flake-config --raw > /dev/null

USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10
```

Expected: 모두 성공. 이 단계는 코드 변경 0줄, 경로 이동만이므로 동등성이 깨지면 import 경로 누락이 원인.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor(users): organize home modules into programs/ and darwin/ subdirs"
```

---

## Task 7: `users/shared/packages/` 카테고리 모듈 + enable 플래그 분해

`users/shared/home-manager.nix`의 인라인 packages 리스트를 카테고리별 모듈로 분해. NixOS 모듈 스타일 `myHome.packages.<category>.enable` 옵션 도입.

**Files:**

- Create: `users/shared/packages/core.nix`
- Create: `users/shared/packages/dev.nix`
- Create: `users/shared/packages/lsp.nix`
- Create: `users/shared/packages/nix-tools.nix`
- Create: `users/shared/packages/cloud.nix`
- Create: `users/shared/packages/security.nix`
- Create: `users/shared/packages/ssh.nix`
- Create: `users/shared/packages/media.nix`
- Create: `users/shared/packages/fonts.nix`
- Create: `users/shared/packages/databases.nix`
- Modify: `users/shared/home-manager.nix` (packages 리스트 제거, imports 추가)

- [ ] **Step 1: users/shared/packages/core.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.core;
in
{
  options.myHome.packages.core.enable =
    lib.mkEnableOption "core utilities" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wget
      curl
      zip
      unzip
      tree
      htop
      jq
      ripgrep
      fd
      bat
      eza
      fzf
    ];
  };
}
```

- [ ] **Step 2: users/shared/packages/dev.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.dev;
in
{
  options.myHome.packages.dev.enable =
    lib.mkEnableOption "development tools" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs_22
      bun
      python3
      python3Packages.pipx
      virtualenv
      uv
      direnv
      pre-commit
      vscode
      gnumake
      cmake
    ];
  };
}
```

- [ ] **Step 3: users/shared/packages/lsp.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.lsp;
in
{
  options.myHome.packages.lsp.enable =
    lib.mkEnableOption "LSP servers" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      lua-language-server
      gopls
      go
      typescript-language-server
      pyright
    ];
  };
}
```

- [ ] **Step 4: users/shared/packages/nix-tools.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.nix-tools;
in
{
  options.myHome.packages.nix-tools.enable =
    lib.mkEnableOption "Nix tooling" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nixfmt
      statix
      deadnix
    ];
  };
}
```

- [ ] **Step 5: users/shared/packages/cloud.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.cloud;
in
{
  options.myHome.packages.cloud.enable =
    lib.mkEnableOption "cloud CLI tools" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      act
      gh
      awscli2
    ];
  };
}
```

- [ ] **Step 6: users/shared/packages/security.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.security;
in
{
  options.myHome.packages.security.enable =
    lib.mkEnableOption "secrets tooling" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
    ];
  };
}
```

- [ ] **Step 7: users/shared/packages/ssh.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.ssh;
in
{
  options.myHome.packages.ssh.enable =
    lib.mkEnableOption "SSH/remote tooling" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mosh
      teleport
      sshpass
    ];
  };
}
```

- [ ] **Step 8: users/shared/packages/media.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.media;
in
{
  options.myHome.packages.media.enable =
    lib.mkEnableOption "media tooling" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg
    ];
  };
}
```

- [ ] **Step 9: users/shared/packages/fonts.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.fonts;
in
{
  options.myHome.packages.fonts.enable =
    lib.mkEnableOption "developer fonts" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      noto-fonts-cjk-sans
      cascadia-code
      d2coding
    ];
  };
}
```

- [ ] **Step 10: users/shared/packages/databases.nix 작성**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.databases;
in
{
  options.myHome.packages.databases.enable =
    lib.mkEnableOption "database CLIs" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      postgresql
      sqlite
    ];
  };
}
```

- [ ] **Step 11: AI/CLI 도구 처리**

기존 home-manager.nix는 `claude-code`, `opencode`, `gemini-cli`를 home.packages에 넣었다. 단, `programs/claude-code.nix`와 `programs/opencode.nix`가 이미 별도 모듈로 존재한다. 중복 방지를 위해 packages 카테고리로는 **gemini-cli만** 분리한다.

`users/shared/packages/ai.nix` 작성:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.ai;
in
{
  options.myHome.packages.ai.enable =
    lib.mkEnableOption "AI CLI tools" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
      opencode
      gemini-cli
    ];
  };
}
```

(주의: `programs/claude-code.nix`가 패키지 자체를 설치하지 않고 설정만 한다면 ai.nix에서 패키지를 제공해야 함. Task 0 베이스라인에서 claude-code/opencode가 home.packages에 있는지 확인된 상태.)

- [ ] **Step 12: users/shared/home-manager.nix 갱신**

`home.packages` 리스트를 제거하고 `imports`에 packages/ 추가.

기존 home-manager.nix의 imports 블록과 home.packages를 다음과 같이 교체.

```nix
{
  pkgs,
  inputs,
  currentSystemUser,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

{
  imports = [
    # Tool configurations (programs)
    ./programs/git.nix
    ./programs/vim.nix
    ./programs/zsh
    ./programs/starship.nix
    ./programs/tmux.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/ghostty.nix
    ./programs/hammerspoon.nix
    ./programs/karabiner.nix

    # Package categories (enable-flag pattern; all default to true)
    ./packages/core.nix
    ./packages/dev.nix
    ./packages/lsp.nix
    ./packages/nix-tools.nix
    ./packages/cloud.nix
    ./packages/security.nix
    ./packages/ssh.nix
    ./packages/media.nix
    ./packages/fonts.nix
    ./packages/databases.nix
    ./packages/ai.nix
  ];

  home = {
    username = currentSystemUser;
    homeDirectory =
      if isDarwin then "/Users/${currentSystemUser}" else "/home/${currentSystemUser}";
    stateVersion = "24.11";
  };

  xdg.enable = true;
}
```

- [ ] **Step 13: 패키지 셋 동등성 검증 (중요)**

리팩토링 후 home.packages 셋이 baseline과 동일한지 확인.

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  eval '.#darwinConfigurations.kakaostyle-jito.config.home-manager.users."jito.hello".home.packages' \
  --impure --accept-flake-config --apply 'pkgs: builtins.sort builtins.lessThan (map (p: p.pname or p.name) pkgs)' \
  --json > /tmp/refactored-pkgs.json

diff /tmp/baseline-pkgs.json /tmp/refactored-pkgs.json
```

Expected: `diff` 출력 없음(파일 동일). 차이가 있으면 누락된 카테고리/패키지 식별 후 보정.

- [ ] **Step 14: 빌드 검증**

```bash
for host in macbook-pro kakaostyle-jito; do
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#darwinConfigurations.${host}.system.outPath" --impure --accept-flake-config --raw > /dev/null
done

USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10
```

Expected: 모두 성공.

- [ ] **Step 15: Commit**

```bash
git add users/shared/
git commit -m "refactor(users): split home packages into enable-flag category modules"
```

---

## Task 8: `import-tree` 도입으로 `flake-modules/` 자동 발견

`davhau/import-tree` 또는 동등한 패턴으로 `flake-modules/` 디렉터리 자동 로딩. 새 모듈 파일 추가 시 `flake.nix` 수정 불필요.

`import-tree`는 NixOS 모듈을 디렉터리에서 자동 발견하는 함수다. flake-parts와 호환된다.

**Files:**

- Modify: `flake.nix` (import-tree input 추가, imports 자동화)

- [ ] **Step 1: flake.nix에 import-tree input 추가**

`inputs` 블록에 추가:

```nix
    import-tree.url = "github:vic/import-tree";
```

- [ ] **Step 2: flake.nix의 outputs 시그니처와 imports 변경**

변경 전:

```nix
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ ... ];
      imports = [
        ./flake-modules/args.nix
        ./flake-modules/hosts.nix
        ./flake-modules/systems.nix
        ./flake-modules/home.nix
        ./flake-modules/checks.nix
        ./flake-modules/dev-shells.nix
        ./flake-modules/packages.nix
        ./flake-modules/formatter.nix
      ];
    };
```

변경 후:

```nix
  outputs =
    inputs@{ flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = import-tree ./flake-modules;
    };
```

- [ ] **Step 3: lockfile 업데이트**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake lock 2>&1 | tail -10
```

Expected: `import-tree` 항목이 `flake.lock`에 추가됨.

- [ ] **Step 4: flake check + 빌드 검증**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -10

for host in macbook-pro baleen-macbook kakaostyle-jito; do
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#darwinConfigurations.${host}.system.outPath" --impure --accept-flake-config --raw > /dev/null
done
for host in vm-aarch64-utm vm-x86_64-utm; do
  USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
    eval ".#nixosConfigurations.${host}.config.system.build.toplevel.outPath" --impure --accept-flake-config --raw > /dev/null
done
```

Expected: 모두 성공.

- [ ] **Step 5: 자동 발견 검증 — 빈 테스트 모듈 추가/제거**

`flake-modules/_smoke.nix` 임시 파일 작성:

```nix
{ ... }: { }
```

flake check 재실행:

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config --no-build 2>&1 | tail -5
```

여전히 통과해야 함. 그다음 파일 제거:

```bash
rm flake-modules/_smoke.nix
```

자동 발견이 작동하지 않으면 import-tree가 점(`.`)으로 시작하는 파일을 무시할 수 있다. 그 경우 이름을 `flake-modules/smoke.nix`로 다시 시도.

- [ ] **Step 6: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat(flake): adopt import-tree for automatic flake-modules discovery"
```

---

## Task 9: 통합 검증 — `make switch` 시뮬레이션

실제 머신에 적용하기 직전 단계. `darwin-rebuild build`(switch 없이 build만)로 활성화 가능한 시스템이 빌드되는지 확인.

**Files:** (변경 없음)

- [ ] **Step 1: 모든 flake check 재실행**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure --accept-flake-config 2>&1 | tail -10
```

Expected: 모든 checks pass. validation 모드는 macOS에서 정상.

- [ ] **Step 2: make test 통과**

```bash
USER=$(whoami) make test 2>&1 | tail -15
```

Expected: validation mode 통과.

- [ ] **Step 3: 현재 머신 활성 시스템과 빌드 결과 차이 점검 (드라이런)**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  build ".#darwinConfigurations.$(hostname -s).system" --impure --accept-flake-config --no-link --print-out-paths
```

Expected: store path 출력. 빌드 실패 시 출력 보고 → 중단.

- [ ] **Step 4: nix fmt 후 변경사항 없음 확인**

```bash
USER=$(whoami) nix --extra-experimental-features 'nix-command flakes' \
  fmt 2>&1 | tail -5
git diff --stat
```

Expected: `git diff --stat` 출력 비어 있음.

- [ ] **Step 5: 사용자에게 make switch 권고**

(이 단계는 자동 실행 금지 — 사용자 직접 실행 권고)

> 본 리팩토링은 다음 사용자 액션 후 검증 완료:
>
> ```bash
> USER=$(whoami) make switch
> ```
>
> 실행 후 zsh/tmux/vim/claude-code/ghostty/hammerspoon/karabiner 동작 확인.

- [ ] **Step 6: 작업 완료 메시지**

(코드 변경 없음, 커밋 없음)

---

## Self-Review

Spec(`docs/superpowers/specs/2026-05-24-nix-industry-standard-refactor-design.md`)의 각 섹션이 plan에 의해 다뤄지는지 확인.

**Spec §3 성공 기준 ↔ plan task 매핑**

| 성공 기준                       | 다루는 Task                                                |
| ------------------------------- | ---------------------------------------------------------- |
| 1. `nix flake check` 통과       | Task 0(베이스라인), 1·3·4·5·6·7·8·9 매 단계 검증           |
| 2. `make test` 통과             | Task 9 Step 2                                              |
| 3. 다섯 호스트 빌드 성공        | Task 0 Step 3, Task 4 Step 5, Task 5 Step 4, Task 8 Step 4 |
| 4. `make switch` 결과 기능 동일 | Task 9 Step 5 (사용자 액션)                                |
| 5. `nix fmt` 단일 엔트리        | Task 1                                                     |
| 6. `flake-modules/` 자동 로딩   | Task 8                                                     |
| 7. 호스트 추가 한 줄            | Task 4 (hosts.nix)                                         |

**Spec §6 마이그레이션 순서 ↔ plan task 매핑**

| Spec 커밋                   | Plan Task                    |
| --------------------------- | ---------------------------- |
| 1. treefmt-nix 도입         | Task 1                       |
| 2. args.nix 공통 인자       | Task 3                       |
| 3. hosts.nix + systems.nix  | Task 4                       |
| 4. 빈 머신 파일 제거        | Task 5                       |
| 5. users/shared 카테고리화  | Task 6 (이동), Task 7 (분해) |
| 6. import-tree 도입         | Task 8                       |
| 7. cache-config 동기화 점검 | Task 2                       |

추가 Task: Task 0 (베이스라인), Task 9 (통합 검증) — spec에는 명시 안 됐으나 안전한 단일 PR 회귀 추적을 위해 필요.

**Placeholder scan:** TBD/TODO 없음. 각 step에 실제 코드/명령 포함. ✓

**Type/네이밍 일관성:**

- `myHome.packages.<category>.enable` — Task 7 전체에서 일관 사용 ✓
- `flake.hosts` attrset 스키마 `{ system; class; user; }` — Task 4 hosts.nix, systems.nix에서 일관 ✓
- `resolveUser` 시그니처 `fallback: string -> string` — Task 3 args.nix, Task 4 hosts.nix에서 일관 ✓
- `overlays`는 perSystem에서만 정의되어 있어 flake-level `systems.nix`에서 인자로 받을 수 있는지 확인 필요. 검토 결과: `_module.args.overlays`를 `perSystem` 안에서 선언하면 `perSystem` 인자에서만 보이고 flake-level에서는 안 보인다. **수정 필요.**

**수정:** Task 3 Step 1의 args.nix를 다음과 같이 보정.

Task 3 Step 1을 다시 확인하면 `overlays`가 `perSystem` 안의 `_module.args`로만 노출되어 있다. 하지만 `systems.nix`(Task 4)와 `darwin.nix`/`nixos.nix`(Task 3)는 flake-level 모듈이라서 `overlays`를 인자로 받지 못한다.

Task 3 Step 1을 다음으로 교체:

```nix
{ inputs, lib, ... }:
let
  overlays = import ../lib/overlays.nix { inherit inputs; };
in
{
  perSystem = { ... }: {
    _module.args.overlays = overlays;
  };

  _module.args = {
    inherit overlays;
    cacheConfig = import ../lib/cache-config.nix;
    resolveUser =
      fallback:
      let
        env = builtins.getEnv "USER";
      in
      if env != "" && env != "root" then env else fallback;
  };
}
```

이렇게 하면 flake-level과 perSystem 양쪽 모두 `overlays`를 인자로 받을 수 있다. → 이 수정을 Task 3 Step 1에 반영.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-24-nix-industry-standard-refactor.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
