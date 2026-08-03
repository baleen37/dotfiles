# Nix 아키텍처 베스트 프랙티스 리팩토링 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** x86_64-darwin을 제거하고 pure flake 평가, typed host metadata, 단계적인 perSystem/withSystem 중앙화를 도입한다.

**Architecture:** systems는 aarch64-darwin, x86_64-linux, aarch64-linux만 유지한다. 호스트는 public flake.hosts output이 아니라 options.dotfiles.hosts 내부 option으로 선언한다. systems.nix가 class별 system output을 생성하고, standalone Home Manager는 withSystem의 per-system pkgs를 사용한다.

**Tech Stack:** Nix 2.32.4, flake-parts, nix-darwin, Home Manager, NixOS modules, treefmt-nix, pre-commit, Make.

## Global Constraints

- builtins.getEnv "USER"를 제거하고 일반 평가 명령에서 --impure를 제거한다.
- 기존 호스트 5개와 Home Manager profile 4개를 유지한다.
- nix run .#test-vm의 SSH port 2222와 testuser/test password 계약을 유지한다.
- trusted-users 변경은 read-only preflight와 non-root smoke 뒤에만 한다.
- 실제 make switch와 live Darwin activation은 실행하지 않는다.
- 각 task는 검증 후 독립 커밋한다.

## 변경 파일 지도

- flake.nix, flake.lock: 지원 systems와 nixos-generators input 정리
- flake-modules/args.nix: resolveUser 제거, per-system pkgs
- flake-modules/hosts.nix: typed dotfiles.hosts option
- flake-modules/systems.nix, lib/mksystem.nix: metadata 소비와 machineModules 전달
- flake-modules/home.nix: withSystem Home Manager
- flake-modules/dev-shells.nix, packages.nix: formatter와 native VM
- Makefile, .envrc, .github/workflows/ci.yml: pure command boundary
- README.md, CONTRIBUTING.md, CLAUDE.md, tests/README.md: 현재 문서 정합성
- tests/unit/evaluation-boundary-test.nix, host-metadata-test.nix, per-system-pkgs-test.nix, test-vm-package-test.nix: 신규 source/evaluation guards
- tests/integration/machine-builds-test.nix, tests/unit/makefile-switch-commands-test.nix, cache-config-test.nix: 기존 contract 보강

## Task 1: 지원 시스템과 pure 사용자 경계

**Files:** flake.nix, flake-modules/args.nix, .envrc, Makefile, CI workflow, 현재 문서, tests/unit/evaluation-boundary-test.nix 신규, makefile-switch-commands-test.nix.

**Produces:** systems 세트와 HM_USER 선택자.

- [ ] Step 1: evaluation-boundary-test.nix에 실패 assertion 작성

~~~nix
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  flakeSource = builtins.readFile ../../flake.nix;
  argsSource = builtins.readFile ../../flake-modules/args.nix;
  makeSource = builtins.readFile ../../Makefile;
  envrcSource = builtins.readFile ../../.envrc;
  ciSource = builtins.readFile ../../.github/workflows/ci.yml;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "evaluation-boundary" [
    (helpers.assertTest "intel-darwin-absent"
      (!(lib.hasInfix "x86_64-darwin" flakeSource)) "Intel Darwin is removed")
    (helpers.assertTest "no-flake-user-read"
      (!(lib.hasInfix "builtins.getEnv" flakeSource)
        && !(lib.hasInfix "builtins.getEnv" argsSource)) "flake is pure")
    (helpers.assertTest "no-user-injection"
      (!(lib.hasInfix "export USER=" makeSource)
        && !(lib.hasInfix "export USER=" envrcSource)
        && !(lib.hasInfix "export USER=" ciSource))
      "workflow does not inject USER")
  ];
}
~~~

makefile-switch-commands-test.nix에는 HM_USER ?=, .#$(HM_USER), --impure 부재를 검사한다.

- [ ] Step 2: 현재 실패 확인

~~~bash
nix build '.#checks.aarch64-darwin.unit-evaluation-boundary' --no-link
nix build '.#checks.aarch64-darwin.unit-makefile-switch-commands' --no-link
~~~

- [ ] Step 3: 최소 구현

flake.nix systems를 다음으로 바꾼다.

~~~nix
systems = [
  "aarch64-darwin"
  "x86_64-linux"
  "aarch64-linux"
];
~~~

.envrc는 use flake만 유지한다. args.nix에서 resolveUser와 builtins.getEnv 사용을 제거한다. Makefile에 다음을 추가하고 switch-home의 Darwin/Linux profile 선택을 모두 HM_USER로 바꾼다.

~~~make
HM_USER ?= $(shell id -un 2>/dev/null || whoami)
~~~

