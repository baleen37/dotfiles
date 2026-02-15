# Tmux Terminal Multiplexer Configuration
#
# Oh My Tmux Inspired Configuration
#
# Features:
#   - Ctrl-a prefix (screen-style)
#   - Intuitive split bindings: | (vertical), - (horizontal)
#   - Vim-style pane navigation: h/j/k/l
#   - Vi-style copy mode with OSC52 clipboard support
#   - Cross-platform: Works on macOS, Linux, and remote SSH
#   - Seamless Vim integration: vim-tmux-navigator plugin
#
# Key Bindings:
#   - Prefix: Ctrl+a
#   - Split panes: Prefix+| (vertical), Prefix+- (horizontal)
#   - Navigate panes: Prefix+h/j/k/l or Ctrl+h/j/k/l (with Vim)
#   - New window: Prefix+c
#   - Next/Prev window: Prefix+n/p
#   - Select window: Prefix+0-9
#   - Rename window: Prefix+,
#   - Copy mode: Prefix+[
#   - Paste: Prefix+]
#
# Copy Mode (vi-style):
#   v: Begin selection
#   y: Copy to system clipboard (works over SSH via OSC52)
#   Esc: Exit copy mode
#   Movement: hjkl, w, b, 0, $, etc.
#

{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  homePath = config.home.homeDirectory;
in
{
  programs.tmux = {
    enable = true;

    plugins = [ ];

    terminal = "screen-256color";
    prefix = "C-a";
    escapeTime = 0;
    historyLimit = 50000;

    # Oh My Tmux inspired configuration
    extraConfig = ''
      # ============================================================================
      # Base configuration
      # ============================================================================
      set -g default-terminal "tmux-256color"
      set -g default-shell ${pkgs.zsh}/bin/zsh
      set -g default-command "${pkgs.zsh}/bin/zsh -l"
      set -g focus-events on

      # Terminal and display settings
      set-environment -g TERM screen-256color
      set -g mouse on
      bind-key -n MouseDown2Pane paste-buffer
      set -g base-index 1
      set -g pane-base-index 1
      set -g renumber-windows on

      # Performance optimizations
      set -g display-time 2000
      set -g repeat-time 500
      set -g status-interval 1

      # Session settings
      set -g remain-on-exit off
      set -g allow-rename off
      set -g destroy-unattached off

      # ============================================================================
      # Prefix key bindings (Ctrl-a style)
      # ============================================================================
      # Send prefix through to application (Ctrl-a Ctrl-a)
      bind C-a send-prefix

      # Last window toggle (Ctrl-a a)
      bind a last-window

      # ============================================================================
      # Pane management (Oh My Tmux style)
      # ============================================================================
      # Intuitive split bindings
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # ============================================================================
      # Window management
      # ============================================================================
      bind c new-window -c "#{pane_current_path}"
      bind n next-window
      bind p previous-window
      bind , command-prompt "rename-window '%%'"

      # Alt keys for window navigation without prefix
      bind -n M-h previous-window
      bind -n M-l next-window

      # ============================================================================
      # Copy mode with OSC52 support
      # ============================================================================
      setw -g mode-keys vi
      bind [ copy-mode
      bind ] paste-buffer

      # Vi-style copy mode bindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi Escape send-keys -X cancel

      # OSC52 clipboard integration for remote SSH support
      set -s set-clipboard external
      set -g allow-passthrough on

      # OSC52 copy bindings (works over SSH)
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "sh -c 'b64=\$(dd bs=1 count=100000 status=none | base64 | tr -d \"\\n\"); printf \"\\033]52;c;%s\\a\" \"\$b64\" > \"\$1\"' sh #{client_tty}"
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "sh -c 'b64=\$(dd bs=1 count=100000 status=none | base64 | tr -d \"\\n\"); printf \"\\033]52;c;%s\\a\" \"\$b64\" > \"\$1\"' sh #{client_tty}"
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "sh -c 'b64=\$(dd bs=1 count=100000 status=none | base64 | tr -d \"\\n\"); printf \"\\033]52;c;%s\\a\" \"\$b64\" > \"\$1\"' sh #{client_tty}"

      # ============================================================================
      # Terminal capabilities
      # ============================================================================
      set -ga terminal-overrides ",*256col*:Tc,*:U8=0"
      set-window-option -g xterm-keys on
      set-option -g extended-keys on
      set -as terminal-features 'xterm*:extkeys'
      set -as terminal-overrides ',*:keys=\E[u'

      # ============================================================================
      # Status bar
      # ============================================================================
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

      # ============================================================================
      # Misc
      # ============================================================================
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
    '';
  };
}
