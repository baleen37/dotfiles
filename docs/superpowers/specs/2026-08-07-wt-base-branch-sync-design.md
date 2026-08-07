# wt 기준 브랜치 최신화

## 목표

새 Git worktree를 만들 때 로컬 `main` 또는 `master`가 원격 기준 브랜치보다 뒤처지지 않도록 먼저 최신화한다.

## 범위

- 새 브랜치를 만드는 `wt <새 브랜치>`와 `wt new`에 적용한다.
- 기준 브랜치는 기존 `_find_base_branch` 규칙을 따른다. `main`을 우선하고, 없으면 `master`를 사용한다.
- 이미 존재하는 브랜치를 worktree로 연결하는 경우에는 기준 브랜치를 변경하지 않는다.
- 기존 worktree 경로, 브랜치 충돌 처리, Herdr 연동, 백그라운드 GC는 변경하지 않는다.

## 동작 설계

새 브랜치 생성이 필요한 경우, 기준 브랜치를 사용하는 실제 main worktree에서 다음을 순서대로 실행한다.

1. `git fetch origin`
2. `git pull --ff-only origin <base_branch>`
3. 최신화된 `<base_branch>`를 기준으로 `git worktree add -b` 실행

기준 worktree 경로는 `git worktree list --porcelain`에서 `branch refs/heads/<base_branch>` 항목과 함께 찾는다. 따라서 현재 셸이 다른 worktree 안에 있어도 기준 브랜치가 체크아웃된 위치에서 명령을 수행할 수 있다. 기준 브랜치가 어떤 worktree에도 체크아웃되어 있지 않으면 생성하지 않는다.

## 실패 처리

fetch 또는 fast-forward pull이 실패하면 오류 메시지를 출력하고 worktree 생성을 중단한다. dirty 상태, `origin` 부재, 로컬 변경과 충돌하는 pull, fast-forward 불가 상황은 모두 이 경로로 처리한다.

최신화 성공 여부는 `git` 명령의 종료 코드로 판단한다. 별도의 강제 reset, stash, merge, rebase는 수행하지 않는다.

## 테스트

문자열 기반 Nix 단위 테스트를 추가해 다음 계약을 고정한다.

- 최신화 헬퍼가 존재한다.
- `git fetch origin`과 `git pull --ff-only origin`을 사용한다.
- main worktree 경로를 `git worktree list --porcelain`에서 찾는다.
- 최신화 실패 시 생성 경로가 중단된다.
- 새 브랜치를 만드는 흐름에서 최신화가 worktree 생성보다 먼저 호출된다.

기존 `wt` 테스트와 `nix flake check --impure`로 회귀를 확인한다.
