# ============================================
# PATH Setup and Environment Variables
# ============================================
# Add user's bin directory and system paths
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# ============================================
# Oh My Zsh Configuration
# ============================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="af-magic"
plugins=(git kubectl)
source "$ZSH/oh-my-zsh.sh"

# ============================================
# Locale Settings
# ============================================
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ============================================
# Load User-defined Dotfiles
# Load ~/.aliases and ~/.functions if available
# ============================================
for file in ~/.{aliases,functions}; do
  if [ -r "$file" ] && [ -f "$file" ]; then
    source "$file"
  fi
done

# ============================================
# fzf (Fuzzy Finder) Setup
# ============================================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ============================================
# SSH Agent Setup
# ============================================
if [ ! -S ~/.ssh/ssh_auth_sock ]; then
  eval "$(ssh-agent)"
  ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
ssh-add -l > /dev/null || ssh-add

# ============================================
# pyenv Setup
# ============================================
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Set compilation flags if needed
export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/bzip2/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include"

# ============================================
# Nix Setup
# ============================================
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# ============================================
# iTerm2 Shell Integration (if available)
# ============================================
if [ -e "${HOME}/.iterm2_shell_integration.zsh" ]; then
  source "${HOME}/.iterm2_shell_integration.zsh"
fi

# ============================================
# Personal Notebook Directory (e.g., wiki)
# ============================================
export ZK_NOTEBOOK_DIR="$HOME/wiki"

# ============================================
# Editor Setup for Remote and Local Sessions
# Uncomment and modify as needed
# ============================================
# if [ -n "$SSH_CONNECTION" ]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi


# Only run in interactive shells
case $- in
    *i*) ;;
      *) return;;
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
    cd "$DOTFILES_DIR" || exit
    if [ -d ".git" ]; then
      echo "Updating dotfiles in $DOTFILES_DIR..."
      git pull && echo "$CURRENT_TIME" > "$CACHE_FILE"
    fi
    cd - > /dev/null
  fi
fi
