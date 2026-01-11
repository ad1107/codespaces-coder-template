# Custom Dockerfile for extending the Universal DevContainer
# Use this if you need to pre-install additional tools
#
# To use: Update main.tf to build from this Dockerfile instead of pulling the image

ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/universal:latest
FROM ${BASE_IMAGE}

# Switch to root for installations
USER root

# -----------------------------------------------------------------------------
# System Updates and Common Tools
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        # Common development tools
        build-essential \
        cmake \
        pkg-config \
        # Network tools
        curl \
        wget \
        dnsutils \
        iputils-ping \
        netcat-openbsd \
        # File tools
        zip \
        unzip \
        tree \
        jq \
        # Process tools
        htop \
        procps \
        # Version control
        git-lfs \
        # Security
        gnupg2 \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Install code-server (VS Code in browser)
# -----------------------------------------------------------------------------
RUN curl -fsSL https://code-server.dev/install.sh | sh

# -----------------------------------------------------------------------------
# Configure code-server
# -----------------------------------------------------------------------------
RUN mkdir -p /home/coder/.config/code-server \
    && echo 'bind-addr: 0.0.0.0:13337' > /home/coder/.config/code-server/config.yaml \
    && echo 'auth: none' >> /home/coder/.config/code-server/config.yaml \
    && echo 'cert: false' >> /home/coder/.config/code-server/config.yaml

# -----------------------------------------------------------------------------
# Pre-install popular VS Code extensions (optional)
# -----------------------------------------------------------------------------
# Uncomment to pre-install extensions:
# RUN code-server --install-extension ms-python.python \
#     && code-server --install-extension ms-vscode.vscode-typescript-next \
#     && code-server --install-extension esbenp.prettier-vscode \
#     && code-server --install-extension dbaeumer.vscode-eslint

# -----------------------------------------------------------------------------
# GitHub CLI
# -----------------------------------------------------------------------------
RUN (type -p wget >/dev/null || (apt update && apt-get install wget -y)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Create workspace directory structure
# -----------------------------------------------------------------------------
RUN mkdir -p /home/coder/workspace \
    && mkdir -p /home/coder/.vscode-server/extensions \
    && mkdir -p /home/coder/.local/bin

# -----------------------------------------------------------------------------
# Setup shell configurations
# -----------------------------------------------------------------------------
# Add useful aliases and configurations
RUN echo '\n\
# Coder workspace aliases\n\
alias ll="ls -alF"\n\
alias la="ls -A"\n\
alias l="ls -CF"\n\
alias ..="cd .."\n\
alias ...="cd ../.."\n\
alias gs="git status"\n\
alias gp="git pull"\n\
alias gc="git commit"\n\
alias gco="git checkout"\n\
alias gd="git diff"\n\
\n\
# Add local bin to PATH\n\
export PATH="$HOME/.local/bin:$PATH"\n\
\n\
# Set default editor\n\
export EDITOR="code --wait"\n\
export VISUAL="code --wait"\n\
' >> /home/coder/.bashrc

# Same for zsh if present
RUN if [ -f /home/coder/.zshrc ]; then \
    echo '\n\
# Coder workspace aliases\n\
alias ll="ls -alF"\n\
alias la="ls -A"\n\
alias l="ls -CF"\n\
alias ..="cd .."\n\
alias ...="cd ../.."\n\
alias gs="git status"\n\
alias gp="git pull"\n\
alias gc="git commit"\n\
alias gco="git checkout"\n\
alias gd="git diff"\n\
\n\
# Add local bin to PATH\n\
export PATH="$HOME/.local/bin:$PATH"\n\
\n\
# Set default editor\n\
export EDITOR="code --wait"\n\
export VISUAL="code --wait"\n\
' >> /home/coder/.zshrc; \
    fi

# -----------------------------------------------------------------------------
# Fix permissions
# -----------------------------------------------------------------------------
RUN chown -R coder:coder /home/coder

# -----------------------------------------------------------------------------
# Switch back to coder user
# -----------------------------------------------------------------------------
USER coder

# Set working directory
WORKDIR /home/coder/workspace

# Default command (overridden by Coder agent)
CMD ["sleep", "infinity"]
