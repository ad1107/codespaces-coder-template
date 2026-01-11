terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.5"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables (Parameters shown in Coder UI)
# -----------------------------------------------------------------------------

variable "docker_socket" {
  type        = string
  description = "Path to Docker socket on the Coder host"
  default     = "/var/run/docker.sock"
}

data "coder_parameter" "repo_url" {
  name         = "repo_url"
  display_name = "Git Repository URL"
  description  = "GitHub repository to clone (optional). Leave empty to start with an empty workspace."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/github.svg"
  order        = 1
}

data "coder_parameter" "custom_image" {
  name         = "custom_image"
  display_name = "Custom Docker Image"
  description  = "Override the default devcontainer image (optional). Leave empty to use the Universal image."
  type         = "string"
  default      = ""
  mutable      = false
  icon         = "/icon/docker.svg"
  order        = 2
}

data "coder_parameter" "dotfiles_repo" {
  name         = "dotfiles_repo"
  display_name = "Dotfiles Repository"
  description  = "Personal dotfiles repo URL (optional). Will be cloned and installed automatically."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 3
}

data "coder_parameter" "git_author_name" {
  name         = "git_author_name"
  display_name = "Git Author Name"
  description  = "Your name for Git commits"
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 4
}

data "coder_parameter" "git_author_email" {
  name         = "git_author_email"
  display_name = "Git Author Email"
  description  = "Your email for Git commits"
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/git.svg"
  order        = 5
}

data "coder_parameter" "cpu_cores" {
  name         = "cpu_cores"
  display_name = "CPU Cores"
  description  = "Number of CPU cores to allocate"
  type         = "number"
  default      = "4"
  mutable      = false
  icon         = "/icon/memory.svg"
  order        = 6

  validation {
    min = 1
    max = 16
  }
}

data "coder_parameter" "memory_gb" {
  name         = "memory_gb"
  display_name = "Memory (GB)"
  description  = "Amount of RAM to allocate in GB"
  type         = "number"
  default      = "8"
  mutable      = false
  icon         = "/icon/memory.svg"
  order        = 7

  validation {
    min = 1
    max = 64
  }
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------

provider "coder" {}

provider "docker" {
  host = "unix://${var.docker_socket}"
}

# -----------------------------------------------------------------------------
# Coder Data Sources
# -----------------------------------------------------------------------------

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  # Use custom image if provided, otherwise use the Universal devcontainer image
  container_image = data.coder_parameter.custom_image.value != "" ? data.coder_parameter.custom_image.value : "mcr.microsoft.com/devcontainers/universal:latest"

  # Extract repo name from URL for workspace folder (like GitHub Codespaces)
  repo_name = data.coder_parameter.repo_url.value != "" ? regex("([^/]+?)(\\.git)?$", data.coder_parameter.repo_url.value)[0] : ""

  # Working directory - /workspaces/{repo_name} or just /workspaces (like GitHub Codespaces)
  workspace_dir = data.coder_parameter.repo_url.value != "" ? "/workspaces/${local.repo_name}" : "/workspaces"

  # Username - the Universal image uses "codespace" user (same as GitHub Codespaces)
  username = "codespace"

  # Git configuration
  git_author_name  = data.coder_parameter.git_author_name.value != "" ? data.coder_parameter.git_author_name.value : data.coder_workspace_owner.me.full_name
  git_author_email = data.coder_parameter.git_author_email.value != "" ? data.coder_parameter.git_author_email.value : data.coder_workspace_owner.me.email
}

# -----------------------------------------------------------------------------
# Coder Agent
# -----------------------------------------------------------------------------

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  dir  = local.workspace_dir

  startup_script = templatefile("${path.module}/scripts/startup.sh", {
    GIT_AUTHOR_NAME  = local.git_author_name
    GIT_AUTHOR_EMAIL = local.git_author_email
    REPO_URL         = data.coder_parameter.repo_url.value
    WORKSPACE_DIR    = local.workspace_dir
    DOTFILES_REPO    = data.coder_parameter.dotfiles_repo.value
    USERNAME         = local.username
  })

  env = {
    GIT_AUTHOR_NAME     = local.git_author_name
    GIT_AUTHOR_EMAIL    = local.git_author_email
    GIT_COMMITTER_NAME  = local.git_author_name
    GIT_COMMITTER_EMAIL = local.git_author_email
    CODER_WORKSPACE     = data.coder_workspace.me.name
    WORKSPACE_FOLDER    = local.workspace_dir
  }

  metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    order        = 1
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage"
    key          = "mem_usage"
    order        = 2
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk Usage"
    key          = "disk_usage"
    order        = 3
    script       = "coder stat disk --path /workspaces"
    interval     = 60
    timeout      = 1
  }
}

