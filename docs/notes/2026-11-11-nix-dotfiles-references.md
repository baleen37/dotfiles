# Nix dotfiles 구조 개선 참고 레포

- 조사일: 2026-11-11
- 범위: 현재 flake-parts, nix-darwin/NixOS, Home Manager 구조와 비교할 공개 레포
- 방법: 레포의 README와 실제 소스, 프로젝트 공식 문서 확인. 다른 레포의 빌드·테스트는 실행하지 않았다.

## 결론

현재 구조와 가까운 ryoppippi/dotfiles를 먼저 보고, factory 단순화는 mitchellh/nixos-config, 플랫폼·호스트 계층은 ryan4yin/nix-config를 참고한다. dendritic은 별도의 구조 대안으로 이해한다. 아래 추천은 현재 저장소에 대한 설계 판단이며, 공식 표준 순위가 아니다.

| 레포                                                                | 확인한 패턴                                                   | 현재 저장소에서 참고할 점               | 주의                                                                              |
| ------------------------------------------------------------------- | ------------------------------------------------------------- | --------------------------------------- | --------------------------------------------------------------------------------- |
| [ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles)         | flake-parts, 공통 HM·Darwin·Linux 구분, 공유 패키지 생성 함수 | 시스템과 perSystem의 패키지 정책 일관성 | Darwin 디렉터리에도 HM 모듈이 있으므로 디렉터리 이름만으로 계층을 판단하지 않는다 |
| [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) | 시스템 factory로 machine·사용자 OS·HM 설정 조립               | mksystem.nix의 조립과 정책 경계         | 개인 환경 예외까지 복사하지 않는다                                                |
| [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)       | home/base, linux, darwin, hosts 분리                          | 공통·플랫폼·호스트 예외의 경계          | 큰 homelab 구성이므로 필요한 계층만 참고한다                                      |
| [mightyiam/dendritic](https://github.com/mightyiam/dendritic)       | 기능별로 여러 설정 계층을 함께 정의                           | OS와 HM이 함께 바뀌는 기능의 응집도     | dotfiles 템플릿보다 패턴 명세이며 전면 전환을 권장하는 근거는 없다                |

## 직접 확인할 소스

1. ryoppippi: [구조 설명](https://github.com/ryoppippi/dotfiles/blob/5373142117955aee74e192c45a4503c08fd16adf/nix/README.md), [mk-pkgs.nix](https://github.com/ryoppippi/dotfiles/blob/5373142117955aee74e192c45a4503c08fd16adf/nix/mk-pkgs.nix), [Darwin 연결](https://github.com/ryoppippi/dotfiles/blob/5373142117955aee74e192c45a4503c08fd16adf/nix/flake/hosts/darwin.nix).
2. mitchellh: [mksystem.nix](https://github.com/mitchellh/nixos-config/blob/40d483d74cf48d64379fc9a857237ee18c519ff4/lib/mksystem.nix), [README](https://github.com/mitchellh/nixos-config/blob/40d483d74cf48d64379fc9a857237ee18c519ff4/README.md). [evantravers References](https://github.com/evantravers/dotfiles#references)는 특히 mksystem.nix를 참고했다고 명시한다.
3. ryan4yin: [Home Manager 계층 설명](https://github.com/ryan4yin/nix-config/blob/0dcbbb02e93b26b09b7af398da2eab8667290300/home/README.md), [전체 설명과 검증 절차](https://github.com/ryan4yin/nix-config/blob/0dcbbb02e93b26b09b7af398da2eab8667290300/README.md).
4. dendritic: [패턴 명세](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md). 명세가 연결한 실제 사용 레포는 [mightyiam/infra](https://github.com/mightyiam/infra)이며, 이번에는 infra 내부 코드를 검증하지 않았다.

## 공식 기반과 설계 선택

[flake-parts](https://flake.parts/)는 flake 출력을 모듈로 나누는 기반을 제공한다. [Home Manager nix-darwin 통합](https://nix-community.github.io/home-manager/installation/nix-darwin.html)은 시스템 구성과 사용자 환경을 함께 활성화하는 경로를 제공한다. 현재 저장소는 이 기반을 이미 사용한다.

디렉터리명, 자동 import, 기본 enable 정책, specialArgs 사용 범위와 dendritic 채택은 설계 선택이다. dendritic의 안티패턴 설명을 Nix 전체의 공식 규칙으로 해석하지 않는다.

## 유지 상태 확인의 범위

GitHub API의 pushed_at 확인값은 ryoppippi/dotfiles 2026-11-10, mitchellh/nixos-config 2026-09-28, ryan4yin/nix-config 2026-11-10, mightyiam/dendritic 2026-09-04이다(UTC 날짜). API는 https://api.github.com/repos/{owner}/{repo}에서 확인했다. push 시각은 코드 변경일이나 테스트 통과를 보증하지 않는다.

## 현재 저장소에 적용할 검토 순서

1. users/shared/darwin/ 안의 시스템 모듈과 HM 모듈의 책임을 드러낸다. 디렉터리 이동 필요성은 별도로 판단한다.
2. lib/mksystem.nix에서 시스템 조립과 공통 정책의 경계를 검토한다. 분리 자체를 목표로 삼지 않는다.
3. 기존 typed hosts와 자동 모듈 탐색은 유지한 채, 실제 불편을 해결하는 패턴만 도입한다.

이 노트는 조사 결과이며 구현 변경은 포함하지 않는다.

## 후속 조사: 최근 구조의 흐름

2026-11-11 확인한 공개 프로젝트에서는 호스트 중심에서 기능 중심 구성으로 향하는 흐름이 눈에 띈다. 이는 조사한 소스의 설계 방향을 종합한 해석이다. 채택률 자료가 없으므로 커뮤니티 전체의 대세 또는 공식 표준이라는 뜻은 아니다.

| 흐름            | 확인한 변화                                                       | 현재 저장소 판단                                                                  |
| --------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Dendritic       | 한 기능의 NixOS·Darwin·HM 설정을 함께 정의하고 최상위 모듈로 조합 | flake-parts와 import-tree는 이미 있지만 자동 import만으로 Dendritic인 것은 아니다 |
| Den             | context에 따른 기능 조합과 호스트·사용자 관계 모델링              | 관계가 복잡할 때 비용 대비 검토한다                                               |
| flake-file      | 모듈에서 의존성을 선언하고 flake 파일 생성                        | input 관리가 병목일 때 검토한다                                                   |
| flake 독립 구성 | npins와 evalModules 같은 대안 경로 지원                           | flakes 폐기가 최신 표준이라는 근거는 없다                                         |

근거는 [Dendritic 명세](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md), [infra 실제 적용](https://github.com/mightyiam/infra/blob/65e185d7389994ea13faeda31cc9e056281f53e4/README.md), [Den 현재 README](https://github.com/denful/den/blob/bb76c5f29a3acc4fb5c7ce739caee04cbdeb3530/README.md), [flake-file README](https://github.com/denful/flake-file/blob/7b08dbc223bb1a758a515aad9653a6bf196bc772/README.md), [npins](https://github.com/andir/npins)이다.

Den은 현재 자신을 Dendritic와 별개라고 명시한다. Dendritic은 [2025년 발표](https://discourse.nixos.org/t/the-dendritic-pattern/61271)부터 발전해 왔으므로 2026년에 막 등장한 방식으로 설명하지 않는다.

검색 인덱스에는 vic/vix가 Den+npins 사례로 나오지만, [현재 커밋 README](https://github.com/vic/vix/blob/1746000529e0f45d975976fdf4268449800ed9e4/README.md)는 vic/yen을 사용한다. 빠르게 변하는 실험 사례이며 널리 채택된 표준이라는 증거는 없다.

권장 실험은 OS와 HM에 걸친 기능 하나의 관계를 한곳에서 읽히게 하는 것이다. 프레임워크 전환보다 기능 변경 시 함께 수정할 위치가 명확해지는지를 검증한다.

## 후속 조사: 최근 커뮤니티 의견

2026년 7~10월 Reddit 원문 토론 4개를 확인했다. 아래는 참여자의 경험과 의견이며, 채택률 조사나 커뮤니티 합의가 아니다. 절대 날짜는 검색 도구의 원문 렌더에서, 내용은 원문 열기로 확인했다. Reddit JSON API는 403이었으며 HTML 열기에서는 상대 날짜가 표시되었다.

| 시점·토론                                                                                                                                  | 찬성 경험                                                                 | 반대·유보                                                                                                  |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [2026-10-26: 설정 수정은 언제 끝나는가](https://www.reddit.com/r/NixOS/comments/1xfk91q/does_anyone_else_feel_like_theyre_never_done/)     | Dendritic 전환 후 구조 재편보다 모듈 추가·선택 위주가 되었다는 경험       | 작업 시간 감소를 측정한 자료는 아니다                                                                      |
| [2026-07-19~20: 일반 구성에도 필요한가](https://www.reddit.com/r/NixOS/comments/1v1537q/honest_takes_on_the_dendritic_pattern_not_seeing/) | 같은 기능의 flake·OS·HM 설정을 한곳에서 관리                              | 비슷한 호스트 두 대에는 과하다는 의견. 당시 Den의 인수 실수에 따른 silent no-op 등 추적 어려움 경험도 보고 |
| [2026-07-13: Den 회의론자의 전환](https://www.reddit.com/r/NixOS/comments/1uv7zgh/long_time_dendritic_pattern_den_detractor/)              | 6개 레포를 옮기며 모듈 재사용·이동과 의존성 관리가 편해졌다는 작성자 경험 | 복잡도 대비 이점이 작다는 반론과 더 작은 도구 조합을 택한 사례                                             |
| [2026-09-01: 단일 시스템의 flake-parts](https://www.reddit.com/r/NixOS/comments/1w3z6lv/is_there_any_use_case_for_flakeparts_in_a/)        | 파일 분리와 perSystem, 패키지·설정 동시 관리의 이점                       | 실제 필요가 생기기 전에는 plain Nix를 유지하라는 의견                                                      |

이를 종합하면 기능을 모으는 이점과 프레임워크 추가 비용을 따로 평가하라는 해석이 적절하다. Den 경험에 대한 불만을 Dendritic 전체의 결함이나 현재 Den에서 확인된 버그로 일반화하지 않는다. 현재 저장소에서는 기능 하나를 대상으로 수정 위치와 오류 추적 계층이 줄어드는지 비교한다.

## 범위 확장: 다른 구조와 실무 베스트 프랙티스

사용자는 특정 패턴에 국한하지 않은 비교를 요청했다. 다음은 Dendritic·Den 이외의 구조와 운영 사례다. 공식 소스의 동작과 현재 저장소에 대한 추천을 구분하며, 외부 레포 빌드는 수행하지 않았다.

### 명시적 모듈 조합: Misterio77

[nix-starter-configs의 standard/flake.nix](https://github.com/Misterio77/nix-starter-configs/blob/fe4c4b136e0e073c71d8190a791ba03ccb47c5ac/standard/flake.nix)는 패키지·overlays·재사용 모듈을 나누고 명시적인 진입 모듈 목록으로 조립한다. [home.nix](https://github.com/Misterio77/nix-starter-configs/blob/fe4c4b136e0e073c71d8190a791ba03ccb47c5ac/standard/home-manager/home.nix)는 필요한 사용자 모듈의 imports를 보여준다.

별도 개인 레포인 [Foundry의 global](https://github.com/Misterio77/Foundry/blob/8e8c8091cd71e386f729f31b959dc8c3e0a4ca25/hosts/nixos/common/global/default.nix)과 [atlas 호스트](https://github.com/Misterio77/Foundry/blob/8e8c8091cd71e386f729f31b959dc8c3e0a4ca25/hosts/nixos/atlas/default.nix)는 공통 기본값과 선택 기능을 구분해 조립한다. 예전 nix-config 주소는 Foundry로 이동했다. global/optional 구분은 starter 자체의 패턴이 아니다.

현재 대부분 기본 활성화하는 사용자 모듈 중 진짜 공통 필수와 선택 기능을 구분할 필요가 있는지 비교한다. 모든 호스트가 같은 도구를 원한다면 기본 활성화가 잘못된 것은 아니다. 개인 패키지 목록이나 템플릿의 NixOS 버전을 그대로 복사하지 않는다.

### 디렉터리 규약 기반 출력: Blueprint

[폴더 구조 문서](https://github.com/numtide/blueprint/blob/2bf123541bd5024046f32299c9f8a6cc6bdd8a9f/docs/content/getting-started/folder_structure.md)는 hosts, modules, packages, checks를 출력에 대응시킨다. [공통 Home Manager 템플릿](https://github.com/numtide/blueprint/blob/2bf123541bd5024046f32299c9f8a6cc6bdd8a9f/templates/nixos-and-darwin-shared-homes/flake.nix)도 제공한다.

현재의 typed hosts와 factory를 파일 위치·이름 규약으로 대체하는 선택이다. 저자가 experimental이며 복잡한 flake에는 적합하지 않을 수 있다고 명시하므로, 교체를 기본 추천하지 않는다.

### Homebrew 자체와 패키지 관리 분리

[nix-homebrew README](https://github.com/zhaofengli/nix-homebrew/blob/52bc87da3f30c2261a6d1cfef3c892097b53daeb/README.md)는 Homebrew 버전·prefix 소유자·tap을 관리하고, 패키지는 nix-darwin에 맡긴다. 기존 설치의 autoMigrate와 mutableTaps 설정도 제공한다. 모든 cask 바이너리의 버전 재현성을 보장하는 것은 아니다.

현재 install.sh의 Homebrew 설치와 users/shared/darwin/homebrew.nix의 사용자 정의 activation 유지 비용을 비교할 수 있다. nix-homebrew 자체는 현재 brew bundle stamp 최적화를 대체하지 않는다.

### 비밀값과 원격 배포는 필요할 때 도입

[sops-nix README](https://github.com/Mic92/sops-nix/blob/fe7b4228405aeac2ce7192c2049a6e2bc8637082/README.md)는 암호화한 파일을 보관하고 활성화 시 복호화하며 권한을 선언하는 방식을 설명한다. [Darwin 검사 구성](https://github.com/Mic92/sops-nix/blob/fe7b4228405aeac2ce7192c2049a6e2bc8637082/checks/darwin.nix)도 있다. 실제 여러 호스트에 배포할 비밀값이 있을 때 검토한다. 현재 Keychain OAuth나 SSH 개인키를 옮길 필요가 있다고 판단하지 않는다.

[deploy-rs 최소 예제](https://github.com/serokell/deploy-rs/blob/1cec0527bd09074bbee6d4461900ce5d58267217/examples/simple/flake.nix)는 원격 호스트와 profile 활성화 경로를 선언하고 deployChecks를 연결한다. 반복적인 VM 원격 배포가 복잡해지면 참고한다.

### 현재 CI에서 확인한 점

flake.lock, follows, 공유 overlays, typed hosts, test-build, 3개 플랫폼 CI, 설치 파일 hash 검증은 이미 갖췄다. [Nix 공식 flake check 문서](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-check.html)의 --no-build 의미에 따라 평가와 실제 빌드를 구분한다.

현재 .github/workflows/ci.yml에서 일반 PR의 전체 시스템 closure 빌드는 x86_64-linux만 실행하고, Darwin·ARM Linux는 main과 태그에서 실행한다. assertion 검사는 PR에서도 세 플랫폼에서 빌드한다. 따라서 시스템 모듈 변경 PR에 관련 플랫폼 closure 빌드를 추가할 필요가 있는지 검토할 수 있다. 모든 PR에 무조건 전체 빌드를 추가하면 비용과 대기 시간이 늘어난다.

## 실제 구성 경로 추가 조사: 다른 dotfiles 3개

각 레포의 조사 시점 HEAD에서 진입점, 호스트, Home Manager, 도구 선택 코드를 추적했다. 빌드·활성화 검증은 하지 않았다.

### fufexan/dotfiles: 공통 기반과 사용자 프로필

- 경로: flake → hosts/default.nix → 공통 시스템과 호스트 설정 → HM main 또는 server 프로필.
- [호스트 조립](https://github.com/fufexan/dotfiles/blob/b3029bf982d371903652e0b1e07eed8f5fa95b3e/hosts/default.nix), [프로필 정의](https://github.com/fufexan/dotfiles/blob/b3029bf982d371903652e0b1e07eed8f5fa95b3e/home/profiles/default.nix), [main imports](https://github.com/fufexan/dotfiles/blob/b3029bf982d371903652e0b1e07eed8f5fa95b3e/home/profiles/main/default.nix), [server imports](https://github.com/fufexan/dotfiles/blob/b3029bf982d371903652e0b1e07eed8f5fa95b3e/home/profiles/server/default.nix).
- main은 GUI·게임·Wayland·서비스를 추가하고 server의 추가분은 Helix다. 공통 기반은 둘 다 포함한다.
- 참고할 점: VM·WSL과 데스크톱의 사용자 도구 조합이 실제로 다르면 공통 기반과 추가분으로 표현한다.
- 제한: [공통 HM](https://github.com/fufexan/dotfiles/blob/b3029bf982d371903652e0b1e07eed8f5fa95b3e/home/default.nix)의 사용자·홈 경로는 mihai로 고정. Linux 중심이며 현재 입력은 .tack에서 가져온다. 사용자 전달과 Darwin 지원은 현재 저장소의 방식을 유지할 이유가 있다.

### dustinlyons/nixos-config: 공통 설정과 플랫폼별 추가분

- 경로: flake → Darwin/NixOS 출력 → 플랫폼별 HM → 공유 programs·파일·패키지 구성.
- [flake](https://github.com/dustinlyons/nixos-config/blob/8adf74afa67fdd62d90be340ca816d244c7e3758/flake.nix), [Darwin HM](https://github.com/dustinlyons/nixos-config/blob/8adf74afa67fdd62d90be340ca816d244c7e3758/modules/darwin/home-manager.nix), [공유 programs](https://github.com/dustinlyons/nixos-config/blob/8adf74afa67fdd62d90be340ca816d244c7e3758/modules/shared/home-manager.nix).
- Darwin과 NixOS가 실제 출력에 연결된다. Homebrew 자체·tap은 nix-homebrew, 앱 목록은 nix-darwin으로 분리한다.
- 주의: programs의 일반 attrset 결합인 //는 Nix 모듈 imports 병합과 다르며 오른쪽 값이 우선한다. home.file에서는 별도로 mkMerge를 사용한다.
- 제한: 사용자 dustin의 반복과 아키텍처·호스트가 섞인 출력 키를 현재 typed hosts보다 개선된 것으로 볼 근거는 없다.

### EmergentMind/nix-config: hostSpec과 core/optional

- 경로: flake가 호스트 디렉터리 발견 → mkHost → host-spec과 core/optional → hostSpec.users 순회 → home/<user>/<host>.nix.
- [factory](https://github.com/EmergentMind/nix-config/blob/9f457783b2d40edf355d88ea2cea0c4a37843484/flake.nix), [genoa 시스템 조합](https://github.com/EmergentMind/nix-config/blob/9f457783b2d40edf355d88ea2cea0c4a37843484/hosts/nixos/genoa/default.nix), [사용자와 HM 연결](https://github.com/EmergentMind/nix-config/blob/9f457783b2d40edf355d88ea2cea0c4a37843484/hosts/common/users/default.nix), [사용자 환경](https://github.com/EmergentMind/nix-config/blob/9f457783b2d40edf355d88ea2cea0c4a37843484/home/ta/genoa.nix).
- optional 파일은 명시적으로 선택하고 일부 introdus 기능은 enable로 제어하며 core 및 로컬 파일 일부는 자동 발견한다. 자동 import와 명시적 선택은 서로 다른 역할로 공존할 수 있다.
- 참고할 점: homeModules 예외가 커지면 호스트별 HM 진입 파일을 둔다.
- 제한: 현재 darwinConfigurations는 주석 처리되어 있다. 외부 introdus 라이브러리, private·로컬 path 입력과 큰 hostSpec이 있어 단순 frameworkless 또는 활성 macOS 사례로 소개하지 않는다.

### 현재 구조에 대한 판단 보완

자동 import와 기본 활성화는 서로 다른 결정이다. 필요하다면 자동 발견은 유지하고 프로필에서 활성화할 수 있으며, 명시적 imports 전환이 필수는 아니다. 두 방식 모두 선택 정책이 읽히는지가 핵심이다.

현재 추적된 hosts.nix의 여섯 호스트에는 homeModules override가 없고 독립 HM도 동일한 공통 진입점을 사용한다. 그러므로 먼저 실제로 필요한 도구 조합 차이를 확인한다. VM·WSL과 Mac의 차이가 크면 사용자 환경의 공통 기반과 추가분을 분리하고, 차이가 작으면 기존 선택 정책을 유지한다. 기본 활성화에 의존하는 테스트가 이미 있으므로 명시적 선택으로 바꾸면 테스트 계약도 함께 바뀐다.

## 추가 실제 코드 조사: 역할·자체 홈 관리·설정 내장 패키지

아래 네 레포도 조사 시점 HEAD의 실제 조립 경로를 읽었다. 빌드는 실행하지 않았다.

### nmasur/dotfiles

경로는 flake → lib 빌더가 hosts/<system>/<host> 발견 → OS 출력과 별도 HM 출력 → profiles → presets다.

- [flake](https://github.com/nmasur/dotfiles/blob/0d96b8fbedca690abbb997ef896a4c41d795c702/flake.nix)
- [빌더](https://github.com/nmasur/dotfiles/blob/0d96b8fbedca690abbb997ef896a4c41d795c702/lib/default.nix)
- [실제 Mac lookingglass](https://github.com/nmasur/dotfiles/blob/0d96b8fbedca690abbb997ef896a4c41d795c702/hosts/aarch64-darwin/lookingglass/default.nix)
- [Darwin HM 프로필](https://github.com/nmasur/dotfiles/blob/0d96b8fbedca690abbb997ef896a4c41d795c702/platforms/home-manager/modules/nmasur/profiles/darwin-base.nix)

프로필은 presets의 enable을 mkDefault true로 설정하고 호스트가 예외를 덮어쓸 수 있다. 호스트 파일에 home-manager.users가 있지만 buildDarwin/buildNixos는 이 속성을 제거하고 별도 homeConfigurations를 만들어 HM을 standalone으로만 활성화한다. 주석은 통합 HM과 standalone의 중복 generation 경험을 이유로 설명한다. 이는 해당 작성자의 선택이며 현재 저장소에서 같은 문제가 확인된 것은 아니다. 참고할 것은 프로필의 기본값 정책과 활성화 주체의 명확성이다.

### hlissner/dotfiles

경로는 자체 mkFlake/mapHosts → 호스트의 modules.profiles → role/user/hardware/networks → 공통 모듈 트리와 자체 홈 관리다.

- [자체 시스템 빌더](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/lib/nixos.nix)
- [ramen 호스트](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/hosts/ramen/default.nix)
- [workstation 역할](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/modules/profiles/role/workstation.nix)
- [tmux 선택 옵션](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/modules/shell/tmux.nix)
- [자체 홈 관리](https://github.com/hlissner/dotfiles/blob/0e6e93a8478eb76a2d8ad87f6befb1fd20b7261e/modules/home.nix)

자동 발견하지만 기능은 별도 enable로 제어한다. tmux는 기본 비활성화다. 현재 HM을 쓰지 않고 home.configFile/configLink를 자체 구현하며 systemd oneshot으로 링크를 갱신하고 이전 링크 기록을 정리한다. 일반 파일 충돌은 건너뛰고 실패를 보고한다. 역할과 mkDefault 정책은 참고할 만하나 홈 관리자까지 직접 구현할 필요를 입증하지 않는다.

### NotAShelf/nyx

경로는 호스트 factory → options/common/profiles 트리와 역할 조합 → 사용자 목록 → 사용자별 HM → osConfig 옵션을 읽는 도구 모듈이다.

- [호스트 조립](https://github.com/NotAShelf/nyx/blob/d407b4d6e5ab7f60350af61a3d73a62a5e9ac660/hosts/default.nix)
- [사용자와 HM 연결](https://github.com/NotAShelf/nyx/blob/d407b4d6e5ab7f60350af61a3d73a62a5e9ac660/homes/default.nix)
- [enyo 사용자 환경 선택](https://github.com/NotAShelf/nyx/blob/d407b4d6e5ab7f60350af61a3d73a62a5e9ac660/hosts/enyo/modules/usrEnv.nix)
- [MPV HM 모듈](https://github.com/NotAShelf/nyx/blob/d407b4d6e5ab7f60350af61a3d73a62a5e9ac660/homes/notashelf/programs/media/mpv/default.nix)

호스트의 modules.usrEnv 옵션으로 HM 도구를 켠다. 사용자 목록에서 계정과 HM 연결을 관리하고 패키지 집합을 공유한다. 이 MPV 모듈은 osConfig에 의존하므로 standalone HM에 그대로 재사용할 수 없다. 다중 사용자 선택을 한곳에 모으는 이점과 옵션 추적 계층 증가를 함께 평가해야 한다.

### sioodmy/dotfiles

경로는 user.packages → flake packages/devShells/NixOS 설치에 재사용하며, 별도 homix가 홈 파일을 연결한다.

- [사용자 패키지와 NixOS 모듈](https://github.com/sioodmy/dotfiles/blob/0f7d2d186378d5ee2b1b914bccf898b4a5bf6c3d/user/default.nix)
- [설정 내장 tmux 패키지](https://github.com/sioodmy/dotfiles/blob/0f7d2d186378d5ee2b1b914bccf898b4a5bf6c3d/user/wrapped/tmux/default.nix)
- [homix](https://github.com/sioodmy/dotfiles/blob/0f7d2d186378d5ee2b1b914bccf898b4a5bf6c3d/modules/homix/default.nix)
- [호스트 조립](https://github.com/sioodmy/dotfiles/blob/0f7d2d186378d5ee2b1b914bccf898b4a5bf6c3d/hosts/default.nix)

tmux는 writeText로 만든 설정의 store 경로를 wrapProgram의 -f 인수로 주입한다. 도구 하나를 사용자 홈 전체 활성화 없이 패키지 단위로 시험·재사용하는 대안이다. HM을 쓰지 않으며 파일 연결은 사용자 권한 systemd 서비스로 수행한다. 홈 링크 충돌·제거 수명 주기를 직접 관리하는 비용이 있어 HM 대체를 권장할 근거는 없다.

### 반복되는 원칙과 작성자별 선택

반복되는 원칙은 공통 기본값·역할별 선택·호스트 예외를 드러내는 것, 발견과 활성화를 구분하는 것, 계정·홈 경로·적용 주체를 명확히 하는 것이다. 자체 HM 대체, 광범위한 custom lib, OS/HM 활성화 통합 여부, wrapper 패키지 적용 범위는 작성자의 요구에 따른 선택이다.

## 2026-11-12: 선택 빈도와 GitHub 관심도

구조별 실제 이용률을 비교하는 신뢰할 만한 통계는 이번 조사에서 찾지 못했다. 일반 Nix 모듈과 Home Manager에 flake-parts를 결합하는 구성은 기존 레포와 템플릿에서 반복 확인했지만, 이를 전체 점유율 1위라는 사실로 해석하지 않는다. flake-parts는 호스트·공통 모듈 배치를 대체하는 구조가 아니라 함께 사용할 flake 조립 도구다. 근거는 [starter 코드](https://github.com/Misterio77/nix-starter-configs/blob/fe4c4b136e0e073c71d8190a791ba03ccb47c5ac/standard/flake.nix)와 [flake-parts 공식 설명](https://flake.parts/)이다.

2026-11-12 GitHub REST API에서 확인한 관심도는 아래와 같다. 별·포크 수는 실제 구조 채택자 수가 아니며, 템플릿과 개인 설정 레포의 목적도 다르다.

| 레포                                                                               |   별 | 포크 | 종류          |
| ---------------------------------------------------------------------------------- | ---: | ---: | ------------- |
| [nix-starter-configs](https://api.github.com/repos/Misterio77/nix-starter-configs) | 3854 |  172 | 스타터 템플릿 |
| [hlissner/dotfiles](https://api.github.com/repos/hlissner/dotfiles)                | 1957 |  101 | 개인 설정     |
| [Misterio77/Foundry](https://api.github.com/repos/Misterio77/Foundry)              | 1346 |   57 | 개인 설정     |
| [nmasur/dotfiles](https://api.github.com/repos/nmasur/dotfiles)                    |  264 |    7 | 개인 설정     |

현재 저장소에서는 선택 빈도 추정보다 기존 모듈·Home Manager·flake-parts 기반을 유지하며 starter의 단순한 조합 방식을 참고하는 것이 변경 비용 측면에서 합리적이다. 이는 설계 추천이지 인기 통계의 결론은 아니다.
