# ============================================
# PATH Setup and Environment Variables
# ============================================
# Add user's bin directory and system paths
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# Homebrew (for Apple Silicon)
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Alias for using Homebrew under x86_64 architecture (if needed)
alias axbrew='arch -x86_64 /usr/local/homebrew/bin/brew'

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
# nvm (Node Version Manager) Setup
# ============================================
export NVM_DIR="$HOME/.nvm"
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  . "/opt/homebrew/opt/nvm/nvm.sh"  # Load nvm
fi
if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
  . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # Load nvm bash completion
fi

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

