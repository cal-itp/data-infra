FROM python:3.11-slim-bookworm

LABEL org.opencontainers.image.source="https://github.com/cal-itp/data-infra"

# ---- Environment ------------------------------------------------------------
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    USER=calitp

# ---- System packages (single RUN, apt cache mount) -------------------------
# BuildKit cache mount keeps the apt package archive between builds
RUN --mount=type=cache,target=/var/cache/apt \
    # Install packages that are already in default Debian repos
    apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    libgdal-dev \
    tzdata \
    ssh \
    make \
    rsync \
    git \
    gh && \
    \
    # Add Google Cloud SDK repository
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    \
    # Update package list with new repo and install google-cloud-cli
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-cli && \
    \
    # Add the official HashiCorp repository
    curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" \
    > /etc/apt/sources.list.d/hashicorp.list && \
    \
    # Update package lists and install Terraform
    apt-get update && \
    apt-get install -y --no-install-recommends terraform && \
    \
    # Clean up apt lists
    rm -rf /var/lib/apt/lists/*

# ---- Non‑root user ---------------------------------------------------------
RUN useradd --create-home --shell /bin/bash $USER && \
    chown -R $USER:$USER /home/$USER

USER $USER
# ---- Python / uv -----------------------------------------------------------
ENV PATH="$PATH:/home/$USER/.local/bin"
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir "uv==0.11.11"
RUN uv tool install black && \
    uv tool install memray && \
    uv tool install pre-commit

WORKDIR /workspaces/data-infra
