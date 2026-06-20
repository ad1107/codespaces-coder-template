#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

test -d "$root/legacy/old-template" || fail "legacy/old-template is missing"
test -f "$root/templates/docker-envbuilder/main.tf" || fail "docker-envbuilder template is missing"
test -f "$root/templates/docker-devcontainer-integration/main.tf" || fail "docker-devcontainer-integration template is missing"
test -f "$root/templates/docker-envbuilder/template.json" || fail "docker-envbuilder metadata is missing"
test -f "$root/templates/docker-devcontainer-integration/template.json" || fail "docker-devcontainer metadata is missing"

grep -F '"name": "Codespaces Envbuilder"' "$root/templates/docker-envbuilder/template.json" >/dev/null || fail "envbuilder display name metadata is wrong"
grep -F '"name": "Codespaces Devcontainer"' "$root/templates/docker-devcontainer-integration/template.json" >/dev/null || fail "devcontainer display name metadata is wrong"
grep -F '"icon": "/icon/devcontainers.svg"' "$root/templates/docker-envbuilder/template.json" >/dev/null || fail "envbuilder icon metadata is wrong"
grep -F '"icon": "/icon/devcontainers.svg"' "$root/templates/docker-devcontainer-integration/template.json" >/dev/null || fail "devcontainer icon metadata is wrong"

if grep -R "postCreateCommand" "$root/templates" >/dev/null; then
  fail "templates must not manually handle postCreateCommand"
fi

if grep -R "jq" "$root/templates" >/dev/null; then
  fail "templates must not parse devcontainer.json with jq"
fi

grep -R 'ghcr.io/coder/envbuilder' "$root/templates/docker-envbuilder" >/dev/null || fail "envbuilder image is not used"
grep -R 'mcr.microsoft.com/devcontainers/universal:linux' "$root/templates" >/dev/null || fail "universal devcontainer image preset is missing"
grep -R 'mcr.microsoft.com/devcontainers/base:debian-12' "$root/templates/docker-envbuilder" >/dev/null || fail "envbuilder Debian preset is missing"
grep -R 'mcr.microsoft.com/devcontainers/base:alpine-3.22' "$root/templates/docker-envbuilder" >/dev/null || fail "envbuilder Alpine preset is missing"
grep -R 'mcr.microsoft.com/devcontainers/javascript-node:22-bookworm' "$root/templates/docker-devcontainer-integration" >/dev/null || fail "v2 Node parent preset is missing"
grep -R 'custom_base_image' "$root/templates/docker-envbuilder" >/dev/null || fail "envbuilder custom image parameter is missing"
grep -R 'custom_parent_image' "$root/templates/docker-devcontainer-integration" >/dev/null || fail "v2 custom parent image parameter is missing"
grep -R 'download.docker.com/linux/static/stable' "$root/templates/docker-envbuilder" >/dev/null || fail "envbuilder Docker CLI bootstrap is missing"
grep -R 'download.docker.com/linux/static/stable' "$root/templates/docker-devcontainer-integration" >/dev/null || fail "v2 Docker CLI bootstrap is missing"
grep -R 'expose_node_tools' "$root/templates/docker-devcontainer-integration" >/dev/null || fail "v2 NVM package-manager exposure is missing"
grep -R 'NOPASSWD:ALL' "$root/templates" >/dev/null || fail "passwordless sudo bootstrap is missing"
grep -RF 'regex = "^\\S.*devcontainer\\.json$"' "$root/templates" >/dev/null || fail "devcontainer path regex must be JS-compatible"
grep -R 'default      = "2"' "$root/templates/docker-envbuilder/main.tf" >/dev/null || fail "CPU default is not 2"
grep -R 'default      = "3"' "$root/templates/docker-envbuilder/main.tf" >/dev/null || fail "memory default is not 3"
grep -R 'value = "6"' "$root/templates/docker-envbuilder/main.tf" >/dev/null || fail "memory max option 6 is missing"

if command -v node >/dev/null 2>&1; then
  node -e 'const re = new RegExp("^\\S.*devcontainer\\.json$"); if (!re.test(".devcontainer/devcontainer.json")) process.exit(1)' \
    || fail "devcontainer path regex rejects the default in JavaScript"
fi

if grep -R 'default      = "8"' "$root/templates" >/dev/null; then
  fail "a template defaults to 8 GB"
fi

grep -R 'coder_devcontainer' "$root/templates/docker-devcontainer-integration" >/dev/null || fail "v2 does not use coder_devcontainer"

echo "Smoke checks passed."
