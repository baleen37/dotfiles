# Tmux Terminal Multiplexer Configuration
#
# Oh My Tmux Inspired Configuration
#
# Features:
#   - Ctrl-a prefix (screen-style)
#   - Intuitive split bindings: | (left/right), - (top/bottom)
#   - Vim-style pane navigation: h/j/k/l
#   - Vi-style copy mode with tmux-native OSC52 clipboard support
#   - Truecolor (RGB) + undercurl inherited from xterm-ghostty terminfo
#   - Cross-platform: Works on macOS, Linux, and remote SSH
#   - Seamless Vim integration: vim-tmux-navigator plugin
#
# Key Bindings:
#   - Prefix: Ctrl+a
#   - Split panes: Prefix+| (left/right), Prefix+- (top/bottom)
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
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.tmux;
in
{
  options.modules.programs.tmux.enable = lib.mkEnableOption "Tmux multiplexer configuration";

  config = lib.mkIf cfg.enable {
    programs.sesh = {
      enable = true;
      tmuxKey = "T";
    };

    programs.tmux = {
      enable = true;

      plugins = with pkgs.tmuxPlugins; [
        resurrect
        continuum
        vim-tmux-navigator
      ];

      terminal = "tmux-256color";
      prefix = "C-a";
      escapeTime = 0;
      historyLimit = 50000;

      # Oh My Tmux inspired configuration
      extraConfig = ''
        # ============================================================================
        # Base configuration
        # ============================================================================
        # default-terminal is emitted by programs.tmux.terminal = "tmux-256color"
        set -g default-shell ${pkgs.zsh}/bin/zsh
        # default-command left unset: tmux runs default-shell as a login shell
        set -g focus-events on

        # Terminal and display settings
        set -g mouse on
        bind-key -n MouseDown2Pane paste-buffer
        set -g base-index 1
        set -g pane-base-index 1
        set -g renumber-windows on

        # Performance optimizations
        set -g display-time 2000
        set -g repeat-time 500
        set -g status-interval 5

        # Session settings
        set -g remain-on-exit off
        set -g allow-rename off
        set -g destroy-unattached off

        # Restore the most recently saved session when tmux starts.
        set -g @continuum-restore 'on'

        # Propagate session + active pane title to the Ghostty tab/window title.
        # Complements allow-rename off: that only blocks window-name renames;
        # pane titles (OSC 2) still flow, which is how coding agents (Claude
        # Code etc.) report their status (spinner = working, ✳ = waiting).
        set -g set-titles on
        set -g set-titles-string "#S  #{?#{!=:#{pane_title},#{host}},#{pane_title},#I:#W}"

        # ============================================================================
        # Prefix key bindings (Ctrl-a style)
        # ============================================================================
        # Send prefix through to application (Ctrl-a Ctrl-a)
        bind C-a send-prefix

        # Last window toggle (Ctrl-a a)
        bind a last-window

        # ============================================================================
        # Pane management
        # ============================================================================
        # Intuitive split bindings, keeping the current pane's path
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '%'
        unbind '"'

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

        # OSC52 clipboard integration. The xterm-ghostty terminfo carries the Ms
        # capability, so tmux emits OSC52 itself on copy — no manual printf hack
        # needed. 'on' (vs 'external') also lets apps inside tmux (Neovim/agent
        # OSC52 yank) populate the clipboard. allow-passthrough keeps DCS-wrapped
        # OSC52 from coding agents (Claude Code, etc.) working through tmux.
        set -s set-clipboard on
        set -g allow-passthrough on

        # Copy to system clipboard via tmux-native OSC52 (works over SSH).
        bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
        bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel
        bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

        # ============================================================================
        # Terminal capabilities
        # ============================================================================
        # Truecolor (RGB). terminal-features matches the OUTER terminal's TERM,
        # which is xterm-ghostty under Ghostty. The xterm-ghostty terminfo also
        # already advertises Smulx/Setulc (undercurl) and Ss/Se (cursor shape),
        # so no manual terminal-overrides are needed for those.
        set -as terminal-features ',xterm-ghostty:RGB'

        # Mosh 1.4 preserves truecolor and exports COLORTERM=truecolor, but its
        # outer terminal is xterm-256color rather than xterm-ghostty.
        set -as terminal-features ',xterm-256color:RGB'

        # Extended keys (CSI u). Ghostty speaks the CSI-u encoding; tmux 3.6
        # defaults extended-keys-format to xterm form, so set csi-u explicitly
        # for modifier combos (e.g. Shift+Enter) to reach apps inside tmux.
        set-option -g extended-keys on
        set-option -s extended-keys-format csi-u
        set -as terminal-features ',xterm-ghostty:extkeys'

        # ============================================================================
        # Status bar
        # ============================================================================
        set -g status-position bottom
        set -g status-bg colour234
        set -g status-fg colour137
        set -g status-left-length 20
        set -g status-right-length 50
        set -g status-left '#[fg=colour233,bg=colour241,bold] #S '
        set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M '

        # Window status display. Shows the active pane's title (agent status:
        # spinner = working, ✳ = waiting) when a program sets one via OSC 2;
        # falls back to the window name when the title is the default (#{host}).
        # Truncated to 30 chars to keep the window list readable.
        setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#{?#{!=:#{pane_title},#{host}},#{=/30/…:pane_title},#W}#[fg=colour50]#F '
        setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#{?#{!=:#{pane_title},#{host}},#{=/30/…:pane_title},#W}#[fg=colour244]#F '

        # ============================================================================
        # Misc
        # ============================================================================
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
      '';
    };
  };
}
