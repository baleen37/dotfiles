# macOS·Debian·Windows 호스트 관리 조사

조사일: 2026-11-08. 공식 문서와 공식 프로젝트 자료를 사용했다.
문서로 확인한 사실과 이 저장소에 대한 설계 판단을 구분한다.
이번 조사는 구현 전환을 승인하거나 실제 기기에 설정을 적용하는 작업이 아니다.

## 현재 확정한 범위와 실행 구조

대상은 macOS·Debian이며 Windows 원격 접속 자동화는 제외한다. 기존 Windows·WSL
구성과 UTM 제거는 유지한다. Nix를 기본으로 쓰되 Homebrew·APT 같은 네이티브
도구를 함께 사용한다. 로컬과 원격은 같은 호스트 측 적용 진입점을 사용한다.
Ansible을 쓰는 경우에도 코드 전달·스크립트 트리거·결과 수집만 담당한다.
실제 적용 경로와 도구별 책임은 [원격 접속 구성](../remote-access.md)에 기록한다.

아래는 범위 확정 전의 대안 비교와 공식 문서 조사 기록이다. Ansible이 구성 자체를
소유하는 제안과 Windows 관련 예시는 현재 구현 계획으로 채택하지 않았다.

## 조사 당시의 대안 평가

**Nix를 기본으로 유지하고, 비Nix 영역을 여러 기기에서 검사·수렴시키는 Ansible 계층을 권한다.**
핵심 요구는 최초 설치 편의뿐 아니라 기기 전체의 일관성이다. 단일 적용 명령만으로는
실제 상태의 이탈을 발견하거나 복구할 수 없다. 이는 이 요구에 대한 설계 판단이며,
Ansible이 업계 전체의 유일한 표준이라는 뜻은 아니다.

문제는 OS별 작업 파일이 있다는 사실보다, 각 작업 파일이 별도의 정책·설치기·비밀정보
배포·주기 작업을 갖게 되는 데 있다. 실행기는 OS에 맞게 나눌 수 있지만 같은 설정의
소유자는 하나여야 한다. Nix와 다른 도구가 동일 앱이나 설정을 동시에 관리하지 않는다.

| 선택                                  | 적합한 운영                          | 이 저장소에서의 판단                                                 |
| ------------------------------------- | ------------------------------------ | -------------------------------------------------------------------- |
| Nix 유지 + Ansible                    | 여러 기기의 공통 정책·상태 점검·복구 | 현재 요구에 추천. 기존 Nix의 담당 범위와 겹치지 않게 한다.           |
| Nix 유지 + 얇은 OS별 적용기           | 각 기기의 최초 설치·수동 적용        | bootstrap에 활용 가능하나 이것만으로 fleet 일관성을 보장하지 못한다. |
| chezmoi 추가                          | 주로 사용자 dotfiles 배포            | Home Manager와 겹친다. 현재 요구의 기본 선택으로 권하지 않는다.      |
| Windows DSC·WinGet Configuration 확대 | Windows 자체의 선언형 구성           | Windows 담당으로 유효하다. 다른 OS까지 통합하는 도구는 아니다.       |

## 여기서 일관성이 의미하는 것

동일한 OS 명령을 실행하는 것이 아니라 다음 계약을 같은 정책으로 관리하는 것이다.

| 대상 상태 | 공통 계약                                  | OS별 구현 예                      |
| --------- | ------------------------------------------ | --------------------------------- |
| 앱        | 필요한 앱 설치·허용 버전                   | Nix/Homebrew, APT, Windows MSI    |
| 서비스    | 활성화·실행·부팅 시 시작                   | launchd, systemd, Windows Service |
| RustDesk  | 접속 정책·비밀번호 revision·기기별 고유 ID | 앱 CLI와 검증 작업                |
| Tailscale | 기존 identity 보존·역할에 맞는 가입        | 상태 조회 후 미가입 기기만 등록   |
| 상태 이탈 | 수동 변경 감지·보고·필요 시 복구           | 같은 inventory와 playbook         |

