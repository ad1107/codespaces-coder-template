# Security

These templates assume a trusted personal or small-team environment.

## Docker Socket Risk

The default Docker mode is `host_socket_easy_unsafe`.

The workspace mounts:

```text
/var/run/docker.sock:/var/run/docker.sock
```

This lets the workspace use the host Docker daemon. It also means code inside the workspace can effectively control the host through Docker.

Do not use this mode for:

- Public multi-user hosting.
- Untrusted developers.
- Random repositories you have not reviewed.
- Malicious code samples.

## Why It Is Accepted For v1

The default environment is a trusted Coder host where convenience matters. The socket mode keeps Docker commands simple and avoids blocking v1 on a larger isolation project.

## Safer Future Options

- Rootless Podman.
- Docker-in-Docker with careful persistence.
- Sysbox.
- Kubernetes workspaces.
- VM-backed workspaces.
- Proxmox backend.

Those options belong in later versions because each adds operational complexity.

## Secrets

Do not hardcode private email addresses, tokens, SSH keys, or personal secrets in reusable Terraform. v1 intentionally does not implement private repository authentication.
