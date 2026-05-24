# Sub-project 2: 머신별 프로파일 토글 (D-lite) — 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `flake.hosts`에 머신별 `homeModules` 속성을 추가하고 `lib/mksystem.nix`가 이를 home-manager에 머지하여, 머신마다 `modules.programs.*.enable` / `modules.packages.*.enable`을 자유롭게 override할 수 있게 한다.

**Architecture:** D-lite 패턴 — 호스트 메타데이터에 직접 모듈 override를 데이터로 선언, mksystem이 `lib.mkMerge`로 home-manager 사용자 모듈에 머지. self-gating 모듈(D-full)이나 별도 옵션 트리(B)는 5개 머신 규모에는 과함.

**Tech Stack:** Nix, `lib.mkMerge`, `flake-parts`의 `flake.hosts` 메타데이터.

**Spec:** `docs/superpowers/specs/2026-05-25-home-manager-module-options-design.md` — Sub-project 2

**전제 조건:** Sub-project 1 (`docs/superpowers/plans/2026-05-25-hm-modules-namespace.md`)이 완료되어 모든 모듈에 `modules.*.enable` 옵션이 존재해야 한다.

---

## 파일 구조

| 경로 | 책임 | 변경 종류 |
|---|---|---|
| `lib/mksystem.nix` | `homeModules` 인자 받아 home-manager.users에 mkMerge | 수정 |
| `flake-modules/systems.nix` | host의 `homeModules`를 mksystem으로 전달 | 수정 |
| `flake-modules/hosts.nix` | `kakaostyle-jito`에 `homeModules` 블록 추가 (예시) | 수정 |
| `tests/unit/host-overrides-test.nix` | host의 homeModules가 머신 derivation에 반영되는지 검증 | 신규 |

### Task 1: mksystem.nix에 homeModules 인자 추가

**Files:** Modify: `lib/mksystem.nix`

- [ ] **Step 1: 현재 파일 확인 — 인자 시그니처와 home-manager 블록 위치**

```bash
sed -n '1,25p' lib/mksystem.nix
```
Expected:
```nix
{
  inputs,
  self,
  overlays ? [ ],
}:

name:
{
  system,
  user,
  darwin ? false,
  wsl ? false,
}:
```

```bash
grep -n "users\.\${user}" lib/mksystem.nix
```
Expected: home-manager 통합 블록의 라인 번호.

- [ ] **Step 2: 인자에 `homeModules ? { }` 추가**

```nix
name:
{
  system,
  user,
  darwin ? false,
  wsl ? false,
  homeModules ? { },
}:
```

- [ ] **Step 3: home-manager 블록에서 `users.${user}`을 `lib.mkMerge`로 변경**

`lib/mksystem.nix`의 home-manager 블록 (대략 91~100줄)에서:

기존:
```nix
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
  users.${user} = import userHMConfig;
  extraSpecialArgs = {
    inherit inputs self;
    currentSystemUser = user;
    isDarwin = darwin;
  };
};
```

변경 후:
```nix
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
  users.${user} = lib.mkMerge [
    (import userHMConfig)
    homeModules
  ];
  extraSpecialArgs = {
    inherit inputs self;
    currentSystemUser = user;
    isDarwin = darwin;
  };
};
```

- [ ] **Step 4: diff 확인**

```bash
git diff lib/mksystem.nix
```
Expected: 정확히 3개 부분 변경 — 인자 1줄 추가, `users.${user} = import ...` → `lib.mkMerge [...]` 4줄.

- [ ] **Step 5: 평가 sanity — homeModules=빈 채로 빌드 통과**

```bash
export USER=$(whoami)
nix flake check --impure 2>&1 | tail -15
```
Expected: error 없음.

- [ ] **Step 6: Commit**

```bash
git add lib/mksystem.nix
git commit -m "feat(mksystem): accept homeModules arg and merge into home-manager.users"
```

### Task 2: systems.nix에서 homeModules 전달

**Files:** Modify: `flake-modules/systems.nix`

- [ ] **Step 1: 현재 파일 확인**

```bash
cat flake-modules/systems.nix
```
Expected: `mkDarwin`과 `mkNixos` 함수 정의.

- [ ] **Step 2: 두 함수 모두 `homeModules` 전달**

기존:
```nix
mkDarwin =
  name: h:
  mkSystem name {
    inherit (h) system user;
    darwin = true;
  };

mkNixos =
  name: h:
  mkSystem name {
    inherit (h) system user;
  };
```

