# Codespaces-like Coder Templates

Self-hosted Coder templates for a personal homelab that feel close to GitHub Codespaces: paste a public GitHub repo, pick a devcontainer-aware image path, create the workspace, and open it in VS Code Web or VS Code Desktop.

This project is built for a trusted single-user or small homelab Coder install. It favors convenience, persistence, and fast iteration over hardened multi-tenant isolation.

## What You Get

- Two Docker-backed Coder templates:
  - `codespaces-envbuilder`: stable default using Coder Envbuilder.
  - `codespaces-devcontainer`: closer Dev Containers behavior using `coder_devcontainer`.
- Public GitHub HTTPS repo cloning.
- Optional empty workspaces when no repo URL is supplied.
- Devcontainer path support, defaulting to `.devcontainer/devcontainer.json`.
- VS Code Web and VS Code Desktop buttons.
- Persistent `/workspaces`, `/home/coder`, VS Code server data, code-server data, config, and cache.
- Host Docker socket access for `docker`, `docker build`, and `docker compose`.
- Image presets plus custom image fields.

## Template Choice

| Template | Best for | How it works | Devcontainer fidelity | Complexity | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `codespaces-envbuilder` | Daily homelab workspaces, simple repos, reliable starts | Coder starts `ghcr.io/coder/envbuilder`, Envbuilder clones the repo and builds from the devcontainer config | Good for many common devcontainer repos, but not perfect Codespaces parity | Lower | Use this first |
| `codespaces-devcontainer` | Docker Compose, multi-container devcontainers, testing closer Dev Containers behavior | Coder starts a parent container, clones the repo, installs `@devcontainers/cli`, then starts a devcontainer sub-agent | Closest path to VS Code Dev Containers behavior | Higher | Use when Envbuilder is not enough |

Short version: start with Envbuilder. Reach for Devcontainer Integration when the repo really needs the Dev Containers CLI flow.

## How It Works

### Envbuilder Flow

1. Coder creates a Docker container from `ghcr.io/coder/envbuilder`.
2. Envbuilder receives the repo URL, branch, devcontainer path, workspace folder, and Coder agent script.
3. Envbuilder clones the repo into `/workspaces/<repo>`.
4. Envbuilder builds or selects the workspace image from the repo's devcontainer config.
5. The Coder agent starts in the resulting workspace.
6. You open `/workspaces/<repo>` from VS Code Web or VS Code Desktop.

If `repo_url` is empty, the template skips Envbuilder and boots a direct empty workspace from the selected base image.

### Devcontainer Integration Flow

1. Coder creates a parent Docker container.
2. The template clones the repo into `/workspaces/<repo>`.
3. The `devcontainers-cli` module installs `@devcontainers/cli`.
4. `coder_devcontainer` starts the actual devcontainer from the repo.
5. Coder exposes the devcontainer as the workspace agent for terminals, SSH, ports, and VS Code.

This is the better long-term path for Docker Compose and multi-container devcontainers, but it has more moving parts.

## Install Or Update

Run these from a machine that can reach your Coder server and has a logged-in `coder` CLI.

```bash
coder login https://coder.example.com
```

Push the Envbuilder template:

```bash
cd /path/to/codespaces-coder-template/templates/docker-envbuilder
coder templates push codespaces-envbuilder
coder templates edit codespaces-envbuilder \
  --display-name "Codespaces Envbuilder" \
  --icon "/icon/devcontainers.svg" \
  --default-ttl 8h \
  --yes
```

Push the Devcontainer Integration template:

```bash
cd /path/to/codespaces-coder-template/templates/docker-devcontainer-integration
coder templates push codespaces-devcontainer
coder templates edit codespaces-devcontainer \
  --display-name "Codespaces Devcontainer" \
  --icon "/icon/devcontainers.svg" \
  --default-ttl 8h \
  --yes
```

Replace `/path/to/codespaces-coder-template` and `https://coder.example.com` with your own checkout path and Coder URL.

## Create A Workspace

1. Open your Coder deployment.
2. Click **New workspace**.
3. Pick **Codespaces Envbuilder** for the default path, or **Codespaces Devcontainer** for the Dev Containers Integration path.
4. Enter a workspace name.
5. Set `repo_url` to a public GitHub HTTPS URL, for example:

   ```text
   https://github.com/owner/repo
   ```