switch, switch-home, test, fmt-diff, test-build, test-containers에서 flake 평가에 쓰이는 --impure와 export USER를 제거한다. CI의 USER export와 closure build --impure도 제거한다. 현재 README, CONTRIBUTING, CLAUDE, tests/README의 USER 전제와 Intel Darwin 표기를 갱신한다.

- [ ] Step 4: 검증

~~~bash
nix build '.#checks.aarch64-darwin.unit-evaluation-boundary' --no-link
nix build '.#checks.aarch64-darwin.unit-makefile-switch-commands' --no-link
env -u USER nix flake check --no-build --all-systems --show-trace
make -n switch-home HM_USER=jito.hello
make -n switch-home HM_USER=baleen
~~~

Expected: 세 systems가 평가되고 dry-run에 --impure와 USER injection이 없다.

- [ ] Step 5: 커밋

~~~bash
git add flake.nix .envrc Makefile .github/workflows/ci.yml README.md CONTRIBUTING.md CLAUDE.md tests/README.md tests/unit/evaluation-boundary-test.nix tests/unit/makefile-switch-commands-test.nix
git commit -m "refactor: make flake evaluation pure"
~~~

## Task 2: Typed internal host metadata

**Files:** flake-modules/args.nix, hosts.nix, systems.nix, lib/mksystem.nix, machine-builds-test.nix, 신규 host-metadata-test.nix, 현재 host 문서.

**Produces:** config.dotfiles.hosts와 explicit user mapping.

- [ ] Step 1: host-metadata-test.nix 작성

lib.evalModules로 hosts.nix를 평가하고 다음 summary가 정확히 일치하는지 검사한다.

~~~nix
{
  macbook-pro = { system = "aarch64-darwin"; class = "darwin"; user = "baleen"; };
  baleen-macbook = { system = "aarch64-darwin"; class = "darwin"; user = "baleen"; };
  kakaostyle-jito = { system = "aarch64-darwin"; class = "darwin"; user = "jito.hello"; };
  vm-aarch64-utm = { system = "aarch64-linux"; class = "nixos"; user = "baleen"; };
  vm-x86_64-utm = { system = "x86_64-linux"; class = "nixos"; user = "baleen"; };
}
~~~

또한 모든 machineModules가 non-empty이고 x86_64-darwin이 없는지 검사한다.

- [ ] Step 2: 실패 확인

~~~bash
nix build '.#checks.aarch64-darwin.unit-host-metadata' --no-link
~~~

- [ ] Step 3: schema와 host 선언 구현

hosts.nix의 핵심 schema는 다음과 같다.

~~~nix
hostType = lib.types.submodule {
  options = {
    system = lib.mkOption {
      type = lib.types.enum [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    };
    class = lib.mkOption {
      type = lib.types.enum [ "darwin" "nixos" ];
    };
    user = lib.mkOption {
      type = lib.types.strMatching "[^[:space:]].*";
    };
    homeModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
    };
    machineModules = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };
  };
};
options.dotfiles.hosts = lib.mkOption {
  type = lib.types.attrsOf hostType;
  default = { };
};
~~~

각 host의 machineModules에는 Darwin common.nix 또는 대응하는 NixOS VM module을 명시한다. resolveUser와 flake.hosts를 제거한다. systems.nix는 config.dotfiles.hosts를 class로 filter하고 mksystem에 homeModules와 machineModules를 전달한다. mksystem의 machineConfig filename inference를 제거하고 전달된 machineModules를 module list에 넣는다.

- [ ] Step 4: user mapping integration assertion 추가

machine-builds-test.nix에서 Darwin output users가 baleen, baleen, jito.hello이고 NixOS output users가 baleen, baleen인지 attrset equality로 검사한다.

- [ ] Step 5: 검증과 커밋

~~~bash
nix build '.#checks.aarch64-darwin.unit-host-metadata' --no-link
nix build '.#checks.aarch64-darwin.integration-machine-builds' --no-link
env -u USER nix eval '.#darwinConfigurations.kakaostyle-jito.config.home-manager.users' --apply builtins.attrNames --json
nix flake show --all-systems
git add flake-modules/args.nix flake-modules/hosts.nix flake-modules/systems.nix lib/mksystem.nix tests/unit/host-metadata-test.nix tests/integration/machine-builds-test.nix README.md CLAUDE.md
git commit -m "refactor: make host metadata typed and internal"
~~~

Expected: unknown flake output hosts 경고가 없고 user mapping이 고정된다.

## Task 3: per-system package centralization

**Files:** flake-modules/args.nix, home.nix, home-configurations-test.nix, 신규 per-system-pkgs-test.nix.

- [ ] Step 1: failing test 작성

