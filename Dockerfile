FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    zsh \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    golang \
    make \
    apt-transport-https \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    && tar xf lazygit.tar.gz lazygit \
    && install lazygit /usr/local/bin \
    && rm lazygit lazygit.tar.gz

# Install uv (provides uvx) — needed for MCP servers
RUN pip install --break-system-packages uv

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK (includes gsutil)
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update && apt-get install -y google-cloud-cli && rm -rf /var/lib/apt/lists/*

# Git wrapper that blocks push operations
COPY scripts/git-wrapper.sh /usr/local/bin/git
RUN chmod +x /usr/local/bin/git

# Shell config
COPY scripts/.zshrc /home/node/.zshrc

# Set zsh as default shell for node user
RUN usermod -s /bin/zsh node

# Pre-create directories that will be used as mount points or by podman cp,
# so they exist and are owned by node before any runtime mounts.
RUN mkdir -p /home/node/.claude \
             /home/node/.config/gh \
             /home/node/.config/gcloud \
             /home/node/project

# Ensure node user owns its home directory
RUN chown -R node:node /home/node

# Use existing node user (UID 1000) — matches podman rootless default mapping
USER node
WORKDIR /home/node

# Project is copied in by the run script after container start
# Keep container alive; user attaches via exec
CMD ["sleep", "infinity"]
