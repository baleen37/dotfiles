# Tmux Terminal Multiplexer Configuration
#
# Complete tmux configuration with plugins and optimizations.
# Following YAGNI principle - all settings in one file.
#
# FEATURES:
#   - Performance optimized settings
#   - Platform-aware clipboard integration
#   - Session persistence with resurrect/continuum
#   - True color support
#   - Vim integration
#
# VERSION: 3.1.0 (Single file configuration)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
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

      # Session stability settings
      set -g set-clipboard external
      set -g remain-on-exit off
      set -g allow-rename off
      set -g destroy-unattached off

      # Enhanced copy-paste with platform awareness
      setw -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # Platform-optimized clipboard integration
      ${lib.optionalString isDarwin ''
        # macOS: Use pbcopy/pbpaste when available
        if command -v pbcopy >/dev/null 2>&1; then
          bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
          bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
          bind-key ] run "pbpaste | tmux load-buffer - && tmux paste-buffer"
        fi
      ''}
      ${lib.optionalString isLinux ''
        # Linux: Use xclip when available
        if command -v xclip >/dev/null 2>&1; then
          bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
          bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
          bind-key ] run "xclip -out -selection clipboard | tmux load-buffer - && tmux paste-buffer"
        fi
      ''}

      # Fallback to tmux buffer (universal)
      bind-key -T copy-mode-vi Y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel

      # Buffer management shortcuts
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
