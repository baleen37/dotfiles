# Bootstrap / switch 분리

## 후속 변경: GUI 없는 인증

부트스트랩 도구에서 1Password GUI와 앱 복사 단계를 제거했다. 현재 흐름은
Nix로 CLI 준비 → 기존 GUI 연동 또는 CLI 인증 확인 → 필요하면 터미널에서
`op account add`와 `op signin --raw` → 기존 age 키 복원이다. GUI 연동을 사용할 수
없을 때만 `OP_BIOMETRIC_UNLOCK_ENABLED=false`로 터미널 인증을 시도한다.
사용자가 이 환경 변수를 미리 false로 지정하면 처음부터 GUI 연동을 사용하지 않는다. 세션 토큰은 출력하거나 파일로 저장하지 않는다.
기존 호스트의 1Password 앱 선택은 유지하여 전체 switch 때 설치한다.
아래 GUI 설치·서명 검증 기록은 변경 이전 구현의 실행 기록이다.

후속 실행 검증: GUI 없는 bootstrap-tools 빌드 성공. 격리한 CLI 설정으로 실제
Nix `op`가 터미널의 계정 주소 입력 프롬프트까지 도달한 뒤 입력 없이 중단했다.
Nix 설치·플랫폼 명령과 인증 서비스를 대체한 격리 환경에서는 공개 bootstrap CLI의
계정 등록 → 로그인 → 가짜 age 키 복원이 성공했고 키 권한은 `0600`이었다.
비대화형·미인증 실행은 설치 완료로 보고하지 않고 종료 코드 1로 중단했다.
실제 개인 금고 인증과 개인 키 복원은 실행하지 않았다.

