# ADR 0005: 원격 접속은 한 번 할 일은 bootstrap, 반복할 일은 switch 활성화에서 한다

- 상태: 제안
- 날짜: 2026-11-10

원격 접속 설정을 성격대로 나눈다. 기기당 한 번 하는 등록은 bootstrap이, 매번 맞춰 둘 설정은
switch의 시스템 활성화가 맡는다. 별도 `dotfiles-remote-apply` 단계는 없앤다.

| 할 일                  | 성격                 | 맡는 곳                       |
| ---------------------- | -------------------- | ----------------------------- |
| age identity 받기      | 한 번                | bootstrap                     |
| Tailscale 설치·가입    | 한 번                | bootstrap                     |
| RustDesk 비밀번호·옵션 | 반복, 바뀔 때만 변경 | switch의 시스템 활성화 (root) |

원격 기기도 SSH로 들어가 같은 `./bootstrap.sh`와 `./switch.sh`를 실행한다. 별도 원격 설치 명령은
만들지 않는다.

이유: 반복 실행은 사람 입력 없이 끝나야 하고, 한 번만 필요한 일은 등록 단계에 둔다.
RustDesk 설정을 sudo 별도 단계로 두면 switch마다 암호를 물었다. 활성화는 이미 root로,
암호 없이 돈다([ADR 0003](0003-passwordless-repeat-bootstrap-and-switch.md)). 사용자가 고칠 수 있는
flake를 root로 활성화하는 순간 root 코드 실행은 이미 위임된 것이므로, RustDesk만 암호로 막아도
얻는 보안은 없다.

macOS RustDesk 설정은 사용자가 GUI에 로그인해 RustDesk 서버가 떠 있어야 적용된다. 조건이 안 되면
활성화는 실패하지 않고 건너뛰며, 다음 switch에서 적용한다.

이 결정은 [원격 접속 문서](../remote-access.md)의 "switch가 원격 접속 설정을 적용한다"와
"RustDesk 설정에는 비밀번호 없는 sudo 예외를 두지 않는다"를 대체한다.
