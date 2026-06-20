# Architecture

This repository contains two Coder templates because there are two useful goals.

`docker-envbuilder` is the default v1. It runs the workspace through Envbuilder, which turns a repository's devcontainer configuration into the workspace image. This avoids Bash JSON parsing and gives a stable, low-friction path for a small homelab.

`docker-devcontainer-integration` is the closer GitHub Codespaces-style v2. It starts a parent Coder workspace, installs `@devcontainers/cli`, clones the repo, and lets Coder's Dev Containers Integration start a devcontainer as a sub-agent.

## Envbuilder Flow

1. Coder provisions a Docker container from `ghcr.io/coder/envbuilder`.
2. Envbuilder receives `ENVBUILDER_GIT_URL`, `ENVBUILDER_WORKSPACE_FOLDER`, and the Coder agent init script.
3. Envbuilder clones the public GitHub repo into `/workspaces/<repo>`.
4. Envbuilder builds or falls back based on the repo's devcontainer configuration.
5. The Coder agent starts in the resulting environment.
6. VS Code Web and VS Code Desktop open the workspace folder.

## Dev Containers Integration Flow

1. Coder starts a parent workspace container.
2. `/workspaces` and `/home/coder` are mounted from persistent Docker volumes.
3. The repo is cloned safely into `/workspaces/<repo>`.
4. The `devcontainers-cli` module installs `@devcontainers/cli`.
5. `coder_devcontainer` starts the devcontainer from the repo.
6. Coder exposes the devcontainer as a sub-agent for terminal, SSH, port forwarding, and VS Code.

## Persistent Volumes

Volumes use immutable workspace IDs:

```text
coder-${workspace_id}-workspaces
coder-${workspace_id}-home
coder-${workspace_id}-vscode-server
coder-${workspace_id}-code-server-data
coder-${workspace_id}-code-server-config
coder-${workspace_id}-cache
```

Each volume carries labels for owner, owner ID, workspace ID, workspace name at creation, template name, and template mode.

## Docker Socket Flow

The templates mount the host Docker socket into the workspace. This lets commands such as `docker ps`, `docker build`, and `docker compose up` use the host Docker daemon. It is convenient and intentionally unsafe outside a trusted single-user homelab.
