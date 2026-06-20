variable "docker_socket_path" {
  type        = string
  description = "Path to the host Docker socket."
  default     = "/var/run/docker.sock"
}

variable "docker_socket_group_id" {
  type        = string
  description = "Supplemental group ID that can read the mounted Docker socket. Check with `getent group docker | cut -d: -f3` on the host."
  default     = "999"
}

variable "workspace_image" {
  type        = string
  description = "Admin fallback parent image used when the Parent Image parameter is custom but empty."
  default     = "mcr.microsoft.com/devcontainers/universal:linux"
}
