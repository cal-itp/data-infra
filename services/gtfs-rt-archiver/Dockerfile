# Stage 1: Base build stage
FROM python:3.11-slim AS builder

 # Install uv
COPY --from=ghcr.io/astral-sh/uv:0.11.5 /uv /uvx /bin/

# Create the app directory
RUN mkdir /app

# Set the working directory
WORKDIR /app

# Set environment variables to optimize Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# Copy dependency management files
COPY pyproject.toml uv.lock .

# install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    git

# Synchronize dependencies.
# This layer is cached until uv.lock or pyproject.toml change.
RUN --mount=type=cache,target=/root/.cache \
    uv sync \
    --no-dev \
    --frozen \
    --no-install-project \
    --compile-bytecode

# Stage 2: Production stage
FROM python:3.11-slim

 # Install uv
COPY --from=ghcr.io/astral-sh/uv:0.11.5 /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# Set environment variables to optimize Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# Copy the virtual environment from the builder stage
COPY --from=builder /app /app

# Copy project files
COPY . /app/

# Install package
RUN --mount=type=cache,target=/root/.cache \
    uv sync \
    --no-dev \
    --frozen

CMD ["uv", "run",  "--no-sync", "subscriber.py"]
