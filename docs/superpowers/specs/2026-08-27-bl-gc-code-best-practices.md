# `bl gc` 셸 도구 베스트 프랙티스 조사

**Date:** 2026-08-27
**Status:** 조사 완료, 권고사항 일부 적용 완료
**Scope:** Bash/ShellCheck 오류 처리와 안전한 파일 삭제, Git worktree `list`/`remove` 계약, Nix `writeShellApplication`, Docker prune 범위
**Reviewed commit:** `a2db080f` (`feat(toolkit): add safe baleen gc command`)

검토 기준은 기존 커밋 `a2db080f`와 그 위에 적용한 베스트 프랙티스 변경이다. 변경 범위는 셸 도구, Home Manager 모듈, 해당 단위 테스트로 제한했다.

이 문서는 공식 1차 자료만 외부 근거로 사용했다. Bash와 ShellCheck는 각 프로젝트의 공식 문서, Git은 공식 Git 문서, Nix는 Nixpkgs 공식 매뉴얼과 현재 저장소가 고정한 Nixpkgs 소스, Docker는 Docker 공식 CLI 문서를 기준으로 삼았다. 저장소 코드와 테스트에 대한 판단은 `현재 저장소 적용` 절에 별도로 적었다.

## 결론

현재 `bl gc`의 삭제 범위와 확인 흐름은 전반적으로 안전하다. 이번 적용으로 다음 항목을 코드와 테스트에 반영했다.

1. `writeShellApplication`의 기본 `errexit`을 제외해 선택적 cache/Docker 명령의 실패가 전체 best-effort GC를 중단시키지 않게 했다.
2. `git worktree list --porcelain -z`를 사용해 worktree metadata를 NUL-safe하게 파싱한다.
3. `locked` worktree를 후보에서 명시적으로 제외한다.
4. GNU/BSD `stat` 차이를 고려해 GNU 형식을 먼저 시도하고 BSD 형식으로 fallback한다.

다음 항목은 현재 동작에 필요한 범위를 넘어서는 후속 테스트/관찰성 개선으로 남겼다.

- `prunable` metadata를 별도 상태로 출력하는 기능
- `git worktree list` 실패와 “Git 저장소 아님” 상태를 서로 구분하는 진단 메시지
- 실패하는 `du`/`df`와 built wrapper를 fixture에서 직접 사용하는 별도 runtime 테스트

그 외의 핵심 선택은 유지하는 것이 맞다.

- `git worktree remove`를 `--force` 없이 호출한다.
- 현재 worktree, main worktree, dirty worktree, detached/bare/unrecognized worktree를 후보에서 제외한다.
- 직접 파일 삭제는 allowlist로 제한하고, `~/Library/Caches` 전체 같은 넓은 경로를 재귀 삭제하지 않는다.
- Docker는 중지된 컨테이너, dangling image, 기본 범위의 builder cache만 별도 확인 후 정리한다.
- Docker volume, 실행 중인 컨테이너, `image prune -a`, 광범위한 `system prune`은 추가하지 않는다.
- `stats`와 `--dry-run`을 삭제 실행과 분리한다.

## 현재 구현의 경계

검토한 파일은 다음과 같다.

- [`users/shared/programs/baleen-toolkit.sh`](../../../users/shared/programs/baleen-toolkit.sh)
- [`tests/unit/baleen-toolkit-test.nix`](../../../tests/unit/baleen-toolkit-test.nix)
- [`users/shared/programs/baleen-toolkit.nix`](../../../users/shared/programs/baleen-toolkit.nix)

현재 셸 도구는 다음 흐름을 가진다.

```text
bl gc
  -> 디스크/캐시/worktree/Docker 통계 표시
  -> 개발 캐시 정리 확인
  -> 3일 이상 지난 clean worktree 정리 확인
  -> Nix store GC
  -> Docker 정리 별도 확인
  -> 남은 디스크와 변화량 표시
```

