# wt 워크트리 워크플로우 재설계

## 목표

Zsh의 `gw` 워크트리 래퍼를 `wt`로 대체하면서, 조사에서 드러난 세 가지 실제 문제를 해결한다.

1. **정리 경로 부재.** `.worktrees/`에 70개, 2.0G가 쌓여 있다. 47개가 30일 이상 방치됐고 20개는 이미 `main`에 머지되어 변경사항도 없다. `git worktree prune`은 이 중 하나도 지우지 못한다(`prunable` 0 — 디렉터리가 전부 실재하므로). 기존 `gw rm`은 경로를 직접 입력해야 해서 실질적으로 쓰이지 않았다.
2. **셸과 Claude Code 훅의 규칙 분기.** `gw.nix`는 `YYMMDD-` 프리픽스를 쓰지만 `WorktreeCreate` 훅이 호출하는 `~/.claude/setup-worktree.sh`는 구식 `00000-` 번호 방식을 쓴다. 더구나 이 스크립트는 **저장소에 없고** 현재 머신에만 존재한다. `settings.json`은 저장소에 있으면서 없는 파일을 가리키므로 새 머신에서는 훅이 깨진다.
3. **전환 수단 없음.** 워크트리가 70개인데 이동하려면 경로를 알아야 한다.

이름 변경 자체도 근거가 있다. `gw`는 Gradle wrapper 니모닉과 겹친다. `wt`는 macOS/Linux에서 충돌이 없다 — 유일한 충돌 사례인 Windows Terminal `wt.exe`는 이 저장소가 macOS/NixOS 전용이므로 해당하지 않는다.

## 결정

- `gw`는 **완전히 제거**한다. alias나 deprecation 경고를 남기지 않는다.
- `.worktrees/<YYMMDD>-<sanitized-branch>` 레이아웃을 **유지**한다. 업계 다수파는 형제 디렉터리나 bare-repo 허브지만, 이 저장소는 `.gitignore`에 `.worktrees/`가 등록되어 있고 `ls`의 nix-direnv gc-root 스캔이 `*/.worktrees/*/.direnv/*` 경로 구조에 묶여 있다. 레이아웃 변경은 `ls` 로직 재작성과 기존 워크트리 이관을 강제하는 반면 얻는 것이 없다. IDE의 중첩 프로젝트 오인식 경고는 Vim 중심인 이 환경에 해당사항이 적다.
- 인자 없는 `wt`는 **fzf 피커**를 띄운다. 워크트리가 70개 쌓인 상황에서는 '찾기'가 '만들기'보다 자주 필요하다.
- 랜덤 이름 생성은 `wt new`로 분리한다. 인자 없는 `wt`가 피커가 되었으므로 별도 진입점이 필요하다.
- `wt prune`은 **기본 dry-run**이다. 2.0G를 삭제하는 동작이므로 `--yes` 없이는 목록만 출력한다.
- Claude Code 훅 스크립트를 저장소로 편입하고 경로 규칙을 셸 함수와 일치시킨다.

## 사용자 동작

```
wt                    fzf 피커 → 선택한 워크트리로 cd
wt <이름>             워크트리 생성 후 cd (기존 브랜치면 재사용)
wt new                랜덤 이름으로 생성 후 cd
wt ls                 머신 전역 목록 (모든 저장소)
wt rm <경로>...       명시적 제거 + 백그라운드 nix store gc
wt prune [--stale] [--yes]
                      머지+클린 워크트리 일괄 정리
wt -h | --help        도움말
```

`ls`, `rm`, `new`, `prune`은 예약어이므로 브랜치 이름으로 쓸 수 없다. 기존 `gw`도 `ls`/`rm`에 같은 제약이 있었다.

### `wt` (피커)

현재 저장소의 `git worktree list`를 fzf로 보여준다. 각 행은 브랜치명, 메인 루트 기준 상대경로, 마지막 커밋 시각을 표시한다. 프리뷰 창에는 해당 워크트리의 `git log --oneline -5`와 `git status -s`를 띄운다. 선택하면 `cd`하고, ESC로 나가면 아무 동작도 하지 않는다.

