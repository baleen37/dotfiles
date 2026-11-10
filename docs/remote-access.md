# 호스트별 원격 접속

macOS·Debian에서 같은 호스트 측 진입점을 실행한다.

```bash
ssh user@host
cd ~/dotfiles
./bootstrap.sh       # 도구와 기존 identity 준비
./switch.sh --build   # 활성화 없는 빌드·선언 검증
./switch.sh           # 대상 호스트에서 구성 적용
```

로컬 터미널에서도 같은 `switch.sh`를 실행한다. SSH·Ansible은 접속·체크아웃 배포·실행만
담당하며, 스크립트는 현재 호스트만 설정한다. 별도 원격 실행 옵션·관리 서버는 없다.
체크아웃·기존 age identity·필요한 관리자 권한은 bootstrap 단계에서 준비한다.

신규 Tailscale 가입에는 `secrets/remote-access.json`의 sops 암호문을 사용한다.
`tailscale-auth-key`에는 가입 전용 OAuth secret을 보관한다. 이 자격증명은 자동 만료되지
않으며, 권한은 `auth_keys`, 허용 태그는 `tag:infra`로 제한했다. 기존 관리용 `all` 권한
OAuth는 배포하지 않는다. Tailscale CLI가 필요할 때 가입 키를 발급하므로 주기적인 가입
키 교체나 별도 발급 서버가 필요 없다.

`machines/remote-access.json`의 `tailscale.tags`가 신규 기기의 태그를 선언한다.
OAuth에는 `ephemeral=false&preauthorized=true`를 지정해 지속적으로 사용할 기기를
등록한다. 기존 가입 기기는 자격증명을 다시 사용하거나 태그·identity를 바꾸지 않는다.
일반 가입 키의 최대 90일 만료와 등록된 기기의 node key 만료는 별도다.

근거: [Tailscale OAuth 문서](https://tailscale.com/docs/features/oauth-clients),
[가입 키 문서](https://tailscale.com/docs/features/access-control/auth-keys).

## 도구별 책임

| 대상                   | 기존 IaC·네이티브 도구        | 적용 흐름                                   |
| ---------------------- | ----------------------------- | ------------------------------------------- |
| macOS 기반·사용자 환경 | Nix·nix-darwin·Home Manager   | 기존 `switch.sh`                            |
| macOS GUI 앱           | Nix에 선언한 Homebrew cask    | RustDesk·Tailscale 설치                     |
| Debian 사용자 환경     | 기존 standalone Home Manager  | 기존 사용자 환경 유지                       |
| Debian 네이티브 앱     | APT·검증된 `.deb`             | bootstrap에서 설치, switch에서 적용         |
| 공통 원격 접속 정책    | `machines/remote-access.json` | `scripts/lib/remote_access.py`로 한 번 적용 |

Debian의 Nix 사용자 환경과 네이티브 앱 설치는 서로 덮어쓰지 않는다. 이번 `switch.sh`는
Debian 네이티브 영역을 담당하고 기존 Nix 기반은 그대로 유지한다. Windows·WSL 기존 구성은
변경하지 않으며, UTM 호스트는 제거했다. 별도 RustDesk 서버는 설치하지 않는다.

## 설치와 앱 설정

macOS는 `switch.sh`가 Nix·Homebrew와 사용자 launch agent를 적용한 뒤
`dotfiles-remote-apply`를 한 번 실행한다. RustDesk 관리자 설정은 현재 시스템 프로필의
고정된 `dotfiles-remote-configure`로 수행하며 일반 sudo 관리자 인증을 요구한다.
사용자 소유 앱과 시크릿 경로를 읽으므로 비밀번호 없는 sudo 예외는 추가하지 않는다.
RustDesk 사용자 서버 준비는 최대 10초 기다린 뒤 실패를 반환한다.

Debian은 APT로 설치·버전을 관리하고 RustDesk·Tailscale 자체 서비스만 부팅 시 시작한다.
별도 설정 타이머·복호화 서비스·적용기 복사본은 설치하지 않는다. 더 높은 설치 버전은
내리지 않으며, 필요한 버전이 이미 설치됐으면 해당 `.deb`를 다시 받지 않는다.
세부 준비 과정은 [Debian 안내](../machines/debian/README.md)를 따른다.

공통 코드는 현재 옵션을 읽고 필요한 항목만 변경한 뒤 다시 읽어 확인한다. RustDesk
비밀번호는 비밀 값·정책·앱 파일 revision이 바뀔 때만 설정한다. 이 marker는 실제 비밀번호의
유효성을 독립적으로 증명하는 수단은 아니다. 외부에서 비밀번호를 바꾼 경우에는 명시적인
비밀번호 재적용이 필요하다. 기기 ID는 복제하거나 재생성하지 않는다.

## 비밀정보와 최초 가입

공통 비밀번호는 `secrets/remote-access.json`의 `rustdesk-password`에 sops 암호문으로
보관한다. macOS는 sops-nix가 복호화한 파일을 읽고, Debian은 적용 시 기존 identity로
복호화한다. Debian에 root용 age 개인 키 복사본을 새로 보관하지 않는다.
평문 비밀번호는 Nix 평가·store·로그에 넣지 않는다. RustDesk 공식 CLI는 적용 순간
비밀번호를 프로세스 인자로 전달하므로 그 순간의 인자 노출까지 제거한 구성은 아니다.

Tailscale은 기존 로그인과 기기 identity를 보존한다. 사용자 의도로 중지한 세션도 강제로
다시 연결하지 않는다. 신규 가입 자격증명은 macOS에서 sops-nix가 복호화한 파일을 사용하고,
Debian에서는 적용 중에만 root 전용 임시 파일을 만들어 사용한 뒤 삭제한다. 자격증명이
없거나 회수됐거나 기기 승인이 대기 중이면 적용이 실패로 끝난다. 성공했다고 보고하지 않는다.

macOS 화면 녹화·손쉬운 사용 권한과 최초 VPN 확장 승인은 별도다. macOS RustDesk 설정은
선택된 사용자가 GUI에 로그인한 상태에서 적용한다. 권한·가입 준비 후 같은 `switch.sh`를
다시 실행하면 된다. 앱을 부팅·로그인 시 실행하는 것과 설정을 주기적으로 재적용하는 것은
구분한다.

## 검증 범위

`--build`는 macOS에서 활성화 없는 Nix 빌드, Debian에서 선언만 검증한다.
실제 상태 이탈 감사는 아니다. `--build`는 자격증명을 발급하거나 기기를 등록하지 않는다.

Debian 12 ARM64의 격리 OrbStack와 실제 사용 중인 `debian-dev-pve4`의 Debian 13
amd64에서 검증했다. 실제 호스트에는 SSH로 접속해 기존 Nix 환경을 유지한 채 대상의
`switch.sh`를 실행했다. 가입 전용 OAuth로 Tailscale 신규 가입과 반복 적용, 동일 기기 ID
유지, Mac RustDesk 클라이언트의 인증·1280×800 AV1 영상 처리 로그를 확인했다.
임시 가입 키 파일이 남지 않는 것도 확인했다.

macOS에서도 실제 적용과 기존 가입 상태 보존, 전체 assertion 빌드와 전체 플랫폼 평가를
확인했다. 시각 확인·키보드/마우스 조작·오디오와 macOS 최초 신규 가입은 별도 검증 범위다.
