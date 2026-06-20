# Persistence

The default persistence model is `homelab_comfy`.

This means the workspace should feel like a personal remote Linux computer. User files, editor state, shell configuration, and caches survive stop/start. Running processes and temporary files do not.

## Persisted Paths

- `/workspaces`
- `/home/coder`
- `/home/coder/.vscode-server`
- `/home/coder/.local/share/code-server`
- `/home/coder/.config/code-server`
- `/home/coder/.cache`

Optional language caches usually live under `/home/coder`, so they are covered by the home volume:

- `/home/coder/.npm`
- `/home/coder/.pnpm-store`
- `/home/coder/.cache/pip`
- `/home/coder/go/pkg/mod`
- `/home/coder/.cargo`

## Not Persisted

- Running processes
- `/tmp`
- Container root filesystem
- Manual `apt` installs outside persistent volumes

Tools that matter should come from the repo's devcontainer, Dockerfile, or template scripts.

## Lifecycle Semantics

Stop workspace:

- Container compute stops.
- Persistent volumes remain.
- Files remain.
- Running processes stop.

Start workspace:

- Container compute returns.
- Persistent volumes remount.
- `/workspaces` files remain.
- `/home/coder` files remain.

Rebuild workspace:

- Container root filesystem may be recreated.
- Persistent volumes remain.
- Devcontainer or template-defined tools should be reapplied.

Delete workspace:

- Terraform/Coder resources are destroyed.
- Persistent volumes may be destroyed as part of the workspace lifecycle.
- Back up important work before deleting.

## Difference From Strict Codespaces

GitHub Codespaces is more deliberately ephemeral. This repo is more comfortable for a personal homelab: it keeps home and editor state so a stopped workspace feels like a paused remote machine when it comes back.
