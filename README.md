# Dotfiles

Personal macOS setup for a new machine: Homebrew packages, shell config, git identities, Ghostty, and optional system defaults.

## Quick start

Clone into the personal workspace path used by git identity rules:

```sh
mkdir -p ~/Dev/github
git clone git@github.com:jzhangdev/dotfiles.git ~/Dev/github/dotfiles
cd ~/Dev/github/dotfiles
./bootstrap.sh
```

Then open a new terminal window (or restart Ghostty).

## What bootstrap does

1. Ensures **Xcode Command Line Tools** are installed
2. Installs **Homebrew** (if missing) and runs `brew bundle` against `Brewfile`
3. Installs **proto** (if missing) into `~/.proto`
4. Creates workspace dirs: `~/Dev/github`, `~/Dev/work`
5. Symlinks tracked configs into `$HOME` (existing files are moved to `~/.dotfiles-backup/<timestamp>/`)
6. Creates **git identity** files if missing:
   - `~/.config/git/personal.inc` → repos under `~/Dev/github/`
   - `~/.config/git/work.inc` → repos under `~/Dev/work/`
7. Optionally applies **macOS defaults** (`scripts/macos.sh`)

Re-running is safe: correct symlinks are left alone; existing identity files are kept.

## Linked files

| Repo path | Home path |
|-----------|-----------|
| `.zshrc` | `~/.zshrc` |
| `.config/git/config` | `~/.config/git/config` |
| `.config/ghostty/config` | `~/.config/ghostty/config` |
| `.config/starship.toml` | `~/.config/starship.toml` |

## Environment variables

| Variable | Effect |
|----------|--------|
| `DOTFILES_SKIP_BREW=1` | Skip Homebrew install and `brew bundle` |
| `DOTFILES_SKIP_PROTO=1` | Skip proto install |
| `DOTFILES_SKIP_MACOS=1` | Skip macOS defaults |
| `DOTFILES_APPLY_MACOS=1` | Apply macOS defaults without prompting |
| `DOTFILES_HOME_OVERRIDE=/path` | Install into an alternate home (for testing) |
| `GIT_PERSONAL_NAME` / `GIT_PERSONAL_EMAIL` | Noninteractive personal git identity |
| `GIT_WORK_NAME` / `GIT_WORK_EMAIL` | Noninteractive work git identity |

Example noninteractive dry-ish run (no brew, no proto, no macOS, temp home):

```sh
DOTFILES_SKIP_BREW=1 \
DOTFILES_SKIP_PROTO=1 \
DOTFILES_SKIP_MACOS=1 \
DOTFILES_HOME_OVERRIDE=/tmp/dotfiles-test \
GIT_PERSONAL_NAME=you \
GIT_PERSONAL_EMAIL=you@example.com \
GIT_WORK_NAME=you \
GIT_WORK_EMAIL=you@work.com \
./bootstrap.sh
```

## Layout

```text
.
├── bootstrap.sh          # one-shot installer
├── Brewfile              # Homebrew formulae and casks
├── .zshrc                # shell config
├── .config/
│   ├── git/config        # shared git settings + includeIf identities
│   ├── ghostty/config
│   └── starship.toml
└── scripts/
    └── macos.sh          # opt-in macOS defaults
```

## Local overrides

Machine-specific shell settings belong in `~/.zshrc.local` (not tracked). It is sourced at the end of `.zshrc` when present.

Git user name/email stay in the untracked identity files under `~/.config/git/`.

## Notes

- **proto**: [moonrepo proto](https://moonrepo.dev/proto) is installed to `~/.proto`. `.zshrc` exports `PROTO_HOME`, puts `~/.proto/shims` ahead of `~/.proto/bin` on `PATH`, and runs `proto activate zsh` after other `PATH` changes. Pin tools in `~/.proto/.prototools` or a project `.prototools`, then `proto install`.
- **Bitwarden SSH agent**: `.zshrc` sets `SSH_AUTH_SOCK` only if the Bitwarden desktop agent socket exists.
- **Git identities**: only apply when the repo lives under the matching `gitdir:` path. Outside those trees, set `user.name` / `user.email` yourself or extend `.config/git/config`.
- **macOS defaults**: conservative developer-oriented settings (Finder, keyboard, screenshots, Dock). Review `scripts/macos.sh` before applying on a machine you already customized.
