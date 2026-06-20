#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DOTFILES_REPO:-}" ]; then
  echo "No dotfiles repository supplied."
  exit 0
fi

if command -v coder >/dev/null 2>&1 && coder dotfiles "$DOTFILES_REPO" -y; then
  echo "Dotfiles installed with coder dotfiles."
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is unavailable; skipping dotfiles."
  exit 0
fi

if [ ! -d "$HOME/.dotfiles/.git" ]; then
  git clone "$DOTFILES_REPO" "$HOME/.dotfiles" || exit 0
fi

for installer in install.sh install bootstrap.sh setup.sh; do
  if [ -f "$HOME/.dotfiles/$installer" ]; then
    (cd "$HOME/.dotfiles" && sh "$installer") || true
    exit 0
  fi
done

echo "Dotfiles cloned; no standard install script found."
