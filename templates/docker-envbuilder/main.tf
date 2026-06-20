provider "coder" {}

provider "docker" {
  host = "unix://${var.docker_socket_path}"
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "repo_url" {
  name         = "repo_url"
  display_name = "Public GitHub Repository"
  description  = "Optional public GitHub HTTPS repository to clone into /workspaces."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/github.svg"
  order        = 1

  validation {
    regex = "^$|^https://github\\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\\.git)?$"
    error = "Use an empty value or a public GitHub HTTPS URL such as https://github.com/owner/repo."
  }
}

data "coder_parameter" "repo_branch" {
  name         = "repo_branch"
  display_name = "Repository Branch"
  description  = "Optional branch to clone."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 2
}

data "coder_parameter" "devcontainer_path" {
  name         = "devcontainer_path"
  display_name = "Devcontainer Path"
  description  = "Path to devcontainer.json inside the repository."
  type         = "string"
  default      = ".devcontainer/devcontainer.json"
  mutable      = true
  icon         = "/icon/devcontainers.svg"
  order        = 3

  validation {
    regex = "^\\S.*devcontainer\\.json$"
    error = "Use a path ending in devcontainer.json, for example .devcontainer/devcontainer.json."
  }
}

data "coder_parameter" "dotfiles_repo" {
  name         = "dotfiles_repo"
  display_name = "Dotfiles Repository"
  description  = "Optional dotfiles repository."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 6
}

data "coder_parameter" "git_author_name" {
  name         = "git_author_name"
  display_name = "Git Author Name"
  description  = "Optional Git user.name."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 7
}

data "coder_parameter" "git_author_email" {
  name         = "git_author_email"
  display_name = "Git Author Email"
  description  = "Optional Git user.email."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 8
}

data "coder_parameter" "cpu_cores" {
  name         = "cpu_cores"
  display_name = "CPU Cores"
  description  = "CPU cores for the workspace container."
  type         = "number"
  default      = "2"
  mutable      = false
  icon         = "/icon/memory.svg"
  order        = 9

  option {
    name  = "1 core"
    value = "1"
  }
  option {
    name  = "2 cores"
    value = "2"
  }
  option {
    name  = "3 cores"
    value = "3"
  }
  option {
    name  = "4 cores"
    value = "4"
  }
}

data "coder_parameter" "memory_gb" {
  name         = "memory_gb"
  display_name = "Memory"
  description  = "RAM for the workspace container."
  type         = "number"
  default      = "3"
  mutable      = false
  icon         = "/icon/memory.svg"
  order        = 10

  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "3 GB"
    value = "3"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "5 GB"
    value = "5"
  }
  option {
    name  = "6 GB"
    value = "6"
  }
}

data "coder_parameter" "persistence_mode" {
  name         = "persistence_mode"
  display_name = "Persistence Mode"
  description  = "Only homelab-comfy persistence is implemented in v1."
  type         = "string"
  default      = "homelab_comfy"
  mutable      = false
  icon         = "/emojis/1f4be.png"
  order        = 11

  option {
    name  = "homelab-comfy"
    value = "homelab_comfy"
  }
}

data "coder_parameter" "base_image_preset" {
  name         = "base_image_preset"
  display_name = "Base Image"
  description  = "Fallback image used when Envbuilder has no usable devcontainer image or Dockerfile."
  type         = "string"
  default      = "mcr.microsoft.com/devcontainers/universal:linux"
  mutable      = false
  icon         = "/icon/docker.svg"
  order        = 4

  option {
    name  = "Universal (Codespaces-like)"
    value = "mcr.microsoft.com/devcontainers/universal:linux"
  }
  option {
    name  = "Ubuntu 24.04 base"
    value = "mcr.microsoft.com/devcontainers/base:ubuntu-24.04"
  }
  option {
    name  = "Debian 12 base"
    value = "mcr.microsoft.com/devcontainers/base:debian-12"
  }
  option {
    name  = "Debian Bullseye base"
    value = "mcr.microsoft.com/devcontainers/base:bullseye"
  }
  option {
    name  = "Alpine 3.22 base"
    value = "mcr.microsoft.com/devcontainers/base:alpine-3.22"
  }
  option {
    name  = "Coder Ubuntu base"
    value = "codercom/enterprise-base:ubuntu"
  }
  option {
    name  = "Custom image"
    value = "custom"
  }
}