변경 후:
```nix
mkDarwin =
  name: h:
  mkSystem name {
    inherit (h) system user;
    darwin = true;
    homeModules = h.homeModules or { };
  };

mkNixos =
  name: h:
  mkSystem name {
    inherit (h) system user;
    homeModules = h.homeModules or { };
  };
```

- [ ] **Step 3: 평가 — 모든 머신 여전히 빌드 가능 (homeModules 비어 있음)**

```bash
export USER=$(whoami)
nix flake check --impure 2>&1 | tail -15
```
Expected: error 없음.

- [ ] **Step 4: Commit**

```bash
git add flake-modules/systems.nix
git commit -m "feat(systems): forward host.homeModules to mksystem"
```

### Task 3: hosts.nix에 kakaostyle-jito.homeModules 추가

**Files:** Modify: `flake-modules/hosts.nix`

- [ ] **Step 1: 현재 파일 확인**

```bash
cat flake-modules/hosts.nix
```
Expected: 5개 호스트 정의.

- [ ] **Step 2: `kakaostyle-jito`에 `homeModules` 블록 추가**

기존:
```nix
kakaostyle-jito = {
  system = "aarch64-darwin";
  class = "darwin";
  user = "jito.hello";
};
```

변경 후:
```nix
kakaostyle-jito = {
  system = "aarch64-darwin";
  class = "darwin";
  user = "jito.hello";
  homeModules = {
    # 회사 macOS는 hammerspoon / karabiner를 사용하지 않는다
    modules.programs.hammerspoon.enable = false;
    modules.programs.karabiner.enable = false;
  };
};
```

- [ ] **Step 3: 빌드 확인 — kakaostyle-jito에서 hammerspoon 사라짐**

```bash
export USER=$(whoami)
nix build '.#darwinConfigurations.kakaostyle-jito.system' --impure --no-link 2>&1 | tail -10
```
Expected: 빌드 성공.

```bash
# kakaostyle-jito의 home.file 평가에서 .hammerspoon 키 부재 확인
nix eval '.#darwinConfigurations.kakaostyle-jito.config.home-manager.users."jito.hello".home.file' --impure --apply 'f: f ? ".hammerspoon"' 2>&1 | tail -3
```
Expected: `false`.

```bash
# macbook-pro에서는 .hammerspoon 존재 확인
nix eval '.#darwinConfigurations.macbook-pro.config.home-manager.users.baleen.home.file' --impure --apply 'f: f ? ".hammerspoon"' 2>&1 | tail -3
```
Expected: `true`.

> 위 eval 명령이 home-manager 노출 경로 차이로 실패할 수 있다. 대안: 빌드한 toplevel을 inspect — `nix-store -q --references $(nix build '.#darwinConfigurations.kakaostyle-jito.system' --impure --no-link --print-out-paths) | grep hammerspoon` 결과가 비어 있는지.

- [ ] **Step 4: Commit**

```bash
git add flake-modules/hosts.nix
git commit -m "feat(hosts): disable hammerspoon/karabiner on kakaostyle-jito"
```

### Task 4: unit test — host의 homeModules가 derivation에 반영되는지

**Files:** Create: `tests/unit/host-overrides-test.nix`

- [ ] **Step 1: 테스트 작성**

```nix
# tests/unit/host-overrides-test.nix
#
# Verifies that a host's `homeModules` attribute actually overrides
# `modules.programs.*.enable` in the resulting darwin/nixos configuration.

{ pkgs, lib, inputs, self, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # The kakaostyle-jito host should have hammerspoon disabled via homeModules.
  jitoCfg =
    self.darwinConfigurations.kakaostyle-jito.config;

  hammerspoonEnabledOnJito =
    jitoCfg.home-manager.users."jito.hello".modules.programs.hammerspoon.enable;

  # By contrast, macbook-pro (no override) should keep the module-level default
  # (`pkgs.stdenv.hostPlatform.isDarwin` == true on aarch64-darwin).
  proCfg =
    self.darwinConfigurations.macbook-pro.config;

  hammerspoonEnabledOnPro =
    proCfg.home-manager.users.baleen.modules.programs.hammerspoon.enable;

in
{
  override-disables-hammerspoon = helpers.assertTest
    "kakaostyle-jito disables hammerspoon"
    (hammerspoonEnabledOnJito == false)
    "host.homeModules must override modules.programs.hammerspoon.enable to false on kakaostyle-jito";

  default-keeps-hammerspoon = helpers.assertTest
    "macbook-pro keeps hammerspoon default"
    (hammerspoonEnabledOnPro == true)
    "macbook-pro (no override) must keep hammerspoon default=true (Darwin)";
}
```

