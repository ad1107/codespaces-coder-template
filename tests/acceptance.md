# Acceptance Tests

Run these against a test Coder instance before replacing an existing template.

## 1. Empty Workspace

Create a workspace with no `repo_url`.

- Workspace starts.
- `/workspaces` exists.
- VS Code Web opens `/workspaces`.
- Terminal works.

## 2. Public GitHub Repo Without Devcontainer

Create a workspace with a public GitHub repo that has no devcontainer.

- Repo appears in `/workspaces/<repo>`.
- VS Code opens `/workspaces/<repo>`.
- Create a file in the repo.
- Stop workspace.
- Start workspace.
- Confirm the file remains.

## 3. Public GitHub Repo With Simple Devcontainer

Use `examples/minimal-devcontainer`.

- Devcontainer is handled by Envbuilder or Coder Dev Containers tooling.
- `.post-create-ran` exists.
- No template script parses `devcontainer.json` or extracts only `postCreateCommand`.

## 4. Homelab-Comfy Persistence

Inside the workspace:

```bash
echo workspaces > /workspaces/persist-test.txt
echo home > ~/home-persist-test.txt
```

Stop and start the workspace.

- `/workspaces/persist-test.txt` remains.
- `~/home-persist-test.txt` remains.

## 5. Ephemeral Behavior

Inside the workspace:

```bash
echo tmp > /tmp/tmp-test.txt
```

Stop and start the workspace.

- `/tmp` behavior matches the docs.
- Do not rely on `/tmp` for important work.

## 6. VS Code Desktop

Click VS Code Desktop.

- It opens the correct folder.
- For v2, verify the devcontainer sub-agent is available when a devcontainer starts.

## 7. Browser VS Code

Open VS Code Web.

- It opens the correct folder.
- Basic editing and terminal use work.

## 8. Resource Limits

Create a workspace with default settings.

- CPU default is 2 cores.
- RAM default is 3 GB.
- Max RAM option is 6 GB.
- No template defaults to 8 GB.

## 8a. Image Presets

Create a v1 workspace with the default image settings.

- `base_image_preset` defaults to `mcr.microsoft.com/devcontainers/universal:linux`.
- A no-devcontainer repo uses the fallback image, and an empty v1 workspace boots the selected base image directly.

Create a v2 workspace with the default image settings.

- `parent_image_preset` defaults to `mcr.microsoft.com/devcontainers/universal:linux`.
- `devcontainer --version` works inside the parent workspace.
- `docker ps` works inside the parent workspace.
- `git` and either `curl` or `wget` are available inside the parent workspace.

Create one workspace with a custom image value.

- The selected custom image appears in Coder metadata.
- Invalid image references with spaces are rejected.

## 9. Docker Socket Easy Mode

Inside the workspace:

```bash
docker ps
```

- Command works or fails with a documented Docker socket group permission issue.
- README and `docs/security.md` warn that this is unsafe for untrusted code.

## 10. Delete Behavior

Create files in `/workspaces` and `/home/coder`.

Delete the workspace.

- Confirm Terraform/Coder resource cleanup behavior.
- Confirm docs accurately describe the risk that persistent volumes may be destroyed.