**정책 선언 → 실제 상태 조회 → 차이 보고 → 적용 → 재검증**이 있어야 한다.
실행 명령을 하나로 감싸는 것과 이 상태 관리 과정은 다르다.
Ansible 공식 문서는 playbook을 반복 가능한 다중 기기 구성관리로 설명하며,
inventory는 그룹 정책과 호스트별 예외를 제공한다.
[Playbooks](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html),
[inventory](https://docs.ansible.com/projects/ansible/latest/getting_started/get_started_inventory.html)

## 공식 문서에서 확인한 내용

### 1. Ansible은 중앙 관리를 제공하지만 최초 연결 준비는 남는다

Ansible controller는 macOS에서 실행할 수 있다. Windows native controller는 지원하지
않으며 Windows를 제어 대상으로 삼을 때는 SSH 또는 WinRM/PSRP 연결이 필요하다.
Windows SSH 공식 지원은 Ansible 2.18부터이며 Microsoft OpenSSH 7.9.0.0 이상이
요구된다. [controller 요건](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html),
[Windows 연결](https://docs.ansible.com/projects/ansible/latest/os_guide/intro_windows.html),
[Windows SSH](https://docs.ansible.com/projects/ansible/latest/os_guide/windows_ssh.html)

**판단:** 아직 Tailscale에 가입하지 않은 새 기기를 Tailscale만으로 찾아 가입시키는 것은
불가능하다. local bootstrap, LAN SSH, 이미 준비된 WinRM 같은 최초 경로가 필요하다.
이는 Ansible을 배제할 이유가 아니라 최초 준비와 반복 구성관리를 분리할 이유다.

### 2. Nix의 사용자 환경 관리와 native 시스템 관리는 범위가 다르다

Home Manager는 사용자 패키지와 dotfiles를 관리하며 NixOS·Darwin 모듈 외에 standalone
방식을 제공한다. Nix의 공식 Windows 설치 경로는 WSL2다.
[Home Manager](https://github.com/nix-community/home-manager),
[Nix 설치 플랫폼](https://nix.dev/install-nix)

**판단:** Debian 사용자 환경에는 기존 standalone Home Manager를 활용할 수 있지만,
Debian의 native 시스템 서비스와 Windows의 native 서비스까지 같은 NixOS 모듈처럼
취급해서는 안 된다. 기존 Nix 구성을 전면 교체하는 것보다 관리 경계를 명시하는 편이 낫다.

### 3. RustDesk의 멱등성은 도구를 바꿔도 설계해야 한다

RustDesk는 `--password`, `--get-id`, `--import-config` 등 CLI와 Windows 배포 방식을
문서화한다. Ansible의 command 계열 모듈은 일반 명령 실행 기능이며, `creates`·`removes`
등을 이용한 상태 판정이 가능하지만 RustDesk 비밀번호 상태를 이해하는 전용 resource는
아니다. check mode도 모든 명령의 실제 결과를 예측하지는 못한다.
[RustDesk CLI](https://rustdesk.com/docs/en/client/),
[Windows command](https://docs.ansible.com/projects/ansible/latest/collections/ansible/windows/win_command_module.html),
[check mode](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html)

**판단:** 설정 조회·변경 판정·비밀번호 회전 시점은 여전히 필요하다. Ansible YAML 안에
큰 shell·PowerShell 스크립트를 옮기는 것만으로 파편화가 해결되지는 않는다.
비밀번호 설정 CLI를 쓰면 적용 순간 프로세스 인자에 비밀번호가 들어간다.
로그 숨김과 프로세스 인자 노출은 별도 문제다.

Ansible은 Debian APT, Homebrew cask, Windows package·service용 공식 collection 모듈을
제공한다. 이 범위는 직접 만든 범용 설치기 대신 검증된 상태 관리 기능을 활용할 수 있다.
다만 Nix가 cask 설치를 소유한다면 Ansible Homebrew 모듈로 같은 앱을 중복 관리하지 않는다.
[APT](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_module.html),
[Homebrew cask](https://docs.ansible.com/projects/ansible/latest/collections/community/general/homebrew_cask_module.html),
[Windows package](https://docs.ansible.com/projects/ansible/latest/collections/ansible/windows/win_package_module.html),
[Windows service](https://docs.ansible.com/projects/ansible/latest/collections/ansible/windows/win_service_module.html)

`changed_when`은 변경 보고 규칙이며 실제 명령의 반복 실행을 막는 장치가 아니다.
조회할 수 없는 비밀번호 상태에 marker만 두고 전체 drift 검사를 보장했다고 보고하지 않는다.
[Ansible Lint 지침](https://docs.ansible.com/projects/lint/rules/no-changed-when/)

### 4. Ansible의 장점은 대상 기기에 age identity를 배포하지 않을 수 있다는 점이다

`community.sops.sops` lookup은 controller의 파일을 controller의 sops 실행기로
복호화한다. 이 collection은 ansible-core 내장이 아니다. `no_log`는 작업 출력에 대한
보호이며 디버그 출력이나 다른 작업의 재출력까지 자동 보호하지 않는다.
[sops lookup](https://docs.ansible.com/projects/ansible/latest/collections/community/sops/sops_lookup.html),
[Ansible 로깅](https://docs.ansible.com/projects/ansible-core/2.22/reference_appendices/logging.html)

**판단:** 중앙 push를 선택하면 공통 비밀번호는 sops로 보관하고 관리 컴퓨터에서만
복호화할 수 있다. 대상마다 age 개인 키·sops 실행기·별도 복호화 서비스를 복제하는 구조를
줄일 수 있다. 대신 controller 접근과 고정된 collection 버전을 관리해야 한다.
독립적인 local 적용을 선택하면 해당 기기에서 비밀정보를 얻는 bootstrap 경로가 필요하다.

### 5. Tailscale 가입은 사용자 기기와 서비스 기기를 구분해야 한다

Tailscale은 태그를 서비스 기기용 신원으로 설명하며 MacBook 같은 최종 사용자 기기의
인증에 적합하지 않다고 명시한다. 사용자 생성 auth key는 사용자 소유 기기를 등록할 수
있지만 태그를 지정하면 태그 소유가 된다. 가입용 auth key의 수명은 최대 90일이다.
[태그](https://tailscale.com/docs/features/tags),
[auth keys](https://tailscale.com/docs/features/access-control/auth-keys)

OAuth client credential 흐름은 태그 소유 기기 자동화에 사용한다. 사용자 소유 OAuth app
기기 등록 흐름은 기기마다 사용자 동의를 요구한다.
[OAuth clients](https://tailscale.com/docs/features/oauth-clients),
[사용자 소유 기기 등록](https://tailscale.com/docs/features/oauth-apps/device-provisioning)

**판단:** 하나의 영구 가입 키를 모든 개인 노트북·무인 기기에 복사하는 방식은 권하지 않는다.
가입용 키의 만료와 이미 가입한 기기의 인증 상태는 별개다. 개인 기기의 최초 동의와
무인 서비스 기기의 자동 등록을 다른 정책으로 둔다. RustDesk 공통 비밀번호를 쓰기로 한
사용자 결정은 Tailscale의 기기 신원·가입 키까지 공유한다는 의미가 아니다.

### 6. chezmoi와 Windows DSC도 각자의 범위가 있다

chezmoi는 패키지 설치를 imperative script로 처리하며, scripts는 선언형 동작을 벗어나므로
적게 쓰고 멱등성을 직접 지키도록 안내한다.
[패키지 관리](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/),
[스크립트](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)

WinGet Configuration은 YAML과 PowerShell DSC를 사용하는 Microsoft의 공식 선언형
구성 기능이다. 다만 개요 문서만으로 sops 연동이나 RustDesk 전용 resource 지원까지
확인하지는 못했다. 지원하지 않는다고 단정하는 것도 근거가 부족하다.
[Microsoft 안내](https://learn.microsoft.com/en-us/windows/package-manager/configuration/)

**판단:** chezmoi를 추가하는 것은 기존 Home Manager와 중복되기 쉽다. Windows는 이미
있는 WinGet 선언을 유지하고, 앱이 제공하는 CLI가 필요한 부분만 작게 보완하는 편이 낫다.

### 7. 설치 완료와 원격 제어 완료는 다르다

RustDesk의 macOS 화면 제어에는 Accessibility·Screen Recording 등의 권한이 필요하다.
Tailscale을 통한 RustDesk 직접 접속은 별도 RustDesk 서버 없는 공식 안내 조합이지만,
RustDesk 주소록 동기화와는 별개 요구다.
[RustDesk Mac](https://rustdesk.com/docs/en/client/mac/),
[Tailscale·RustDesk](https://tailscale.com/blog/tailscale-rustdesk-remote-desktop-access)

**판단:** OS 권한 승인과 실제 두 기기 간 화면 제어를 완료 조건에 포함해야 한다.
구성 평가·합성 인증정보 테스트만으로 실제 접속 성공을 보고하지 않는다.

## 권장 구조와 관리 책임

다음은 구현 승인이 아닌 제안이다. 기존 Nix 기반, UTM 제거, sops 암호화 파일은 유지한다.

```text
기존 Nix 설정                    # 기존 담당 유지
configuration-management/
  inventory.yml                 # 공통 호스트 원본에서 생성하거나 원본 자체로 지정
  group_vars/                   # 공통 정책·역할별 예외·secret 참조
  requirements.yml              # collection 버전 고정
  site.yml
  roles/remote_access/
    tasks/main.yml
    tasks/darwin.yml
    tasks/debian.yml
    tasks/windows.yml
```

호스트 이름과 역할을 Nix registry와 Ansible inventory에 각각 수동 관리하지 않는다.
공통 데이터에서 각 도구의 입력을 내보내는 방식과 기존 선언 확장 중 하나를 선택한다.
구체적 파일 형식은 아직 확정하지 않았다.

| 항목                                       | 담당 추천                            |
| ------------------------------------------ | ------------------------------------ |
| 기존 Nix 패키지·Home Manager·nix-darwin    | 기존 Nix                             |
| Nix 밖의 Debian·Windows 앱과 시스템 서비스 | Ansible의 OS별 모듈                  |
| Nix로 선언하지 못한 앱 설정·가입 상태      | 공통 Ansible role의 조회·조건부 적용 |
| 공통 비밀정보 저장                         | 기존 sops                            |
| 복호화·점검·실행 결과                      | Mac/Linux controller에서 Ansible     |

OS별 작업 파일은 정상적인 구현 차이다. 분산된 정책·중복된 설정 소유권·각각의
범용 적용기가 파편화다. RustDesk 전용 CLI가 필요한 작은 부분까지 사라지는 것은 아니다.

## 지속적인 일관성: 점검과 강제 적용을 구분

Ansible은 실행할 때 상태를 수렴시키며, 실행하지 않는 동안 상태를 자동 강제하지 않는다.
`ansible-pull`은 각 노드가 저장소에서 받아 cron 등으로 실행하는 방식을 지원한다.
그러나 Windows native controller는 지원되지 않으므로 모든 OS에 같은 pull 실행기를
설치하는 설계는 맞지 않는다. Mac controller에서 같은 playbook을 수동·예약 실행하는
방식을 기본으로 권한다. 잠든 노트북은 정책 위반과 미접속을 구분해 보고한다.
[ansible-pull](https://docs.ansible.com/projects/ansible/latest/cli/ansible-pull.html),
[Windows 요건](https://docs.ansible.com/projects/ansible/latest/os_guide/intro_windows.html)

| 실행 방식           | 의미                    | 도입 순서                      |
| ------------------- | ----------------------- | ------------------------------ |
| 필요할 때 적용      | 실행 시 정책으로 수렴   | 먼저 구현                      |
| 정기 읽기 전용 점검 | 이탈·미접속 보고        | 기본 추가 권장                 |
| 정기 자동 적용      | 검증된 항목을 자동 복구 | 서비스 등 안전한 범위부터 선택 |

`--check`·`--diff`는 지원 모듈만 시뮬레이션한다. RustDesk CLI에는 별도 읽기 전용
검증이 필요하다. 비밀 작업은 `no_log`와 `diff: false`로 보호하고 결과를 재출력하지 않는다.
현재 만든 앱별 60초 설정 작업은 이 공통 점검·적용 계층으로 대체하는 방향을 권한다.
점검 주기는 기기 사용 패턴에 맞춰 정하며, 분 단위 재적용을 기본값으로 두지 않는다.

AWX도 예약 작업을 제공하지만 현재 규모에서 별도 서버·DB·웹 운영까지 추가할 근거는
약하다. 우선 CLI와 controller의 OS scheduler로 시작하고, 다중 관리자·UI·중앙 실행
이력이 필요해질 때 검토한다. [AWX schedules](https://github.com/ansible/awx/blob/devel/docs/schedules.md)

## 구현 전 검증 기준

1. 설치·서비스·앱 설정별 관리 도구를 하나씩 지정하고 중복 소유가 없는지 확인한다.
2. 실제 Debian·Windows에서 두 번 적용해 재설치·재가입·ID 재생성이 없는지 확인한다.
3. 서비스 중지·설정 수정을 의도적으로 만들어 읽기 전용 점검이 감지하는지 확인한다.
4. 적용 후 정책으로 복구되고 다시 점검했을 때 차이가 없는지 확인한다.
5. 비밀번호 회전·재부팅·미접속 기기·최초 가입을 별도 시나리오로 검증한다.

## 아직 결정하지 않은 사항

여러 기기의 일관성 관리가 핵심 요구임을 확인했다. 실제 Debian·Windows 호스트 정보,
관리 컴퓨터, 정기 점검·자동 복구 범위는 확정하지 않았다.
Tailscale 신규 가입 자격증명은 확보하지 못했다. native 설치·서비스·방화벽·예약 작업은
실제 Debian·Windows 대상에서 검증하지 않았다. 이번 조사는 이 미완료 상태를 바꾸지 않는다.