homeConfigurations.baleen.activationPackage가 평가되고, overlays로 import한 expected pkgs에 claude-code가 존재하는지 검사한다.

~~~nix
overlayPkgs = import inputs.nixpkgs {
  system = pkgs.stdenv.hostPlatform.system;
  overlays = import ../../lib/overlays.nix { inherit inputs; };
  config.allowUnfree = true;
};
~~~

- [ ] Step 2: 실패 확인

~~~bash
nix build '.#checks.aarch64-darwin.unit-per-system-pkgs' --no-link
~~~

- [ ] Step 3: implementation

args.nix perSystem을 다음으로 구성한다.

~~~nix
perSystem = { system, ... }: {
  _module.args = {
    inherit overlays;
    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };
  };
};
~~~

home.nix의 mkHomeConfig는 withSystem system ({ pkgs, ... }: homeManagerConfiguration { inherit pkgs; ... }) 형태로 바꾼다. 네 profile 이름과 currentSystemUser, isDarwin, shared home module은 유지한다. readOnlyPkgs는 도입하지 않는다.

- [ ] Step 4: 검증과 커밋

~~~bash
nix build '.#checks.aarch64-darwin.unit-per-system-pkgs' --no-link
nix build '.#checks.aarch64-darwin.integration-home-configurations' --no-link
env -u USER nix build '.#homeConfigurations."jito.hello".activationPackage' --no-link
env -u USER nix build '.#homeConfigurations.baleen-linux.activationPackage' --no-link
git add flake-modules/args.nix flake-modules/home.nix tests/unit/per-system-pkgs-test.nix tests/integration/home-configurations-test.nix
git commit -m "refactor: centralize per-system nixpkgs"
~~~

## Task 4: Formatter cleanup과 native NixOS VM

**Files:** flake.nix, flake.lock, dev-shells.nix, packages.nix, README.md, CLAUDE.md, 신규 test-vm-package-test.nix.

- [ ] Step 1: failing source assertions 작성

nixos-generators input 부재, packages.nix의 config.system.build.vm 존재, devShell의 nixfmt-rfc-style와 alejandra 부재를 검사한다.

- [ ] Step 2: 실패 확인

~~~bash
nix build '.#checks.aarch64-darwin.unit-test-vm-package' --no-link
~~~

- [ ] Step 3: native VM 구현

flake.nix에서 nixos-generators input을 제거하고 nix flake lock을 실행한다. dev-shells에서 두 formatter package를 제거한다. packages.nix는 기존 VM overrides와 machine module에 다음 module을 추가한다.

~~~nix
({ modulesPath, ... }: {
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
})
~~~

Linux-only package는 다음 output을 사용한다. machineModule은 기존의 system별 VM module path를 계산한다.

~~~nix
mkTestVm = system:
  let
    qemuVmModule = { modulesPath, ... }: {
      imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
    };
    machineModule = builtins.toPath (
      (toString ../machines/nixos)
      + "/vm-"
      + lib.head (lib.splitString "-" system)
      + "-utm.nix"
    );
  in
  (inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [ qemuVmModule machineModule vmOverrides ];
  }).config.system.build.vm;
~~~

- [ ] Step 4: 검증과 커밋

~~~bash
nix flake lock
nix build '.#checks.aarch64-darwin.unit-test-vm-package' --no-link
nix fmt -- --ci
nix eval '.#packages.x86_64-linux.test-vm.name'
nix eval '.#packages.aarch64-linux.test-vm.name'
git add flake.nix flake.lock flake-modules/dev-shells.nix flake-modules/packages.nix tests/unit/test-vm-package-test.nix README.md CLAUDE.md
git commit -m "refactor: use native nixos vm build"
~~~

Linux + KVM에서만 nix run .#test-vm을 실행하고 testuser port 2222 계약을 기록한다.

## Task 5: Cache data와 daemon privilege audit

**Files:** flake.nix, lib/mksystem.nix, CI/setup action, cache-config-test.nix. lib/cache-config.nix는 public cache data source로 유지한다.

- [ ] Step 1: read-only preflight

~~~bash
id -un
id -Gn
nix show-config | rg '^(trusted-users|trusted-substituters|substituters|trusted-public-keys)'
nix store ping --store 'https://baleen-nix.cachix.org'
nix store ping --store 'https://cache.nixos.org'
env -u USER nix eval '.#nixosConfigurations.vm-x86_64-utm.config.nix.settings.trusted-users' --json
env -u USER nix eval '.#nixosConfigurations.vm-x86_64-utm.config.nix.settings.trusted-substituters' --json
~~~

daemon은 변경하지 않고 결과를 기록한다.

- [ ] Step 2: cache drift test 강화

