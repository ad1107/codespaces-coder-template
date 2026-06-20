# docker-envbuilder

Default v1 template.

This template uses Envbuilder to clone a public GitHub repo and build the workspace from its devcontainer configuration. It does not parse `devcontainer.json` in Bash.

## Defaults

- Public GitHub repos only.
- `/workspaces/<repo>` for repository workspaces.
- `/workspaces` when no repo is provided.
- `/home/coder` and editor state persisted.
- Host Docker socket mounted.
- 2 CPU cores and 3 GB RAM by default.
- 6 GB max selectable RAM.

## Push

```bash
coder templates push codespaces-envbuilder
```

Run this from `templates/docker-envbuilder`.

## Docker Socket Permissions

If `docker ps` fails with a permission error, set `docker_socket_group_id` to the host Docker group ID.