6. Optionally set `repo_branch`.
7. Leave `devcontainer_path` as `.devcontainer/devcontainer.json` unless the repo uses a different path.
8. Choose CPU, memory, persistence, and image options.
9. Click **Create Workspace**.
10. Open VS Code Web or VS Code Desktop from the workspace page.

To create an empty workspace, leave `repo_url` blank. The workspace opens at `/workspaces`.

## Image Options

The default image is:

```text
mcr.microsoft.com/devcontainers/universal:linux
```

That is the most Codespaces-like preset and the safest default for general development.

### Envbuilder Image Presets

`codespaces-envbuilder` uses `base_image_preset` as the fallback image when a repo has no usable devcontainer image or when you create an empty workspace.

Available presets:

- Universal Codespaces-like image: `mcr.microsoft.com/devcontainers/universal:linux`
- Ubuntu 24.04 base: `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`
- Debian 12 base: `mcr.microsoft.com/devcontainers/base:debian-12`
- Debian Bullseye base: `mcr.microsoft.com/devcontainers/base:bullseye`
- Alpine 3.22 base: `mcr.microsoft.com/devcontainers/base:alpine-3.22`
- Coder Ubuntu base: `codercom/enterprise-base:ubuntu`
- Custom image

### Devcontainer Parent Image Presets

`codespaces-devcontainer` uses `parent_image_preset` for the parent Coder container that runs Docker and `@devcontainers/cli`.

Available presets:

- Universal Codespaces-like image: `mcr.microsoft.com/devcontainers/universal:linux`
- Node 22 Debian 12: `mcr.microsoft.com/devcontainers/javascript-node:22-bookworm`
- Node 22 Bullseye: `mcr.microsoft.com/devcontainers/javascript-node:22-bullseye`
- Coder Node Ubuntu: `codercom/enterprise-node:ubuntu`
- Custom image

For custom images, use a normal Docker image reference such as:

```text
ghcr.io/owner/image:tag
```

Very small custom images should include `sh`, `git`, `curl` or `wget`, `tar`, Docker CLI, and for the devcontainer template, `npm`, `yarn`, or `pnpm`.

## Persistence

The templates persist these paths through stop/start:

- `/workspaces`
- `/home/coder`
- `/home/coder/.vscode-server`
- `/home/coder/.local/share/code-server`
- `/home/coder/.config/code-server`
- `/home/coder/.cache`

Stop/start keeps your files. Rebuild may recreate the container root filesystem. Delete destroys the workspace resources, so back up important work before deleting a workspace.

## Sudo And Root

There is normally no root password in these containers. Use:

```bash
sudo <command>
```

The root-bootstrapped workspace paths configure `coder` for passwordless sudo. If a custom image still asks for a sudo password, that image probably does not grant `coder` passwordless sudo. Use the Universal preset or bake this into the custom image:

```text
coder ALL=(ALL) NOPASSWD:ALL
```

## Known Startup Warning

Some Microsoft devcontainer images may print this on first boot:

```text
rm: cannot remove '/usr/local/share/nvm/current': Permission denied
```

It is usually harmless. It comes from Node/NVM startup code trying to refresh the `current` symlink under `/usr/local/share/nvm` as the non-root `coder` user. The templates now make that NVM directory writable in the root-bootstrapped paths, but a repo-built Envbuilder image may still show it depending on the upstream image.

## Docker Socket Warning

Both templates mount the host Docker socket:

```text
/var/run/docker.sock:/var/run/docker.sock
```

This is convenient for a trusted homelab because containers can run Docker commands against the host daemon. It is not safe for untrusted repositories or public multi-user hosting. Code inside the workspace can effectively control the host Docker daemon.

Safer future options are tracked in [docs/security.md](docs/security.md).

## Test

Static smoke checks:

```bash
bash tests/smoke-test.sh
```

Manual acceptance coverage is in [tests/acceptance.md](tests/acceptance.md).

## More Docs

- [Architecture](docs/architecture.md)
- [Homelab install](docs/homelab-install.md)
- [Persistence](docs/persistence.md)
- [Security](docs/security.md)
- [Limitations](docs/limitations.md)

## Roadmap

- Private GitHub repo support.
- GitHub OAuth or SSH clone support.
- Safer Docker modes such as rootless Podman, Sysbox, Docker-in-Docker, Kubernetes, or VM-backed workspaces.
- Better cache and prebuild flows.
- Repo picker from the GitHub API.
- Backup and restore helpers for persistent volumes.
