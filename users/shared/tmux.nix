# Tmux Terminal Multiplexer Configuration
#
# Standard Configuration with Enhanced Copy-Paste Support
#
# Features:
#   - Standard copy-paste: Mouse selection auto-copies to clipboard
#   - Vi-style copy mode: v to select, y to copy
#   - Cross-platform support: pbcopy (macOS), xclip (Linux)
#   - Middle-click paste: MouseDown2Pane for quick paste
#   - Session persistence: resurrect + continuum plugins
#   - Vim integration: vim-tmux-navigator plugin
#
# Key Bindings:
#   - Prefix: Ctrl+b
#   - Copy mode: Prefix+[ or v in copy mode
#   - Paste: Prefix+] or middle-click
#   - Window split: | (horizontal), - (vertical)
#   - Window navigate: Alt+h/l (no prefix needed)
#
# Copy Mode (vi-style):
#   v: Begin selection
#   y: Copy to system clipboard
#   r: Rectangle toggle
#   Movement: hjkl, w, b, 0, $, etc.
#

{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;
  inherit (pkgs.stdenv) isLinux;
  homePath = config.home.homeDirectory;
in
{
  programs.tmux = {
    enable = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      # yank  # Removed - Task 2: Remove Yank Plugin Dependency
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
      bind-key -n MouseDown2Pane paste-buffer  # Middle-click paste
      set -g base-index 1
      set -g pane-base-index 1
      set -g renumber-windows on

      # Performance optimizations
      set -g display-time 2000
      set -g repeat-time 500
      set -g status-interval 1

      # Session stability settings with standard clipboard synchronization
      set -g set-clipboard on   # Enable external clipboard by default for automatic synchronization
      set -g remain-on-exit off
      set -g allow-rename off
      set -g destroy-unattached off

      # Standard copy-paste configuration
      setw -g mode-keys vi
      bind [ copy-mode
      bind ] paste-buffer
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel

      # Cross-platform clipboard integration with copy-pipe-and-cancel
      ${lib.optionalString isDarwin ''
        # macOS: pbcopy/pbpaste integration
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key C-c run "tmux save-buffer - | pbcopy"
        bind-key C-v run "pbpaste | tmux load-buffer -"
      ''}
      ${lib.optionalString isLinux ''
        # Linux: xclip integration with fallback
        if command -v xclip >/dev/null 2>&1; then
          bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
          bind-key C-c run "tmux save-buffer - | xclip -in -selection clipboard >/dev/null"
          bind-key C-v run "xclip -out -selection clipboard | tmux load-buffer -"
        fi
      ''}


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
      set -g @resurrect-dir "${homePath}/.config/tmux/resurrect"
    '';
  };
}
