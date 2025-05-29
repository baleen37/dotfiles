# dotfiles (Nix, Home Manager, nix-darwin)

이 저장소는 macOS 및 Linux 개발 환경을 [Nix](https://nixos.org/), [Home Manager](https://nix-community.github.io/home-manager/), [nix-darwin](https://github.com/LnL7/nix-darwin)로 선언적으로 관리합니다. [phip1611/nixos-configs](https://github.com/phip1611/nixos-configs) 스타일 구조를 따릅니다.

## 폴더 구조

```
common/
  modules/           # 공통 Nix 모듈 (user-env, services, system 등)
    user-env/        # 사용자 환경(앱, dotfiles 등) 모듈 (wezterm, nvim, hammerspoon, homerow 등)
    ...
  nix/               # 공통 패키지, 오버레이, 라이브러리
  config/            # 앱별 설정파일 (nvim, hammerspoon 등)
hosts/               # 호스트별 설정 (baleen, jito 등)
profiles/            # 역할/목적별 프로필
modules/             # (필요시) 시스템/공통 모듈
utils/               # 설치/유틸 스크립트
flake.nix            # Nix flake 진입점
install.sh           # 설치 스크립트
```

## 주요 파일/모듈 작성법
- **공통 앱/환경 모듈**: `common/modules/user-env/<name>/default.nix` (Home Manager 스타일)
  - 예: `hammerspoon`, `homerow` 등은 `home.packages`, `launchd.agents`, `xdg.configFile` 등만 선언
- **호스트별 설정**: `hosts/<host>/home.nix`에서 공통 모듈을 import하여 사용
- **패키지/오버레이**: `common/nix/packages/`, `common/nix/overlays/`

## 테스트/적용 방법
- Nix flake 테스트: `nix flake check`
- 실제 적용(macOS): `darwin-rebuild switch --flake .#<host>`
- Home Manager 적용: `home-manager switch --flake .#<host>`

## 변경 이력
- 2024-06: phip1611 스타일 구조로 전체 마이그레이션
  - 모든 공통 모듈/패키지 `common/`으로 이동
  - `hammerspoon`, `homerow` 등 Home Manager 스타일로 리팩토링
  - import 경로 및 Nix 표현식 일관성 유지

## 참고
- 새로운 앱/설정은 `common/modules/user-env/`에 Home Manager 스타일로 추가
- macOS/Linux 공통 모듈은 `common/modules/shared/` 활용