공식 근거: [CLI 수동 로그인](https://developer.1password.com/docs/cli/sign-in-manually/),
[환경 변수](https://developer.1password.com/docs/cli/environment-variables/).

## 실제 GUI 인증 확인

현재 Mac에서 앱 연동을 켠 CLI가 GUI 계정 1개를 인식했다. `whoami`는 처음에
`account is not signed in`으로 실패했으나 `op signin` 뒤 성공했다.
이에 bootstrap은 상태 조회 실패 시 GUI signin을 먼저 요청하도록 수정했다.
기본 참조 `op://Private/dotfiles/age-key`의 실제 조회는 Private 금고에 dotfiles
항목이 없어 실패했다. 임시 파일은 정리했고 사용자 키 파일은 변경하지 않았다.
이 참조는 확인된 기존 항목이 아니라 구현 중 정한 명명 규칙이다.

## 키 문서 이름 정리

Private 금고의 기존 문서 제목을 `dotfiles/sops`로 변경했다. 실제 `op item edit`
응답에서 새 제목과 기존 item ID 유지를 확인했다. 제목만 변경했으며 키 본문은
편집하지 않았다. bootstrap 안내와 README도 새 이름으로 맞췄다.
아래 `SOPS AGE Private Key - wooto/infra`는 발견 당시 이름이다.

## 실제 키 문서 발견

1Password 항목 검색에서 Private 금고의 `SOPS AGE Private Key - wooto/infra`
문서를 발견했다. 실제 `op document get` 다운로드와 `age-keygen -y` 검증이
성공했다. 비밀값을 출력하지 않았으며 임시 다운로드는 삭제했다.
기본 복원 대상은 이 문서의 item/vault ID로 수정했다. 기존 `--age-key-ref`는
다른 필드를 명시하는 용도로 유지한다. 이 키로 dotfiles 암호문을 복호화하는
검증은 아직 없다(실제 dotfiles SOPS 암호문이 선언되지 않음).

## SOPS age 필드로 이관

문서 항목의 필드 편집이 실제 저장에 반영되지 않아 Secure Note `dotfiles/sops`를
만들었다. `age-key`는 CONCEALED 개인키, `age-recipient`는 STRING 공개 수신자다.
실제 `op read` 결과가 원본 키와 일치하고 `age-keygen -y`의 공개키도 일치함을
확인했다. 원본 문서는 `dotfiles/sops (attachment)`로 이름만 바꿔 보존했다.
bootstrap 기본 참조는 새 Secure Note의 `age-key` 필드로 변경했다.
이는 1Password 저장 규칙이며 SOPS가 1Password 필드 구조를 직접 해석하는 것은 아니다.

## 사용자 흐름

```bash
./bootstrap.sh
./switch.sh
```

기존 `install.sh`를 `bootstrap.sh`로 변경했다. Bootstrap은 고정된 Nix 패키지로 1Password 앱·CLI와 SOPS 도구를 준비하고, 사용자 인증 후 기존 age 키를 공급한다. 전체 호스트를 활성화하지 않는다. Switch는 준비 상태를 검사한 뒤 플랫폼에 맞는 전체 적용을 수행한다.

1Password는 공식 nix-darwin 모듈과 같은 위치에 설치한다. 다른 GUI 앱의 기존 Homebrew 구성은 유지한다. 기존 Mac의 `1password`·`1password-cli` cask 선언은 공식 Nix 모듈로 옮겼다. Makefile 적용 명령은 새 스크립트의 호환 진입점이다.

개인 키는 0600 임시 파일로 받아 검증하고, 같은 파일시스템에서 덮어쓰기 없는 링크 생성으로 최종 경로에 배치한다. 기존 키는 보존한다. 인증 실패·빈 키·잘못된 키에서 성공으로 보고하지 않는다. 암호문이 아직 선언되지 않았다면 키 구문 검증까지만 가능하다고 표시한다.

사용자 시크릿은 sops-nix Home Manager 모듈로 선언한다. 기존 upstream 설치 프로그램을 동기 실행하도록 활성화 순서를 연결했다. 복호화는 파일 연결보다 먼저, GPG import는 복호화 성공 후에 수행한다. 실제 금고 참조·수신자·암호문은 제공되지 않아 임의로 만들지 않았다. GPG ownertrust는 변경하지 않는다.

## 관찰한 검증 결과

| 검증                                             | 결과                                                                                                              |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| bootstrap 도구의 실제 Nix 빌드                   | 성공                                                                                                              |
| Nix 패키지 `op --version`                        | `2.41.0`                                                                                                          |
| 1Password 앱 `codesign --verify --deep --strict` | 성공                                                                                                              |
| 실제 `switch.sh macbook-pro --build`             | 전체 시스템 빌드 성공, 활성화 없음                                                                                |
| 전체 3개 플랫폼 평가                             | 성공                                                                                                              |
| Darwin 단위·통합 assertion 빌드                  | 119개 통과                                                                                                        |
| CLI 시나리오                                     | 도구 설치 실패·op 누락·빈 응답·op 실패·잘못된 키·권한·기존 키 재사용·명시적 skip·build-only·Darwin 적용 분기 통과 |
| 실제 SOPS/GPG 암호화 fixture                     | 올바른 키 성공, 다른 키 거부, GPG import·재import 성공                                                            |
| 실제 HM 활성화 — 임시 홈                         | SSH 키·토큰 배포와 GPG import 성공, 순서 확인                                                                     |

실제 HM 활성화에서 다음 순서를 관찰했다.

```text
Activating writeBoundary
Activating sops-nix
Activating importSecretGpgKeys
Activating installPackages
Activating linkGeneration
```

복원된 가짜 SSH 키는 `ssh-keygen -y`로 파싱됐고 권한은 0600이었다. 토큰 내용도 fixture와 일치했다. 암호문과 키는 모두 검증용 데이터다.

## 한계와 검증 중 수정

- 1Password GUI 로그인·CLI 연동 및 개인 금고 접근은 실행하지 않았다. 실제 사용자 키·서비스 인증 성공을 의미하지 않는다. 로그인 시 launchd 재복호화도 이번 실행 검증에는 포함하지 않았다.
- Linux는 평가했다. 실행 빌드와 VM 검증은 Linux 빌더가 없어 수행하지 않았다.
- 전체 treefmt 검사는 기존 작업 트리의 별도 Raycast 노트에서 포맷 차이가 있었다. 해당 사용자 문서는 이 작업에서 변경하지 않았다.
- 임시 홈 검증의 첫 실행에서 HOME만 바꾸고 실제 XDG 환경변수를 상속한 실수가 있었다. Home Manager의 실제 `current-home` 포인터가 테스트 generation을 가리켰다. 활성 시스템의 기존 사용자 generation으로 복구하고, 테스트가 생성한 실제 홈의 profile 링크를 제거했다. 실제 홈의 설정 파일은 대상이 아니었으며, 이후 HOME·모든 XDG 경로·GNUPGHOME을 분리해 재검증했다. 검증 스킬에도 이 격리 조건을 기록했다.

상세 로그는 `/tmp/dotfiles-setup-*.log`, `/tmp/dotfiles-switch-live-build.log`와 `/tmp/dotfiles-sops-live-root`가 가리키는 임시 검증 폴더에 있다. 실제 시스템 전체 활성화는 수행하지 않았다.
