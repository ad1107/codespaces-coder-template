# Universal DevContainer Template for [Coder](https://coder.com)

This template brings the GitHub Codespaces experience to your self-hosted Coder installation. It is designed to provide a persistent, fully featured development environment that pulls the container image once and retains all data, extensions, and system changes across restarts.  

## Overview

Unlike ephemeral containers that rebuild on every start, this template persists the entire root filesystem. This architecture offers several distinct advantages:

*   **State Persistence:** The user home directory, system packages installed via `apt`, VS Code extensions, and project files in `/workspaces` are preserved indefinitely.
*   **Performance:** The workspace boots in seconds because the container image is not recreated on startup.
*   **Lifecycle Control:** Workspaces do not have an auto-shutdown timer. They run continuously until manually stopped, making them suitable for long-running background tasks or servers, ensuring full persistence.
*   **Resource Management:** Administrators and users can define specific CPU core and RAM limits to manage infrastructure load effectively. Pull once, reuse indefinitely and rebuilds frequently based on devcontainer.json
*   **Self-hosted:** Easily deploy freely, with privacy on any devices you own, without limits.

## Environment Architecture

The workspace runs as the non-root `codespace` user, mirroring the permissions and setup found in GitHub Codespaces. The environment is configured with passwordless `sudo`, allowing for seamless system administration without interrupting the workflow.

### Directory Structure

The filesystem organization ensures compatibility with standard devcontainer patterns:

```
/
├── home/
│   └── codespace/           # Persisted user configuration (.bashrc, .gitconfig)
│       └── .vscode-server/  # Persisted VS Code extensions and server data
│
└── workspaces/              # Persisted project storage
    └── {repo-name}/         # Cloned repositories reside here
```

### Editor Integration

The environment is optimized for VS Code. Users can connect via the browser-based VS Code Web or use the official Coder extension to connect a local VS Code Desktop instance. Settings, keybindings, and extensions are synchronized automatically if the user signs in to their GitHub or Microsoft account within the editor.

## Included Tooling

By default, the template uses the `mcr.microsoft.com/devcontainers/universal` image. This provides a comprehensive toolchain suitable for most development tasks without requiring additional installation.

*   **Languages:** Python (3.x), Node.js (LTS), Java (OpenJDK), Go, Rust, Ruby, PHP, and .NET.
*   **DevOps & Cloud:** Docker CLI (Docker-in-Docker supported), kubectl, Terraform, AWS CLI, and Azure CLI.
*   **Utilities:** Git (with GitHub CLI), Bash, Zsh, Vim, and Nano.

## Usage

### Deployment

To add this template to your Coder deployment:

```bash
cd /path/to/devcontainer-universal
coder templates push devcontainer-universal
```

### Workspace Creation

When creating a workspace, you can configure several parameters to tailor the environment to your needs.

| Parameter | Description | Default |
|-----------|-------------|---------|
| **Git Repository URL** | Automatically clones a repository into `/workspaces`. Leave empty for a blank environment. | Empty |
| **Custom Docker Image** | Overrides the default Microsoft Universal image. | `mcr.microsoft.com/devcontainers/universal` |
| **Dotfiles Repository** | URL to a dotfiles repo for automatic configuration. | Empty |
| **Git Author Name/Email** | Sets the global git configuration for the workspace. | Coder User Data |
| **CPU Cores** | Allocation of compute resources (1-16 cores). | 4 |
| **Memory (GB)** | Allocation of RAM (1-64 GB). | 8 |

### Custom Images

While the Microsoft Universal image is the default, the template accepts any Docker image. Common alternatives include:

*   `mcr.microsoft.com/devcontainers/base:ubuntu` (Lightweight)
*   `mcr.microsoft.com/devcontainers/python:3.11`
*   `mcr.microsoft.com/devcontainers/javascript-node:18`
*   `mcr.microsoft.com/devcontainers/go:1.21`

## License

MIT