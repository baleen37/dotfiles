---
description:
globs:
alwaysApply: true
---
# Nix 환경 및 폴더 구조 가이드

이 프로젝트는 Nix, Home Manager, nix-darwin을 활용하여 macOS 및 공통 개발 환경을 선언적으로 관리합니다.

## Nix 관련 주요 폴더 구조

- [flake.nix](mdc:flake.nix): Nix flake 진입점, 전체 환경 선언
- [install.sh](mdc:install.sh): Nix 및 환경 설치 스크립트
- [modules/](mdc:modules):
  - [modules/darwin/](mdc:modules/darwin): macOS(darwin) 전용 시스템/유저/프로그램 설정
  - [modules/shared/](mdc:modules/shared): macOS/Linux 공통 프로그램 설정
- [libraries/nixpkgs/](mdc:libraries/nixpkgs): 직접 빌드하는 Nix 패키지(예: Hammerspoon, Homerow 등)
- [libraries/home-manager/](mdc:libraries/home-manager): Home Manager 확장 모듈
- [config/](mdc:config): 앱별 설정파일(예: nvim, hammerspoon)

## Nix 관련 파일/모듈 수정 시 주의사항

- Nix 모듈, 패키지, flake, 환경 관련 파일을 수정할 경우 반드시 아래 테스트를 수행해야 합니다:
  - `nix flake check` 또는 CI에서 제공하는 Nix 관련 테스트를 실행해 정상적으로 빌드/적용되는지 확인할 것
  - macOS 환경에서는 `darwin-rebuild switch --flake .#<host>`로 실제 적용 테스트 권장

## 참고
- 새로운 프로그램/설정 추가는 `modules/` 또는 `libraries/`에 Nix로 선언하면 됩니다.
- macOS 외 Linux도 공통 모듈(`modules/shared/`)을 통해 확장 가능합니다.
