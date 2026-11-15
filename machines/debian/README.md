# Debian 네이티브 원격 접속

Debian 12·13의 amd64·arm64 호스트에서 실행한다. Nix·standalone Home Manager로
사용자 환경을 관리하고, 원격 접속 앱·서비스는 APT로 관리한다. 현재 제공하는 Linux
Home Manager 프로필은 `baleen-linux`(amd64)이며 Chrome을 포함한다. 다른 사용자·아키텍처는
일치하는 `homeConfigurations`를 먼저 선언해야 한다.

```bash
bash ./bootstrap.sh
bash ./switch.sh --build
bash ./switch.sh
```

최초 준비와 첫 적용에는 `just`가 필요하지 않다. Nix가 없어도 bootstrap이 준비한다.
bootstrap은 Home Manager를 활성화하지 않으므로 직후에 `just`가 설치됐다고 가정하지 않는다.
개발 프로필을 처음 적용한 뒤 새 로그인 셸에서 `just`를 사용하거나,
Nix가 준비된 뒤 `nix develop --command just --list`로 개발 셸의 runner를 사용한다.

bootstrap은 Nix·Home Manager 준비 도구, APT 패키지와 identity를 준비한다.
switch는 Home Manager를 적용한 뒤 네이티브 원격 접속과 동기화를 설정한다.
`--build`는 Home Manager를 빌드하고 네이티브 선언을 검증하며 환경을 활성화하지 않는다.
Chrome은 Home Manager 선언으로 관리하므로 별도의 `nix profile install`은 필요하지 않다.
필요한 명령에만 sudo를 사용한다. 기존 identity 경로는 환경 변수로 지정한다.

```bash
SOPS_AGE_KEY_FILE=/home/baleen/.config/sops/age/keys.txt ./switch.sh
```

SSH로 접속한 대상에서 `cd ~/dotfiles && ./switch.sh`를 실행한다.
가입 키는 체크아웃의 sops 암호문에서 읽으며 관리용 OAuth나 별도 원격 실행 옵션은
필요하지 않다. 세부 정책은 [공통 안내](../../docs/remote-access.md)를 따른다.

APT로 RustDesk·Tailscale·sops·age를 설치한다. 필요한 버전이 이미 설치되어 있으면 해당
`.deb`를 다시 다운로드하지 않으며, 높은 버전은 내리지 않는다. 버전·SHA-256·공통 접속
정책은 `machines/remote-access.json`에 선언한다. Tailscale은 공식 서명된 stable APT
저장소를 사용한다. 서비스의 자동 시작·재시작은 설치 단계에서 억제한다. 신규 서비스는 비활성 상태로
준비하고, 기존 서비스의 실행 상태와 시작 정책은 보존한다. 설치가 끝나면 bootstrap이
`tailscaled`를 활성화하고 tailnet에 한 번 가입한다. switch는 RustDesk를 활성화하고 설정을
맞추며 Tailscale 가입은 하지 않는다([ADR 0005](../../docs/adr/0005-remote-access-enroll-in-bootstrap-converge-in-switch.md)).

기존 `~/.config/sops/age/keys.txt` 또는 `SOPS_AGE_KEY_FILE`의 identity를 사용한다.
bootstrap은 키가 없으면 고정된 1Password CLI를 설치하고 기존 `dotfiles/sops` 항목에서 복원한다.
이 경우 최초 1Password 인증이 필요하다. 다른 참조는 `DOTFILES_AGE_KEY_REF=op://...`로 지정한다.
잘못된 기존 키·symlink는 거부하고, 복원 도중 만들어진 키도 덮어쓰지 않는다.
identity를 별도 root 디렉터리에 복사하지 않는다.

적용 시 공통 코드가 sops를 복호화하고 비밀번호는 메모리에서 사용한다. Tailscale 등록
키만 `/run`의 root 전용 임시 디렉터리에 기록한 뒤 성공·실패 모두 제거한다.
RustDesk 공식 CLI의 프로세스 인자에는 적용 순간 비밀번호가 포함된다. 명령 출력은 숨긴다.

