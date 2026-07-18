# tmux 세션 워크플로 설계 (A안: 자작 미니멀)

- 날짜: 2026-07-18
- 상태: 설계 승인 대기
- 관련: PR #1335 (vim-tmux-navigator, 분할 키 기본값 복원 — 본 설계와 독립)

## 배경 / 문제

현재 tmux 사용 패턴은 "터미널 탭 보조 → 단일 세션 멀티 window"를 거쳐 프로젝트별
세션으로 진화하는 중이며, 다음 세 가지 페인포인트가 있다:

1. **세션 검색**: 기존 세션 이름이 기억나지 않아 `tmux ls` → `attach`를 수동 반복
2. **gw 워크트리 단절**: `gw`가 워크트리를 만들어도 tmux 세션과 연결되지 않음
3. **SSH/mosh 수동 attach**: 원격 접속 후 매번 손으로 `tmux attach`

기성 도구(sesh, tms, workmux)를 검토했으나, 이 저장소의 워크트리 컨벤션
(`<repo>/.worktrees/YYMMDD-<branch>` 평면 레이아웃)이 sesh의 `.bare` 가정과
어긋나고, tms/workmux는 "워크트리 = window" 모델이라 아래 원칙과 상충한다.
필요한 기능이 셸 스크립트 40줄 수준이므로 자작(A안)을 채택한다.

## 원칙

- **세션 = 작업 단위(체크아웃)**: 일반 레포도, 워크트리도 각각 독립 세션
- 새 외부 의존성 없음 (기존 tmux + fzf + zsh만 사용)
- 옵트인: 기존 워크플로(tmux 밖 gw, 일반 SSH)를 깨지 않는다

## 세션 이름 규칙

| 대상 | 세션 이름 | 예시 |
|---|---|---|
| 일반 레포 | 디렉토리명 | `search-data`, `dotfiles` |
| 워크트리 | `<레포>/<워크트리 디렉토리명>` | `inhouse/260716-feat-jito-recommend...` |

- tmux 세션명에서 특수 취급되는 `.`, `:`는 `_`로 치환한다
- 워크트리 판별: 경로에 `/.worktrees/` 세그먼트가 포함되면 워크트리로 간주,
  레포명은 `.worktrees` 바로 앞 디렉토리명

## 구성 요소

### 1. `ts` 스크립트 (신규, 핵심)

`pkgs.writeShellApplication`으로 만들어 `home.packages`로 배포. 동작:

- **`ts <경로>`**: 경로 → 세션명 계산 → `tmux new-session -A -d -s <name> -c <path>`
  후, `$TMUX` 안이면 `switch-client -t <name>`, 밖이면 `attach -t <name>`
- 인자 없이 실행하면 usage 출력 (피커 모드 없음)
- **비스코프(추후 확장점)**: 피커/디렉토리 검색은 넣지 않는다. 세션 간 전환은
  tmux 내장 `prefix+s`(choose-tree)를 사용한다. 새 세션은 `gw`(워크트리) 또는
  `ts <경로>`(예: `ts .`)로 만든다
- 의존성: tmux (기존 설치분). runtimeInputs로 명시

배치: `users/shared/programs/tmux.nix` 안에서 정의 (tmux 전용 부품이므로 동일
모듈에 둠. 파일이 과도하게 커지면 `tmux/` 하위 분리는 후속 판단)

### 2. gw 연동 (`users/shared/programs/zsh/gw.nix`)

워크트리 생성/전환 성공 후 마지막 단계:

- `$TMUX`가 설정되어 있고 `ts`가 PATH에 있으면 → `ts <워크트리 경로>` 호출
  (cd 대신 세션 생성+전환)
- tmux 밖이거나 `ts`가 없으면 → 기존처럼 `cd` (동작 보존)
- 기존 워크트리로 전환하는 분기(`_handle_existing_worktree`)에도 동일 적용

### 3. SSH/mosh 자동 attach (`users/shared/programs/ssh.nix`)

전역 강제가 아닌 호스트별 옵트인 패턴:

```
Host <원격호스트>
  RequestTTY yes
  RemoteCommand tmux new -A -s main
```

- 셸 rc 레벨 자동 attach는 채택하지 않음 (scp/rsync/비인터랙티브 셸 파손 위험)
- mosh: `mosh <host> -- tmux new -A -s main` 형태의 별칭으로 대응
- 적용 대상 호스트는 구현 시 사용자가 지정 (스펙 범위: 패턴 제공까지)

## 에러 처리

- `ts <경로>`: 경로가 디렉토리가 아니면 에러 메시지 후 종료 1
- tmux 서버가 없을 때 `ts` 단독 실행: `new-session -A`가 서버를 시작하므로 정상 동작

## 테스트 / 검증

- 통합 테스트 (`tests/integration/tmux-functionality-test.nix` 기존 패턴):
  - `ts` 스크립트가 home.packages에 포함되는지 단언
- 수동 검증 (`make switch` 후):
  1. 레포 디렉토리에서 `ts .` → 레포명 세션 생성 확인, 재실행 시 기존 세션 전환 확인
  2. tmux 안에서 `gw` → 워크트리 전용 세션으로 자동 전환 확인
  3. tmux 밖에서 `gw` → 기존처럼 cd만 되는지 확인
  4. `prefix+s`(내장 choose-tree)로 세션 간 전환 확인

## 변경 파일 목록

| 파일 | 변경 |
|---|---|
| `users/shared/programs/tmux.nix` | `ts` 스크립트 정의 (home.packages) |
| `users/shared/programs/zsh/gw.nix` | 말미에 tmux 연동 분기 (3~5줄) |
| `users/shared/programs/ssh.nix` | 옵트인 RemoteCommand 패턴 (호스트는 추후 지정) |
| `tests/integration/tmux-functionality-test.nix` | `ts` 패키지 단언 추가 |

## 비채택 대안

- **sesh + zoxide**: 워크트리 레이아웃 불일치로 glue가 여전히 필요, 의존성 2개 추가
- **tms / workmux**: "워크트리 = window" 모델이 본 설계 원칙과 상충
- **셸 rc 자동 tmux attach**: scp/비인터랙티브 파손 위험으로 SSH config 방식 채택