> 위 테스트는 `self.darwinConfigurations.*.config`에 접근한다. tests/default.nix가 test에 self/inputs를 전달하는지 확인 필요. `flake-modules/checks.nix`가 `import ../tests { inherit system inputs self; }`로 호출하므로 self는 전달됨.

> `homeConfigurations`도 같이 테스트하고 싶다면 검증 대상을 추가하면 되지만, MVP는 darwin 한정.

- [ ] **Step 2: 테스트 실행**

```bash
export USER=$(whoami)
nix build '.#checks.aarch64-darwin.host-overrides' --impure 2>&1 | tail -10
```
Expected: 빌드 성공.

> Linux runner나 다른 system에서는 darwin 머신 평가가 불가능할 수 있음. 그 경우 테스트가 자기 system에 맞춰 skip 처리되어야 함 — `tests/lib/platform-helpers.nix` 패턴 참조해 darwin-only로 등록.

- [ ] **Step 3: Commit**

```bash
git add tests/unit/host-overrides-test.nix
git commit -m "test(hosts): verify homeModules overrides reach darwin configurations"
```

### Task 5: 최종 검증 — 모든 머신 + macbook-pro에서 hammerspoon 살아 있음

**Files:** (검증만)

- [ ] **Step 1: 모든 머신 빌드**

```bash
export USER=$(whoami)
for h in macbook-pro baleen-macbook kakaostyle-jito; do
  echo "=== $h ==="
  nix build ".#darwinConfigurations.$h.system" --impure --no-link 2>&1 | tail -3
done
for h in vm-aarch64-utm vm-x86_64-utm; do
  echo "=== $h ==="
  nix build ".#nixosConfigurations.$h.config.system.build.toplevel" --impure --no-link 2>&1 | tail -3
done
```
Expected: 5개 모두 성공.

- [ ] **Step 2: 회귀 없는지 — macbook-pro에서 hammerspoon, karabiner 모두 존재**

```bash
export USER=$(whoami)
nix eval '.#darwinConfigurations.macbook-pro.config.home-manager.users.baleen.modules.programs.hammerspoon.enable' --impure
nix eval '.#darwinConfigurations.macbook-pro.config.home-manager.users.baleen.modules.programs.karabiner.enable' --impure
```
Expected: 둘 다 `true`.

- [ ] **Step 3: kakaostyle-jito에서 둘 다 disabled 확인**

```bash
nix eval '.#darwinConfigurations.kakaostyle-jito.config.home-manager.users."jito.hello".modules.programs.hammerspoon.enable' --impure
nix eval '.#darwinConfigurations.kakaostyle-jito.config.home-manager.users."jito.hello".modules.programs.karabiner.enable' --impure
```
Expected: 둘 다 `false`.

- [ ] **Step 4: make test 통과**

```bash
make test
```
Expected: pass.

- [ ] **Step 5: PR 준비**

```bash
git log --oneline -8
```
Expected: 4~5개 커밋. PR 생성은 별도 명령.

---

## Self-Review

**Spec coverage:**
- `homeModules` 인자 추가 ✓ (Task 1)
- `systems.nix` 전달 ✓ (Task 2)
- 예시 host에 토글 적용 ✓ (Task 3)
- unit test ✓ (Task 4)
- 최종 검증 ✓ (Task 5)

**Placeholder scan:** TBD/TODO 없음. ✓

**Type 일관성:** `homeModules`라는 이름이 Task 1, 2, 3, 4 전반에서 동일하게 사용됨. ✓

**알려진 위험:**
1. Task 3/4의 eval 경로(`config.home-manager.users.<user>.modules.programs.*`)가 home-manager의 useUserPackages/useGlobalPkgs 조합에서 실제로 노출되는지는 빌드해 봐야 안다. eval이 실패하면 derivation grep 폴백.
2. Task 4 unit test가 darwin-only 머신을 평가해야 하는데, Linux CI runner에서는 평가 자체가 안 될 수 있음. platform-helpers.nix로 darwin-only 등록 필요.
3. Sub-project 1이 완료되지 않은 채로 실행하면 `modules.programs.*` 옵션이 존재하지 않아 Task 3에서 eval 에러. 반드시 Sub-project 1 PR 머지 후 실행.
