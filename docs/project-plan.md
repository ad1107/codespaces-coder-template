# Project Plan

Build a self-hosted, Codespaces-like Coder template set for trusted personal or small-team development.

The goal is not to claim perfect GitHub Codespaces parity. The goal is to provide the useful workflow:

```text
Create workspace
Choose a public GitHub repo
Workspace boots
Repo appears in /workspaces
VS Code Web works
VS Code Desktop works
Files persist after stop/start
Home directory feels personal
Devcontainer configuration is handled by real tooling
Stop/start feels predictable
Delete means delete
```

## Fixed Decisions

Use these defaults unless the template grows a safer alternative:

```text
Persistence style:
  homelab_comfy

Security mode:
  trusted personal use first

Docker mode:
  host Docker socket first

Devcontainer strategy:
  Envbuilder first
  Coder Dev Containers Integration second

Private repos:
  future work

Repo source:
  public GitHub HTTPS repos first

Default CPU:
  2 cores

Default RAM:
  3 GB

Max selectable RAM:
  6 GB

Never:
  default to 8 GB RAM
```

Do not hardcode private email addresses, tokens, SSH keys, local usernames, domains, IP addresses, or personal paths into reusable Terraform or docs.

## Architecture

The repository ships two templates.

| Template | Purpose |
| --- | --- |
| `docker-envbuilder` | Stable default template using Coder Envbuilder. |
| `docker-devcontainer-integration` | Closer Dev Containers behavior using `@devcontainers/cli` and `coder_devcontainer`. |

Why two templates?

```text
docker-envbuilder:
  simpler
  reliable first path
  good default for many repos

docker-devcontainer-integration:
  closer to true Dev Containers behavior
  better for Docker Compose and multi-container repos
  more moving parts
```

## Repository Structure

```text
.
|-- README.md
|-- legacy/
|   `-- old-template/
|-- docs/
|   |-- architecture.md
|   |-- persistence.md
|   |-- security.md
|   |-- limitations.md
|   |-- homelab-install.md
|   `-- project-plan.md
|-- templates/
|   |-- docker-envbuilder/
|   `-- docker-devcontainer-integration/
|-- examples/
`-- tests/
```

## Template 1: docker-envbuilder

This is the stable first path.

Expected flow:

```text
1. User creates a workspace from the Envbuilder template.
2. User optionally enters a public GitHub repo URL.
3. Workspace starts.
4. Repo is cloned into /workspaces/<repo-name> when provided.
5. Envbuilder handles devcontainer-aware build behavior.
6. VS Code Web opens.
7. VS Code Desktop opens.
8. Files in /workspaces and /home/coder persist.
```

Required parameters:

```text
repo_url
repo_branch
devcontainer_path
dotfiles_repo
git_author_name
git_author_email
cpu_cores
memory_gb
persistence_mode
base_image_preset
custom_base_image
```

Do not manually parse `devcontainer.json` with Bash. Do not extract and run only `postCreateCommand`.

## Template 2: docker-devcontainer-integration

This is the closer Dev Containers path.

Expected flow:

```text
1. Parent workspace starts.
2. Repo is cloned into /workspaces/<repo-name>.
3. Devcontainer config is detected.
4. Devcontainer is built by real tooling.
5. Devcontainer can be started, stopped, rebuilt, and attached.
6. VS Code opens the right workspace environment.
```

Use real tooling:

```text
Coder Dev Containers Integration
coder_devcontainer
@devcontainers/cli
```

Target support includes common devcontainer fields such as `image`, `build`, `features`, `dockerComposeFile`, VS Code customizations, mounts, environment variables, lifecycle commands, and forwarded ports. Do not promise perfect support unless tests confirm it.

## Persistence

The default model is `homelab_comfy`.

Persist:

```text
/workspaces
/home/coder
/home/coder/.vscode-server
/home/coder/.local/share/code-server
/home/coder/.config/code-server
/home/coder/.cache
```

Do not persist:

```text
/tmp
running processes
container root filesystem
manual package installs outside persistent paths
```

Use immutable workspace IDs in Docker volume names, and label resources with owner, owner ID, workspace ID, workspace name at creation, template name, and template mode.

## Security

The first Docker mode is `host_socket_easy_unsafe`.

Mount:

```text
/var/run/docker.sock:/var/run/docker.sock
```

Document clearly that this is convenient for trusted use and unsafe for untrusted code, public hosting, or random repositories.

Future safer modes:

```text
rootless Podman
Docker-in-Docker
Sysbox
Kubernetes workspaces
VM-backed workspaces
```

## Documentation Requirements

The README should explain:

```text
what this is
what this is not
quick start
which template to use
architecture
persistence
stop/start/rebuild/delete behavior
VS Code Web vs VS Code Desktop
devcontainer support
Docker security warning
troubleshooting
limitations
roadmap
```

Docs should cover:

```text
architecture
persistence
security
limitations
generic install/update commands
```

## Acceptance Tests

Create and maintain:

```text
tests/acceptance.md
tests/smoke-test.sh
```

Acceptance coverage:

```text
empty workspace
public GitHub repo without devcontainer
public GitHub repo with simple devcontainer
persistence through stop/start
documented /tmp behavior
VS Code Desktop
VS Code Web
resource defaults
Docker socket mode
delete behavior
```

## Non-Goals For v1

```text
private GitHub repo auth
GitLab support
Bitbucket support
SSH repo URLs
multi-user isolation
rootless Podman
Sysbox
Kubernetes backend
VM backend
full Microsoft VS Code web clone
perfect GitHub Codespaces parity
```

## Definition Of Done

```text
A user can push the template to Coder.
A user can create a workspace from a public GitHub repo.
The repo appears in /workspaces.
VS Code Web works.
VS Code Desktop works.
Files in /workspaces survive stop/start.
Files in /home/coder survive stop/start.
The template defaults to 2 CPU and 3 GB RAM.
The template never defaults to 8 GB RAM.
Docs accurately explain limitations.
The template does not fake devcontainer support with Bash JSON parsing.
Docker socket mode is clearly marked as convenient but unsafe.
```
