# flake-parts Migration Design

## Overview

Plain flake에서 flake-parts로 마이그레이션하여 구조 개선, 캐시 drift 검증 자동화, CI 캐시 전략 개선을 달성한다.

## Goals

- flake.nix를 ~295줄에서 ~40줄로 축소
- genAttrs 4-platform 반복 제거 (perSystem 자동 처리)
- 캐시 설정 drift를 자동 감지
- CI 캐시 히트율 개선

## Non-Goals

- ez-configs 도입 (커스텀 mksystem.nix 유지)
- flake-parts partitions (개인 dotfiles에 과도)
- 기존 machines/, users/, tests/ 구조 변경

## Directory Structure

```
.
├── flake.nix                      # 최소: nixConfig + inputs + mkFlake (~40줄)
├── flake.lock
├── flake-modules/                 # flake-parts 모듈들
│   ├── darwin.nix                 # flake.darwinConfigurations
│   ├── nixos.nix                  # flake.nixosConfigurations
│   ├── home.nix                   # flake.homeConfigurations
│   ├── checks.nix                 # perSystem: checks
│   ├── dev-shells.nix             # perSystem: devShells + formatter
│   └── packages.nix               # perSystem: packages + e2e-tests
├── lib/
│   ├── mksystem.nix               # 기존 팩토리 (inputs 전달 방식만 조정)
│   ├── cache-config.nix           # 캐시 단일 소스 (변경 없음)
│   └── user-info.nix              # 변경 없음
├── machines/                      # 변경 없음
├── users/shared/                  # 변경 없음
├── tests/                         # 변경 없음
├── scripts/
│   └── check-cache-sync.sh        # CI: flake.nix <-> cache-config.nix drift 검증
├── Makefile
└── .github/
```

## flake.nix

```nix
{
  description = "Nix flakes-based dotfiles";

  nixConfig = {
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    accept-flake-config = true;
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "github:DeterminateSystems/determinate";
    claude-code.url = "github:anthropics/claude-code/sdk-nix";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin" "x86_64-darwin"
        "x86_64-linux" "aarch64-linux"
      ];
      imports = [
        ./flake-modules/darwin.nix
        ./flake-modules/nixos.nix
        ./flake-modules/home.nix
        ./flake-modules/checks.nix
        ./flake-modules/dev-shells.nix
        ./flake-modules/packages.nix
      ];
    };
}
```

## flake-modules

### darwin.nix

```nix
{ inputs, ... }:
let
  mkSystem = import ../lib/mksystem.nix { inherit inputs; };
in
{
  flake.darwinConfigurations = {
    macbook-pro = mkSystem "macbook-pro" {
      system = "aarch64-darwin";
      user = "baleen";
      darwin = true;
    };
    baleen-macbook = mkSystem "baleen-macbook" {
      system = "aarch64-darwin";
      user = "baleen";
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

### nixos.nix

```nix
{ inputs, ... }:
let
  mkSystem = import ../lib/mksystem.nix { inherit inputs; };
