# Mitchellh Style Nix Dotfiles Refactoring

> **Goal:** 완전한 mitchellh/nixos-config 스타일로 리팩토링하여 단순하고 관리하기 쉬운 구조로 전환

**Architecture:** 사용자 중심 구조, 속성 기반 플랫폼 감지, 하드웨어 분리

**Tech Stack:** Nix flakes, nix-darwin, NixOS, mitchellh patterns

---

## Current State Analysis

**현재 구조 문제점:**
- `users/shared/` - 사용자별 분리가 아님
- 복잡한 mkSystem 인터페이스
- 하드웨어 설정이 분리되지 않음
- 다중 사용자 지원 방식이 비효율적

**Target 상태:**
- mitchellh 스타일: `users/baleen/`, `users/jito/` 구조
- 간단한 mkSystem: `name: { system, user, darwin?, wsl? }`
- 하드웨어 설정 분리: `machines/hardware/`
- 속성 기반 플랫폼 감지

## Design Overview

### 최종 사용자 구성
- **주 사용자:** baleen (모든 설정 소유)
- **임시 사용자:** jito (baleen 설정 참조, macbook-pro-jito만 사용)

### 최종 머신 구성
- `macbook-pro-baleen`: baleen의 macbook-pro (baleen 사용자)
- `macbook-pro-jito`: jito의 macbook-pro (jito 사용자)
- `vm-aarch64-utm`: VM (baleen 사용자)

---

## Implementation Plan

### Task 1: 사용자 구조 재설계

**Files:**
- Create: `users/baleen/` 디렉토리 구조
- Create: `users/jito/` 디렉토리 구조
- Remove: `users/shared/` 디렉토리

**Step 1: baleen 사용자 구조 생성**
```bash
mkdir -p users/baleen
cp users/shared/home-manager.nix users/baleen/
cp users/shared/darwin.nix users/baleen/
cp users/shared/nixos.nix users/baleen/
cp -r users/shared/.config users/baleen/
```

**Step 2: jito 사용자 구조 생성 (baleen 참조)**
```bash
mkdir -p users/jito

# home-manager.nix (baleen 설정 참조)
cat > users/jito/home-manager.nix << 'EOF'
{
  imports = [ ../baleen/home-manager.nix ];
  # jito 특정 설정이 필요하면 여기에 추가
}
EOF

# darwin.nix (baleen 설정 참조)
cat > users/jito/darwin.nix << 'EOF'
{
  imports = [ ../baleen/darwin.nix ];
  # jito 특정 설정이 필요하면 여기에 추가
}
EOF

# nixos.nix (baleen 설정 참조, VM은 baleen만 사용)
cat > users/jito/nixos.nix << 'EOF'
{
  imports = [ ../baleen/nixos.nix ];
  # jito 특정 설정이 필요하면 여기에 추가
}
EOF
```

**Step 3: 기존 설정 파일 백업 및 제거**
```bash
mv users/shared users/shared.backup.$(date +%Y%m%d)
```

---

### Task 2: 머신 구조 재설계

**Files:**
- Modify: `machines/` 구조
- Create: `machines/hardware/` 디렉토리

**Step 1: 현재 머신 파일 분석**
```bash
# 현재 머신 설정 확인
ls -la machines/
```

**Step 2: 하드웨어 분리**
```bash
mkdir -p machines/hardware

# macbook-pro-baleen.nix 생성
cat > machines/macbook-pro-baleen.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware/macbook-pro-baleen.nix ];

  # baleen 맥북 특정 설정
  networking.hostName = "macbook-pro-baleen";
}
EOF

# macbook-pro-jito.nix 생성
cat > machines/macbook-pro-jito.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware/macbook-pro-jito.nix ];

  # jito 맥북 특정 설정
  networking.hostName = "macbook-pro-jito";
}
EOF

# vm-aarch64-utm.nix 생성 (기존 파일 활용)
cp machines/nixos/vm-aarch64-utm.nix machines/vm-aarch64-utm.nix 2>/dev/null || \
cat > machines/vm-aarch64-utm.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware/vm-aarch64-utm.nix ];

  # VM 특정 설정
  networking.hostName = "vm-aarch64-utm";
}
EOF
```

**Step 3: 하드웨어 설정 파일 생성**
```bash
# 하드웨어 설정은 기존 설정을 기반으로 생성
# 추후 구체적인 하드웨어 정보에 맞게 수정 필요
cat > machines/hardware/macbook-pro-baleen.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  # baleen 맥북 하드웨어 설정
  # 현재 설정에서 하드웨어 관련 부분 이동
}
EOF

cat > machines/hardware/macbook-pro-jito.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  # jito 맥북 하드웨어 설정 (다른 사양)
  # 현재 설정에서 하드웨어 관련 부분 이동
}
EOF
```

