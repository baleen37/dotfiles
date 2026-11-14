# 인기 NixOS 설정 레포 조사

- 조사일: 2026-11-12, GitHub API 수치 확인 시각 01:34 UTC
- 범위: 알려진 후보 13개와 `nixos-config in:name`의 별순 검색 상위 10개를 확인하고, 관심도와 현재 저장소 관련성으로 5개를 선정했다.
- 방법: GitHub REST API의 별·포크·보관 상태·기본 브랜치 HEAD 확인 후 실제 구성 코드를 읽었다. 외부 레포 빌드·활성화는 실행하지 않았다.
- 해석: GitHub 전체 인기순 순위가 아니다. 별은 관심도이며 실제 채택자 수나 품질 순위가 아니다.

## 선정한 레포

| 레포                                                                    |   별 | 포크 | 구성의 특징                                            |
| ----------------------------------------------------------------------- | ---: | ---: | ------------------------------------------------------ |
| [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config) | 3652 |  198 | Darwin/NixOS별 구성과 공유 사용자 설정, 시작 템플릿    |
| [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config)     | 3126 |  244 | 작은 시스템 factory로 기기·사용자 OS·Home Manager 조립 |
| [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)           | 2115 |  101 | 공통·플랫폼·호스트별 홈 설정과 홈랩                    |
| [hlissner/dotfiles](https://github.com/hlissner/dotfiles)               | 1957 |  101 | 역할·하드웨어·사용자 선택과 자체 flake·홈 관리         |
| [Misterio77/Foundry](https://github.com/Misterio77/Foundry)             | 1346 |   57 | 호스트가 공통 필수·사용자·선택 기능을 명시적으로 조합  |

수치 원본: [dustinlyons API](https://api.github.com/repos/dustinlyons/nixos-config), [mitchellh API](https://api.github.com/repos/mitchellh/nixos-config), [ryan4yin API](https://api.github.com/repos/ryan4yin/nix-config), [hlissner API](https://api.github.com/repos/hlissner/dotfiles), [Foundry API](https://api.github.com/repos/Misterio77/Foundry). 수치는 조사 시점의 스냅샷이다.

## 실제 구성 코드와 적용 판단

### dustinlyons/nixos-config

[flake.nix](https://github.com/dustinlyons/nixos-config/blob/07d20bd01ad7e43a41cfb2b9d4f6b4fb61eaa58e/flake.nix)는 플랫폼별 출력, NixOS named host, 템플릿과 설치·적용 앱을 연결한다. [Darwin HM 구성](https://github.com/dustinlyons/nixos-config/blob/07d20bd01ad7e43a41cfb2b9d4f6b4fb61eaa58e/modules/darwin/home-manager.nix)은 플랫폼별 패키지·파일과 공유 programs 설정을 결합한다.

Mac 온보딩과 Homebrew 연결을 참고할 만하다. 사용자 이름 반복과 일반 attrset의 `//` 병합까지 현재 typed hosts 구조에 도입할 필요는 없다. 일반 attrset 병합과 Nix 모듈 imports 병합은 다르다.

### mitchellh/nixos-config

[flake.nix](https://github.com/mitchellh/nixos-config/blob/40d483d74cf48d64379fc9a857237ee18c519ff4/flake.nix)에서 [mksystem.nix](https://github.com/mitchellh/nixos-config/blob/40d483d74cf48d64379fc9a857237ee18c519ff4/lib/mksystem.nix)를 사용해 기기 설정·사용자 OS 설정·사용자 HM 설정을 조립한다. Darwin·VM·WSL 구성을 포함한다.

현재 lib/mksystem.nix의 조립 책임을 비교하기 가장 직접적인 사례다. 작성자의 VM·WSL 운영 예외와 구조 자체를 구분해 참고한다.

### ryan4yin/nix-config

[Mac fern 출력](https://github.com/ryan4yin/nix-config/blob/a6fd893cbbb3e97710f9b1bfea80ac0a4151561b/outputs/aarch64-darwin/src/fern.nix)은 Darwin 모듈과 HM 모듈을 나눠 [macosSystem 빌더](https://github.com/ryan4yin/nix-config/blob/a6fd893cbbb3e97710f9b1bfea80ac0a4151561b/lib/macosSystem.nix)에 전달한다. [호스트별 홈 진입점](https://github.com/ryan4yin/nix-config/blob/a6fd893cbbb3e97710f9b1bfea80ac0a4151561b/home/hosts/darwin/darwin-fern.nix)은 공통 Darwin 홈 설정 위에 호스트별 SSH identity를 추가한다.

플랫폼·호스트별 사용자 설정을 분리하는 방식이 유용하다. 여러 nixpkgs·private inputs·자체 helpers가 있는 전체 홈랩 구성까지 옮길 필요는 없다.

### hlissner/dotfiles

[시스템 빌더](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/lib/nixos.nix)와 [ramen 호스트](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/hosts/ramen/default.nix)는 역할·하드웨어·사용자 선택을 조합한다. [home.nix](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/modules/home.nix)는 홈 파일·링크와 정리용 systemd 서비스를 직접 구현한다. 현재 Home Manager 사용 사례로 소개하지 않는다.

역할과 호스트 예외는 참고하되 현재 Home Manager와 flake-parts를 대체할 근거는 없다.

### Misterio77/Foundry

[atlas 호스트](https://github.com/Misterio77/Foundry/blob/89614110da97e32acbb9731df725245519b74cd3/hosts/nixos/atlas/default.nix)는 common/global, 사용자와 optional 기능을 직접 import한다. [global](https://github.com/Misterio77/Foundry/blob/89614110da97e32acbb9731df725245519b74cd3/hosts/nixos/common/global/default.nix)은 HM과 패키지 정책·공통 모듈을 연결한다.

필수 기반과 선택 기능을 읽기 쉽게 표현하는 방식이 유용하다. global의 Steam 하드웨어·Tailscale 같은 항목은 작성자의 공통값이지 모든 사용자에게 필요한 기본값이 아니다.

## 별도 분류와 추천 상태 정정

| 대상                                                                                          | 확인 결과           | 해석                                                            |
| --------------------------------------------------------------------------------------------- | ------------------- | --------------------------------------------------------------- |
| [Misterio77/nix-starter-configs](https://api.github.com/repos/Misterio77/nix-starter-configs) | 3854별·172포크      | 시작 템플릿. 현재 프로젝트 구조 기준은 계속 standard 템플릿이다 |
| [fufexan/dotfiles](https://api.github.com/repos/fufexan/dotfiles)                             | 1155별·55포크       | main/server 사용자 프로필 참고 사례                             |
| [NotAShelf/nyx](https://api.github.com/repos/NotAShelf/nyx)                                   | 437별·archived=true | 이전 구조 조사와 구분하여 현재 유지 중인 추천 대상에서는 제외   |
| [Frost-Phoenix/nixos-config](https://api.github.com/repos/Frost-Phoenix/nixos-config)         | 940별·archived=true | 보관된 사례                                                     |
| [sioodmy/nixus](https://api.github.com/repos/sioodmy/nixus)                                   | 923별               | 이전 dotfiles 주소의 현재 canonical 이름                        |

zaney/zaneyos 주소는 API에서 404였다. 이름 검색에서 librephoenix/nixos-config 1038별, XNM1/linux-nixos-hyprland-config-dotfiles 950별, JaKooLit/NixOS-Hyprland 393별도 확인했으나 이번에는 내부 코드를 추적하지 않았다. 따라서 구조 평가는 하지 않는다. 이들까지 포함한 전체 인기순 순위라고 주장하지 않는다.

## 현재 저장소에 대한 추천

프로젝트의 기준은 nix-starter-configs standard와 flake-parts 유지다. 보완 참고 순서는 Foundry의 기능 선택, mitchellh의 시스템 조립, ryan4yin의 플랫폼별 HM 진입점으로 잡는다. Mac 온보딩은 dustinlyons를 참고한다.

자동 모듈 발견과 기능 활성화는 별개다. 기존 자동 발견을 유지하면서 호스트에서 optional 기능을 선택하는 현재 방식에도 위 원칙을 적용할 수 있다. Debian 네이티브 서비스 적용과 Windows 측 설정까지 단일 방식으로 모두 해결하는 레포는 이번 선정 목록에서 확인되지 않았다.
