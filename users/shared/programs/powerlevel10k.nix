# Powerlevel10k Prompt Configuration
#
# Starts from the bundled Pure preset and keeps the layout the Starship prompt
# had: user, directory, git, virtualenv and ➜ on one line, duration on the right.
# Instant prompt draws the prompt before the rest of .zshrc runs, and git status
# comes from the gitstatusd daemon, so neither blocks on startup or Enter.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.powerlevel10k;
  p10kDir = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";

  p10kConfig = pkgs.writeText "p10k.zsh" ''
    source ${p10kDir}/config/p10k-pure.zsh

    typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs virtualenv prompt_char)
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time)

    # Always show the user name, not only over SSH or as root.
    typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=3
    typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO,ROOT,REMOTE,REMOTE_SUDO}_CONTENT_EXPANSION='%B%n%b'

    typeset -g POWERLEVEL9K_DIR_FOREGROUND=6
    typeset -g POWERLEVEL9K_VCS_FOREGROUND=5
    typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=3

    typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=2
    typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='%B➜%b'

    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3

    # direnv-instant may print while loading an .envrc; that is expected.
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  '';
in
{
  options.modules.programs.powerlevel10k.enable =
    lib.mkEnableOption "Powerlevel10k prompt configuration"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    programs.zsh.initContent = lib.mkMerge [
      # Must run before anything else in .zshrc, compinit (570) included.
      (lib.mkOrder 200 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      # Pinned after docker's mkAfter (1500) and before the zsh module body (1520):
      # modules are imported alphabetically, so equal orders would reorder .zshrc.
      (lib.mkOrder 1510 ''
        # The user name shows the same either way, so skip the `who -m` SSH
        # probe p10k runs while the theme loads.
        typeset -gix P9K_SSH=$(( ''${+SSH_CONNECTION} || ''${+SSH_CLIENT} || ''${+SSH_TTY} ))
        typeset -gx _P9K_SSH_TTY=$TTY
        source ${p10kDir}/powerlevel10k.zsh-theme
        source ${p10kConfig}
      '')
    ];
  };
}
