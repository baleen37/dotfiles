# tmux Agent Status Rendering 설계

## 목표

bstack `me` 플러그인이 tmux pane option으로 기록한 agent 상태를 Herdr 없이
기존 tmux UI에 표시한다.

성공 조건:

- 현재 window 목록에 agent 상태 glyph가 보인다.
- `status-right`에 tmux server 전체의 상태별 agent 수가 보인다.
- 기존 OSC 2 `pane_title` 표시는 상태가 없을 때 fallback으로 유지된다.
- Continuum이 추가하는 `status-right` 내용과 기존 날짜/시간 표시가 유지된다.
- `me` 플러그인이 없거나 agent가 tmux 밖에서 실행돼도 tmux는 정상 동작한다.

## 외부 인터페이스

dotfiles는 pane-local tmux user option `@agent_status`만 소비한다. 허용 값은 다음
다섯 가지다.

| 값            | 표시      | 의미                           |
| ------------- | --------- | ------------------------------ |
| `running`     | `●`       | agent가 turn을 처리 중         |
| `needs_input` | `▲`       | 권한 승인이나 사용자 입력 대기 |
| `ready`       | `○`       | 다음 입력을 받을 수 있음       |
| `error`       | `✕`       | provider가 보고한 실패         |
| 값 없음       | 표시 없음 | agent 상태를 알 수 없음        |

이번 bstack 공용 hook은 Claude와 Codex가 함께 제공하는 이벤트만 사용하므로
`error`를 아직 쓰지 않는다. dotfiles는 이후 provider adapter가 `error`를
기록해도 설정 변경 없이 표시할 수 있게 렌더링만 지원한다.

## 구성

### 상태별 glyph

`users/shared/programs/tmux.nix`에서 semantic state를 glyph로 바꾸는 tmux format을
한 번 정의하고 현재/비현재 window format에서 재사용한다. 상태가 없으면 기존
`pane_title != host` 조건과 window name fallback을 그대로 사용한다.

### 전체 요약

`users/shared/programs/tmux-agent-status-summary.sh`는
`tmux list-panes -a -F '#{@agent_status}'` 결과만 읽는다. 알려진 상태의 개수를
세고 0보다 큰 항목만 고정 순서 `●N ▲N ○N ✕N`으로 출력한다.

스크립트는 transcript, process tree, `capture-pane`, Herdr 파일을 읽지 않는다.
tmux server가 없거나 명령이 실패하면 빈 문자열과 성공 exit code를 반환한다.

Home Manager는 스크립트를 `pkgs.writeShellApplication`으로 패키징한다. tmux
설정은 store의 절대 실행 경로를 사용하므로 login shell PATH에 의존하지 않는다.

### status-right 순서

요약 command는 Continuum plugin의 `extraConfig` 안 기존 `status-right` 앞부분에
추가한다. 이 설정은 Continuum이 로드되기 전에 존재해야 하며, 이후 Continuum이
기존 `status-right`를 확장하는 동작을 유지한다.

## 저장소 경계

- bstack `plugins/me`: lifecycle event를 `@agent_status`로 변환하고 pane option을
  설정하거나 해제한다.
- dotfiles: semantic state를 tmux UI로 렌더링하고 전체 개수를 집계한다.
- Herdr: 의존하지 않으며 이 기능의 source of truth도 아니다.

## 오류 처리

- option 값이 없거나 알려지지 않았으면 glyph와 집계에서 제외한다.
- tmux server 조회 실패는 status bar를 깨뜨리지 않고 빈 요약으로 끝낸다.
- `SessionEnd`가 SIGKILL 등으로 누락되면 stale option이 남을 수 있다. 이번
  최소 범위에서는 다음 lifecycle event나 pane 종료가 이를 정리한다.
- prompt, cwd, assistant message 같은 외부 문자열은 status format에 넣지 않는다.

## 검증

- 실제 summary script를 fake tmux command와 함께 실행해 상태별 집계, 빈 상태,
  조회 실패 동작을 검증한다.
- 생성된 tmux 설정에서 window format이 `@agent_status`를 우선하고 기존
  `pane_title` fallback을 보존하는지 검증한다.
- 생성된 설정에서 agent summary가 Continuum load보다 먼저 설정되고 날짜/시간
  표시가 유지되는지 검증한다.
- focused integration checks, `make test`, formatter를 실행한다.
