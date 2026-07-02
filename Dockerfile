FROM debian:bookworm-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    zsh \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    make \
    apt-transport-https \
    ca-certificates \
    gnupg \
    jq \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Go from official tarball
RUN GO_VERSION=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1) \
    && curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    && tar xf lazygit.tar.gz lazygit \
    && install lazygit /usr/local/bin \
    && rm lazygit lazygit.tar.gz

# Install Node.js (needed by some Claude MCP plugins)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install uv (provides uvx) — needed for MCP servers
RUN pip install --break-system-packages uv

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

# Create cj user (UID 1000) with zsh
RUN useradd -m -u 1000 -s /bin/zsh cj

# Shell config
COPY scripts/.zshrc /home/cj/.zshrc

# Pre-create directories that will be used as mount points or by podman cp,
# so they exist and are owned by cj before any runtime mounts.
RUN mkdir -p /home/cj/.claude \
             /home/cj/.config/gh \
             /home/cj/.config/gcloud \
             /home/cj/project

# Ensure cj user owns its home directory
RUN chown -R cj:cj /home/cj

# Install Claude Code via native installer
USER cj
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/cj/.local/bin:${PATH}"

WORKDIR /home/cj

# Project is copied in by the run script after container start
# Keep container alive; user attaches via exec
CMD ["sleep", "infinity"]
