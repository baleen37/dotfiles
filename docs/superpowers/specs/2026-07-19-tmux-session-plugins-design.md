# Tmux 세션 플러그인 설계

## 목표

Home Manager가 관리하는 tmux 설정에 세션 저장과 자동 복원 기능을 추가하고, Neovim과 tmux 사이의 탐색을 연결한다.

## 설계

- `programs.tmux.plugins`에 `resurrect`, `continuum`, `vim-tmux-navigator`를 이 순서로 선언한다.
- `extraConfig`에 `set -g @continuum-restore 'on'`을 추가해 tmux 시작 시 저장된 세션을 자동 복원한다.
- TPM은 추가하지 않는다. Home Manager가 플러그인 패키지 설치와 로딩을 담당하므로 별도 플러그인 관리자가 필요하지 않다.
- `tmux-yank`는 추가하지 않는다. 현재 설정이 tmux-native OSC52 클립보드를 사용하며 관련 통합 테스트도 존재한다.

## 범위

`users/shared/programs/tmux.nix`와 해당 통합 테스트만 수정한다. 기존 키 바인딩, 화면 표시, 터미널 기능 및 클립보드 설정은 변경하지 않는다.

## 검증

- 통합 테스트에서 세 플러그인이 모두 선언됐는지 확인한다.
- 통합 테스트에서 Continuum 자동 복원 옵션이 활성화됐는지 확인한다.
- 기존 tmux 통합 테스트 전체를 실행해 기존 동작이 유지되는지 확인한다.