in
{
  flake.nixosConfigurations = {
    vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
      system = "aarch64-linux";
      user = "baleen";
    };
    vm-x86_64-utm = mkSystem "vm-x86_64-utm" {
      system = "x86_64-linux";
      user = "baleen";
    };
  };
}
```

### home.nix

```nix
{ inputs, ... }:
{
  flake.homeConfigurations = {
    # 기존 4개 homeConfigurations 이전
    # withSystem 불필요 — pkgs를 직접 지정하므로
  };
}
```

### checks.nix

```nix
{ inputs, ... }:
{
  perSystem = { system, pkgs, ... }:
  let
    testSuite = import ../tests {
      inherit pkgs system;
      inherit (inputs) nixpkgs;
      lib = pkgs.lib;
    };
  in
  {
    checks = testSuite;
  };
}
```

### dev-shells.nix

```nix
{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-rfc-style;
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixfmt-rfc-style
        lua-language-server
        nil
        shellcheck
        shfmt
        pre-commit
      ];
    };
  };
}
```

### packages.nix

```nix
{ inputs, ... }:
{
  perSystem = { system, pkgs, lib, ... }: {
    packages = lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      # VM generation packages
    };
  };

  # e2e-tests는 flake 섹션 (Linux only)
  flake.e2e-tests = {};  # 기존 로직 이전
}
```

## Cache Strategy

### Single Source of Truth

`lib/cache-config.nix` — 변경 없음, 이미 시스템 설정의 단일 소스.

`flake.nix` nixConfig — Nix 제약으로 import 불가, 별도 유지 필수.

### Drift Detection

`scripts/check-cache-sync.sh`:
- `nix eval`로 `lib/cache-config.nix`에서 substituters/keys 추출
- flake.nix의 nixConfig 섹션을 파싱하여 비교
- 불일치 시 exit 1 + diff 출력
- pre-commit hook + CI step으로 실행

### CI Cache Key Improvement

변경 전:
```yaml
key: nix-${{ runner.os }}-${{ hashFiles('**/flake.lock') }}-${{ week }}
```

변경 후:
```yaml
key: nix-${{ runner.os }}-${{ runner.arch }}-${{ hashFiles('**/flake.lock') }}
restore-keys: |
  nix-${{ runner.os }}-${{ runner.arch }}-
```

- 주간 로테이션 제거 (flake.lock 변경 시 자연 갱신)
- arch 추가 (ARM/x64 캐시 분리)

## mksystem.nix Changes

시그니처를 `{ inputs }:` 래퍼 추가:

```nix
{ inputs }:
name: { system, user, darwin ? false, wsl ? false }:
let
  # 기존 로직 유지
in
  ...
```

기존 내부 로직 변경 없음. inputs를 클로저 대신 명시적 인자로 받는 것만 변경.

## Makefile Changes

조건 변수를 상단에 한 번만 정의:

```makefile
UNAME := $(shell uname)
IS_DARWIN := $(filter Darwin,$(UNAME))
IS_LINUX := $(filter Linux,$(UNAME))
```

각 타겟에서 재사용. 중복 조건문 통합.

## Known Gotchas (Researched)

| Gotcha | Status | Mitigation |
|--------|--------|------------|
| home directory 이중 정의 | 기존 mksystem.nix에서 처리 중 | 마이그레이션 시 확인 |
| homeManagerModules 병합 충돌 | 해당 없음 (미사용) | N/A |
| flake-utils 혼용 | 해당 없음 (미사용) | N/A |
| nixConfig은 mkFlake 외부 | 설계에 반영됨 | N/A |
| inputs.self 접근 | 필요 시 모듈 인자로 전달 | 구현 시 확인 |

## Verification Plan

각 단계마다 검증:

1. `nix flake check --impure` — flake 평가 성공
2. `make test` — 기존 테스트 전체 통과
3. `nix build '.#darwinConfigurations.macbook-pro.system'` — Darwin 빌드 성공
4. `darwin-rebuild switch --flake .#macbook-pro` — 실제 적용 테스트
5. `scripts/check-cache-sync.sh` — drift 검증 통과

## Research Sources

- [flake.parts 공식 문서](https://flake.parts/)
- [hercules-ci/flake-parts GitHub](https://github.com/hercules-ci/flake-parts)
- [linyinfeng/dotfiles](https://github.com/linyinfeng/dotfiles) — flake-modules/ 패턴
- [Mic92/dotfiles](https://github.com/Mic92/dotfiles) — Darwin + NixOS hybrid
- [NixOS Discourse: flake-parts migration](https://discourse.nixos.org/t/how-to-migrate-to-flake-parts/31646)
- [Vladimir Timofeenko: flake-parts custom modules](https://vtimofeenko.com/posts/flake-parts-writing-custom-flake-modules/)
- [home-manager Discussion #7551](https://github.com/nix-community/home-manager/discussions/7551)
