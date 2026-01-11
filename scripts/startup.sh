#!/bin/bash
set -e

echo ""
echo "========================================"
echo "  Welcome to your Coder Workspace!"
echo "========================================"
echo ""
echo "  This environment is similar to GitHub Codespaces."
echo "  - Run as user: ${USERNAME}"
echo "  - Use 'sudo' for root access"
echo "  - Projects stored in: /workspaces"
echo ""

# Ensure /workspaces directory exists and has correct ownership
    mkdir -p /workspaces
sudo chown -R ${USERNAME}:${USERNAME} /workspaces 2>/dev/null || true

# Ensure home directory has correct ownership
sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} 2>/dev/null || true

# Git Configuration
if [ -n "${GIT_AUTHOR_NAME}" ]; then
  git config --global user.name "${GIT_AUTHOR_NAME}"
  echo "Git user.name: ${GIT_AUTHOR_NAME}"
fi

if [ -n "${GIT_AUTHOR_EMAIL}" ]; then
  git config --global user.email "${GIT_AUTHOR_EMAIL}"
  echo "Git user.email: ${GIT_AUTHOR_EMAIL}"
fi

git config --global credential.helper "cache --timeout=3600"
git config --global init.defaultBranch main
git config --global --add safe.directory "*"

# Clone repository if specified and not already cloned
if [ -n "${REPO_URL}" ] && [ ! -d "${WORKSPACE_DIR}/.git" ]; then
  echo ""
  echo "Cloning repository: ${REPO_URL}"
  mkdir -p "$(dirname "${WORKSPACE_DIR}")"
  git clone "${REPO_URL}" "${WORKSPACE_DIR}" || echo "Clone failed, continuing..."
  
  # Run devcontainer postCreateCommand if exists
  if [ -f "${WORKSPACE_DIR}/.devcontainer/devcontainer.json" ]; then
    echo "Found devcontainer.json"
    if command -v jq &> /dev/null; then
      POST_CREATE=$(jq -r '.postCreateCommand // empty' "${WORKSPACE_DIR}/.devcontainer/devcontainer.json" 2>/dev/null || true)
      if [ -n "$POST_CREATE" ] && [ "$POST_CREATE" != "null" ]; then
        echo "Running postCreateCommand: $POST_CREATE"
        cd "${WORKSPACE_DIR}" && eval "$POST_CREATE" || true
      fi
    fi
  fi
fi

# Setup dotfiles if specified
if [ -n "${DOTFILES_REPO}" ]; then
  echo ""
  echo "Setting up dotfiles from: ${DOTFILES_REPO}"
  coder dotfiles "${DOTFILES_REPO}" -y 2>/dev/null || echo "Dotfiles setup completed"
fi

echo ""
echo "========================================"
echo "  Workspace initialization complete!"
echo "========================================"
echo ""
