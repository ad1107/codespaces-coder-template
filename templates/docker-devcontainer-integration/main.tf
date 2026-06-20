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
  description  = "CPU cores for the parent workspace container."
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
  description  = "RAM for the parent workspace container."
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
  description  = "Only homelab-comfy persistence is implemented."
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

data "coder_parameter" "parent_image_preset" {
  name         = "parent_image_preset"
  display_name = "Parent Image"
  description  = "Image for the parent Coder workspace that installs and runs @devcontainers/cli."
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
    name  = "Node 22 Debian 12"
    value = "mcr.microsoft.com/devcontainers/javascript-node:22-bookworm"
  }
  option {
    name  = "Node 22 Bullseye"
    value = "mcr.microsoft.com/devcontainers/javascript-node:22-bullseye"
  }
  option {
    name  = "Coder Node Ubuntu"
    value = "codercom/enterprise-node:ubuntu"
  }
  option {
    name  = "Custom image"
    value = "custom"
  }
}

data "coder_parameter" "custom_parent_image" {
  name         = "custom_parent_image"
  display_name = "Custom Parent Image"
  description  = "Optional image reference used only when Parent Image is Custom image. Apt/apk/yum/dnf images are bootstrapped with missing basics; very minimal images should include sh, curl or wget, Docker CLI, and npm/yarn/pnpm."
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
  repo_url      = trimspace(data.coder_parameter.repo_url.value)
  repo_branch   = trimspace(data.coder_parameter.repo_branch.value)
  repo_name     = local.repo_url != "" ? trimsuffix(basename(local.repo_url), ".git") : ""
  workspace_dir = local.repo_url != "" ? "/workspaces/${local.repo_name}" : "/workspaces"
  parent_image_preset = trimspace(data.coder_parameter.parent_image_preset.value)
  custom_parent_image = trimspace(data.coder_parameter.custom_parent_image.value)
  parent_image = (
    local.parent_image_preset == "custom" && local.custom_parent_image != "" ?
    local.custom_parent_image :
    local.parent_image_preset != "custom" ? local.parent_image_preset : var.workspace_image
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
    "template.name"                  = "codespaces-devcontainer"
    "template.mode"                  = "docker-devcontainer-integration"
  }
}

resource "docker_image" "workspace" {
  name         = local.parent_image
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

  startup_script = file("${path.module}/scripts/bootstrap.sh")

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

resource "coder_script" "clone_repo" {
  count              = data.coder_workspace.me.start_count
  agent_id           = coder_agent.main.id
  display_name       = "Clone repository"
  icon               = "/icon/git.svg"
  script             = file("${path.module}/scripts/clone-repo.sh")
  run_on_start       = true
  start_blocks_login = true
}

resource "coder_script" "install_dotfiles" {
  count        = data.coder_workspace.me.start_count
  agent_id     = coder_agent.main.id
  display_name = "Install dotfiles"
  icon         = "/icon/git.svg"
  script       = file("${path.module}/scripts/install-dotfiles.sh")
  run_on_start = true
}

resource "coder_script" "healthcheck" {
  count        = data.coder_workspace.me.start_count
  agent_id     = coder_agent.main.id
  display_name = "Workspace healthcheck"
  icon         = "/emojis/2705.png"
  script       = file("${path.module}/scripts/healthcheck.sh")
  run_on_start = true
}

module "devcontainers-cli" {
  count              = data.coder_workspace.me.start_count
  source             = "registry.coder.com/coder/devcontainers-cli/coder"
  version            = "~> 1.0"
  agent_id           = coder_agent.main.id
  start_blocks_login = true
}

resource "coder_devcontainer" "repo" {
  count            = data.coder_workspace.me.start_count == 0 || local.repo_url == "" ? 0 : 1
  agent_id         = coder_agent.main.id
  workspace_folder = local.workspace_dir
  config_path      = data.coder_parameter.devcontainer_path.value

  depends_on = [
    coder_script.clone_repo,
    module.devcontainers-cli,
  ]
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
  count    = data.coder_workspace.me.start_count
  image    = docker_image.workspace.image_id
  name     = "coder-${data.coder_workspace.me.id}-devcontainer-parent"
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

      expose_node_tools() {
        for dir in \
          /usr/local/share/nvm/current/bin \
          /usr/local/share/nvm/versions/node/*/bin \
          /opt/nodejs/*/bin \
          /usr/local/node*/bin; do
          [ -d "$dir" ] || continue
          for tool in node npm yarn pnpm; do
            if [ -x "$dir/$tool" ] && [ ! -x "/usr/local/bin/$tool" ]; then
              ln -sf "$dir/$tool" "/usr/local/bin/$tool" 2>/dev/null || true
            fi
          done
        done
      }

      install_basics
      expose_node_tools
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
  env       = ["CODER_AGENT_TOKEN=${coder_agent.main.token}", "DOCKER_HOST=unix:///var/run/docker.sock"]
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
    value = "docker-devcontainer-integration"
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
    key   = "parent image"
    value = local.parent_image
  }
}

output "workspace_directory" {
  value       = local.workspace_dir
  description = "Primary parent workspace directory."
}

output "template_mode" {
  value       = "docker-devcontainer-integration"
  description = "Template implementation mode."
}
