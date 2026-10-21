#!/usr/bin/env bash
# Install or update Neovim and this config on Linux. Safe to re-run: each step
# installs what is missing and updates what is already there.
#
#   curl -fsSL http://192.168.1.91:3001/AnimalRacer3/nvim/raw/branch/main/install.sh | bash
#
# Steps:
#   1. System packages LazyVim needs (git, ripgrep, fd, a C compiler, ...)
#   2. Latest stable Neovim from GitHub releases into ~/.local/opt/nvim
#   3. This config into ~/.config/nvim (clone, or fast-forward pull if present)
#   4. The Open WebUI API key, saved outside the repo
#   5. Plugins, pinned to lazy-lock.json
#
# Overrides: NVIM_CONFIG_REPO, NVIM_CONFIG_BRANCH, NVIM_SKIP_DEPS=1, OPENWEBUI_API_KEY.
set -euo pipefail

REPO="${NVIM_CONFIG_REPO:-http://192.168.1.91:3001/AnimalRacer3/nvim.git}"
BRANCH="${NVIM_CONFIG_BRANCH:-main}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
OPT_DIR="$HOME/.local/opt"
BIN_DIR="$HOME/.local/bin"
NVIM="$BIN_DIR/nvim"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

as_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

install_deps() {
  if [ "${NVIM_SKIP_DEPS:-0}" = 1 ]; then return; fi
  local common=(git curl tar gzip unzip ripgrep gcc make)
  info "Installing system packages"
  if command -v zypper >/dev/null; then
    as_root zypper --non-interactive install --no-recommends "${common[@]}" fd
  elif command -v apt-get >/dev/null; then
    as_root apt-get update -q
    as_root apt-get install -y "${common[@]}" fd-find
  elif command -v dnf >/dev/null; then
    as_root dnf install -y "${common[@]}" fd-find
  elif command -v pacman >/dev/null; then
    as_root pacman -S --needed --noconfirm "${common[@]}" fd
  else
    warn "unknown package manager; install these yourself: ${common[*]} fd"
  fi
}

install_neovim() {
  local arch
  case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *) echo "error: no Neovim release for $(uname -m)" >&2; exit 1 ;;
  esac

  # The /releases/latest redirect names the tag without using the rate-limited API.
  local latest current=""
  latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/neovim/neovim/releases/latest)"
  latest="${latest##*/}"
  if [ -x "$OPT_DIR/nvim/bin/nvim" ]; then
    current="$("$OPT_DIR/nvim/bin/nvim" --version | head -n1 | awk '{print $2}')"
  fi

  if [ "$current" = "$latest" ]; then
    info "Neovim $current is up to date"
  else
    info "Installing Neovim $latest${current:+ (was $current)}"
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/neovim/neovim/releases/download/$latest/nvim-linux-$arch.tar.gz" \
      | tar -xz -C "$tmp"
    mkdir -p "$OPT_DIR"
    rm -rf "$OPT_DIR/nvim"
    mv "$tmp/nvim-linux-$arch" "$OPT_DIR/nvim"
    rm -rf "$tmp"
  fi

  mkdir -p "$BIN_DIR"
  ln -sf "$OPT_DIR/nvim/bin/nvim" "$NVIM"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not on your PATH; add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
  if [ "$(command -v nvim || true)" != "$NVIM" ] && command -v nvim >/dev/null; then
    warn "'nvim' on your PATH is $(command -v nvim), not $NVIM; remove the other copy or put $BIN_DIR first"
  fi
}

install_config() {
  if [ -d "$CONFIG_DIR/.git" ]; then
    info "Updating config in $CONFIG_DIR"
    git -C "$CONFIG_DIR" pull --ff-only || warn "could not fast-forward $CONFIG_DIR (local changes?); left as is"
  else
    if [ -e "$CONFIG_DIR" ]; then
      local backup
      backup="$CONFIG_DIR.bak-$(date +%Y%m%d-%H%M%S)"
      info "Moving existing $CONFIG_DIR to $backup"
      mv "$CONFIG_DIR" "$backup"
    fi
    info "Cloning $REPO into $CONFIG_DIR"
    git clone --branch "$BRANCH" "$REPO" "$CONFIG_DIR"
  fi
}

save_api_key() {
  local key_file="$DATA_DIR/openwebui_api_key" key="${OPENWEBUI_API_KEY:-}"
  if [ -z "$key" ] && [ -s "$key_file" ]; then return; fi
  if [ -z "$key" ]; then
    # stdin is the script itself under `curl | bash`, so ask on the terminal.
    if ! (: </dev/tty) 2>/dev/null; then
      warn "no terminal to ask for the Open WebUI API key; write it to $key_file later"
      return
    fi
    printf 'Open WebUI API key (Settings > Account > API Keys; blank to skip): ' >/dev/tty
    read -rs key </dev/tty || true
    echo >/dev/tty
    [ -n "$key" ] || return
  fi
  mkdir -p "$DATA_DIR"
  (umask 077 && printf '%s' "$key" >"$key_file")
  info "Saved API key to $key_file"
}

install_deps
install_neovim
install_config
save_api_key

info "Installing plugins (pinned by lazy-lock.json)"
"$NVIM" --headless "+Lazy! restore" "+Lazy! clean" +qa

info "Done. Run 'nvim'; run this script again any time to update."
