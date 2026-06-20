# docker-devcontainer-integration

Experimental v2 template.

This template starts a parent Coder workspace and then uses Coder's Dev Containers Integration to build/start a real devcontainer with `@devcontainers/cli` and Docker.

## Defaults

- Public GitHub repos only.
- Safe clone behavior into `/workspaces/<repo>`.
- `coder_devcontainer` autostart when a repo is supplied.
- Host Docker socket mounted.
- 2 CPU cores and 3 GB RAM by default.
- 6 GB max selectable RAM.

## Push

```bash
coder templates push codespaces-devcontainer
```

Run this from `templates/docker-devcontainer-integration`.

## Notes

This is the better long-term template for Docker Compose and multi-container devcontainers, but it is more complex than `docker-envbuilder`.
