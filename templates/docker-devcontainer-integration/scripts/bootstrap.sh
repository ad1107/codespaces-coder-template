#!/usr/bin/env bash
set -euo pipefail

mkdir -p /workspaces "$HOME" "$HOME/.vscode-server" "$HOME/.local/share/code-server" "$HOME/.config/code-server" "$HOME/.cache"

if command -v sudo >/dev/null 2>&1; then
  sudo chown -R "$(id -u):$(id -g)" /workspaces "$HOME" 2>/dev/null || true
fi

if command -v git >/dev/null 2>&1; then
  if [ -n "${GIT_AUTHOR_NAME:-}" ]; then
    git config --global user.name "${GIT_AUTHOR_NAME}" || true
  fi
  if [ -n "${GIT_AUTHOR_EMAIL:-}" ]; then
    git config --global user.email "${GIT_AUTHOR_EMAIL}" || true
  fi
  git config --global init.defaultBranch main || true
  git config --global credential.helper "cache --timeout=3600" || true
  git config --global --add safe.directory "${WORKSPACE_FOLDER:-/workspaces}" || true
fi

echo "Parent workspace bootstrapped."
