# sudo 암호와 앱·에이전트 승인 분리 조사

- 날짜: 2026-11-08
- 질문: Herdr에서 bootstrap과 switch를 실행할 때 앞으로 권한·암호를 묻지 않도록 설정할 수 있는가?
- 범위: 공식 sudo 매뉴얼, Apple 문서·소스, Herdr 공식 매뉴얼과 설치된 CLI

## 결론

sudo 암호를 생략하는 설정은 sudoers의 `NOPASSWD`다. 현재 머신 설정에 추가한
명령별 `NOPASSWD`가 이 방식이다. 현재 시스템에는 아직 적용되지 않았으므로
최초 관리자 인증과 적용이 남아 있다. 유효한 관리자 세션·인증 캐시·기존 무암호
권한이 없다면, 사용자 권한만으로 최초 관리자 권한을 부여할 수는 없다.

현재 에이전트 도구의 실행 승인 정책은 이미 자동 허용이다. 이는 이 조사 세션의
실행 환경 관찰이며, sudo 인증이나 macOS 개인정보 권한을 바꾸지는 않는다.

## 선택지

| 설정                            | 반복 인증                    | 적용 범위                                                            |
| ------------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| 명령별 `NOPASSWD`               | 해당 명령은 생략             | 현재 구현. 호스트 적용과 세대 정리 명령                              |
| `NOPASSWD: ALL`                 | 모든 허용 sudo 명령에서 생략 | 해당 사용자로 실행되는 모든 프로그램의 무암호 관리자 실행            |
| `Defaults:baleen !authenticate` | 기본 인증 생략               | 기존 허용 규칙의 인증 기본값 변경. `PASSWD` 태그로 재정의 가능       |
| `timestamp_timeout=-1`          | 최초 인증 필요               | 인증 캐시의 시간 만료 제거. 재부팅·캐시 삭제·세션 범위의 영향은 남음 |
| Touch ID                        | 지문 승인 필요               | 암호 입력 대체. 사용자 상호작용은 유지                               |

정책 의미는 [sudo 공식 매뉴얼 원본](https://raw.githubusercontent.com/sudo-project/sudo/main/docs/sudoers.mdoc.in)과
설치된 sudo 1.9.17p2의 `man sudoers`에서 `PASSWD and NOPASSWD`, `authenticate`,
`timestamp_timeout`, `timestamp_type` 항목을 확인했다. 무인 반복 실행에는
현재의 명령별 `NOPASSWD`가 직접적인 해결책이며, 캐시 연장은 동등한 대안이 아니다.

전체 sudo 인증을 생략하는 문법 자체는 다음과 같다. 이번 조사로 추가 적용하지 않았다.

```sudoers
baleen ALL = (ALL) NOPASSWD: ALL
```

## 권한의 세 층

1. macOS 앱 관리: 다른 앱을 갱신·삭제할 수 있는 동의다. 관리자 인증 면제가 아니다.
   [Apple 앱 관리 설정](https://support.apple.com/en-au/guide/mac-help/mchl211c911f/mac)
2. Herdr와 내부 에이전트의 실행 승인: 확인한 공식 매뉴얼과 로컬 `herdr-app --help`,
   `herdr-app --skill`, `hc --help`에는 Herdr만 sudo를 영구 허용하는 옵션이 없었다.
   미발견을 기능 부재의 확정으로 보지는 않는다.
   [Herdr 공식 매뉴얼](https://github.com/herdrdev/herdr-app/blob/master/defaults/AGENTS.md)
3. sudo 관리자 인증: OS의 sudoers 정책으로 제어한다. Herdr에서 명령 실행을
   승인하는 것만으로 sudo 암호가 없어지지는 않는다는 판단은 두 실행 계층을
   결합한 추론이다.

Touch ID는 사용자 상호작용과 실행 세션의 영향을 받으므로 무인 실행을 보장하지 않는다.
현재 Herdr 세션에서 실제 Touch ID 성공 여부는 검증하지 않았다.
[Apple pam_tid 소스](https://github.com/apple-oss-distributions/pam_modules/blob/main/modules/pam_tid/pam_tid.c)

## 현재 구현의 의미와 남은 검증

- bootstrap은 설치가 필요할 때만 `sudo -v`를 실행한다. 준비된 머신의 재실행은
  sudo 없이 가능하지만, 새 도구 설치까지 무조건 무인화한 것은 아니다.
- switch는 현재 머신의 `darwin-rebuild switch`와 `nh clean all --keep 3`에
  `NOPASSWD`를 선언한다. 로컬 호스트와 필터링된 임시 소스 경로를 지원한다.
- 명령별 규칙이 있어도 `sudo -v`의 인증 조건은 별개다. 기본 `verifypw` 정책에서는
  두 명령의 허용만으로 모든 sudo 인증 확인이 무암호가 되지는 않는다.
- 사용자가 수정 가능한 flake를 root로 활성화하므로, 명령별 규칙이 악의적인
  구성의 root 코드 실행까지 차단하는 보안 경계는 아니라는 점은 실행 구조에 대한 추론이다.

최초 적용 후 정확한 명령·인자로 `sudo -n -l <command> <arguments>`를 확인하고,
인증 캐시가 없는 상태에서 실제 switch를 검증한다. `true`는 허용 목록에 없으므로
`sudo -n true` 실패를 정책 전체의 실패로 해석하면 안 된다.

현재 규칙의 의도와 최초 적용 절차는 [ADR 0003](../adr/0003-passwordless-repeat-bootstrap-and-switch.md)에 기록했다.
이번 조사는 시스템 권한을 변경하지 않았다.
