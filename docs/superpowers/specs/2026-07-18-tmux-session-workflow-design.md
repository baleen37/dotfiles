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
필요한 기능이 gw 함수 내 몇 줄 + SSH 설정 수준이므로 자작(A안)을 채택한다.
별도 스크립트(`ts`)와 fzf 피커도 검토했으나 스코프에서 제외했다(비채택 대안 참조).

## 원칙

- **세션 = 작업 단위(체크아웃)**: 일반 레포도, 워크트리도 각각 독립 세션
- 새 외부 의존성 없음 (기존 tmux + zsh만 사용)
- 옵트인: 기존 워크플로(tmux 밖 gw, 일반 SSH)를 깨지 않는다

## 세션 이름 규칙 (gw가 만드는 세션)

- 세션 이름 = `<레포>/<워크트리 디렉토리명>` (예: `inhouse/260716-feat-jito-...`)
- 레포명은 `.worktrees` 바로 앞 디렉토리명
- tmux 세션명에서 특수 취급되는 `.`, `:`는 `_`로 치환한다

## 구성 요소

### 1. gw 연동 (`users/shared/programs/zsh/gw.nix`)

워크트리 생성/전환 성공 후 마지막 단계를 분기한다:

- **`$TMUX` 안이면**: 위 이름 규칙으로 세션명을 계산해
  `tmux new-session -A -d -s <name> -c <경로>` 후 `tmux switch-client -t <name>`
  (별도 스크립트 없이 gw 함수 내 헬퍼 몇 줄로 인라인)
- **tmux 밖이면**: 기존처럼 `cd` (동작 보존)
- 기존 워크트리로 전환하는 분기(`_handle_existing_worktree`)에도 동일 적용

세션 간 전환은 tmux 내장 `prefix+s`(choose-tree)를 사용한다. 일반 레포의
세션이 필요하면 `tmux new -A -s <이름> -c <경로>`를 직접 쓴다 (도구화하지 않음).

### 2. SSH/mosh 자동 attach (`users/shared/programs/ssh.nix`)

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

- gw의 tmux 분기에서 세션 생성/전환이 실패하면 경고 출력 후 기존 `cd`로 폴백
  (워크트리 생성 자체는 이미 성공한 상태이므로 작업을 잃지 않는다)

## 테스트 / 검증

- 수동 검증 (`make switch` 후):
  1. tmux 안에서 `gw` → 워크트리 전용 세션(`<레포>/<워크트리>`)으로 자동 전환 확인
  2. 같은 브랜치로 다시 `gw` → 기존 세션으로 전환(중복 생성 없음) 확인
  3. tmux 밖에서 `gw` → 기존처럼 cd만 되는지 확인
  4. `prefix+s`(내장 choose-tree)로 세션 간 전환 확인

## 변경 파일 목록

| 파일                               | 변경                                           |
| ---------------------------------- | ---------------------------------------------- |
| `users/shared/programs/zsh/gw.nix` | 말미에 tmux 세션 생성/전환 분기                |
| `users/shared/programs/ssh.nix`    | 옵트인 RemoteCommand 패턴 (호스트는 추후 지정) |

## 비채택 대안

- **sesh + zoxide**: 워크트리 레이아웃 불일치로 glue가 여전히 필요, 의존성 2개 추가
- **tms / workmux**: "워크트리 = window" 모델이 본 설계 원칙과 상충
- **자작 `ts` 스크립트 + fzf 피커**: 검토했으나 스코프 축소 과정에서 제외.
  세션 전환은 내장 `prefix+s`로 충분하고, 세션 생성은 gw 인라인으로 충분
- **셸 rc 자동 tmux attach**: scp/비인터랙티브 파손 위험으로 SSH config 방식 채택
