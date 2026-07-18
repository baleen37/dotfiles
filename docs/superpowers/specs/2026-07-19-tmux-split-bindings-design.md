# tmux 분할 키 설계

- 날짜: 2026-07-19
- 상태: 승인됨

## 목표

tmux의 기본 분할 키 대신 입력하기 쉬운 다음 바인딩을 사용한다.

- `Prefix+|`: 현재 pane 경로를 유지하며 좌우 분할 (`split-window -h`)
- `Prefix+-`: 현재 pane 경로를 유지하며 상하 분할 (`split-window -v`)

기본 `%`와 `"` 바인딩은 해제해 분할 키를 위 두 가지로 한정한다.

## 변경 범위

- `users/shared/programs/tmux.nix`의 바인딩과 설명을 갱신한다.
- `tests/integration/tmux-functionality-test.nix`가 새 바인딩과 기본 키 해제를 검증하게 한다.
- 다른 tmux 설정은 변경하지 않는다.

## 검증

- tmux 통합 테스트에서 `|`/`-` 바인딩과 `%`/`"` 해제를 확인한다.
- 생성된 tmux 설정의 문법을 검사한다.
