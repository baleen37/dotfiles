# dotfiles (Nix + Home Manager + nix-darwin)

이 프로젝트는 Nix, Home Manager, nix-darwin을 활용하여 macOS 및 공통 개발 환경을 선언적으로 관리합니다.

## 폴더 구조 (2024 리팩토링)

```
dotfiles/
  .github/
  common/
    config/
      hammerspoon/
        Spoons/
        configApplications.lua
        init.lua
    nix/
      packages/
        default.nix
        programs/
      home-manager/
        default.nix
        programs/
    programs/
      act/
      git/
      nvim/
      ssh/
      tmux/
      vscode/
      wezterm/
  profiles/
    darwin/
      home.nix
      configuration.nix
      darwin-application-activation.nix
      programs/
        hammerspoon/
        homerow/
        ...
    nixos/
      programs/
        homerow/
  hosts/
    baleen/
    jito/
  utils/
    bin/
    setup/
  flake.nix
  flake.lock
  README.md
  ...
```

- `common/`: 공통 Nix 모듈, 패키지, 앱별 설정
- `profiles/`: OS별(특히 macOS, NixOS) 환경/프로그램 선언
- `hosts/`: 호스트별(기기별) 오버레이/설정
- `utils/`: bin, setup 등 유틸리티/스크립트

## 설치 및 적용

```sh
# Nix, Home Manager, nix-darwin 설치
./install.sh

# 환경 적용 (macOS)
darwin-rebuild switch --flake .#baleen

# 환경 적용 (NixOS)
nixos-rebuild switch --flake .#<hostname>

# 테스트
nix flake check
```

## 주요 파일/폴더 설명
- `common/nix/packages/`: 직접 빌드하는 Nix 패키지 (예: Hammerspoon, Homerow)
- `common/nix/home-manager/`: Home Manager 확장 모듈
- `common/config/`: 앱별 설정파일(예: nvim, hammerspoon)
- `profiles/darwin/`: macOS(darwin) 전용 시스템/유저/프로그램 설정
- `profiles/nixos/`: NixOS 전용 프로그램 설정
- `utils/`: bin, setup 등 유틸리티/스크립트

## 참고
- 새로운 프로그램/설정 추가는 `common/`, `profiles/`에 Nix로 선언하면 됩니다.
- macOS 외 Linux도 공통 모듈(`common/`)을 통해 확장 가능합니다.

## 테스트 및 빌드
- Nix 모듈, 패키지, flake, 환경 관련 파일을 수정할 경우 반드시 아래 테스트를 수행해야 합니다:
  - `nix flake check` 또는 CI에서 제공하는 Nix 관련 테스트를 실행해 정상적으로 빌드/적용되는지 확인할 것
  - macOS 환경에서는 `darwin-rebuild switch --flake .#<host>`로 실제 적용 테스트 권장
