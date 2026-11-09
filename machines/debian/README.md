# Debian 네이티브 원격 접속

Debian 12·13의 amd64·arm64 호스트에서 실행한다. 기존 Nix·standalone Home Manager
사용자 환경은 유지하고 네이티브 앱·서비스만 적용한다.

```bash
./switch.sh --check
./switch.sh
```

동일한 하위 진입점은 `machines/debian/apply.sh`다. 적용은 필요한 명령에만 sudo를
사용한다. 관리자 계정에서 실행할 경우에도 기존 사용자 identity 경로를 명시할 수 있다.

```bash
./switch.sh --age-key-file /home/baleen/.config/sops/age/keys.txt
```

SSH로 접속한 대상에서 `cd ~/dotfiles && ./switch.sh`를 실행한다.
가입 키는 체크아웃의 sops 암호문에서 읽으며 관리용 OAuth나 별도 원격 실행 옵션은
필요하지 않다. 세부 정책은 [공통 안내](../../docs/remote-access.md)를 따른다.

APT로 RustDesk·Tailscale·sops·age를 설치한다. 필요한 버전이 이미 설치되어 있으면 해당
`.deb`를 다시 다운로드하지 않으며, 높은 버전은 내리지 않는다. 버전·SHA-256·공통 접속
정책은 `machines/remote-access.json`에 선언한다. Tailscale은 공식 서명된 stable APT
저장소를 사용한다. RustDesk·Tailscale 자체 서비스만 부팅 시 시작한다.

기존 `~/.config/sops/age/keys.txt` 또는 `SOPS_AGE_KEY_FILE`의 identity를 사용한다.
없으면 고정된 1Password CLI를 설치하고 기존 `dotfiles/sops` 항목에서 복원한다.
이 경우 최초 1Password 인증이 필요하다. 다른 참조는 `--age-key-ref op://...`로 지정한다.
identity를 별도 root 디렉터리에 복사하지 않는다.

적용 시 공통 코드가 sops를 복호화하고 비밀번호는 메모리에서 사용한다. Tailscale 등록
키만 `/run`의 root 전용 임시 디렉터리에 기록한 뒤 성공·실패 모두 제거한다.
RustDesk 공식 CLI의 프로세스 인자에는 적용 순간 비밀번호가 포함된다. 명령 출력은 숨긴다.

신규 Tailscale 가입에는 공유 sops 파일의 `tailscale-auth-key`를 사용한다. 가입 전용
OAuth secret과 `tag:infra`가 선언되어 있다. 자격증명을 사용할 수 없거나 기기 승인이
대기 중이면 실패를 반환한다. 기존 로그인·중지 상태·기기 ID는 보존한다.

```bash
systemctl status rustdesk tailscaled
```

설정은 apply 때 한 번 수행한다. 별도 재설정 타이머·적용 서비스·적용기 배포는 없다.
`--check`는 선언 출력이며 실제 서비스 상태 점검은 아니다. RustDesk 화면 제어에는
그래픽 세션이 필요하고 Wayland·로그인 화면 제어에는 제약이 있다. 가상 화면을 만들거나
디스플레이 서버를 바꾸지 않는다. 출처:
[RustDesk Linux](https://rustdesk.com/docs/en/client/linux/),
[Tailscale Debian 패키지](https://pkgs.tailscale.com/stable/).

RustDesk의 설정용 사용자 `--server`가 준비된 데스크톱 세션이 필요하다.
화면 없는 Debian에서 systemd 서비스가 실행 중인 것만으로 화면 제어 준비가 끝난 것은
아니다. 이 경우 자동으로 GUI·가상 디스플레이를 설치하지 않고 실패를 반환한다.
