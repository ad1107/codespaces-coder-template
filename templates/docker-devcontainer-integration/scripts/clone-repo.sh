#!/usr/bin/env bash
set -euo pipefail

repo_url="${REPO_URL:-}"
repo_branch="${REPO_BRANCH:-}"
workspace_folder="${WORKSPACE_FOLDER:-/workspaces}"

mkdir -p /workspaces

if [ -z "$repo_url" ]; then
  echo "No repo_url supplied. Created /workspaces only."
  exit 0
fi

case "$repo_url" in
  https://github.com/*) ;;
  *)
    echo "Only public GitHub HTTPS repositories are supported in these templates." >&2
    exit 1
    ;;
esac

repo_name="$(basename "$repo_url" .git)"
if [ "$workspace_folder" = "/workspaces" ]; then
  workspace_folder="/workspaces/$repo_name"
fi

if [ -d "$workspace_folder/.git" ]; then
  echo "$workspace_folder already exists. Not pulling or overwriting."
  git -C "$workspace_folder" status --short --branch || true
  exit 0
fi

if [ -e "$workspace_folder" ] && [ -n "$(find "$workspace_folder" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "$workspace_folder exists and is not empty, but is not a git checkout. Refusing to overwrite." >&2
  ls -la "$workspace_folder" || true
  exit 1
fi

clone_args=()
if [ -n "$repo_branch" ]; then
  clone_args+=(--branch "$repo_branch" --single-branch)
fi

mkdir -p "$(dirname "$workspace_folder")"
git clone "${clone_args[@]}" "$repo_url" "$workspace_folder"
git -C "$workspace_folder" status --short --branch || true
