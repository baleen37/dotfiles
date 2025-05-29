{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    extraConfig = ''
      set -ga terminal-overrides ',*-256color*:Tc'

      set -g mode-keys vi


      bind-key -T copy-mode-vi 'v' send -X begin-selection # Begin selection in copy mode.
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle # Begin selection in copy mode.
      bind-key -T copy-mode-vi 'y' send -X copy-selection # Yank selection in copy mode.

      bind C attach-session -t . -c "#{pane_current_path}" # Change the current directory for a tmux session.

      # mouse on
      set -g mouse on

      # fix ssh agent when tmux is detached
      setenv -g SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock

      set-option -g history-limit 3000
    '';
  };
}
