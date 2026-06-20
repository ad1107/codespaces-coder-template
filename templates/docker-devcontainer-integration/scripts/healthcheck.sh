#!/usr/bin/env bash
set -euo pipefail

echo "Workspace folder: ${WORKSPACE_FOLDER:-/workspaces}"
test -d /workspaces
test -d "$HOME"

if command -v docker >/dev/null 2>&1; then
  docker ps >/dev/null 2>&1 && echo "Docker socket reachable." || echo "Docker command exists, but socket is not reachable."
else
  echo "Docker CLI not found in parent workspace."
fi

if command -v devcontainer >/dev/null 2>&1; then
  devcontainer --version || true
else
  echo "@devcontainers/cli is not installed yet."
fi
