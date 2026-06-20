# Homelab Install

These commands are intentionally generic. Replace the example Coder URL and checkout path with values for your own deployment.

## Initial Clone

```bash
coder login https://coder.example.com
git clone https://github.com/example/codespaces-coder-template.git
cd codespaces-coder-template
```

## Push v1 Template

```bash
cd templates/docker-envbuilder
coder templates push codespaces-envbuilder
coder templates edit codespaces-envbuilder \
  --display-name "Codespaces Envbuilder" \
  --icon "/icon/devcontainers.svg" \
  --default-ttl 8h \
  --yes
```

## Push v2 Template

```bash
cd ../docker-devcontainer-integration
coder templates push codespaces-devcontainer
coder templates edit codespaces-devcontainer \
  --display-name "Codespaces Devcontainer" \
  --icon "/icon/devcontainers.svg" \
  --default-ttl 8h \
  --yes
```

## Upgrade

```bash
cd /path/to/codespaces-coder-template
git pull

cd templates/docker-envbuilder
coder templates push codespaces-envbuilder
coder templates edit codespaces-envbuilder --display-name "Codespaces Envbuilder" --icon "/icon/devcontainers.svg" --default-ttl 8h --yes
```

## Docker Socket Group

If `docker ps` fails inside a workspace with a permissions error, check the host Docker group ID:

```bash
getent group docker | cut -d: -f3
```

Then update the template variable `docker_socket_group_id` to that value before pushing the template again.

## Safety

Do not overwrite the old broken template until the new one passes the acceptance tests in `tests/acceptance.md`.