data "coder_parameter" "custom_base_image" {
  name         = "custom_base_image"
  display_name = "Custom Base Image"
  description  = "Optional image reference used only when Base Image is Custom image. Empty workspaces boot this image directly; apt/apk/yum/dnf images are bootstrapped with missing basics."
  type         = "string"
  default      = ""
  mutable      = false
  icon         = "/icon/docker.svg"
  order        = 5

  validation {
    regex = "^$|^[A-Za-z0-9][A-Za-z0-9._/:@-]+$"
    error = "Use an image reference like registry.example.com/owner/image:tag, without spaces."
  }
}

locals {
  repo_url          = trimspace(data.coder_parameter.repo_url.value)
  repo_branch       = trimspace(data.coder_parameter.repo_branch.value)
  repo_name         = local.repo_url != "" ? trimsuffix(basename(local.repo_url), ".git") : ""
  workspace_dir     = local.repo_url != "" ? "/workspaces/${local.repo_name}" : "/workspaces"
  envbuilder_git_url = (
    local.repo_url != "" && local.repo_branch != "" ?
    "${local.repo_url}#refs/heads/${local.repo_branch}" :
    local.repo_url
  )

  devcontainer_path = trim(data.coder_parameter.devcontainer_path.value, "/")
  devcontainer_dir  = dirname(local.devcontainer_path)
  devcontainer_json = basename(local.devcontainer_path)
  base_image_preset = trimspace(data.coder_parameter.base_image_preset.value)
  custom_base_image = trimspace(data.coder_parameter.custom_base_image.value)
  base_image = (
    local.base_image_preset == "custom" && local.custom_base_image != "" ?
    local.custom_base_image :
    local.base_image_preset != "custom" ? local.base_image_preset : var.fallback_image
  )

  git_author_name = (
    trimspace(data.coder_parameter.git_author_name.value) != "" ?
    data.coder_parameter.git_author_name.value :
    coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
  )
  git_author_email = (
    trimspace(data.coder_parameter.git_author_email.value) != "" ?
    data.coder_parameter.git_author_email.value :
    data.coder_workspace_owner.me.email
  )

  docker_labels = {
    "coder.owner"                    = data.coder_workspace_owner.me.name
    "coder.owner_id"                 = data.coder_workspace_owner.me.id
    "coder.workspace_id"             = data.coder_workspace.me.id
    "coder.workspace_name_at_creation" = data.coder_workspace.me.name
    "template.name"                  = "codespaces-envbuilder"
    "template.mode"                  = "docker-envbuilder"
  }

  envbuilder_env = {
    CODER_AGENT_TOKEN                  = coder_agent.main.token
    CODER_AGENT_URL                    = replace(data.coder_workspace.me.access_url, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
    ENVBUILDER_INIT_SCRIPT             = replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
    ENVBUILDER_GIT_URL                 = local.envbuilder_git_url
    ENVBUILDER_GIT_CLONE_SINGLE_BRANCH = local.repo_branch != "" ? "true" : ""
    ENVBUILDER_WORKSPACE_FOLDER        = local.workspace_dir
    ENVBUILDER_DEVCONTAINER_DIR        = local.devcontainer_dir
    ENVBUILDER_DEVCONTAINER_JSON_PATH  = local.devcontainer_json
    ENVBUILDER_FALLBACK_IMAGE          = local.base_image
    ENVBUILDER_SKIP_REBUILD            = "true"
    WORKSPACE_FOLDER                   = local.workspace_dir
    REPO_URL                           = local.repo_url
    REPO_BRANCH                        = local.repo_branch
    DOTFILES_REPO                      = trimspace(data.coder_parameter.dotfiles_repo.value)
    GIT_AUTHOR_NAME                    = local.git_author_name
    GIT_AUTHOR_EMAIL                   = local.git_author_email
    GIT_COMMITTER_NAME                 = local.git_author_name
    GIT_COMMITTER_EMAIL                = local.git_author_email
    DOCKER_HOST                        = "unix:///var/run/docker.sock"
    HOME                               = "/home/coder"
    USER                               = "coder"
  }

  docker_env = [
    for key, value in local.envbuilder_env : "${key}=${value}"
    if value != ""
  ]
}

resource "docker_image" "envbuilder" {
  name         = var.envbuilder_image
  keep_locally = true
}

resource "docker_image" "empty_workspace" {
  count        = data.coder_workspace.me.start_count == 0 || local.repo_url != "" ? 0 : 1
  name         = local.base_image
  keep_locally = true
}

resource "docker_volume" "workspaces" {
  name = "coder-${data.coder_workspace.me.id}-workspaces"

  lifecycle {
    ignore_changes = all
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"

  lifecycle {
    ignore_changes = all
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "docker_volume" "vscode_server" {
  name = "coder-${data.coder_workspace.me.id}-vscode-server"

  lifecycle {
    ignore_changes = all
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "docker_volume" "code_server_data" {
  name = "coder-${data.coder_workspace.me.id}-code-server-data"

  lifecycle {
    ignore_changes = all
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "docker_volume" "code_server_config" {
  name = "coder-${data.coder_workspace.me.id}-code-server-config"

  lifecycle {
    ignore_changes = all
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "docker_volume" "cache" {
  name = "coder-${data.coder_workspace.me.id}-cache"

  lifecycle {
    ignore_changes = all
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p /workspaces "$HOME" "$HOME/.vscode-server" "$HOME/.local/share/code-server" "$HOME/.config/code-server" "$HOME/.cache"

    if command -v sudo >/dev/null 2>&1; then
      sudo chown -R "$(id -u):$(id -g)" /workspaces "$HOME" 2>/dev/null || true
    fi

    if command -v git >/dev/null 2>&1; then
      if [ -n "$${GIT_AUTHOR_NAME:-}" ]; then
        git config --global user.name "$${GIT_AUTHOR_NAME}" || true
      fi
      if [ -n "$${GIT_AUTHOR_EMAIL:-}" ]; then
        git config --global user.email "$${GIT_AUTHOR_EMAIL}" || true
      fi
      git config --global init.defaultBranch main || true
      git config --global credential.helper "cache --timeout=3600" || true
      git config --global --add safe.directory "$${WORKSPACE_FOLDER}" || true
    fi

    if [ -n "$${DOTFILES_REPO:-}" ]; then
      if command -v coder >/dev/null 2>&1 && coder dotfiles "$${DOTFILES_REPO}" -y; then
        echo "Dotfiles installed with coder dotfiles."
      else
        if command -v git >/dev/null 2>&1; then
          if [ ! -d "$HOME/.dotfiles/.git" ]; then
            git clone "$${DOTFILES_REPO}" "$HOME/.dotfiles" || true
          fi
          for installer in install.sh install bootstrap.sh setup.sh; do
            if [ -f "$HOME/.dotfiles/$installer" ]; then
              (cd "$HOME/.dotfiles" && sh "$installer") || true
              break
            fi
          done
        fi
      fi
    fi

    if [ -n "$${REPO_URL:-}" ]; then
      echo "Repository: $${REPO_URL}"
      echo "Workspace folder: $${WORKSPACE_FOLDER}"
      if [ -d "$${WORKSPACE_FOLDER}/.git" ] && command -v git >/dev/null 2>&1; then
        git -C "$${WORKSPACE_FOLDER}" status --short --branch || true
      else
        echo "No git checkout found at $${WORKSPACE_FOLDER}. Check Envbuilder logs if a repo was expected."
      fi
    else
      echo "No repo_url supplied. Open /workspaces and clone manually when ready."
    fi
  EOT

  env = {
    GIT_AUTHOR_NAME     = local.git_author_name
    GIT_AUTHOR_EMAIL    = local.git_author_email
    GIT_COMMITTER_NAME  = local.git_author_name
    GIT_COMMITTER_EMAIL = local.git_author_email
    WORKSPACE_FOLDER    = local.workspace_dir
    REPO_URL            = local.repo_url
    REPO_BRANCH         = local.repo_branch
    DOTFILES_REPO       = trimspace(data.coder_parameter.dotfiles_repo.value)
    DOCKER_HOST         = "unix:///var/run/docker.sock"
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_mem_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Workspaces Disk"
    key          = "2_workspaces_disk"
    script       = "coder stat disk --path /workspaces"
    interval     = 60
    timeout      = 1
  }
}

module "vscode-web" {
  count          = data.coder_workspace.me.start_count
  source         = "registry.coder.com/coder/vscode-web/coder"
  version        = "1.4.3"
  agent_id       = coder_agent.main.id
  folder         = local.workspace_dir
  accept_license = true
  subdomain      = false
  order          = 1
}

module "vscode" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/vscode-desktop/coder"
  version  = "1.2.0"
  agent_id = coder_agent.main.id
  folder   = local.workspace_dir
  order    = 2
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count == 0 || local.repo_url == "" ? 0 : 1
  image    = docker_image.envbuilder.image_id
  name     = "coder-${data.coder_workspace.me.id}-envbuilder"
  hostname = data.coder_workspace.me.name

  env       = local.docker_env
  group_add = compact([var.docker_socket_group_id])

  cpu_period = 100000
  cpu_quota  = tonumber(data.coder_parameter.cpu_cores.value) * 100000
  cpu_shares = tonumber(data.coder_parameter.cpu_cores.value) * 1024
  memory      = tonumber(data.coder_parameter.memory_gb.value) * 1024
  memory_swap = tonumber(data.coder_parameter.memory_gb.value) * 1024

  capabilities {
    add = ["SYS_PTRACE"]
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    volume_name    = docker_volume.workspaces.name
    container_path = "/workspaces"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.home.name
    container_path = "/home/coder"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.vscode_server.name
    container_path = "/home/coder/.vscode-server"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.code_server_data.name
    container_path = "/home/coder/.local/share/code-server"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.code_server_config.name
    container_path = "/home/coder/.config/code-server"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.cache.name
    container_path = "/home/coder/.cache"
    read_only      = false
  }

  volumes {
    host_path      = var.docker_socket_path
    container_path = "/var/run/docker.sock"
    read_only      = false
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "docker_container" "empty_workspace" {
  count    = data.coder_workspace.me.start_count == 0 || local.repo_url != "" ? 0 : 1
  image    = docker_image.empty_workspace[0].image_id
  name     = "coder-${data.coder_workspace.me.id}-workspace"
  hostname = data.coder_workspace.me.name

  user = "root"
  command = [
    "sh",
    "-c",
    <<-EOT
      install_basics() {
        need_tools=""
        command -v docker >/dev/null 2>&1 || need_tools=1
        command -v git >/dev/null 2>&1 || need_tools=1
        command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || need_tools=1
        command -v tar >/dev/null 2>&1 || need_tools=1
        [ -n "$need_tools" ] || return 0

        if command -v apt-get >/dev/null 2>&1; then
          export DEBIAN_FRONTEND=noninteractive
          apt-get update || true
          apt-get install -y ca-certificates curl wget git bash sudo tar || true
          rm -rf /var/lib/apt/lists/* 2>/dev/null || true
        elif command -v apk >/dev/null 2>&1; then
          apk add --no-cache ca-certificates curl wget git bash shadow sudo tar || true
        elif command -v dnf >/dev/null 2>&1; then
          dnf install -y ca-certificates curl wget git bash sudo shadow-utils tar || true
        elif command -v yum >/dev/null 2>&1; then
          yum install -y ca-certificates curl wget git bash sudo shadow-utils tar || true
        fi

        if ! command -v docker >/dev/null 2>&1; then
          docker_arch=""
          case "$(uname -m)" in
            x86_64|amd64) docker_arch="x86_64" ;;
            aarch64|arm64) docker_arch="aarch64" ;;
            armv7l|armhf) docker_arch="armhf" ;;
          esac
          if [ -n "$docker_arch" ] && command -v tar >/dev/null 2>&1; then
            docker_version="29.6.0"
            docker_url="https://download.docker.com/linux/static/stable/$docker_arch/docker-$docker_version.tgz"
            docker_tmp="$(mktemp -d 2>/dev/null || echo /tmp/docker-cli-install)"
            rm -rf "$docker_tmp"
            mkdir -p "$docker_tmp"
            if command -v curl >/dev/null 2>&1; then
              curl -fsSL "$docker_url" -o "$docker_tmp/docker.tgz" || true
            elif command -v wget >/dev/null 2>&1; then
              wget -qO "$docker_tmp/docker.tgz" "$docker_url" || true
            fi
            if [ -s "$docker_tmp/docker.tgz" ] && tar -xzf "$docker_tmp/docker.tgz" -C "$docker_tmp" 2>/dev/null; then
              install -m 0755 "$docker_tmp/docker/docker" /usr/local/bin/docker 2>/dev/null || {
                cp "$docker_tmp/docker/docker" /usr/local/bin/docker 2>/dev/null || true
                chmod 0755 /usr/local/bin/docker 2>/dev/null || true
              }
            fi
            rm -rf "$docker_tmp"
          fi
        fi

        if ! command -v docker >/dev/null 2>&1; then
          echo "warning: Docker CLI is still unavailable after bootstrap" >&2
        fi
      }

      ensure_group() {
        name="$1"
        gid="$2"
        if [ -n "$gid" ] && awk -F: -v gid="$gid" '$3 == gid { found=1 } END { exit found ? 0 : 1 }' /etc/group 2>/dev/null; then
          return 0
        fi
        if grep -q "^$name:" /etc/group 2>/dev/null; then
          return 0
        fi
        if command -v groupadd >/dev/null 2>&1; then
          if [ -n "$gid" ]; then
            groupadd --gid "$gid" "$name" 2>/dev/null || true
          else
            groupadd "$name" 2>/dev/null || true
          fi
        elif command -v addgroup >/dev/null 2>&1; then
          if [ -n "$gid" ]; then
            addgroup -g "$gid" "$name" 2>/dev/null || true
          else
            addgroup "$name" 2>/dev/null || true
          fi
        fi
      }

      configure_coder_user() {
        if command -v sudo >/dev/null 2>&1; then
          mkdir -p /etc/sudoers.d
          printf 'coder ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/coder
          chmod 0440 /etc/sudoers.d/coder
        fi
        if [ -d /usr/local/share/nvm ]; then
          chown coder:coder /usr/local/share/nvm 2>/dev/null || true
          chown -h coder:coder /usr/local/share/nvm/current 2>/dev/null || true
        fi
      }

      install_basics
      chmod 0644 /etc/resolv.conf /etc/hosts 2>/dev/null || true
      if ! id coder >/dev/null 2>&1; then
        ensure_group coder ""
        useradd --create-home --home-dir /home/coder --shell /bin/bash --gid coder coder 2>/dev/null || \
          useradd -m -d /home/coder -s /bin/sh -g coder coder 2>/dev/null || \
          adduser -D -h /home/coder -s /bin/sh -G coder coder 2>/dev/null || true
      fi
      configure_coder_user
      mkdir -p /workspaces /home/coder /home/coder/.vscode-server /home/coder/.local/share/code-server /home/coder/.config/code-server /home/coder/.cache
      chown -R coder:coder /workspaces /home/coder 2>/dev/null || true
      docker_group="$(awk -F: -v gid="${var.docker_socket_group_id}" '$3 == gid { print $1; exit }' /etc/group 2>/dev/null || true)"
      if [ -z "$docker_group" ]; then
        ensure_group docker-host "${var.docker_socket_group_id}"
        docker_group="$(awk -F: -v gid="${var.docker_socket_group_id}" '$3 == gid { print $1; exit }' /etc/group 2>/dev/null || true)"
      fi
      if [ -n "$docker_group" ]; then
        usermod --append --groups "$docker_group" coder 2>/dev/null || true
        adduser coder "$docker_group" 2>/dev/null || true
      fi
      cat >/tmp/coder-init.sh <<'CODER_INIT'
${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}
CODER_INIT
      chmod 0755 /tmp/coder-init.sh
      chown coder:coder /tmp/coder-init.sh 2>/dev/null || true
      exec su coder -c /tmp/coder-init.sh
    EOT
  ]

  env       = local.docker_env
  group_add = compact([var.docker_socket_group_id])

  cpu_period = 100000
  cpu_quota  = tonumber(data.coder_parameter.cpu_cores.value) * 100000
  cpu_shares = tonumber(data.coder_parameter.cpu_cores.value) * 1024
  memory      = tonumber(data.coder_parameter.memory_gb.value) * 1024
  memory_swap = tonumber(data.coder_parameter.memory_gb.value) * 1024

  capabilities {
    add = ["SYS_PTRACE"]
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    volume_name    = docker_volume.workspaces.name
    container_path = "/workspaces"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.home.name
    container_path = "/home/coder"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.vscode_server.name
    container_path = "/home/coder/.vscode-server"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.code_server_data.name
    container_path = "/home/coder/.local/share/code-server"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.code_server_config.name
    container_path = "/home/coder/.config/code-server"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.cache.name
    container_path = "/home/coder/.cache"
    read_only      = false
  }

  volumes {
    host_path      = var.docker_socket_path
    container_path = "/var/run/docker.sock"
    read_only      = false
  }

  dynamic "labels" {
    for_each = local.docker_labels
    iterator = docker_label
    content {
      label = docker_label.key
      value = docker_label.value
    }
  }
}

resource "coder_metadata" "workspace" {
  count       = data.coder_workspace.me.start_count
  resource_id = coder_agent.main.id

  item {
    key   = "mode"
    value = "docker-envbuilder"
  }
  item {
    key   = "repo"
    value = local.repo_url == "" ? "none" : local.repo_url
  }
  item {
    key   = "workspace folder"
    value = local.workspace_dir
  }
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory_gb.value} GB"
  }
  item {
    key   = "base image"
    value = local.base_image
  }
}

output "workspace_directory" {
  value       = local.workspace_dir
  description = "Primary workspace directory."
}

output "template_mode" {
  value       = "docker-envbuilder"
  description = "Template implementation mode."
}
