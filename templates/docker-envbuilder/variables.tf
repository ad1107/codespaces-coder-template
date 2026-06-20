variable "docker_socket_path" {
  type        = string
  description = "Path to the host Docker socket used by the Docker provider and mounted into workspaces."
  default     = "/var/run/docker.sock"
}

variable "docker_socket_group_id" {
  type        = string
  description = "Supplemental group ID that can read the mounted Docker socket. Check with `getent group docker | cut -d: -f3` on the host."
  default     = "999"
}

variable "envbuilder_image" {
  type        = string
  description = "Envbuilder image used to build and start workspaces."
  default     = "ghcr.io/coder/envbuilder:latest"
}

variable "fallback_image" {
  type        = string
  description = "Admin fallback image used when the Base Image parameter is custom but empty."
  default     = "mcr.microsoft.com/devcontainers/universal:linux"
}