# -----------------------------------------------------------------------------
# VS Code Web - Using Official Coder Module
# -----------------------------------------------------------------------------

module "vscode-web" {
  count          = data.coder_workspace.me.start_count
  source         = "registry.coder.com/coder/vscode-web/coder"
  version        = "1.4.3"
  agent_id       = coder_agent.main.id
  folder         = local.workspace_dir
  accept_license = true
  subdomain      = false
  extensions     = ["ms-python.python", "esbenp.prettier-vscode"]
}

# -----------------------------------------------------------------------------
# VS Code Desktop - Opens to workspace folder
# -----------------------------------------------------------------------------

module "vscode" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/vscode-desktop/coder"
  version  = "1.2.0"
  agent_id = coder_agent.main.id
  folder   = local.workspace_dir
}

# -----------------------------------------------------------------------------
# Docker Volumes for Persistence
# -----------------------------------------------------------------------------

# Home directory for codespace user - persists user configs, dotfiles, etc.
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"

  labels {
    label = "coder.workspace.id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace.name"
    value = data.coder_workspace.me.name
  }
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
}

# /workspaces directory - persists all project files (like GitHub Codespaces)
resource "docker_volume" "workspaces_volume" {
  name = "coder-${data.coder_workspace.me.id}-workspaces"

  labels {
    label = "coder.workspace.id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace.name"
    value = data.coder_workspace.me.name
  }
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
}

# VS Code Server extensions and settings
resource "docker_volume" "vscode_volume" {
  name = "coder-${data.coder_workspace.me.id}-vscode"

  labels {
    label = "coder.workspace.id"
    value = data.coder_workspace.me.id
  }
}

# -----------------------------------------------------------------------------
# Docker Image
# -----------------------------------------------------------------------------

resource "docker_image" "main" {
  name         = local.container_image
  keep_locally = true
}

# -----------------------------------------------------------------------------
# Docker Container
# -----------------------------------------------------------------------------

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  image    = docker_image.main.image_id
  hostname = data.coder_workspace.me.name

  # Run as codespace user (UID 1000) - same as GitHub Codespaces
  user = "1000:1000"

  cpu_shares = data.coder_parameter.cpu_cores.value * 1024
  memory     = data.coder_parameter.memory_gb.value * 1024 * 1024 * 1024

  privileged = false

  capabilities {
    add = ["SYS_PTRACE", "NET_ADMIN", "NET_RAW"]
  }

  dns = ["8.8.8.8", "8.8.4.4"]

  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "CODER_WORKSPACE_NAME=${data.coder_workspace.me.name}",
    "CODER_OWNER_NAME=${data.coder_workspace_owner.me.name}",
    "GIT_AUTHOR_NAME=${local.git_author_name}",
    "GIT_AUTHOR_EMAIL=${local.git_author_email}",
    "GIT_COMMITTER_NAME=${local.git_author_name}",
    "GIT_COMMITTER_EMAIL=${local.git_author_email}",
    "WORKSPACE_FOLDER=${local.workspace_dir}",
    "TERM=xterm-256color",
    "TZ=UTC",
    "USER=${local.username}",
    "HOME=/home/${local.username}",
  ]

  # Working directory
  working_dir = local.workspace_dir

  # Volume mounts for persistence
  volumes {
    volume_name    = docker_volume.home_volume.name
    container_path = "/home/${local.username}"
  }

  volumes {
    volume_name    = docker_volume.workspaces_volume.name
    container_path = "/workspaces"
  }

  volumes {
    volume_name    = docker_volume.vscode_volume.name
    container_path = "/home/${local.username}/.vscode-server"
  }

  # Mount Docker socket for Docker-in-Docker capabilities
  volumes {
    host_path      = var.docker_socket
    container_path = "/var/run/docker.sock"
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "container_image" {
  description = "Docker image used for this workspace"
  value       = local.container_image
}

output "workspace_directory" {
  description = "Primary workspace directory"
  value       = local.workspace_dir
}

output "username" {
  description = "Username in the container"
  value       = local.username
}