전역 조회가 아니라 현재 저장소만 대상으로 하는 이유는 정확성이다. `wt ls`의 gc-root 스캔은 direnv에 진입한 적 있는 워크트리만 잡아내므로 피커의 기반으로는 불완전하다. 머신 전역 조회는 `wt ls`로 남긴다.

저장소 밖에서 실행하면 오류를 낸다.

### `wt prune`

각 워크트리를 세 분류로 판정한다.

| 분류  | 조건                                         | 기본 동작                  |
| ----- | -------------------------------------------- | -------------------------- |
| safe  | `main`에 머지됨 + uncommitted 없음           | 삭제 대상                  |
| stale | 미머지 + uncommitted 없음 + 30일 이상 미변경 | `--stale` 지정 시에만 대상 |
| keep  | uncommitted 있음, 또는 현재 위치한 워크트리  | 항상 보존                  |

메인 워크트리는 판정에서 제외한다. 판정 기준의 `main`은 `main`이 없으면 `master`로 대체한다 — 기존 `_find_base_branch`와 같은 규칙이다.

인자 없이 실행하면 분류별 목록과 회수 예상 용량만 출력하고 종료한다. `--yes`를 붙이면 실제로 삭제한다. 삭제는 `git worktree remove`로 수행하고, uncommitted가 없다고 판정된 것만 대상이므로 `--force`는 쓰지 않는다.

현재 위치한 워크트리가 삭제 대상에 포함될 수 있는데(예: 머지된 브랜치에서 실행), 이 경우는 keep으로 분류해 보존한다. 자기 발밑을 지우는 동작은 혼란스럽고, 다음 실행에서 다른 위치에서 지우면 된다.

전체 삭제가 끝난 뒤 `nix store gc`를 백그라운드에서 **한 번만** 실행한다. 개별 삭제마다 띄우지 않는다.

### `wt rm`

현행 `gw rm`과 동일하다. 경로를 직접 받아 `git worktree remove`에 그대로 넘기므로 `--force` 같은 플래그도 통과시킨다. 제거 후 백그라운드 `nix store gc`.

### `wt new` / `wt <이름>`

현행 `gw`의 생성 경로를 그대로 옮긴다. 랜덤 이름 생성(형용사-명사-성씨, 충돌 시 5회 재시도), 기존 브랜치 재사용, 이미 다른 워크트리에 체크아웃된 브랜치면 그쪽으로 이동, 계층적 ref 충돌 처리(`cannot lock ref`) 모두 유지한다. 생성 후 백그라운드 `nix store gc`도 유지한다.

## 구성 경계

### `users/shared/programs/zsh/wt.nix`

`gw.nix`를 리네임하고 함수명을 `wt`로 바꾼다. 순수 문자열을 반환하는 현행 패턴을 유지한다 — 테스트가 `import`로 문자열을 읽어 `lib.hasInfix`로 검증하는 구조에 의존한다.

추가되는 것은 피커와 `prune` 두 갈래다. 기존 헬퍼(`_random_branch_name`, `_sanitize_branch`, `_find_base_branch`, `_create_worktree`, `_handle_existing_worktree`, `_handle_ref_conflict`)는 그대로 둔다.

`prune`의 판정 로직은 `_classify_worktree` 헬퍼로 분리한다. 워크트리 경로를 받아 `safe`/`stale`/`keep` 중 하나를 출력한다.

### `users/shared/programs/zsh/default.nix`

188행의 `${import ./gw.nix}`를 `${import ./wt.nix}`로 바꾸고, 13행 주석의 `gw: Git worktree creation/switch`를 `wt`로 갱신한다.

### `users/shared/programs/.config/claude/setup-worktree.sh`

새로 만든다. 현재 `~/.claude/`에만 있는 파일을 저장소로 가져오면서 경로 규칙을 `<repo_root>/.worktrees/<YYMMDD>-<sanitized>`로 고친다.

훅은 bash로 실행되므로 zsh 함수인 `wt`를 호출할 수 없다. 따라서 경로 계산이 두 곳에 존재하게 되는데, 규칙 자체가 한 줄로 표현될 만큼 단순하므로 이 중복은 허용한다. 대신 양쪽이 같은 규칙을 쓰는지 테스트로 고정한다.

### `users/shared/programs/claude-code.nix`

27행의 배포 파일 목록에 `setup-worktree.sh`를 추가하고, `statusline.sh`와 같이 `chmod +x`를 적용한다.

