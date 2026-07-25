#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h}"
setup_home="${DOTFILES_HOME_OVERRIDE:-$HOME}"
backup_root="$setup_home/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backup_created=false
brew_bundle_failed=false

log() {
  print -r -- "==> $*"
}

backup_target() {
  local target="$1"
  local relative="${target#$setup_home/}"
  local destination="$backup_root/$relative"

  if [[ "$backup_created" == false ]]; then
    mkdir -p "$backup_root"
    backup_created=true
  fi

  mkdir -p "${destination:h}"
  mv "$target" "$destination"
  log "Backed up $target to $destination"
}

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "${target:h}"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "Already linked: $target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  ln -s "$source" "$target"
  log "Linked $target -> $source"
}

prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local reply

  if [[ ! -r /dev/tty ]]; then
    print -u2 -- "No terminal available for: $prompt"
    return 1
  fi

  read "reply?$prompt [$default]: " < /dev/tty
  print -r -- "${reply:-$default}"
}

prompt_required() {
  local prompt="$1"
  local reply

  if [[ ! -r /dev/tty ]]; then
    print -u2 -- "No terminal available for: $prompt"
    return 1
  fi

  while [[ -z "${reply:-}" ]]; do
    read "reply?$prompt: " < /dev/tty
  done
  print -r -- "$reply"
}

write_git_identity() {
  local target="$1"
  local name="$2"
  local email="$3"

  if [[ -e "$target" ]]; then
    log "Keeping existing Git identity: $target"
    return
  fi

  mkdir -p "${target:h}"
  (
    umask 077
    {
      print -r -- "[user]"
      print -r -- "    name = $name"
      print -r -- "    email = $email"
    } > "$target"
  )
  log "Created Git identity: $target"
}

install_brew_bundle() {
  if [[ "${DOTFILES_SKIP_BREW:-0}" == 1 ]]; then
    log "Skipping Homebrew setup"
    return
  fi

  local brew_bin
  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  else
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]]; then
      brew_bin=/opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
      brew_bin=/usr/local/bin/brew
    else
      print -u2 -- "Homebrew installation completed but brew was not found."
      return 1
    fi
  fi

  eval "$("$brew_bin" shellenv)"

  # Homebrew 6 requires explicit trust for third-party formulae and casks.
  if "$brew_bin" trust --help >/dev/null 2>&1; then
    "$brew_bin" trust --formula localstack/tap/localstack-cli
  fi

  export HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}"
  log "Installing Brewfile dependencies"
  if ! "$brew_bin" bundle install --file "$repo_root/Brewfile"; then
    brew_bundle_failed=true
    log "Homebrew reported incomplete dependencies; continuing with dotfile setup"
  fi
}

install_brew_bundle

link_file "$repo_root/.zshrc" "$setup_home/.zshrc"
link_file "$repo_root/.config/ghostty/config" "$setup_home/.config/ghostty/config"
link_file "$repo_root/.config/git/config" "$setup_home/.config/git/config"

personal_identity="$setup_home/.config/git/personal.inc"
work_identity="$setup_home/.config/git/work.inc"

if [[ ! -e "$personal_identity" ]]; then
  personal_name="${GIT_PERSONAL_NAME:-$(prompt_with_default "Personal Git name" "jzhangdev")}"
  personal_email="${GIT_PERSONAL_EMAIL:-$(prompt_with_default "Personal Git email" "zhangjie9477@gmail.com")}"
  write_git_identity "$personal_identity" "$personal_name" "$personal_email"
fi

if [[ ! -e "$work_identity" ]]; then
  work_name="${GIT_WORK_NAME:-$(prompt_required "Work Git name")}"
  work_email="${GIT_WORK_EMAIL:-$(prompt_required "Work Git email")}"
  write_git_identity "$work_identity" "$work_name" "$work_email"
fi

log "Dotfiles setup complete"

if [[ "$brew_bundle_failed" == true ]]; then
  print -u2 -- "Homebrew did not satisfy every Brewfile dependency."
  exit 1
fi
