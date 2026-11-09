# Debian 네이티브 준비·적용 검증

2026-11-09에 실제 Debian 12·13 ARM64의 APT·systemd·권한 동작을 확인했다.
합성 age identity와 암호문을 사용했다. 실제 계정 자격증명이나 개인 키는 사용하지 않았다.

## 결과

| 확인 항목                                | Debian 12 · systemd 252.39                             | Debian 13 · systemd 257.13                                   |
| ---------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| bootstrap 패키지 설치·기존 identity 검증 | 성공                                                   | 성공                                                         |
| 최초 설치 후 서비스 비활성·시작 안 됨    | 수정 후 `disabled` / `inactive`                        | 수정 전 자동 활성화 문제 재현                                |
| 실행 중 bootstrap 재실행                 | 실행 ID·시작 정책 보존                                 | 실행 ID·시작 정책 보존                                       |
| 키 없는 `switch --build`                 | 종료 0, 패키지·서비스 변경 없음                        | 종료 0, 패키지·서비스 변경 없음                              |
| 키 없는 일반 switch                      | 종료 1, 서비스 변경 없음                               | 종료 1, 서비스 변경 없음                                     |
| 유효한 키로 일반 switch                  | 서비스 시작, RustDesk 사용자 서버 준비 부족으로 종료 1 | 서비스 시작·RustDesk 설정 후 Tailscale 가입 키 부재로 종료 1 |
| identity                                 | 원본과 동일, `600 baleen:baleen`                       | 원본과 동일, `600 baleen:baleen`                             |
| 원격 설정 성공 기록                      | 준비 실패로 생성되지 않음                              | 디렉터리 `700 root:root`, 파일 `600 root:root`               |
| 관리자 권한 없는 원격 설정               | 별도 실행하지 않음                                     | 관리자 권한 요구로 종료 1                                    |
| `/run/dotfiles-remote-*` 잔여 파일       | 없음                                                   | 없음                                                         |

테스트 VM은 `dotfiles-architecture-verify12`, `dotfiles-architecture-verify`다.
macOS 파일 공유와 호스트 통합을 끈 `--isolated` 머신으로 만들었다. 검증 후 정지했다.

## 실제로 발견한 문제와 수정

`machines/debian/apply.py`가 직접 서비스를 시작하지 않아도 패키지 설치 후 스크립트가 시작했다.
Debian 13에서 수정 전 bootstrap 종료 직후 두 서비스가 모두 `enabled` / `active`였다.

설치된 패키지의 `/var/lib/dpkg/info/rustdesk.postinst`는 `systemctl enable`과 `start`를,
`tailscale.postinst`는 `deb-systemd-helper enable`과 `deb-systemd-invoke restart`를 호출했다.
외부 명령 adapter가 APT를 대신하던 기존 테스트에서는 드러나지 않았다.

수정은 두 부분이다.

1. APT 실행에만 `SYSTEMD_OFFLINE=1`을 전달해 설치 스크립트의 systemctl이 실행 중인 manager에 명령하지 않게 한다. [systemd 공식 설명](https://systemd.io/ENVIRONMENT/)
2. 설치 전 서비스의 시작 정책을 저장하고 성공·실패 모두 복구한다. 신규 서비스는 `disabled`, 기존 서비스는 이전 정책을 유지한다. 기존 실행을 중단하거나 재시작하지 않는다.

실제 Debian 12의 새 설치에서 두 서비스가 `disabled` / `inactive`인 것을 확인했다.
Debian 12·13 모두 실행 중 재실행 전후 `InvocationID`와 `UnitFileState`가 같았다.

회귀 시나리오 `tests/integration/debian-setup.py`는 APT가 unit을 활성화하는 동작을 흉내 내고,
새 서비스 비활성 복구·기존 활성 서비스 보존·설치 실패 시 정책 복구를 실제 CLI에서 검증한다.

## 재현용 합성 fixture 준비

macOS의 저장소 루트에서 실행한다. `orb`, `age-keygen`, `sops`가 필요하다.
아래 키는 테스트 전용으로 새로 생성하며 실제 identity를 복사하지 않는다.

```bash
fixture=$(mktemp -d)
for file in bootstrap.sh switch.sh \
  scripts/lib/setup.sh scripts/lib/flake-source.sh \
  scripts/lib/identity.py scripts/lib/remote_access.py \
  machines/debian/apply.sh machines/debian/apply.py machines/remote-access.json; do
  mkdir -p "$fixture/$(dirname "$file")"
  cp "$file" "$fixture/$file"
done
mkdir -p "$fixture/secrets"
age-keygen -o "$fixture/identity"
recipient=$(age-keygen -y "$fixture/identity")
printf '{"rustdesk-password":"native-verification-synthetic-password"}' |
  sops --encrypt --age "$recipient" --input-type json --output-type json /dev/stdin \
    > "$fixture/secrets/remote-access.json"

machine=dotfiles-native-repro
orb create --isolated --memory 2G --cpus 2 debian:12 "$machine"
tar -C "$fixture" -cf - . |
  orb -m "$machine" sh -c 'mkdir -p ~/dotfiles-native-probe; tar -xf - -C ~/dotfiles-native-probe'
orb -m "$machine"
```

VM 안에서 합성 키를 준비한 뒤 공개 명령을 실행한다.

```bash
cd ~/dotfiles-native-probe
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age
cp identity ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
./bootstrap.sh
systemctl is-enabled rustdesk.service tailscaled.service
systemctl is-active rustdesk.service tailscaled.service
```

`is-enabled`의 `disabled`와 `is-active`의 `inactive`는 이 단계의 기대 결과다.
이 상태 조회는 성공 코드가 아닌 값을 반환할 수 있다.

## 부작용·권한 확인 명령

VM 안에서 다음처럼 CLI 실행 전후 값을 비교했다.

```bash
systemctl show -p ActiveState -p InvocationID rustdesk tailscaled > before.services
sha256sum /var/log/apt/history.log > before.apt
SOPS_AGE_KEY_FILE="$PWD/no-key" ./switch.sh --build
SOPS_AGE_KEY_FILE="$PWD/no-key" ./switch.sh
systemctl show -p ActiveState -p InvocationID rustdesk tailscaled > after.services
sha256sum /var/log/apt/history.log > after.apt
cmp before.services after.services
cmp before.apt after.apt
cmp identity ~/.config/sops/age/keys.txt
stat -c '%a %U:%G' ~/.config/sops/age/keys.txt
```

일반 switch를 실행하면 실제 서비스가 시작된다. GUI나 가입 자격증명 없이 성공했다고
보고하지 않는지 확인했다. 실행 중 bootstrap 재실행은 `InvocationID`와 `UnitFileState`의
실행 전후 파일을 비교했다. Debian 13에서는 일반 사용자로 `remote_access.py debian ...`을
직접 실행해 관리자 권한 요구를 확인했고, 생성된 상태 파일의 root 소유권·권한도 확인했다.

## 검증 한계

신규 Tailscale 가입·기존 가입 계정 보존·GUI 화면 제어의 성공은 이번 검증 범위가 아니다.
의도적으로 가입 키를 넣지 않았고 Debian 12에는 데스크톱 사용자 세션이 없다.
실제 네이티브 실행은 ARM64이며 amd64는 별도 실행하지 않았다.