worktree 후보의 나이는 [`worktree_age_seconds`](../../../users/shared/programs/baleen-toolkit.sh#L159-L178)가 worktree 루트 디렉터리 mtime과 현재 `HEAD`의 commit timestamp 중 더 최근인 값을 기준으로 계산한다. 이 값은 Git이 제공하는 “마지막 사용 시각”이 아니라 현재 요구사항을 구현하기 위한 보수적 휴리스틱이다. 3일(`259200`초)은 사용자가 정한 정책이며 Git의 공식 의미가 아니다.

## 1. Bash와 ShellCheck

### 공식 계약

Bash의 `errexit`은 실패한 모든 명령에서 무조건 종료하는 옵션이 아니다. Bash 공식 매뉴얼은 실패 명령이 `if`/`while`/`until` 조건, `&&`/`||` 목록의 특정 위치, `!`, 파이프라인의 비마지막 명령 등에 있으면 셸이 종료하지 않을 수 있다고 설명한다. `pipefail`을 켜면 파이프라인은 마지막으로 실패한 명령의 상태를 반영한다. [Bash Reference Manual: The Set Builtin](https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin), [Bash Reference Manual: Pipelines](https://www.gnu.org/software/bash/manual/html_node/Pipelines.html)

ShellCheck는 다음 패턴을 오류 처리의 기준으로 제시한다.

- 재귀 삭제에 사용하는 변수가 비어 있을 수 있으면 `${var:?}` 같은 방어를 사용한다. 특히 빈 변수와 wildcard가 결합되면 시스템 루트까지 확장될 수 있다. [ShellCheck SC2115](https://www.shellcheck.net/wiki/SC2115)
- `A && B || C`를 `if/then/else`로 사용하지 않는다. `A`가 성공해도 `B`가 실패하면 `C`가 실행될 수 있다. [ShellCheck SC2015](https://www.shellcheck.net/wiki/SC2015)
- 실패를 검사할 때 `$?`를 나중에 비교하기보다 `if command` 또는 `if ! command`로 직접 검사한다. [ShellCheck SC2181](https://www.shellcheck.net/wiki/SC2181)
- `cd` 실패 뒤 삭제나 쓰기 작업이 다른 디렉터리에서 실행되지 않도록 `cd ... || return/exit` 또는 조건문으로 감싼다. [ShellCheck SC2164](https://www.shellcheck.net/wiki/SC2164)
- command substitution 안에서 실행한 명령의 반환값이 가려질 수 있으므로, 중요한 명령은 변수에 먼저 받거나 실패를 무시한다는 의도를 `|| true` 등으로 명시한다. [ShellCheck SC2312](https://www.shellcheck.net/wiki/SC2312)
- Bash는 command substitution 안의 함수 호출에서 `errexit`을 기본적으로 끌 수 있다. 그 동작에 의존하는 함수라면 `inherit_errexit` 또는 함수 내부의 명시적 오류 처리를 사용한다. [ShellCheck SC2311](https://www.shellcheck.net/wiki/SC2311), [Bash Reference Manual: Command Substitution](https://www.gnu.org/software/bash/manual/bash.html#Command-Substitution)

### 현재 코드와의 대조

#### 잘 지키고 있는 부분

- [`run_cleanup`](../../../users/shared/programs/baleen-toolkit.sh#L363-L373)은 각 외부 cleanup 명령을 `if "$@"; then ... else ... fi`로 감싸므로 개별 도구 실패를 기록하고 다음 단계로 진행한다.
- `resolve_cache_path`는 선택적 package manager 명령의 실패를 `|| true`로 명시적으로 무시하고 fallback 경로를 사용한다. 이 위치의 실패 무시는 의도된 optional capability 처리다.
- [`canonical_path`](../../../users/shared/programs/baleen-toolkit.sh#L141-L144)는 `(cd "$path" && pwd -P)`로 `cd` 실패를 확인한다.
- 직접 삭제는 [`clear_known_directory`](../../../users/shared/programs/baleen-toolkit.sh#L375-L389)의 allowlist를 통과한 두 경로에만 수행된다. 현재 코드에는 외부 입력을 wildcard로 붙여 `rm -rf`하는 패턴이 없다.
- 사용자의 확인 응답은 정확히 `y`/`Y`만 승인하고, EOF나 그 밖의 입력은 거부한다. 삭제 단계가 기본 거부인 구조다.
- `A && B || C` 형태로 출력 성공 여부를 기준으로 삭제를 결정하는 코드가 없다. Docker daemon probe의 `command_exists docker && docker info`는 `C`가 이어지는 if-then-else가 아니므로 SC2015의 문제 패턴과는 다르다.

#### 현재 작업 트리의 정책 선택: `errexit`과 진단 파이프라인

현재 stats 경로에는 다음과 같은 보호되지 않은 pipeline assignment가 있다.

- [`print_size`](../../../users/shared/programs/baleen-toolkit.sh#L73-L85)의 `du -sh | awk`
- [`disk_free_kb`](../../../users/shared/programs/baleen-toolkit.sh#L87-L92)의 `df -Pk | awk`
- [`print_disk_status`](../../../users/shared/programs/baleen-toolkit.sh#L94-L102)의 `df -h | awk`
- [`directory_size`](../../../users/shared/programs/baleen-toolkit.sh#L192-L199)의 `du -sh | awk`

이 파일을 Nix 패키지로 실행하면 `writeShellApplication`은 기본으로 본문 앞에 `set -o errexit`, `set -o nounset`, `set -o pipefail`을 삽입한다. 다만 현재 작업 트리의 Nix module은 [`bashOptions = [ "nounset" "pipefail" ]`](../../../users/shared/programs/baleen-toolkit.nix#L12-L19)로 `errexit`을 명시적으로 제외했다. 따라서 현재 built `bl`에서는 `du` 또는 `df` 실패가 즉시 전체 명령을 중단시키지는 않는다.

이 선택은 “best-effort cleanup”이라는 의도에는 맞지만, `errexit`을 제거하면 예상하지 못한 필수 단계의 실패도 계속 진행될 수 있다. Bash 공식 매뉴얼이 설명하듯 `errexit`은 이미 조건문 안의 명령을 예외 처리하므로, 선택적 probe와 cleanup을 `if`로 감싸는 방식이 더 좁은 실패 범위와 더 강한 기본 오류 감지를 함께 제공한다.

권장하는 후속 방향은 `errexit`을 다시 기본값으로 유지하고 통계용 probe를 선택적 capability로 취급하는 것이다.

```bash
if size=$(du -sh "$path" 2>/dev/null | awk 'NR == 1 { print $1 }'); then
  [[ -n $size ]] || size="?"
else
  size="?"
fi
```

`status`, `available`, `directory_size`에도 같은 원칙을 적용한다. cleanup 실행 자체의 실패는 이미 `run_cleanup`이 격리한다. 현재 작업 트리의 `bashOptions` override를 유지할지는 이 명시적 probe 처리와 함께 결정해야 하며, 둘을 동시에 두어 오류를 조용히 삼키는 방향은 피한다.

#### 삭제 안전성 판단

현재 직접 삭제 구현은 ShellCheck가 경고하는 가장 위험한 형태와 거리가 있다.

1. `clear_known_directory`가 허용하는 문자열은 `$HOME/.gradle/caches`와 `$HOME/Library/Developer/Xcode/DerivedData` 두 개뿐이다.
2. allowlist 밖의 경로는 즉시 거부한다.
3. 실제 삭제 전 대상이 디렉터리이고 symlink가 아닌지 확인한다.
4. 삭제 후 같은 known path를 다시 만든다.

따라서 이번 조사에서 더 넓은 삭제 경로를 추가하거나 `find ... -exec rm -rf` 형태로 바꾸는 것은 부적절하다고 판단한다. GNU `rm` 공식 문서도 `-r`이 지정된 디렉터리와 그 내용을 재귀적으로 제거한다고 설명하며, `--`로 이후 인자를 option이 아닌 파일로 구분할 수 있다고 설명한다. [GNU Coreutils `rm` invocation](https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html)

후속 변경에서 삭제 경로가 계산값이나 사용자 입력으로 확장된다면 다음 계약을 새로 요구해야 한다.

- 빈 값과 unset 값을 `${path:?}`로 거부한다.
- 경로를 항상 quote하고, 대상 경계를 allowlist 또는 canonical-path 비교로 확인한다.
- 현재처럼 `--force` 없는 Git 삭제와 별개로, 파일 삭제는 별도의 명확한 확인을 거친다.
- macOS와 Linux의 `rm` 옵션 차이를 확인한 뒤에만 `--` 같은 구현별 옵션을 추가한다.

현재 코드에 남는 실질적인 테스트 항목은 empty/unknown/symlink 경로가 삭제되지 않는지 확인하는 것이다. 이 항목은 현재 함수의 private helper를 직접 호출하는 테스트보다 실제 `bl gc` fixture에서 위험 경로를 만들어 관찰하는 방식이 적합하다.

## 2. Git worktree `list`와 `remove`

### 공식 계약

Git 공식 문서에 따르면 `git worktree list`는 main worktree를 먼저 출력하고 그 뒤 linked worktree를 출력한다. `--porcelain`은 사용자 설정과 Git 버전에 영향을 덜 받는 스크립트용 안정 포맷이며, `-z`와 함께 쓰는 것이 권장된다. `-z`는 worktree 경로에 개행이 포함된 경우에도 파싱할 수 있도록 각 줄을 NUL로 종료한다. [Git `worktree` 공식 문서: `list`](https://git-scm.com/docs/git-worktree#Documentation/git-worktree.txt-list), [Git `worktree` 공식 문서: `--porcelain`/`-z`](https://git-scm.com/docs/git-worktree#Documentation/git-worktree.txt---porcelain)

Porcelain record는 `worktree`, `HEAD`, `branch` 같은 attribute로 구성되고 빈 record가 worktree 하나의 끝을 뜻한다. `bare`, `detached`, `locked`, `prunable`은 값이 없는 flag 또는 값이 있는 attribute로 나타날 수 있다. 따라서 파서는 branch만 가정하면 안 된다. [Git `worktree` 공식 문서: Porcelain Format](https://git-scm.com/docs/git-worktree#_porcelain_format)

`git worktree remove`는 clean worktree만 제거한다. 공식 정의에서 clean은 untracked 파일과 tracked 파일 수정이 없는 상태이며, unclean worktree나 submodule을 제거하려면 `--force`가 필요하다. main worktree는 제거할 수 없다. 잠긴 worktree는 unlock하기 전까지 삭제할 수 없고, 강제 삭제에는 더 강한 force 조건이 필요하다. [Git `worktree` 공식 문서: `remove`](https://git-scm.com/docs/git-worktree#Documentation/git-worktree.txt-remove), [Git `worktree` 공식 문서: `--force`](https://git-scm.com/docs/git-worktree#Documentation/git-worktree.txt--f)

`git worktree prune`은 이미 사라진 working tree의 `$GIT_DIR/worktrees` 관리 정보 정리가 목적이다. 존재하는 오래된 디렉터리를 age policy로 지우는 명령이 아니므로, 그런 대상에는 `git worktree remove`를 사용해야 한다. [Git `worktree` 공식 문서: `prune`](https://git-scm.com/docs/git-worktree#Documentation/git-worktree.txt-prune)

### 현재 코드와의 대조

#### 유지할 부분

- 현재 작업 트리는 [`git worktree list --porcelain -z`](../../../users/shared/programs/baleen-toolkit.sh#L259-L305)을 사용한다.
- 첫 record를 main worktree로 저장하는 방식은 Git 공식 문서의 “main worktree is listed first” 계약에 부합한다.
- current, main, detached, bare, branch 이름을 식별할 수 없는 worktree를 후보에서 제외한다.
- `git status --porcelain`이 비어 있지 않으면 dirty로 보고 후보에서 제외한다. Git 공식 문서도 `--porcelain`을 스크립트용 안정 포맷으로 정의한다. [Git `status` 공식 문서](https://git-scm.com/docs/git-status#Documentation/git-status.txt---porcelainltversiongt)
- 최종 삭제는 [`git worktree remove "$target"`](../../../users/shared/programs/baleen-toolkit.sh#L446-L462)이고 `--force`가 없다. inventory 시점과 삭제 시점 사이에 worktree가 dirty가 되어도 Git의 최종 clean 검사가 보호막으로 남는다.
- missing worktree는 `canonical_path` 단계에서 실제 디렉터리로 확인되지 않으므로 후보가 되지 않는다. 이는 자동 복구나 수동 삭제로 확장하지 않는 fail-closed 동작이다. `prunable` field 자체는 현재 별도 출력하지 않으며, 후속 관찰성 개선으로 남겼다.

#### 현재 작업 트리의 NUL-safe parser와 locked 보호

현재 작업 트리의 parser는 `while IFS= read -r -d '' field`로 NUL-delimited output을 읽고 [`worktree `](../../../users/shared/programs/baleen-toolkit.sh#L268-L305) 접두사를 처리한다. Git 공식 권장 방식에 맞춰 개행이 포함된 경로의 record 경계를 보존한다.

`locked` worktree는 Git이 force 없이 제거하지 않는 보호 대상이므로 후보에서 먼저 제외한다. `prunable`은 실제 경로가 없어 `canonical_path`에서 탈락하는 현재 동작을 유지하고 별도 정리 대상으로 확장하지 않았다.

남은 후속 방향은 `prunable` metadata를 별도 상태로 저장하고, `git worktree list`의 process substitution 반환 상태를 “worktree unavailable”로 구분해 보여주는 것이다. Git minimum version이 `-z`를 보장하지 않는 경우에는 feature detection 후 안전한 fallback을 추가해야 한다.

`git status --porcelain` 자체는 결과를 boolean으로만 확인하므로 현재 코드에서 `-z`가 필수는 아니다. 다만 dirty 이유를 출력하거나 나중에 파일 목록을 보여주는 기능을 추가할 경우 `--porcelain=v1 -z`를 사용해야 한다. [Git `status` 공식 문서: `-z`](https://git-scm.com/docs/git-status#Documentation/git-status.txt-z)

#### 나이 판정은 정책 휴리스틱으로 유지

Git의 `worktree list` 계약에는 “마지막으로 사용된 시각”이 없다. 현재 구현의 `max(directory mtime, HEAD commit timestamp)`는 다음을 보수적으로 보장한다.

- 오래된 commit만 있는 worktree라도 최근 루트 디렉터리 변경이 있으면 후보가 되지 않는다.
- 최근 commit인 worktree는 루트 디렉터리 mtime이 오래돼도 후보가 되지 않는다.
- dirty worktree는 age와 무관하게 앞에서 제외된다.

이 정책은 사용자가 정한 “3일 지난 clean worktree만”이라는 요구를 충족한다. 다만 출력의 `inactivity`는 실제 사용 시각으로 오해될 수 있으므로 후속 UX에서 `heuristic age` 또는 “HEAD/루트 mtime 기준”이라는 설명을 함께 표시하는 것이 바람직하다. 파일 단위의 최근 편집 시각을 전체 worktree scan으로 추적하는 방식은 비용과 오탐 가능성이 커서 이번 범위에는 넣지 않는다.

## 3. Nix `writeShellApplication`

### 공식 계약

Nixpkgs의 `writeShellApplication`은 실행 가능한 shell application을 만들고, `runtimeInputs`를 실행 시 `$PATH`에 넣으며, 기본 check phase에서 `bash -n`과 ShellCheck를 실행한다. 또한 기본 `bashOptions`는 `errexit`, `nounset`, `pipefail`이다. `inheritPath` 기본값은 `true`라서 runtime input 경로 뒤에 부모 `$PATH`를 보존한다. [Nixpkgs 공식 매뉴얼: `writeShellApplication`](https://nixos.org/manual/nixpkgs/unstable/#trivial-builder-writeShellApplication)

현재 저장소가 고정한 nixpkgs `ac6b2166e7a9375683b8e98f860f273222337b16`의 구현도 같은 계약을 보여준다.

- `bashOptions` 기본값이 `errexit`, `nounset`, `pipefail`이다.
- wrapper가 `set -o ...`를 script text보다 먼저 출력한다.
- `runtimeInputs`의 bin path와 부모 PATH를 export한다.
- 기본 check phase에서 shell dry-run과 ShellCheck를 실행한다.

[고정된 Nixpkgs `writeShellApplication` 구현](https://github.com/NixOS/nixpkgs/blob/ac6b2166e7a9375683b8e98f860f273222337b16/pkgs/build-support/trivial-builders/default.nix#L252-L329)

### 현재 코드와의 대조

현재 모듈은 [`pkgs.writeShellApplication`](../../../users/shared/programs/baleen-toolkit.nix#L10-L35)을 사용하고 다음 runtime input을 선언한다.

```nix
runtimeInputs = with pkgs; [
  bash
  coreutils
  gawk
  gnused
  git
];
```

현재 작업 트리는 `bashOptions = [ "nounset" "pipefail" ]`도 명시한다. 이는 `writeShellApplication`의 기본 `errexit`을 의도적으로 끄고, 선택적 cleanup 실패를 계속 진행하려는 정책이다. 이 정책은 모듈 주석과 테스트로 고정했다.

판단은 다음과 같다.

- `writeShellApplication` 선택은 맞다. 별도 build-time shellcheck 설정을 재구현하지 않아도 된다.
- `bashOptions`를 명시한 것은 기본 wrapper 옵션에 대한 의도를 드러낸다. 이 도구는 각 cleanup 단계를 계속 시도하는 best-effort CLI이므로, 이번 범위에서는 `errexit`을 제거하는 정책을 선택했다. 필수 단계와 선택적 probe를 더 세밀하게 구분하는 것은 후속 작업으로 남겼다.
- `coreutils`, `gawk`, `git`은 현재 script가 사용하는 외부 명령을 충족한다.
- `brew`, `npm`, `pnpm`, `yarn`, `uv`, `pip`, `nix`, `docker`는 `command_exists`로 선택적으로 호출된다. `inheritPath = true` 기본값을 통해 사용자 시스템의 실제 설치를 찾는 현재 의도와 맞는다.
- `nix`를 Nixpkgs runtime input으로 강제하지 않는 현재 선택은 유지한다. 사용자의 Determinate Nix/daemon/configuration을 사용해야 하는 optional capability이기 때문이다.
- 현재 script 본문은 `bash`를 외부 명령으로 호출하지 않고, `sed`도 사용하지 않는다. 따라서 `bash`와 `gnused`를 runtimeInputs에서 줄이는 것은 closure 정리 후보지만 기능 안전성과는 무관하다. 실제 wrapper의 shebang과 repository의 minimum platform을 확인한 뒤 별도 변경으로 처리한다.
- `inheritPath = true`는 현재 동작에 의존하는 중요한 정책이므로, 후속 코드 리뷰에서 의도를 더 분명히 하려면 Nix module에 명시적으로 적는 것을 고려할 수 있다. 기본값 자체를 바꾸지는 않는다.

가장 중요한 테스트 결론은 현재 runtime fixture가 [`bash "${scriptPath}"`](../../../tests/unit/baleen-toolkit-test.nix#L109-L122)로 원본 script를 직접 실행한다는 점이다. 이 경로는 Nix wrapper가 넣는 runtime PATH와 `bashOptions`를 재현하지 않는다. 별도로 derivation을 빌드하고 생성된 `/bin/bl`에서 `--help`, `list`, `gc help`, `gc --dry-run`을 실행해 wrapper의 실제 동작을 확인했다.

추가할 만한 후속 테스트는 다음과 같다.

- 실제 `bl` derivation을 build한 뒤 fixture에서 built `/bin/bl`을 실행한다. 원본 script 직접 실행만으로는 wrapper의 runtime PATH와 `bashOptions` 계약을 검증할 수 없다.
- `du`와 `df`가 실패하는 fixture에서 `?`/`unavailable` 출력과 종료 상태를 검증한다.

이 테스트를 추가하면 이번 조사에서 식별한 진단 실패와 실제 wrapper 환경의 위험이 회귀 테스트로 고정된다.

## 4. Docker prune 범위

### 공식 계약

Docker 공식 CLI 문서의 범위는 다음과 같다.

| 명령                     | 기본 prune 범위                                                                | 현재 코드의 호출                 |
| ------------------------ | ------------------------------------------------------------------------------ | -------------------------------- |
| `docker container prune` | 모든 stopped container                                                         | `docker container prune --force` |
| `docker image prune`     | dangling image만. `-a`를 주면 어떤 container도 참조하지 않는 모든 unused image | `docker image prune --force`     |
| `docker builder prune`   | dangling build cache만. `-a`를 주면 모든 unused build cache                    | `docker builder prune --force`   |
| `docker system df`       | Docker daemon의 디스크 사용량 표시                                             | 통계 표시                        |

근거: [Docker `container prune`](https://docs.docker.com/reference/cli/docker/container/prune/), [Docker `image prune`](https://docs.docker.com/reference/cli/docker/image/prune/), [Docker `builder prune`](https://docs.docker.com/reference/cli/docker/builder/prune/), [Docker `system df`](https://docs.docker.com/reference/cli/docker/system/df/)

`--force`는 이미 `bl`이 별도 확인을 했으므로 Docker 명령의 두 번째 확인을 생략하는 옵션이다. Docker 문서도 `-f/--force`를 “Do not prompt for confirmation”으로 정의한다.

Docker의 넓은 `system prune`은 stopped container, unused network, dangling/unused image, build cache를 함께 다루며 `--volumes`를 추가하면 volume까지 범위가 넓어진다. Docker가 기본적으로 volume을 보존하는 이유도 중요한 데이터 삭제를 막기 위해서라고 명시한다. 현재 구현이 `system prune`과 `volume prune`을 사용하지 않는 것은 더 좁고 예측 가능한 정책이다. [Docker `system prune`](https://docs.docker.com/reference/cli/docker/system/prune/)

### 현재 코드와의 대조

- [`docker_available`](../../../users/shared/programs/baleen-toolkit.sh#L312-L323)은 `docker info`로 daemon 연결을 확인하고, 불가능하면 Docker 단계를 건너뛴다. `docker info`는 Docker 공식 문서의 `docker system info` alias다. [Docker `system info`](https://docs.docker.com/reference/cli/docker/system/info/)
- 통계는 `docker system df`만 호출하고 삭제하지 않는다.
- cleanup은 [`clean_docker`](../../../users/shared/programs/baleen-toolkit.sh#L470-L474)의 세 명령으로 분리되어 있다.
- 실행 중인 컨테이너를 직접 삭제하는 명령이 없다. `container prune`은 stopped container만 대상으로 한다.
- `image prune`에 `-a`가 없어 dangling image 기본 범위를 유지한다.
- `builder prune`에 `-a`가 없어 dangling build cache 기본 범위를 유지한다.
- `docker volume prune`, `docker system prune`, `docker network prune`이 없다.
- daemon이 probe 이후 사라져도 각 실제 명령은 [`run_cleanup`](../../../users/shared/programs/baleen-toolkit.sh#L363-L373)이 실패를 기록하고 다음 단계로 진행한다.

현재 정책에 대한 변경은 필요하지 않다. Docker에도 worktree와 같은 3일 age 제한을 도입하고 싶다면 Docker CLI의 `--filter until=...` 또는 label filter를 별도 요구사항으로 결정해야 한다. 사용자가 지정한 3일 정책은 worktree에 한정되어 있으므로, 이번 코드에 Docker filter를 임의로 추가하지 않는다.

## 5. 테스트 개선안

현재 테스트는 Home Manager package membership, 명령 문자열, 실제 Git repository fixture를 함께 검사한다. [`runtimeTest`](../../../tests/unit/baleen-toolkit-test.nix#L44-L122)는 stale/dirty/fresh/locked worktree를 만들고 다음을 검증한다.

- `--dry-run`에서 오래된 clean worktree가 표시된다.
- dry-run 중 stale worktree가 남는다.
- normal run에서 stale worktree가 삭제된다.
- dirty/fresh worktree는 남는다.
- locked worktree는 남는다.

이 테스트는 핵심 worktree 정책의 좋은 tracer다. 이번 적용에서 portable `stat` fallback과 locked worktree 보존 회귀를 추가했고, NUL-safe parser와 `bashOptions`도 source assertion으로 고정했다. 실제 built wrapper의 `--help`, `list`, `gc help`, `gc --dry-run`도 별도로 실행했다.

남은 우선순위 높은 테스트는 다음과 같다.

1. `du`와 `df`가 실패하는 fixture에서 `?`/`unavailable` 출력과 종료 상태를 검증한다.
2. 개행이 포함된 worktree 경로 fixture를 추가해 NUL parser를 동작 수준에서 검증한다.

### 우선순위 중간

1. allowlist 밖 경로, 빈 경로, symlink인 known path가 삭제되지 않는지 확인한다.
2. dry-run에서 `git worktree remove`, `rm`, `nix store gc`, Docker prune이 호출되지 않는지 fake command log로 확인한다.
3. Docker fake CLI로 실제 인자가 `container prune --force`, `image prune --force`, `builder prune --force`인지 확인하고 `-a`, `volume prune`, `system prune`, `network prune`이 없는지 고정한다.
4. 한 Docker subcommand가 실패해도 다음 Docker subcommand가 실행되는지 확인한다.

### 우선순위 낮음

- `runtimeInputs`의 실제 사용 명령을 검증해 `gnused`와 불필요한 `bash`가 제거 가능한지 확인한다.
- 나이 출력에 “root directory mtime/HEAD timestamp heuristic”을 명시하는 UX 회귀 테스트를 추가한다.

## 적용 및 검증 순서

이번 변경은 다음 순서로 적용했다.

1. `writeShellApplication`의 `errexit` 기본값과 best-effort cleanup 정책의 충돌을 확인하고 `bashOptions`를 명시했다.
2. GNU/BSD `stat` 순서를 고치고, `git worktree list --porcelain -z` parser와 locked 보호를 추가했다.
3. portable stat, NUL-safe 목록, locked worktree에 대한 회귀 테스트를 추가했다.
4. `nix fmt`, focused Nix check, `make test-build`, `bash -n`, ShellCheck, pre-commit 전체 검사로 검증했다.

후속 범위는 실패하는 `du`/`df` fixture, built wrapper 전용 fixture, `prunable` 관찰성, Git list 실패 상태 구분이다.

## 공식 자료와 확인 날짜

모든 외부 자료는 2026-08-27 (Asia/Seoul)에 확인했다.

### Bash와 ShellCheck

- [GNU Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
- [Bash: The Set Builtin](https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin)
- [Bash: Pipelines](https://www.gnu.org/software/bash/manual/html_node/Pipelines.html)
- [Bash: Shell Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)
- [ShellCheck SC2115](https://www.shellcheck.net/wiki/SC2115)
- [ShellCheck SC2015](https://www.shellcheck.net/wiki/SC2015)
- [ShellCheck SC2164](https://www.shellcheck.net/wiki/SC2164)
- [ShellCheck SC2181](https://www.shellcheck.net/wiki/SC2181)
- [ShellCheck SC2311](https://www.shellcheck.net/wiki/SC2311)
- [ShellCheck SC2312](https://www.shellcheck.net/wiki/SC2312)
- [GNU Coreutils `rm`](https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html)

### Git

- [Git `worktree`](https://git-scm.com/docs/git-worktree)
- [Git `status`](https://git-scm.com/docs/git-status)

### Nix

- [Nixpkgs `writeShellApplication` manual](https://nixos.org/manual/nixpkgs/unstable/#trivial-builder-writeShellApplication)
- [Repository-pinned Nixpkgs `writeShellApplication` source](https://github.com/NixOS/nixpkgs/blob/ac6b2166e7a9375683b8e98f860f273222337b16/pkgs/build-support/trivial-builders/default.nix#L252-L329)

### Docker

- [Docker `container prune`](https://docs.docker.com/reference/cli/docker/container/prune/)
- [Docker `image prune`](https://docs.docker.com/reference/cli/docker/image/prune/)
- [Docker `builder prune`](https://docs.docker.com/reference/cli/docker/builder/prune/)
- [Docker `system df`](https://docs.docker.com/reference/cli/docker/system/df/)
- [Docker `system info`](https://docs.docker.com/reference/cli/docker/system/info/)
- [Docker `system prune`](https://docs.docker.com/reference/cli/docker/system/prune/)
