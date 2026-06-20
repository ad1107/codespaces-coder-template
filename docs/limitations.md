# Limitations

- v1 supports public GitHub HTTPS repos only.
- Private repo support is not implemented.
- GitLab, Bitbucket, SSH URLs, and arbitrary Git hosts are not v1 targets.
- This is not GitHub Codespaces.
- This is not a full Microsoft VS Code web clone.
- code-server and VS Code Web have marketplace and settings-sync differences from VS Code Desktop.
- The host Docker socket is unsafe for untrusted code.
- Small hosts may only support a few concurrent serious workspaces.
- Envbuilder may not handle every advanced devcontainer shape the same way as VS Code or GitHub Codespaces.
- Docker Compose and multi-container devcontainers are better tested through the v2 Dev Containers Integration template.
- `coder_devcontainer` currently has fewer knobs than raw `devcontainer up`; some advanced CLI arguments may require future Coder/provider support.
