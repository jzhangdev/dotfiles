# Homebrew
export PATH="/opt/homebrew/bin:$PATH"

if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# History
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Options
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt COMPLETE_IN_WORD
setopt EXTENDED_GLOB

# Completion (rebuild dump once per day)
autoload -Uz compinit
_comp_dump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ ! -f "$_comp_dump" || -n ${_comp_dump}(#qN.mh+24) ]]; then
  compinit -d "$_comp_dump"
else
  compinit -C -d "$_comp_dump"
fi
unset _comp_dump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Editor
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
elif command -v vim >/dev/null 2>&1; then
  export EDITOR=vim
else
  export EDITOR=nano
fi
export VISUAL="$EDITOR"

# Aliases
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -lh --git'
  alias la='eza -lha'
  alias tree='eza --tree'
fi
alias ..='cd ..'
alias ...='cd ../..'
alias gsw='git switch'
alias gd='git diff'
alias grb='git rebase'

# proto
if [ -d "$HOME/.proto" ]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi

# Bitwarden SSH agent (only when the socket is present)
_bitwarden_ssh_sock="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
if [ -S "$_bitwarden_ssh_sock" ]; then
  export SSH_AUTH_SOCK="$_bitwarden_ssh_sock"
fi
unset _bitwarden_ssh_sock

# Android SDK
if [ -d "$HOME/Library/Android/sdk" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"
fi

# OpenJDK
if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
  export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
fi

# Claude Code Router
#export ANTHROPIC_BASE_URL="http://localhost:3456"
#export ANTHROPIC_AUTH_TOKEN="dummy"
#export ANTHROPIC_MODEL="glm-5"

# pnpm
if [ -d "$HOME/Library/pnpm" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi
# pnpm end

# Starship
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

export PATH="$HOME/.local/bin:$PATH"

# Machine-local overrides (not tracked in git)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# proto activation runs after every PATH change so tool bins land in front
if command -v proto >/dev/null 2>&1; then
  eval "$(proto activate zsh)"
fi