기존 활성화 스크립트는 파일이 없을 때만 복사하므로, 이미 구식 스크립트가 있는 이 머신에서는 자동으로 갱신되지 않는다. 수동으로 삭제 후 `make switch`가 필요하며, 이는 해당 모듈 주석에 이미 명시된 동작이다.

### `CLAUDE.md`

369행 `` `gw`: Git worktree creation ``을 `wt`의 서브커맨드를 포함한 설명으로 갱신한다.

## 테스트

기존 5개 파일을 리네임하고 내부의 `gw` 참조를 `wt`로 바꾼다.

```
tests/unit/gw-subcommands-test.nix        → wt-subcommands-test.nix
tests/unit/gw-numbering-test.nix          → wt-numbering-test.nix
tests/unit/gw-sanitization-test.nix       → wt-sanitization-test.nix
tests/unit/gw-existing-worktree-test.nix  → wt-existing-worktree-test.nix
tests/unit/gw-random-collision-test.nix   → wt-random-collision-test.nix
```

신규 세 개를 추가한다.

- `wt-prune-test.nix` — `prune` 서브커맨드 존재, 세 분류(`safe`/`stale`/`keep`) 판정 로직 존재, `--yes` 없이는 삭제하지 않음, `nix store gc`가 루프 밖에서 한 번만 호출됨, 메인 워크트리 제외.
- `wt-picker-test.nix` — 인자 없는 호출이 fzf를 거침, `git worktree list`를 기반으로 함, 프리뷰 설정 존재.
- `wt-hook-consistency-test.nix` — `wt.nix`와 `setup-worktree.sh`가 동일한 경로 규칙(`.worktrees/`, `date +%y%m%d`)을 사용함.

테스트는 문자열 검사 방식이라 동작이 아니라 구현의 존재를 확인한다. 이는 기존 `gw` 테스트가 이미 채택한 방식이며 셸 함수를 Nix 평가 시점에 실행할 수 없다는 제약에서 온다. 실제 동작 검증은 아래 실행 단계가 담당한다.

## 검증

1. `make format` → nixfmt 통과
2. `nix flake check --impure` → 신규 포함 전체 테스트 통과
3. `make switch` → 셸 재기동 후 `wt -h` 동작
4. `wt` → 피커가 뜨고 선택 시 이동
5. `wt prune` → dry-run 목록에 safe 20개가 잡히는지 확인
6. `wt prune --yes` → 실제 회수, `git worktree list` 개수 감소 확인
7. `wt prune --stale` → 잔여 검토 후 선택적 실행
8. `~/.claude/setup-worktree.sh` 삭제 후 `make switch` → 새 스크립트 배포 확인, Claude Code로 워크트리 생성 시 `YYMMDD-` 규칙 적용 확인

5~7단계는 메인 워크트리(`/Users/jito.hello/dotfiles`)에서 실행한다. 현재 작업 중인 워크트리는 `keep`으로 분류되어 정리 대상에서 빠지므로, 워크트리 안에서 돌리면 그 하나가 남는다.

6단계는 새 기능의 실전 검증을 겸한다. 판정이 틀려 살아 있어야 할 워크트리를 지우면 브랜치는 남으므로 `wt <브랜치명>`으로 복구할 수 있다.

## 범위 밖

- **post-create 훅(.env 자동 복사).** 업계 도구들이 공통으로 갖췄지만, 이 저장소는 direnv가 환경을 잡아주고 워크트리별로 복사해야 할 비추적 파일의 수요가 확인되지 않았다.
- **tmux 세션 통합.** 현재 워크플로우에 요구가 확인되지 않았다. 이미 sesh 기반 세션 피커가 별도로 존재한다.
- **디렉터리 레이아웃 변경.** 위 결정 참조.
- **기존 워크트리 이름 마이그레이션.** `00003-`, `260630-`, 프리픽스 없는 것이 혼재하지만 `prune`으로 대부분 사라진다. 잔여분에 `git worktree move`를 거는 것은 direnv와 nix gc-root 재생성 비용을 유발하는 데 비해 얻는 것이 이름의 일관성뿐이다.
- **`gw` 하위 호환.** 완전 제거하기로 결정했다.
