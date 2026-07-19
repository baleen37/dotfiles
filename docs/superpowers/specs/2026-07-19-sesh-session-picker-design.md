# Sesh tmux 세션 피커 설계

## 목표

Home Manager가 관리하는 tmux와 Zsh 설정에 sesh, zoxide, fzf 기반 세션 피커를 추가한다. 사용자는 tmux 안에서 `prefix+T`를 눌러 기존 세션이나 자주 방문한 프로젝트를 검색하고, 선택한 항목으로 전환하거나 새 세션을 만들 수 있어야 한다.

## 결정

- 현재 pinned Home Manager의 `programs.sesh` 모듈을 사용한다. sesh 설치와 tmux 바인딩을 직접 작성하지 않는다.
- `programs.sesh.tmuxKey = "T"`로 설정한다. sesh 공식 예제와 같은 대문자 키를 사용해 tmux 기본 `prefix+t` clock mode와 기존 `prefix+s` choose-tree를 보존한다.
- 기존 `programs.fzf` 설정에 `tmux.enableShellIntegration = true`를 추가한다. Home Manager sesh 모듈이 요구하는 fzf tmux 통합을 활성화한다.
- `programs.zoxide.enable = true`와 `enableZshIntegration = true`를 선언한다. Home Manager가 zoxide 패키지를 설치하고 `compinit` 뒤에 Zsh 초기화를 배치하게 한다.
- sesh 모듈의 기본 picker 동작을 유지한다. 별도 `sesh.toml`, 수동 `bind-key`, 커스텀 picker 스크립트는 만들지 않는다.

## 사용자 동작

`prefix+T`는 Home Manager sesh 모듈이 생성한 80% × 70% fzf tmux 팝업을 연다.

- 기본 목록: sesh가 인식한 tmux 세션, 설정 세션, tmuxinator 세션, zoxide 경로
- `Ctrl+a`: 전체 목록
- `Ctrl+t`: tmux 세션
- `Ctrl+g`: sesh 설정 세션
- `Ctrl+x`: zoxide 경로
- `Ctrl+f`: `fd`로 홈 아래 디렉터리 검색
- `Ctrl+d`: 선택한 tmux 세션 삭제
- `Tab` / `Shift+Tab`: 후보 이동
- 오른쪽 55% 영역: `sesh preview` 결과
- Enter: 기존 세션으로 전환하거나 선택한 디렉터리에 새 세션 생성
- Esc: 선택 없이 종료

기본 `sesh.toml`이 비어 있고 tmuxinator 설정이 없다면 최초 전체 목록은 실질적으로 tmux 세션과 zoxide 경로가 중심이 된다.

## 구성 경계

### `users/shared/programs/tmux.nix`

기존 `programs.tmux`와 나란히 `programs.sesh`를 활성화하고 `tmuxKey = "T"`만 지정한다. sesh 모듈 기본값인 아이콘, `s` 셸 별칭, tmux 통합은 유지한다.

### `users/shared/programs/zsh/default.nix`

기존 fzf 블록에서 tmux shell integration을 활성화하고, zoxide의 Zsh integration을 추가한다. 수동 `eval "$(zoxide init zsh)"`는 작성하지 않는다.

## 에러 및 호환성

- Home Manager sesh 모듈의 assertion에 맞게 fzf tmux shell integration을 함께 활성화한다.
- Nix가 sesh, zoxide, fzf 패키지를 선언적으로 설치하므로 별도 Homebrew 설치나 PATH 수정은 하지 않는다.
- `prefix+t`는 변경하지 않으므로 tmux clock mode를 계속 사용할 수 있다.
- `prefix+s`는 변경하지 않으므로 tmux 내장 choose-tree를 계속 사용할 수 있다.
- sesh 모듈의 `Ctrl+d` 세션 삭제 기능은 공식 기본 동작으로 유지하되, 별도의 무확인 `kill-pane` 바인딩은 추가하지 않는다.

## 테스트 및 검증

1. tmux 통합 테스트에서 sesh 활성화와 `tmuxKey = "T"`를 확인한다.
2. Zsh 통합 테스트에서 zoxide와 Zsh integration, fzf tmux integration이 활성화됐는지 확인한다.
3. 관련 Nix checks를 실행해 새 assertion과 기존 tmux/Zsh 동작이 모두 통과하는지 확인한다.
4. Home Manager 적용 후 `sesh`, `zoxide`, `fzf`의 설치 버전을 확인한다.
5. 실제 tmux key table에서 `prefix+T`가 sesh picker에 연결되고 `prefix+t`, `prefix+s`가 보존됐는지 확인한다.

## 변경 파일

- `users/shared/programs/tmux.nix`
- `users/shared/programs/zsh/default.nix`
- `tests/integration/tmux-functionality-test.nix`
- `tests/integration/zsh-test.nix`

## 제외 범위

- 워크트리 생성 시 sesh 세션을 자동 생성하는 `gw` 연동
- 프로젝트별 startup command/window를 정의하는 커스텀 `sesh.toml`
- SSH 또는 mosh 접속 시 tmux 자동 attach
- sesh picker의 source, 색상, 크기, 내부 키 바인딩 커스터마이징
