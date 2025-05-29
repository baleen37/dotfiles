# dotfiles (Nix + Home Manager + nix-darwin)

이 프로젝트는 Nix, Home Manager, nix-darwin을 활용하여 macOS 및 공통 개발 환경을 선언적으로 관리합니다.

## 폴더 구조 (phip1611 스타일)

```
dotfiles/
  .github/
  common/
    modules/
      home-manager/
        nvim/
        tmux/
        git/
        ssh/
        vscode/
        wezterm/
        ...
      nixos/
        ...
    packages/
      homerow/
      hammerspoon/
      ...
    config/
      hammerspoon/
      ...
    lib/
      (필요시 Nix 함수/유틸)
  profiles/
    baleen/
      home.nix
      configuration.nix
      darwin-application-activation.nix
      programs/
        ...
    jito/
      home.nix
      configuration.nix
      programs/
        ...
  utils/
    bin/
    setup/
  flake.nix
  flake.lock
  README.md
  ...
```

- `common/modules/home-manager/`: Home Manager용 공통 모듈(예: nvim, tmux, git 등)
- `common/modules/nixos/`: NixOS용 공통 모듈(필요시)
- `common/packages/`: 직접 빌드하는 패키지(homerow, hammerspoon 등)
- `common/config/`: 앱별/공통 설정파일
- `common/lib/`: Nix 함수/유틸리티(필요시)
- `profiles/<host>/`: 각 호스트(혹은 역할별) 환경 선언(home.nix, configuration.nix 등)
- `utils/`: bin, setup 등 유틸리티/스크립트

## 설치 및 적용

```sh
# Nix, Home Manager, nix-darwin 설치
./install.sh

# 환경 적용 (macOS)
darwin-rebuild switch --flake .#baleen

# 환경 적용 (NixOS)
nixos-rebuild switch --flake .#jito

# 테스트
nix flake check
```

## 주요 파일/폴더 설명
- `common/modules/home-manager/`: Home Manager 공통 모듈
- `common/packages/`: 직접 빌드하는 Nix 패키지 (예: Hammerspoon, Homerow)
- `common/config/`: 앱별 설정파일(예: nvim, hammerspoon)
- `profiles/<host>/`: 호스트별 시스템/유저/프로그램 설정
- `utils/`: bin, setup 등 유틸리티/스크립트

## 참고
- 새로운 프로그램/설정 추가는 `common/`, `profiles/`에 Nix로 선언하면 됩니다.
- macOS 외 Linux도 공통 모듈(`common/`)을 통해 확장 가능합니다.

## 테스트 및 빌드
- Nix 모듈, 패키지, flake, 환경 관련 파일을 수정할 경우 반드시 아래 테스트를 수행해야 합니다:
  - `nix flake check` 또는 CI에서 제공하는 Nix 관련 테스트를 실행해 정상적으로 빌드/적용되는지 확인할 것
  - macOS 환경에서는 `darwin-rebuild switch --flake .#<host>`로 실제 적용 테스트 권장
