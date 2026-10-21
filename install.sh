#!/usr/bin/env bash
# Clean (re)install of this Neovim config from the Gitea server.
#
#   curl -fsSL https://git.garykellstrom.dev/AnimalRacer3/nvim/raw/branch/main/install.sh | bash
#
# Existing config/data/state/cache dirs are moved aside with a timestamp suffix,
# never deleted. Override the source with NVIM_CONFIG_REPO / NVIM_CONFIG_BRANCH.
set -euo pipefail

REPO="${NVIM_CONFIG_REPO:-https://git.garykellstrom.dev/AnimalRacer3/nvim.git}"
BRANCH="${NVIM_CONFIG_BRANCH:-main}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
STAMP="$(date +%Y%m%d-%H%M%S)"

for cmd in git nvim; do
  command -v "$cmd" >/dev/null || { echo "error: '$cmd' is not installed" >&2; exit 1; }
done

for dir in \
  "$CONFIG_DIR" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" \
  "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" \
  "${XDG_CACHE_HOME:-$HOME/.cache}/nvim"; do
  if [ -e "$dir" ]; then
    echo "Backing up $dir -> $dir.bak-$STAMP"
    mv "$dir" "$dir.bak-$STAMP"
  fi
done

echo "Cloning $REPO ($BRANCH) into $CONFIG_DIR"
git clone --branch "$BRANCH" "$REPO" "$CONFIG_DIR"

echo "Installing plugins (pinned by lazy-lock.json)..."
nvim --headless "+Lazy! restore" +qa

echo "Done. Start nvim; AI requests go to \${NVIM_AI_URL:-https://ai.garykellstrom.dev}."
