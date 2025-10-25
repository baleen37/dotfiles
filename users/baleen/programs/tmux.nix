# Tmux 터미널 멀티플렉서 설정
#
# 전체 Tmux 설정을 단일 파일로 관리하는 모듈 (YAGNI 원칙 준수)
#
# 주요 기능:
#   - 성능 최적화: 0ms escape time, 50000 히스토리, 500ms repeat time
#   - 플랫폼별 클립보드 통합:
#       - macOS: pbcopy/pbpaste
#       - Linux: xclip
#       - 범용: tmux 내장 버퍼
#   - 세션 영속성:
#       - resurrect: 세션 자동 저장/복원
#       - continuum: 15분 간격 자동 저장
#   - True Color 지원: 256색 + RGB 컬러
#   - Vim 통합: vim-tmux-navigator 플러그인
#   - 마우스 지원: 스크롤, 패널 크기 조정
#
# 키 바인딩:
#   - Prefix: Ctrl+b
#   - 패널 분할: | (수평), - (수직)
#   - 윈도우 생성: Prefix+t
#   - 윈도우 이동: Alt+h/l (prefix 불필요)
#   - 복사 모드: vi 키 바인딩
#
# VERSION: 3.1.0 (Single file configuration)
# LAST UPDATED: 2024-10-04

{
  pkgs,
  lib,
  platformInfo,
  userInfo,
  ...
}:

let
  inherit (platformInfo) isDarwin isLinux;
  inherit (userInfo) paths;
in
{
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      yank
      resurrect
      continuum
    ];
    terminal = "screen-256color";
    prefix = "C-b";
    escapeTime = 0;
    historyLimit = 50000;

    # Performance optimized tmux configuration
    extraConfig = ''
      # Optimized base configuration
      set -g default-terminal "tmux-256color"
      set -g default-shell ${pkgs.zsh}/bin/zsh
      set -g default-command "${pkgs.zsh}/bin/zsh -l"
      set -g focus-events on

      # Enhanced terminal and display settings
      set-environment -g TERM screen-256color
      set -g mouse on
      set -g base-index 1
      set -g pane-base-index 1
      set -g renumber-windows on

      # Performance optimizations
      set -g display-time 2000
      set -g repeat-time 500
      set -g status-interval 1

      # Session stability settings with security-first clipboard policy
      set -g set-clipboard off  # 보안: 기본적으로 외부 클립보드 비활성화
      set -g remain-on-exit off
      set -g allow-rename off
      set -g destroy-unattached off

      # Standard copy-paste configuration (works everywhere)
      setw -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel

      # Simple platform-specific clipboard integration
      ${lib.optionalString isDarwin ''
        # macOS: pbcopy/pbpaste integration
        bind-key C-c run "tmux save-buffer - | pbcopy"
        bind-key C-v run "pbpaste | tmux load-buffer -"
      ''}
      ${lib.optionalString isLinux ''
        # Linux: xclip integration with fallback
        if command -v xclip >/dev/null 2>&1; then
          bind-key C-c run "tmux save-buffer - | xclip -in -selection clipboard >/dev/null"
          bind-key C-v run "xclip -out -selection clipboard | tmux load-buffer -"
        fi
      ''}

      # Standard buffer management
      bind-key P paste-buffer
      bind-key b list-buffers
      bind-key B choose-buffer

      # Optimized terminal capabilities with True Color support
      set -ga terminal-overrides ",*256col*:Tc,*:U8=0"
      set -ga terminal-overrides ",screen*:Tc,*:U8=0"
      set -ga terminal-overrides ",xterm*:Tc,*:U8=0"
      set -ga terminal-overrides ",tmux*:Tc,*:U8=0"
      set -ga terminal-overrides ",alacritty:Tc,*:U8=0"

      # Keyboard settings
      set-window-option -g xterm-keys on
      set-option -g extended-keys on
      set -as terminal-features 'xterm*:extkeys'

      # Extended key input handling for modern terminals
      set -as terminal-overrides ',*:keys=\E[u'

      # Status bar settings
      set -g status-position bottom
      set -g status-bg colour234
      set -g status-fg colour137
      set -g status-left-length 20
      set -g status-right-length 50
      set -g status-left '#[fg=colour233,bg=colour241,bold] #S '
      set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '

      # Window status display
      setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
      setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

      # Key bindings
      bind | split-window -h
      bind - split-window -v
      bind r source-file ~/.tmux.conf \; display "Config reloaded!"

      # Tab (window) management key bindings
      bind t new-window
      bind Tab last-window

      # Alt keys for window navigation without prefix
      bind -n M-h previous-window
      bind -n M-l next-window

      # Optimized session persistence
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'
      set -g @continuum-boot 'on'

      # Additional performance optimizations
      set -g @resurrect-dir "${paths.config}/tmux/resurrect"
    '';
  };
}
