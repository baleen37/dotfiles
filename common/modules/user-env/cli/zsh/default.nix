{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Oh My Zsh
    ohMyZsh = {
      enable = true;
      theme = "af-magic";
      plugins = [ "git" "kubectl" ];
    };

    # History
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    # Environment Variables
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      PYENV_ROOT = "$HOME/.pyenv";
      ZK_NOTEBOOK_DIR = "$HOME/wiki";
      # LDFLAGS and CPPFLAGS might be better handled by specific development environments if not globally needed
      # LDFLAGS = "-L/usr/local/opt/zlib/lib -L/usr/local/opt/bzip2/lib";
      # CPPFLAGS = "-I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include";
    };

    # Shell Aliases (기존 ~/.aliases 파일 내용을 여기에 추가하거나, 파일을 source 하도록 설정)
    # shellAliases = {
    #   ll = "ls -l";
    # };

    # Init script (기존 .zshrc의 나머지 부분)
    initExtraBeforeCompInit = ''\'\'
      # PATH Setup
      export PATH="$HOME/bin:/usr/local/bin:$PATH"

      # Load User-defined Dotfiles (functions)
      # .aliases 는 programs.zsh.shellAliases 로 관리하거나 아래처럼 source 할 수 있습니다.
      # .functions 는 계속 source 합니다.
      for file in ~/.{functions,aliases}; do
        if [ -r "$file" ] && [ -f "$file" ]; then
          source "$file"
        fi
      done

      # fzf (Fuzzy Finder) Setup
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      # SSH Agent Setup
      if [ ! -S ~/.ssh/ssh_auth_sock ]; then
        eval "$(ssh-agent)"
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
      fi
      export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
      (ssh-add -l > /dev/null || ssh-add) &> /dev/null


      # pyenv Setup
      if [ -d "$PYENV_ROOT/bin" ]; then
        export PATH="$PYENV_ROOT/bin:$PATH"
      fi
      if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
      fi

      # Nix Setup (Home Manager가 자동으로 처리해주는 부분이 많으므로, 중복될 수 있음)
      # if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      #   . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      # fi

      # iTerm2 Shell Integration (if available)
      if [ -e "${HOME}/.iterm2_shell_integration.zsh" ]; then
        source "${HOME}/.iterm2_shell_integration.zsh"
      fi

      # dotfiles auto-update script (기존 .zshrc의 마지막 부분)
      # Only run in interactive shells
      case $- in
          *i*) ;;\
            *) return;;\
      esac

      DOTFILES_DIR="$HOME/dotfiles"
      CACHE_FILE="$HOME/.cache/dotfiles_last_update"
      THRESHOLD=86400  # 86400 seconds = 1 day

      if [ -d "$DOTFILES_DIR" ]; then
        # Ensure cache directory exists
        mkdir -p "$(dirname "$CACHE_FILE")"

        LAST_UPDATE=0
        if [ -f "$CACHE_FILE" ]; then
          LAST_UPDATE=$(cat "$CACHE_FILE")
        fi

        CURRENT_TIME=$(date +%s)
        # Check if the last update was done more than THRESHOLD seconds ago
        if [ $(( CURRENT_TIME - LAST_UPDATE )) -gt $THRESHOLD ]; then
          (
            cd "$DOTFILES_DIR" || exit
            if [ -d ".git" ]; then
              echo "Updating dotfiles in $DOTFILES_DIR..."
              git pull && echo "$CURRENT_TIME" > "$CACHE_FILE"
            fi
            cd - > /dev/null
          ) &
        fi
      fi
    ''''''; # Ensuring correct closing for multiline string
  };

  # fzf integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # pyenv (Home Manager에서 직접 관리 가능)
  # programs.pyenv = {
  #   enable = true;
  #   # versions = [ "3.10.4" ]; # 예시: 설치할 파이썬 버전
  #   # global = "3.10.4";
  # };

  # Home Manager가 ~/.aliases 파일을 관리하도록 하려면:
  # home.file.".aliases".source = ../../.aliases; # .aliases 파일의 실제 경로로 수정
}
