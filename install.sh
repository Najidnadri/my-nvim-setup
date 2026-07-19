#!/usr/bin/env bash
#
# Install / uninstall this Neovim configuration.
#
#   ./install.sh              symlink this repo to ~/.config/nvim
#   ./install.sh uninstall    remove the symlink and Neovim's generated data
#
# The config is symlinked rather than copied, so the repo can live anywhere and
# your edits stay under version control. Nothing is ever deleted outright:
# existing configs and generated data are moved aside to timestamped backups.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
NVIM_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
NVIM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$1" >&2; }

# Move a path aside with a timestamp so nothing is destroyed.
backup() {
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  local dest="${target}.bak.$(date +%Y%m%d%H%M%S)"
  warn "Backing up $target -> $dest"
  mv "$target" "$dest"
}

resolve() { readlink -f "$1" 2>/dev/null || true; }

install_config() {
  if [ "$(resolve "$NVIM_CONFIG")" = "$REPO_DIR" ]; then
    info "Already installed: $NVIM_CONFIG -> $REPO_DIR"
    return 0
  fi
  backup "$NVIM_CONFIG"
  mkdir -p "$(dirname "$NVIM_CONFIG")"
  ln -s "$REPO_DIR" "$NVIM_CONFIG"
  info "Linked $NVIM_CONFIG -> $REPO_DIR"
  info "Run 'nvim' to bootstrap plugins."
}

uninstall_config() {
  # Only remove OUR symlink; a real directory we didn't create is left alone.
  if [ -L "$NVIM_CONFIG" ] && [ "$(resolve "$NVIM_CONFIG")" = "$REPO_DIR" ]; then
    rm "$NVIM_CONFIG"
    info "Removed symlink $NVIM_CONFIG"
  elif [ -e "$NVIM_CONFIG" ]; then
    warn "$NVIM_CONFIG is not a symlink to this repo; leaving it untouched."
  fi
  # Generated, regenerable state — backed up rather than deleted.
  for dir in "$NVIM_DATA" "$NVIM_STATE" "$NVIM_CACHE"; do
    backup "$dir"
  done
  info "Uninstalled. The repo itself is untouched."
}

case "${1:-install}" in
  install) install_config ;;
  uninstall) uninstall_config ;;
  -h | --help | help) sed -n '3,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  *)
    warn "Usage: $0 [install|uninstall]"
    exit 1
    ;;
esac