신규 Tailscale 가입은 bootstrap에서 공유 sops 파일의 `tailscale-auth-key`를 사용한다. 가입 전용
OAuth secret과 `tag:infra`가 선언되어 있다. 자격증명을 사용할 수 없거나 기기 승인이
대기 중이면 실패를 반환한다. 기존 로그인·중지 상태·기기 ID는 보존한다.

```bash
systemctl status rustdesk tailscaled
```

설정은 apply 때 한 번 수행한다. 별도 재설정 타이머·적용 서비스·적용기 배포는 없다.
`--build`는 실제 서비스 상태 점검은 아니다. RustDesk 화면 제어에는
그래픽 세션이 필요하고 Wayland·로그인 화면 제어에는 제약이 있다. 가상 화면을 만들거나
디스플레이 서버를 바꾸지 않는다. 출처:
[RustDesk Linux](https://rustdesk.com/docs/en/client/linux/),
[Tailscale Debian 패키지](https://pkgs.tailscale.com/stable/).

RustDesk의 설정용 사용자 `--server`가 준비된 데스크톱 세션이 필요하다.
화면 없는 Debian에서 systemd 서비스가 실행 중인 것만으로 화면 제어 준비가 끝난 것은
아니다. 이 경우 자동으로 GUI·가상 디스플레이를 설치하지 않고 실패를 반환한다.

실제 Debian 12·13 ARM64의 서비스·권한 검증 결과는
[네이티브 검증 기록](../../docs/notes/2026-11-09-debian-native-verification.md)에 있다.

## ~/wiki 동기화

switch는 Syncthing으로 `~/wiki`를 허브(`machines/syncthing.json`)와만 공유하고, 마지막에
이 기기의 ID를 출력한다. 그 ID를 허브의 기기 목록에 추가해야 동기화가 시작된다.
이 기능 이전에 준비한 호스트는 switch 전에 `./bootstrap.sh`를 다시 실행해 `syncthing`을 설치한다.
기존 `wiki` 폴더가 `~/wiki`가 아닌 경로를 가리키면 공유하지 않고 실패한다.

## 실행 책임과 안전 경계

`apply.py`는 준비·읽기 전용 사전검사·적용 순서를 조율한다. `packages.py`는 APT와
검증된 다운로드·서비스 시작 정책 보존, `syncthing.py`는 wiki 동기화를 맡는다.
루트 bootstrap/switch는 이 실행기와 정책 파일을 원본 저장소가 아닌 같은 실행
스냅샷에서 읽는다. 정상 switch의 네이티브 사전검사가 실패하면 HM 활성화도 시작하지
않으며, HM 완료 후 서비스 적용이 실패하면 부분 적용 상태와 재실행 방법을 표시한다.

사용자 개발 도구는 Nix/HM이, root·systemd가 사용하는 네이티브 서비스와 준비 도구는
APT가 소유한다. 따라서 age·sops·Python의 사용자용/시스템용 설치는 의도적으로
공존한다. 이번 리팩토링은 시스템 의존성을 Nix 사용자 프로필에 의존하도록 바꾸거나
기존 APT 패키지를 제거하지 않는다.

wiki 경로와 제외 규칙은 `machines/syncthing.json`을 Mac과 공유한다. Debian은
기존 장치·폴더와 수동 `.stignore` 규칙을 삭제하지 않으며, 관리 블록의 제외 규칙을
앞에 두어 `.git`·Obsidian 작업공간 파일이 수동 포함 규칙으로 다시 공유되지 않게 한다.
관리 파일이 심볼릭 링크이거나 관리 블록이 잘못됐으면 덮어쓰지 않고 중단한다.
이 제외 규칙 보완은 Debian의 의도적인 정책 변경이며 실제 적용은 다음 switch 때 수행된다.