---

### Task 3: mkSystem 함수 mitchellh 스타일로 재구현

**Files:**
- Modify: `lib/mksystem.nix`

**Step 1: 완전히 새로운 mkSystem 구현**
```nix
# mitchellh/nixos-config 스타일
{ nixpkgs, overlays, inputs }:

name:
{
  system,
  user,
  darwin ? false,
  wsl ? false
}:

let
  # WSL 확인
  isWSL = wsl;

  # Linux 확인 (Darwin과 WSL 제외)
  isLinux = !darwin && !isWSL;

  # 설정 파일 경로
  machineConfig = ../machines/${name}.nix;
  userOSConfig = ../users/${user}/${if darwin then "darwin" else "nixos" }.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  # 시스템 함수 선택
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

in systemFunc rec {
  inherit system;

  modules = [
    # 오버레이 적용
    { nixpkgs.overlays = overlays; }

    # unfree 패키지 허용
    { nixpkgs.config.allowUnfree = true; }

    # WSL 모듈 (필요시)
    (if isWSL then inputs.nixos-wsl.nixosModules.wsl else {})

    # 설정 파일들
    machineConfig
    userOSConfig
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import userHMConfig {
        isWSL = isWSL;
        inputs = inputs;
      };
    }

    # 모듈에 추가 인자 전달
    {
      config._module.args = {
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        isWSL = isWSL;
        inputs = inputs;
      };
    }
  ];
}
```

---

### Task 4: flake.nix 단순화

**Files:**
- Modify: `flake.nix`

**Step 1: 기존 복잡한 설정 제거**
기존의 복잡한 mkSystem 호출과 user 변수 처리를 모두 제거

**Step 2: mitchellh 스타일 한 줄 정의**
```nix
outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
  overlays = [
    # 기존 오버레이 유지
    # ...
  ];

  mkSystem = import ./lib/mksystem.nix {
    inherit overlays nixpkgs inputs;
  };

in {
  # NixOS 시스템
  nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
    system = "aarch64-linux";
    user   = "baleen";
  };

  # Darwin 시스템
  darwinConfigurations.macbook-pro-baleen = mkSystem "macbook-pro-baleen" {
    system = "aarch64-darwin";
    user   = "baleen";
    darwin = true;
  };

  darwinConfigurations.macbook-pro-jito = mkSystem "macbook-pro-jito" {
    system = "aarch64-darwin";
    user   = "jito";
    darwin = true;
  };

  # 기존 apps, devShells 등 유지
  # ...
};
```

---

### Task 5: 통합 테스트 및 검증

**Step 1: 빌드 테스트**
```bash
# flake 구조 확인
nix flake show

# baleen 시스템 빌드 테스트
export USER=baleen
nix build --impure .#darwinConfigurations.macbook-pro-baleen.system --dry-run

# jito 시스템 빌드 테스트
export USER=jito
nix build --impure .#darwinConfigurations.macbook-pro-jito.system --dry-run

# VM 빌드 테스트
export USER=baleen
nix build --impure .#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel --dry-run
```

**Step 2: 기존 테스트 실행**
```bash
make test-quick
```

**Expected:** 모든 테스트 통과

---

## Success Criteria

- ✅ mitchellh 스타일 사용자 구조 (`users/baleen/`, `users/jito/`)
- ✅ 간단한 mkSystem 함수 (`name: { system, user, darwin?, wsl? }`)
- ✅ 하드웨어 설정 분리 (`machines/hardware/`)
- ✅ 한 줄 flake.nix 정의
- ✅ jito는 baleen 설정 참조 (중복 제거)
- ✅ 기존 기능 호환성 유지

---

## Migration Notes

**파일 이동 주의사항:**
- `users/shared/` 백업 필수 (`users.shared.backup.$(date)`)
- Git에서 파일 이동 히스토리 추적 가능하게 `git mv` 사용

**하드웨어 설정:**
- 현재 하드웨어 설정을 `machines/hardware/`로 이동 필요
- 두 macbook-pro의 다른 하드웨어 사양 반영

**향후 확장성:**
- jito가 독립 설정 필요시 `users/jito/*.nix` 파일만 수정하면 됨
- 새로운 사용자 추가 시 동일 패턴으로 쉽게 확장 가능

---

## Rollback Plan

문제 발생 시:
```bash
# 백업에서 복원
mv users.shared.backup.$(date) users/shared
rm -rf users/baleen users/jito

# Git으로 롤백
git reset --hard HEAD~5
```

---

이 리팩토링을 통해 mitchellh/nixos-config의 단순하고 확장 가능한 아키텍처를 완전히 도입할 수 있습니다.