cache-config.nix에는 trusted-users/trusted-substituters가 없고, flake.nix의 top-level nixConfig는 cache file import가 아닌 literal attrset임을 검사한다. 기존 flake/CI/action substituter와 key equality 검사는 유지한다.

- [ ] Step 3: acceptance boundary 구현

accept-flake-config = true를 flake 전역에서 제거한다. cache를 의도적으로 사용하는 Make/CI 명령에만 --accept-flake-config를 명시한다. .envrc에는 넣지 않는다.

- [ ] Step 4: privilege policy 적용

preflight와 non-root smoke가 통과한 경우에만 mksystem의 cacheSettings를 다음으로 좁힌다.

~~~nix
cacheSettings = cacheConfig // {
  trusted-users = [ "root" ];
};
~~~

필요성이 증명된 특정 user만 예외로 유지하고 @admin/@wheel은 복구하지 않는다. smoke가 실패하면 현행 권한을 유지하고 실패 원인을 handoff에 기록한다.

- [ ] Step 5: 검증과 커밋

~~~bash
env -u USER nix build '.#packages.x86_64-linux.test-vm' --no-link --accept-flake-config
env -u USER nix build '.#checks.aarch64-darwin.unit-cache-config' --no-link --accept-flake-config
env -u USER nix eval '.#nixosConfigurations.vm-x86_64-utm.config.nix.settings.trusted-users' --json
git add flake.nix lib/mksystem.nix .github/workflows/ci.yml .github/actions/setup-nix/action.yml tests/unit/cache-config-test.nix
git commit -m "refactor: narrow nix cache privilege policy"
~~~

## Task 6: 문서와 matrix 정합성

**Files:** README.md, CONTRIBUTING.md, CLAUDE.md, tests/README.md, CI workflow.

- [ ] Step 1: canonical commands 갱신

~~~bash
nix flake check --no-build --all-systems --show-trace
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
make switch-home HM_USER=jito.hello
~~~

HM_USER는 standalone profile selector, dotfiles.hosts는 host system user declaration으로 설명한다.

- [ ] Step 2: current docs platform table을 Darwin aarch64-darwin, NixOS x86_64-linux/aarch64-linux으로 고친다. historical docs는 유지한다.

- [ ] Step 3: scan과 커밋

~~~bash
rg -n 'x86_64-darwin|builtins\.getEnv|resolveUser|flake\.hosts|nixfmt-rfc-style|nixos-generators' README.md CONTRIBUTING.md CLAUDE.md tests .envrc Makefile .github flake.nix flake-modules lib
rg -n -- '--impure' README.md CONTRIBUTING.md CLAUDE.md tests/README.md .envrc Makefile .github flake.nix flake-modules lib
git add README.md CONTRIBUTING.md CLAUDE.md tests/README.md .github/workflows/ci.yml
git commit -m "docs: document pure nix workflows"
~~~

Expected: current source/docs에서 금지된 항목이 없다.

## Task 7: 전체 검증과 handoff

- [ ] Step 1: format/diff

~~~bash
nix fmt -- --ci
git diff --check
git status --short
~~~

- [ ] Step 2: all-system pure evaluation

~~~bash
env -u USER nix flake check --no-build --all-systems --accept-flake-config --show-trace
env -u USER nix flake show --all-systems --accept-flake-config
~~~

Expected: 세 systems 평가, x86_64-darwin 부재, unknown flake output hosts 부재, deprecated warning 부재.

- [ ] Step 3: preserved outputs

~~~bash
for host in macbook-pro baleen-macbook kakaostyle-jito; do
  env -u USER nix build ".#darwinConfigurations.$host.system" --no-link --accept-flake-config
done
for host in vm-aarch64-utm vm-x86_64-utm; do
  env -u USER nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link --accept-flake-config
done
for profile in baleen jito.hello testuser; do
  env -u USER nix build ".#homeConfigurations.\"$profile\".activationPackage" --no-link --accept-flake-config
done
env -u USER nix build '.#homeConfigurations.baleen-linux.activationPackage' --no-link --accept-flake-config
~~~

Expected: Darwin 3개, NixOS 2개, Home Manager 4개가 평가된다.

- [ ] Step 4: Make boundary

~~~bash
make -n switch-home HM_USER=jito.hello
make -n switch-home HM_USER=baleen
make -n test-build
make -n fmt-diff
~~~

Expected: generated Nix commands에 --impure와 export USER가 없다. VM runtime은 Linux + KVM에서만 실행한다.

- [ ] Step 5: final evidence

~~~bash
git log --oneline -7
git status --short
nix flake check --no-build --all-systems --show-trace
~~~

CI evaluation, repository build evaluation, VM runtime smoke, cache privilege smoke를 별도 evidence layer로 보고한다. live Darwin activation은 이 작업에서 검증했다고 주장하지 않는다.
