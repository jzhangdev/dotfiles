#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h}"
setup_home="${DOTFILES_HOME_OVERRIDE:-$HOME}"
backup_root="$setup_home/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backup_created=false
brew_bundle_failed=false
linked_paths=()
identity_created=()
identity_kept=()
macos_applied=false

# Relative source (under repo) -> relative target (under $setup_home)
link_specs=(
  ".zshrc:.zshrc"
  ".config/ghostty/config:.config/ghostty/config"
  ".config/git/config:.config/git/config"
  ".config/starship.toml:.config/starship.toml"
)

log() {
  print -r -- "==> $*"
}

warn() {
  print -u2 -r -- "warning: $*"
}

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Installing Xcode Command Line Tools (GUI prompt may appear)"
  xcode-select --install >/dev/null 2>&1 || true

  print -r -- "Waiting for Xcode Command Line Tools to finish installing..."
  print -r -- "Complete the installer dialog, then this script will continue."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  log "Xcode Command Line Tools ready"
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

  if [[ ! -e "$source" ]]; then
    warn "Skip missing source: $source"
    return
  fi

  mkdir -p "${target:h}"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "Already linked: $target"
    linked_paths+=("$target")
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  ln -s "$source" "$target"
  log "Linked $target -> $source"
  linked_paths+=("$target")
}

link_dotfiles() {
  local spec source_rel target_rel
  for spec in "${link_specs[@]}"; do
    source_rel="${spec%%:*}"
    target_rel="${spec#*:}"
    link_file "$repo_root/$source_rel" "$setup_home/$target_rel"
  done
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

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  local reply normalized default_hint

  if [[ "${default:u}" == "Y" ]]; then
    default_hint="Y/n"
  else
    default_hint="y/N"
  fi

  if [[ ! -r /dev/tty ]]; then
    # Noninteractive: only apply when explicitly requested
    [[ "${DOTFILES_APPLY_MACOS:-0}" == 1 ]]
    return $?
  fi

  read "reply?$prompt [$default_hint]: " < /dev/tty
  reply="${reply:-$default}"
  normalized="${reply:l}"
  [[ "$normalized" == y || "$normalized" == yes ]]
}

write_git_identity() {
  local target="$1"
  local name="$2"
  local email="$3"

  if [[ -e "$target" ]]; then
    log "Keeping existing Git identity: $target"
    identity_kept+=("$target")
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
  identity_created+=("$target")
}

ensure_dev_dirs() {
  local dir
  for dir in "$setup_home/Dev/github" "$setup_home/Dev/work"; do
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
      log "Created workspace directory: $dir"
    fi
  done
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

  export HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}"
  log "Installing Brewfile dependencies"
  if ! "$brew_bin" bundle install --file "$repo_root/Brewfile"; then
    brew_bundle_failed=true
    log "Homebrew reported incomplete dependencies; continuing with dotfile setup"
  fi
}

apply_macos_defaults() {
  local script="$repo_root/scripts/macos.sh"

  if [[ "${DOTFILES_SKIP_MACOS:-0}" == 1 ]]; then
    log "Skipping macOS defaults (DOTFILES_SKIP_MACOS=1)"
    return
  fi

  if [[ ! -f "$script" ]]; then
    warn "macOS defaults script missing: $script"
    return
  fi

  if [[ "${DOTFILES_APPLY_MACOS:-0}" == 1 ]] || prompt_yes_no "Apply macOS system defaults?" "Y"; then
    log "Applying macOS defaults"
    zsh "$script"
    macos_applied=true
  else
    log "Skipped macOS defaults"
  fi
}

print_summary() {
  local entry

  print -r -- ""
  log "Dotfiles setup complete"
  print -r -- ""
  print -r -- "Linked configs:"
  if (( ${#linked_paths[@]} )); then
    for entry in "${linked_paths[@]}"; do
      print -r -- "  - $entry"
    done
  else
    print -r -- "  (none)"
  fi

  if (( ${#identity_created[@]} )); then
    print -r -- "Git identities created:"
    for entry in "${identity_created[@]}"; do
      print -r -- "  - $entry"
    done
  fi

  if (( ${#identity_kept[@]} )); then
    print -r -- "Git identities kept:"
    for entry in "${identity_kept[@]}"; do
      print -r -- "  - $entry"
    done
  fi

  if [[ "$backup_created" == true ]]; then
    print -r -- "Backups: $backup_root"
  fi

  if [[ "$macos_applied" == true ]]; then
    print -r -- "macOS defaults: applied"
  else
    print -r -- "macOS defaults: skipped"
  fi

  if [[ "$brew_bundle_failed" == true ]]; then
    print -r -- "Homebrew: incomplete (see messages above)"
  elif [[ "${DOTFILES_SKIP_BREW:-0}" == 1 ]]; then
    print -r -- "Homebrew: skipped"
  else
    print -r -- "Homebrew: ok"
  fi

  print -r -- ""
  print -r -- "Next steps:"
  print -r -- "  1. Restart your terminal (or open a new Ghostty window)"
  print -r -- "  2. Confirm git identity in a personal/work repo with: git config user.email"
  print -r -- "  3. Optional machine overrides: edit ~/.zshrc.local"
}

# --- main -------------------------------------------------------------------

ensure_xcode_clt
install_brew_bundle
ensure_dev_dirs
link_dotfiles

personal_identity="$setup_home/.config/git/personal.inc"
work_identity="$setup_home/.config/git/work.inc"

if [[ ! -e "$personal_identity" ]]; then
  personal_name="${GIT_PERSONAL_NAME:-$(prompt_with_default "Personal Git name" "jzhangdev")}"
  personal_email="${GIT_PERSONAL_EMAIL:-$(prompt_with_default "Personal Git email" "zhangjie9477@gmail.com")}"
  write_git_identity "$personal_identity" "$personal_name" "$personal_email"
else
  log "Keeping existing Git identity: $personal_identity"
  identity_kept+=("$personal_identity")
fi

if [[ ! -e "$work_identity" ]]; then
  work_name="${GIT_WORK_NAME:-$(prompt_required "Work Git name")}"
  work_email="${GIT_WORK_EMAIL:-$(prompt_required "Work Git email")}"
  write_git_identity "$work_identity" "$work_name" "$work_email"
else
  log "Keeping existing Git identity: $work_identity"
  identity_kept+=("$work_identity")
fi

apply_macos_defaults
print_summary

if [[ "$brew_bundle_failed" == true ]]; then
  print -u2 -- "Homebrew did not satisfy every Brewfile dependency."
  exit 1
fi
