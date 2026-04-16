# Homebrew
export PATH="/opt/homebrew/bin:$PATH"

if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# alias
alias ls='eza'
alias ll='eza -lh --git'
alias la='eza -lha'
alias tree='eza --tree'
alias gsw="git switch"
alias gd='git diff'
alias grb='git rebase'

# proto
export PROTO_HOME="$HOME/.proto";
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";

# Bitwarden SSH agent
export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"

# Android SDK
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

# OpenJDK
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

# Claude Code Router
#export ANTHROPIC_BASE_URL="http://localhost:3456"
#export ANTHROPIC_AUTH_TOKEN="dummy"
#export ANTHROPIC_MODEL="glm-5"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Starship
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
